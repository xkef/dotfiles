-- Tab titles and the status line, a plain bar at the bottom. Every
-- color names an ANSI slot, so a tinty switch recolors the bar with the
-- terminal.
local wezterm = require("wezterm")
local path = require("path")

local M = {}

-- The helpers fork, so the status line refreshes their output at these
-- intervals instead of on every redraw.
local AGENTS_INTERVAL = 2
local SYSSTAT_INTERVAL = 5
local CPU_HIGH = 80
local TAB_GAP = "   "

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
  local key_table = window:active_key_table()
  if key_table and key_table ~= "repeat" then
    table.insert(right, { Foreground = { AnsiColor = "Green" } })
    table.insert(right, { Text = "-- " .. key_table:upper():gsub("_MODE", "") .. " --  " })
  end
  for _, info in ipairs(window:active_tab():panes_with_info()) do
    if info.is_zoomed then
      table.insert(right, { Foreground = { AnsiColor = "Olive" } })
      table.insert(right, { Text = "Z  " })
    end
  end
  -- Agent count such as "2• 1◦", empty when no agent runs.
  local count = cached("agent_count", AGENTS_INTERVAL, { "mux-agents", "--count" })
  if count ~= "" then
    table.insert(right, "ResetAttributes")
    table.insert(right, { Text = count .. "  " })
  end
  for _, item in ipairs(sysstat()) do
    table.insert(right, item)
  end
  table.insert(right, { Foreground = { AnsiColor = "Grey" } })
  table.insert(right, { Text = wezterm.strftime("%H:%M") .. "  " })
  table.insert(right, { Foreground = { AnsiColor = "Teal" } })
  table.insert(right, { Attribute = { Intensity = "Bold" } })
  table.insert(right, { Text = wezterm.hostname() .. " " })
  window:set_right_status(wezterm.format(right))
end

-- A tab reads " index:name ", named by program(): a gap of spaces, then
-- the active tab reversed on blue and the others grey, or olive after
-- unseen output.
local function tab_title(tab, background)
  local pane = tab.active_pane
  local text = " " .. tab.tab_index + 1 .. ":" .. program(pane) .. " "
  local gap = { { Background = { Color = background } }, { Text = TAB_GAP } }

  if tab.is_active then
    return {
      gap[1],
      gap[2],
      { Background = { AnsiColor = "Navy" } },
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
    { Foreground = { AnsiColor = unseen and "Olive" or "Grey" } },
    { Text = text },
  }
end

function M.setup()
  wezterm.on("update-status", update)
  wezterm.on("format-tab-title", function(tab, _, _, config)
    return tab_title(tab, config.colors.background)
  end)
end

return M
