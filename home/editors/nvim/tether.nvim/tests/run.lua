-- Headless test runner. Each tests/*_spec.lua returns a list of
-- { name, fn } pairs; names match the spec scenarios they cover.

local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
package.path = root .. "/tests/?.lua;" .. package.path
vim.opt.rtp:prepend(root)
vim.cmd("runtime plugin/tether.lua")

local H = require("helpers")
H.root = root

local filter = arg[1]
local files = vim.fn.glob(root .. "/tests/*_spec.lua", false, true)
table.sort(files)

local passed, failed = 0, {}
for _, file in ipairs(files) do
  local cases = dofile(file)
  local group = vim.fn.fnamemodify(file, ":t:r")
  for _, case in ipairs(cases) do
    local name = case[1]
    if not filter or name:lower():find(filter:lower(), 1, true) or group:find(filter, 1, true) then
      H.before()
      local ok, err = xpcall(case[2], debug.traceback)
      pcall(H.after)
      if ok then
        passed = passed + 1
        io.stdout:write("ok    " .. group .. ": " .. name .. "\n")
      else
        table.insert(failed, group .. ": " .. name)
        io.stdout:write("FAIL  " .. group .. ": " .. name .. "\n" .. tostring(err) .. "\n")
      end
    end
  end
end

io.stdout:write(("\n%d passed, %d failed\n"):format(passed, #failed))
for _, name in ipairs(failed) do
  io.stdout:write("  failed: " .. name .. "\n")
end
os.exit(#failed == 0 and 0 or 1)
