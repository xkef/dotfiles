-- Leader bindings and palette entries for the agents package. leader.lua
-- adds them when this file exists.
local wezterm = require("wezterm")
local act = wezterm.action
local lima = require("lima")
local picker = require("picker")

local M = {}

local PICKER = picker.open({ "mux-agents" })
local LIMA_AGENT = act.SpawnCommandInNewTab({ args = { "lima-agent" } })

M.keys = {
  -- @key wezterm :: v :: Repository copy in the Lima VM, new tab
  { key = "v", mods = "LEADER", action = lima.shell_tab },
  -- @key wezterm :: a :: Agent picker (all workspaces)
  { key = "a", mods = "LEADER", action = PICKER },
  -- @key wezterm :: A :: Claude Code in the Lima VM, new tab
  { key = "A", mods = "LEADER", action = LIMA_AGENT },
}

M.palette = {
  { brief = "Agents", icon = "cod_hubot", action = PICKER },
  { brief = "Lima VM shell on a repository copy", icon = "cod_vm", action = lima.shell_tab },
  { brief = "Claude Code in the Lima VM", icon = "cod_hubot", action = LIMA_AGENT },
}

return M
