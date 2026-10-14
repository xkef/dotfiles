-- Workspaces, one per project, named after its directory with ~ for
-- $HOME, so two projects of the same name stay apart. `mux-workspaces`
-- picks them.
local wezterm = require("wezterm")
local act = wezterm.action
local picker = require("picker")

local M = {}

-- Remembers the workspace being left, for `last`, however the switch
-- happened. update-status runs on every switch, so the workspace it saw
-- before differs from the active one.
local function track(window)
  local active = window:active_workspace()
  local seen = wezterm.GLOBAL.current_workspace
  if seen and seen ~= active then
    wezterm.GLOBAL.last_workspace = seen
  end
  wezterm.GLOBAL.current_workspace = active
end

-- The pickers set switch_workspace to "name<TAB>path". An empty path
-- switches to an open workspace, and a path opens the workspace there if it
-- doesn't exist yet. The agent and tab pickers focus their pane through
-- `wezterm cli` first, so the switch lands on it.
function M.setup()
  wezterm.on("update-status", track)
  picker.on("switch_workspace", function(window, value)
    local workspace, dir = value:match("^([^\t]*)\t(.*)$")
    if not workspace or workspace == "" or workspace == window:active_workspace() then
      return
    end
    local spawn = dir ~= "" and { cwd = dir } or nil
    window:perform_action(act.SwitchToWorkspace({ name = workspace, spawn = spawn }), window:active_pane())
  end)
end

-- Switches to the last workspace, unless every pane of it closed since.
function M.last()
  return wezterm.action_callback(function(window, pane)
    local name = wezterm.GLOBAL.last_workspace
    for _, open in ipairs(wezterm.mux.get_workspace_names()) do
      if open == name then
        window:perform_action(act.SwitchToWorkspace({ name = name }), pane)
        return
      end
    end
  end)
end

function M.create()
  return act.PromptInputLine({
    description = "New workspace:",
    action = wezterm.action_callback(function(window, pane, name)
      if name and name ~= "" then
        window:perform_action(act.SwitchToWorkspace({ name = name }), pane)
      end
    end),
  })
end

return M
