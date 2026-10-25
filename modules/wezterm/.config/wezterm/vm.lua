-- Panes in the Lima VM, through lima.lua, on a Mac with the agents
-- package. Elsewhere every pane is local, and each wrapper returns its
-- action unchanged.
local wezterm = require("wezterm")
local path = require("path")

if wezterm.target_triple:find("darwin") and path.deployed("agents") then
  return require("lima")
end

local M = {}

local function passthrough(action)
  return action
end

function M.in_vm()
  return false
end

M.info_in_vm = M.in_vm
M.split = passthrough
M.tab = passthrough
M.paste = passthrough

return M
