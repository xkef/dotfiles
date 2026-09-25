-- Keeps new panes in the Lima VM from ~/.config/lima/dev.yaml. A pane runs
-- in the VM when its shell reports the lima-dev host through OSC 7. Splits
-- and new tabs of that pane run `limactl shell dev` in the same directory,
-- which exists in the guest because the shares mount at their host paths.
-- Every pane stays in the local mux.
local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

local HOST = "lima-dev"
local SHELL = { "limactl", "shell", "dev" }

-- A tab with a shell in the VM, in the current directory.
M.shell_tab = act.SpawnCommandInNewTab({ args = SHELL })

-- The pane's directory when the pane runs in the VM, else nil.
local function vm_dir(pane)
  local cwd = pane:get_current_working_dir()
  if cwd and cwd.host == HOST then
    return cwd.file_path
  end
end

-- Splits toward direction, "Right" or "Bottom", in the VM for a VM pane
-- and with action for any other pane.
function M.split(action, direction)
  return wezterm.action_callback(function(window, pane)
    local dir = vm_dir(pane)
    local split = dir and act.SplitPane({ direction = direction, command = { args = SHELL, cwd = dir } }) or action
    window:perform_action(split, pane)
  end)
end

-- Opens a tab in the VM for a VM pane and with action for any other pane.
function M.tab(action)
  return wezterm.action_callback(function(window, pane)
    local dir = vm_dir(pane)
    local spawn = dir and act.SpawnCommandInNewTab({ args = SHELL, cwd = dir }) or action
    window:perform_action(spawn, pane)
  end)
end

return M
