-- Workspaces, one per project, named after its directory. `mux-workspaces`
-- picks them.
local wezterm = require("wezterm")
local act = wezterm.action
local picker = require("picker")

local M = {}

-- Remembers the workspace being left, for `last`.
local function switch(window, pane, action)
  wezterm.GLOBAL.last_workspace = window:active_workspace()
  window:perform_action(action, pane)
end

-- The pickers set switch_workspace to "name<TAB>path". An empty path
-- switches to an open workspace, and a path opens the workspace there if it
-- doesn't exist yet. The agent and tab pickers focus their pane through
-- `wezterm cli` first, so the switch lands on it.
function M.setup()
  picker.on("switch_workspace", function(window, value)
    local workspace, dir = value:match("^([^\t]*)\t(.*)$")
    if not workspace or workspace == "" or workspace == window:active_workspace() then
      return
    end
    local spawn = dir ~= "" and { cwd = dir } or nil
    switch(window, window:active_pane(), act.SwitchToWorkspace({ name = workspace, spawn = spawn }))
  end)
end

function M.last()
  return wezterm.action_callback(function(window, pane)
    local name = wezterm.GLOBAL.last_workspace
    if name then
      switch(window, pane, act.SwitchToWorkspace({ name = name }))
    end
  end)
end

function M.create()
  return act.PromptInputLine({
    description = "New workspace:",
    action = wezterm.action_callback(function(window, pane, name)
      if name and name ~= "" then
        switch(window, pane, act.SwitchToWorkspace({ name = name }))
      end
    end),
  })
end

return M
