-- Version control behind one interface. A repository is { root, kind };
-- every call dispatches to the jj or Git backend by kind.

local util = require("tether.core.util")

local M = {}

---@class tether.Repo
---@field root string
---@field kind "jj"|"git"

---@class tether.Range
---@field from? string commit of the old side
---@field to? string commit of the new side; nil means the working copy
---@field rev? string jj revision whose own change to show

local backends = {
  jj = function()
    return require("tether.core.vcs.jj")
  end,
  git = function()
    return require("tether.core.vcs.git")
  end,
}

local function backend(repo)
  return backends[repo.kind]()
end

---@return tether.Repo?
function M.detect(dir)
  dir = util.normalize(dir or vim.fn.getcwd())
  local root = vim.fs.root(dir, ".jj")
  if root then
    return { root = util.normalize(root), kind = "jj" }
  end
  root = vim.fs.root(dir, ".git")
  if root then
    return { root = util.normalize(root), kind = "git" }
  end
end

local current = {}

---The repository of the working directory, cached per directory.
---@return tether.Repo?
function M.current()
  local cwd = vim.fn.getcwd()
  if current.cwd ~= cwd then
    current = { cwd = cwd, repo = M.detect(cwd) }
  end
  return current.repo
end

function M.reset()
  current = {}
end

---Records a checkpoint of the working copy: jj:<op id> or git:<commit>.
function M.checkpoint(repo)
  return backend(repo).checkpoint(repo)
end

---Resolves a checkpoint to a commit id. jj operations resolve to the
---working-copy commit of the workspace that contains cwd.
function M.resolve(repo, ref, cwd)
  if not ref then
    return nil, "no checkpoint"
  end
  local kind, id = ref:match("^(%a+):(.+)$")
  if not kind then
    return nil, "malformed checkpoint " .. ref
  end
  return backend(repo).resolve(repo, kind, id, cwd)
end

---Commit id of the working copy, or nil for Git. jj snapshots first when
---asked.
function M.head(repo, snapshot)
  return backend(repo).head(repo, snapshot)
end

---Unified diff text for a range.
---@param range tether.Range
function M.diff(repo, range)
  return backend(repo).diff(repo, range)
end

---The commit on the old side of a range.
function M.base(repo, range)
  return backend(repo).base(repo, range)
end

---Lines of a file at a commit, or nil when it doesn't exist there.
function M.show(repo, commit, rel)
  return backend(repo).show(repo, commit, rel)
end

---Restores paths (relative to the root) to their content at commit. Paths
---absent there are removed.
function M.restore(repo, commit, rels)
  if #rels == 0 then
    return true
  end
  return backend(repo).restore(repo, commit, rels)
end

---Name of the jj workspace that contains dir.
function M.workspace(repo, dir)
  if not dir or vim.fn.isdirectory(dir) == 0 then
    return nil
  end
  return backend(repo).workspace(repo, dir)
end

---True when dir lies in the repository or another of its jj workspaces.
function M.same_repo(repo, dir)
  if not dir then
    return false
  end
  return util.inside(dir, repo.root) or backend(repo).same_repo(repo, dir)
end

---Adds a jj workspace at path named name.
function M.workspace_add(repo, name, path)
  return backend(repo).workspace_add(repo, name, path)
end

return M
