-- Keeps new panes in the Lima VM from ~/.config/lima/dev.yaml. A pane runs
-- in the VM when its shell reports the lima-dev host through OSC 7. Splits
-- and new tabs of that pane run `limactl shell dev` in the same directory,
-- which exists in the guest because the shares mount at their host paths.
-- Every pane stays in the local mux.
local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

M.HOST = "lima-dev"
-- The shield that marks sandbox panes in tab titles and the status line.
M.MARK = ""
local SHELL = { "limactl", "shell", "dev" }

-- A tab with a shell in the VM, in the current directory.
M.shell_tab = act.SpawnCommandInNewTab({ args = SHELL })

-- The directory in cwd, a URL from OSC 7, when it names the VM, else nil.
local function vm_path(cwd)
  if cwd and cwd.host == M.HOST then
    return cwd.file_path
  end
end

-- The pane's directory when the pane runs in the VM, else nil. During a
-- switch, WezTerm can pass a pane the mux already dropped, and the lookup
-- then throws.
local function vm_dir(pane)
  local ok, cwd = pcall(pane.get_current_working_dir, pane)
  return ok and vm_path(cwd) or nil
end

-- Whether the pane runs in the VM.
function M.in_vm(pane)
  return vm_dir(pane) ~= nil
end

-- Whether the pane in a PaneInformation, as tab titles get it, runs in the VM.
function M.info_in_vm(info)
  local ok, cwd = pcall(function()
    return info.current_working_dir
  end)
  return ok and vm_path(cwd) ~= nil
end

-- Splits toward direction, "Right" or "Down", in the VM for a VM pane
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
