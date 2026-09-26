-- The openspec/ directory tether works with: in the working directory, one
-- of its parents, or at the repository root. Cached per directory.

local api = require("tether.api")

local M = {}

local roots = {}

function M.reset()
  roots = {}
end

---@return string?
function M.get()
  local cwd = vim.fn.getcwd()
  if roots[cwd] == nil then
    local found = vim.fs.find("openspec", { upward = true, type = "directory", path = cwd, limit = 1 })[1]
    if not found then
      local repo = api.repo()
      local at_root = repo and vim.fs.joinpath(repo.root, "openspec")
      if at_root and vim.fn.isdirectory(at_root) == 1 then
        found = at_root
      end
    end
    roots[cwd] = found and api.util.normalize(found) or false
  end
  return roots[cwd] or nil
end

return M
