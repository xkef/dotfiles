-- Tab titles and the status line, a plain bar at the bottom. Every
-- color names an ANSI slot, so a tinty switch recolors the bar with the
-- terminal.
local wezterm = require("wezterm")
local act = wezterm.action
local vm = require("vm")
local path = require("path")

local M = {}

-- The helper forks, so the status line refreshes its output at this
-- interval instead of on every redraw.
local SYSSTAT_INTERVAL = 5
local CPU_HIGH = 80
local TAB_GAP = "   "

-- How long a notice stays in the status line, in seconds.
local NOTICE_SECONDS = 2

-- The notice each window shows, by window id.
local notices = {}

-- The mode label for each copy-mode selection mode, as tmux names them.
local SELECTION_LABELS = { Cell = "VISUAL", Line = "V-LINE", Block = "V-BLOCK" }

-- The copy-mode selection mode of each pane, by pane id, like @mode in
-- tmux's copy-mode.conf. WezTerm doesn't expose the mode, so select()
-- records it.
local selections = {}

local function basename(path)
  return (path or ""):match("([^/]+)$") or ""
end

-- The program a tab shows: the command fish
-- runs, from the WEZTERM_PROG var that fish/conf.d/wezterm.fish sets, or
-- the shell at the prompt.
local SHELL = basename(os.getenv("SHELL"))
local function program(pane)
  local command = (pane.user_vars.WEZTERM_PROG or ""):match("^%s*(%S+)")
  if command then
    return basename(command)
  end
  local name = basename(pane.foreground_process_name)
  if name ~= "" then
    return name
  end
  return SHELL ~= "" and SHELL or pane.title
end

-- The output of args, without trailing whitespace, run again once it is
-- older than interval seconds. wezterm.GLOBAL keeps it across config
-- reloads under name.
local function cached(name, interval, args)
  local cache = wezterm.GLOBAL[name] or { at = 0, text = "" }
  if os.time() - cache.at >= interval then
    local ok, out = wezterm.run_child_process(path.command(args))
    cache = { at = os.time(), text = ok and out:gsub("%s+$", "") or "" }
    wezterm.GLOBAL[name] = cache
  end
  return cache.text
end

-- CPU and memory. mux-sysstat prints "<cpu%>\t<used>/<total>G".
local function sysstat()
  local text = cached("sysstat", SYSSTAT_INTERVAL, { "mux-sysstat" })
  local cpu, mem = text:match("^(%d+)\t(%S+)")
  if not cpu then
    return {}
  end
  return {
    { Foreground = { AnsiColor = tonumber(cpu) >= CPU_HIGH and "Maroon" or "Grey" } },
    { Text = cpu .. "%  " },
    { Foreground = { AnsiColor = "Grey" } },
    { Text = mem .. "  " },
  }
end

local function update(window, pane)
  window:set_left_status(wezterm.format({
    { Foreground = { AnsiColor = "Purple" } },
    { Attribute = { Intensity = "Bold" } },
    { Attribute = { Italic = true } },
    { Text = " " .. window:active_workspace() .. " § " },
  }))

  local right = {}
  local notice = notices[window:window_id()]
  if notice then
    table.insert(right, { Foreground = { AnsiColor = "Green" } })
    table.insert(right, { Text = notice.text .. "  " })
  end
  -- The mode: the copy-mode selection, the active key table, or VISUAL
  -- for a mouse selection, which leaves copy mode off. A selection that
  -- select() didn't make, such as a search match, reads VISUAL. Leaving
  -- copy mode ends its selection.
  local key_table = window:active_key_table()
  local id = pane:pane_id()
  if key_table ~= "copy_mode" then
    selections[id] = nil
  end
  local mode
  if key_table == "copy_mode" then
    mode = SELECTION_LABELS[selections[id]] or window:get_selection_text_for_pane(pane) ~= "" and "VISUAL" or "COPY"
  elseif key_table and key_table ~= "repeat" then
    mode = key_table:upper():gsub("_MODE", "")
  elseif window:get_selection_text_for_pane(pane) ~= "" then
    mode = "VISUAL"
  end
  if mode then
    table.insert(right, { Foreground = { AnsiColor = "Green" } })
    table.insert(right, { Text = "-- " .. mode .. " --  " })
  end
  for _, info in ipairs(window:active_tab():panes_with_info()) do
    if info.is_zoomed then
      table.insert(right, { Foreground = { AnsiColor = "Olive" } })
      table.insert(right, { Text = "Z  " })
    end
  end
  for _, item in ipairs(sysstat()) do
    table.insert(right, item)
  end
  table.insert(right, { Foreground = { AnsiColor = "Grey" } })
  table.insert(right, { Text = wezterm.strftime("%H:%M") .. "  " })
  -- The host the active pane runs on, marked while it's the Lima VM.
  local host, color = wezterm.hostname(), "Teal"
  if vm.in_vm(pane) then
    host, color = vm.MARK .. " " .. vm.HOST, "Maroon"
  end
  table.insert(right, { Foreground = { AnsiColor = color } })
  table.insert(right, { Attribute = { Intensity = "Bold" } })
  table.insert(right, { Text = host .. " " })
  window:set_right_status(wezterm.format(right))
end

-- A tab reads " index:name ", named by program(): a gap of spaces, then
-- the active tab reversed on blue and the others grey, or olive after
-- unseen output. A tab whose active pane runs in the Lima VM adds the
-- shield and takes maroon for blue.
local function tab_title(tab, background)
  local pane = tab.active_pane
  local sandbox = vm.info_in_vm(pane)
  local mark = sandbox and vm.MARK .. " " or ""
  local text = " " .. tab.tab_index + 1 .. ":" .. mark .. program(pane) .. " "
  local gap = { { Background = { Color = background } }, { Text = TAB_GAP } }

  if tab.is_active then
    return {
      gap[1],
      gap[2],
      { Background = { AnsiColor = sandbox and "Maroon" or "Navy" } },
      { Foreground = { Color = background } },
      { Attribute = { Intensity = "Bold" } },
      { Text = text },
    }
  end
  local unseen = false
  for _, p in ipairs(tab.panes) do
    unseen = unseen or p.has_unseen_output
  end
  return {
    gap[1],
    gap[2],
    { Foreground = { AnsiColor = unseen and "Olive" or sandbox and "Maroon" or "Grey" } },
    { Text = text },
  }
end

-- Shows text in the status line of window for NOTICE_SECONDS. A newer
-- notice replaces an older one and outlives its timer.
function M.notify(window, pane, text)
  local id = window:window_id()
  local notice = { text = text }
  notices[id] = notice
  update(window, pane)
  wezterm.time.call_after(NOTICE_SECONDS, function()
    if notices[id] ~= notice then
      return
    end
    notices[id] = nil
    update(window, window:active_pane())
  end)
end

-- Sets the copy-mode selection to mode, "Cell", "Line", or "Block", like
-- v, V, and C-v in tmux's copy-mode.conf. Without a selection it starts
-- one at the cursor, even over a search match that WezTerm selected. The
-- same mode again clears it, and another mode switches it. The label
-- updates at once.
function M.select(mode)
  return wezterm.action_callback(function(window, pane)
    local id = pane:pane_id()
    local current = selections[id]
    local action = act.CopyMode({ SetSelectionMode = mode })
    if current == mode then
      mode, action = nil, act.CopyMode("ClearSelectionMode")
    elseif not current then
      action = act.Multiple({ act.CopyMode("ClearSelectionMode"), action })
    end
    selections[id] = mode
    window:perform_action(action, pane)
    update(window, pane)
  end)
end

-- Performs action, a copy, and names the copied size in a notice, since
-- the copy gives no other sign. A copy ends the copy-mode selection.
function M.copy(action)
  return wezterm.action_callback(function(window, pane)
    selections[pane:pane_id()] = nil
    local text = window:get_selection_text_for_pane(pane)
    window:perform_action(action, pane)
    if text ~= "" then
      M.notify(window, pane, "Copied " .. utf8.len(text) .. " chars")
    else
      update(window, pane)
    end
  end)
end

-- Clears the copy-mode selection when the wheel scrolls, as tmux does,
-- and puts the cursor on the middle row. Otherwise the next key scrolls
-- back to where the cursor was.
function M.scrolled()
  return wezterm.action_callback(function(window, pane)
    if window:active_key_table() ~= "copy_mode" then
      return
    end
    selections[pane:pane_id()] = nil
    window:perform_action(
      act.Multiple({ act.CopyMode("ClearSelectionMode"), act.CopyMode("MoveToViewportMiddle") }),
      pane
    )
    update(window, pane)
  end)
end

function M.setup()
  wezterm.on("update-status", update)
  wezterm.on("format-tab-title", function(tab, _, _, config)
    return tab_title(tab, config.colors.background)
  end)
end

return M
