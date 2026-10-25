-- Leader bindings and palette entries for the agents package. leader.lua
-- adds them when the package is deployed. The Lima VM ones need lima.lua,
-- which vm.lua loads only on macOS.
local wezterm = require("wezterm")
local act = wezterm.action
local vm = require("vm")
local picker = require("picker")

local M = {}

local PICKER = picker.open({ "agents" })

M.keys = {
  -- @key wezterm :: a :: Agent picker (all workspaces)
  { key = "a", mods = "LEADER", action = PICKER },
}

M.palette = {
  { brief = "Agents", icon = "cod_hubot", action = PICKER },
}

if vm.shell_tab then
  local LIMA_AGENT = act.SpawnCommandInNewTab({ args = { "agents", "vm" } })
  -- @key wezterm :: v :: Repository copy in the Lima VM, new tab
  table.insert(M.keys, { key = "v", mods = "LEADER", action = vm.shell_tab })
  -- @key wezterm :: A :: Claude Code in the Lima VM, new tab
  table.insert(M.keys, { key = "A", mods = "LEADER", action = LIMA_AGENT })
  table.insert(M.palette, { brief = "Lima VM shell on a repository copy", icon = "cod_vm", action = vm.shell_tab })
  table.insert(M.palette, { brief = "Claude Code in the Lima VM", icon = "cod_hubot", action = LIMA_AGENT })
end

return M
