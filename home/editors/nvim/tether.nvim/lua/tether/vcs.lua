-- jj and Git access. UI queries to jj run with --ignore-working-copy, so
-- only explicit snapshots add operations to the log.

local util = require("tether.util")

local M = {}

---@class tether.Repo
---@field root string
---@field kind "jj"|"git"

---@class tether.Range
---@field from? string commit of the old side
---@field to? string commit of the new side; nil means the working copy
---@field rev? string jj revision whose own change to show

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

local function trim(s)
  return (s:gsub("%s+$", ""))
end

---@param opts? {snapshot?: boolean, cwd?: string}
local function jj(repo, args, opts)
  opts = opts or {}
  local cmd = { "jj", "--color=never", "--no-pager" }
  if not opts.snapshot then
    table.insert(cmd, "--ignore-working-copy")
  end
  vim.list_extend(cmd, args)
  local cwd = opts.cwd
  if not cwd or vim.fn.isdirectory(cwd) == 0 then
    cwd = repo.root
  end
  return util.run(cmd, { cwd = cwd })
end

local function git(repo, args)
  local cmd = { "git", "--no-pager", "-c", "color.ui=never" }
  vim.list_extend(cmd, args)
  return util.run(cmd, { cwd = repo.root })
end

local function fileset(rel)
  return 'root-file:"' .. rel:gsub("\\", "\\\\"):gsub('"', '\\"') .. '"'
end

local function fail(res)
  return nil, trim(res.stderr ~= "" and res.stderr or res.stdout)
end

---Records a checkpoint of the current working copy: jj:<op id> or git:<commit>.
function M.checkpoint(repo)
  if repo.kind == "jj" then
    local res = jj(repo, { "op", "log", "-n1", "--no-graph", "-T", "id" }, { snapshot = true })
    if res.code ~= 0 then
      return fail(res)
    end
    return "jj:" .. trim(res.stdout)
  end
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

---Resolves a checkpoint to a commit id. jj operations resolve to the
---working-copy commit of the workspace that contains cwd.
function M.resolve(repo, ref, cwd)
  if not ref then
    return nil, "no checkpoint"
  end
  local kind, id = ref:match("^(%a+):(.+)$")
  if kind == "git" then
    return id
  end
  if kind ~= "jj" or repo.kind ~= "jj" then
    return nil, "checkpoint " .. ref .. " doesn't match a " .. repo.kind .. " repository"
  end
  local res = jj(repo, { "--at-op", id, "log", "-r", "@", "--no-graph", "-T", "commit_id" }, { cwd = cwd })
  if res.code ~= 0 then
    return fail(res)
  end
  return trim(res.stdout)
end

---Commit id of the working copy. jj snapshots first when asked; Git has no
---commit for the working tree and returns nil.
function M.head(repo, snapshot)
  if repo.kind ~= "jj" then
    return nil
  end
  local res = jj(repo, { "log", "-r", "@", "--no-graph", "-T", "commit_id" }, { snapshot = snapshot })
  if res.code ~= 0 then
    return fail(res)
  end
  return trim(res.stdout)
end

---Unified diff text for a range.
---@param range tether.Range
function M.diff(repo, range)
  local res
  if repo.kind == "jj" then
    local args = { "diff", "--git" }
    if range.rev then
      vim.list_extend(args, { "-r", range.rev })
    else
      vim.list_extend(args, { "--from", range.from, "--to", range.to or "@" })
    end
    res = jj(repo, args)
  else
    local args = { "diff", "--no-ext-diff", "--no-color", range.from or "HEAD" }
    if range.to then
      table.insert(args, range.to)
    end
    res = git(repo, args)
  end
  if res.code ~= 0 then
    return fail(res)
  end
  return res.stdout
end

---The commit on the old side of a range.
function M.base(repo, range)
  if range.from then
    return range.from
  end
  if repo.kind == "jj" then
    return (range.rev or "@") .. "-"
  end
  return "HEAD"
end

---Lines of a file at a commit, or nil when it doesn't exist there.
function M.show(repo, commit, rel)
  local res
  if repo.kind == "jj" then
    res = jj(repo, { "file", "show", "-r", commit, "--", fileset(rel) })
  else
    res = git(repo, { "show", commit .. ":" .. rel })
  end
  if res.code ~= 0 then
    return nil
  end
  return util.lines(res.stdout)
end

---Restores paths (relative to the root) to their content at commit. Paths
---absent there are removed.
function M.restore(repo, commit, rels)
  if #rels == 0 then
    return true
  end
  if repo.kind == "jj" then
    local args = { "restore", "--from", commit, "--" }
    for _, rel in ipairs(rels) do
      table.insert(args, fileset(rel))
    end
    local res = jj(repo, args, { snapshot = true })
    if res.code ~= 0 then
      return fail(res)
    end
    return true
  end
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

---Name of the jj workspace that contains dir: the workspace whose working
---copy is @ there.
function M.workspace(repo, dir)
  if repo.kind ~= "jj" or not dir or vim.fn.isdirectory(dir) == 0 then
    return nil
  end
  local res = util.run({
    "jj",
    "--color=never",
    "--no-pager",
    "--ignore-working-copy",
    "log",
    "-r",
    "@",
    "--no-graph",
    "-T",
    "working_copies",
  }, { cwd = dir })
  if res.code ~= 0 then
    return nil
  end
  return res.stdout:match("([^%s@]+)@")
end

---The jj repository store a workspace root uses. Workspaces of one
---repository share it: the main workspace holds .jj/repo as a directory,
---and every other workspace holds a file with the path to it.
function M.store(root)
  local repo_path = vim.fs.joinpath(root, ".jj", "repo")
  local stat = vim.uv.fs_stat(repo_path)
  if not stat then
    return nil
  end
  if stat.type == "directory" then
    return util.normalize(repo_path)
  end
  local target = (util.read_lines(repo_path) or {})[1]
  if not target or target == "" then
    return nil
  end
  if target:sub(1, 1) ~= "/" then
    target = vim.fs.joinpath(root, ".jj", target)
  end
  return util.normalize(target)
end

---True when dir lies in a workspace of the same jj repository as repo.
function M.same_repo(repo, dir)
  if not dir then
    return false
  end
  if util.inside(dir, repo.root) then
    return true
  end
  if repo.kind ~= "jj" then
    return false
  end
  local other = vim.fs.root(dir, ".jj")
  if not other then
    return false
  end
  local mine = M.store(repo.root)
  return mine ~= nil and mine == M.store(util.normalize(other))
end

---Adds a jj workspace at path named name.
function M.workspace_add(repo, name, path)
  local res = jj(repo, { "workspace", "add", "--name", name, path }, { snapshot = true })
  if res.code ~= 0 then
    return fail(res)
  end
  return true
end

return M
