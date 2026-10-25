-- Panes in the Lima VM, through lima.lua from the agents package when
-- deployed. Without it every pane is local, and each wrapper returns its
-- action unchanged.
if package.searchpath("lima", package.path) then
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
