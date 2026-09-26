-- Helpers shared by the jj and Git backends.

local M = {}

function M.trim(s)
  return (s:gsub("%s+$", ""))
end

function M.fail(res)
  return nil, M.trim(res.stderr ~= "" and res.stderr or res.stdout)
end

return M
