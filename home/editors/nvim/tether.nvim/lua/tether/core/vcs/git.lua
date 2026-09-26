-- Git backend. The working tree has no commit, so a range without `to`
-- compares against the files on disk.

local common = require("tether.core.vcs.common")
local util = require("tether.core.util")

local M = {}

local trim, fail = common.trim, common.fail

local function git(repo, args)
  local cmd = { "git", "--no-pager", "-c", "color.ui=never" }
  vim.list_extend(cmd, args)
  return util.run(cmd, { cwd = repo.root })
end

---`git stash create` records the tree, tracked changes included, without
---touching it; a clean tree checkpoints at HEAD.
function M.checkpoint(repo)
  local res = git(repo, { "stash", "create" })
  local id = res.code == 0 and trim(res.stdout) or ""
  if id == "" then
    res = git(repo, { "rev-parse", "HEAD" })
    if res.code ~= 0 then
      return fail(res)
    end
    id = trim(res.stdout)
  end
  return "git:" .. id
end

function M.resolve(_, kind, id)
  if kind ~= "git" then
    return nil, "checkpoint " .. kind .. ":" .. id .. " doesn't match a Git repository"
  end
  return id
end

function M.head()
  return nil
end

function M.diff(repo, range)
  local args = { "diff", "--no-ext-diff", "--no-color", range.from or "HEAD" }
  if range.to then
    table.insert(args, range.to)
  end
  local res = git(repo, args)
  if res.code ~= 0 then
    return fail(res)
  end
  return res.stdout
end

function M.base(_, range)
  return range.from or "HEAD"
end

function M.show(repo, commit, rel)
  local res = git(repo, { "show", commit .. ":" .. rel })
  if res.code ~= 0 then
    return nil
  end
  return util.lines(res.stdout)
end

function M.restore(repo, commit, rels)
  for _, rel in ipairs(rels) do
    if git(repo, { "cat-file", "-e", commit .. ":" .. rel }).code == 0 then
      local res = git(repo, { "checkout", commit, "--", rel })
      if res.code ~= 0 then
        return fail(res)
      end
    else
      os.remove(vim.fs.joinpath(repo.root, rel))
    end
  end
  return true
end

function M.workspace()
  return nil
end

function M.same_repo()
  return false
end

function M.workspace_add()
  return nil, "workspaces need jj"
end

return M
