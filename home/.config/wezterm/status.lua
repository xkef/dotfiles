-- Tab titles and the status line, styled like the former tmux bar. Every
-- color names an ANSI slot, so a tinty switch recolors the bar with the
-- terminal.
local wezterm = require("wezterm")
local agents = require("agents")

local M = {}

-- sysstat forks, so the status line refreshes it at this interval instead
-- of on every redraw.
local SYSSTAT_INTERVAL = 5
local CPU_HIGH = 80

local function basename(path)
  return (path or ""):match("([^/]+)$") or ""
end

-- CPU and memory, cached between runs. The script prints "<cpu%>\t<used>/<total>G".
local function sysstat()
  local cache = wezterm.GLOBAL.sysstat or { at = 0, text = "" }
  if os.time() - cache.at >= SYSSTAT_INTERVAL then
    local ok, out = wezterm.run_child_process({ "sysstat" })
    cache = { at = os.time(), text = ok and out:gsub("%s+$", "") or "" }
    wezterm.GLOBAL.sysstat = cache
  end
  local cpu, mem = cache.text:match("^(%d+)\t(.+)$")
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
    { Text = window:active_workspace() .. " § " },
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
  local count = agents.count()
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

-- A tab reads " index:name ". The name is the agent's while one runs, so
-- a sandboxed agent doesn't read as `nono`, and the foreground process
-- otherwise.
local function tab_title(tab)
  local pane = tab.active_pane
  local name = pane.user_vars.agent_state ~= nil and pane.user_vars.agent_state ~= "" and pane.user_vars.agent
    or basename(pane.foreground_process_name)
  if name == "" then
    name = pane.title
  end
  local text = " " .. tab.tab_index + 1 .. ":" .. name .. " "

  if tab.is_active then
    return {
      { Background = { AnsiColor = "Navy" } },
      { Foreground = { AnsiColor = "Black" } },
      { Attribute = { Intensity = "Bold" } },
      { Text = text },
    }
  end
  local unseen = false
  for _, p in ipairs(tab.panes) do
    unseen = unseen or p.has_unseen_output
  end
  return {
    { Foreground = { AnsiColor = unseen and "Olive" or "Grey" } },
    { Text = text },
  }
end

function M.setup()
  wezterm.on("update-status", update)
  wezterm.on("format-tab-title", function(tab)
    return tab_title(tab)
  end)
end

return M
