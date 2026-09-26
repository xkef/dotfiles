-- jj backend. UI queries run with --ignore-working-copy, so only explicit
-- snapshots add operations to the log.

local common = require("tether.core.vcs.common")
local util = require("tether.core.util")

local M = {}

local trim, fail = common.trim, common.fail

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

local function fileset(rel)
  return 'root-file:"' .. rel:gsub("\\", "\\\\"):gsub('"', '\\"') .. '"'
end

function M.checkpoint(repo)
  local res = jj(repo, { "op", "log", "-n1", "--no-graph", "-T", "id" }, { snapshot = true })
  if res.code ~= 0 then
    return fail(res)
  end
  return "jj:" .. trim(res.stdout)
end

function M.resolve(repo, kind, id, cwd)
  if kind ~= "jj" then
    return nil, "checkpoint " .. kind .. ":" .. id .. " doesn't match a jj repository"
  end
  local res = jj(repo, { "--at-op", id, "log", "-r", "@", "--no-graph", "-T", "commit_id" }, { cwd = cwd })
  if res.code ~= 0 then
    return fail(res)
  end
  return trim(res.stdout)
end

function M.head(repo, snapshot)
  local res = jj(repo, { "log", "-r", "@", "--no-graph", "-T", "commit_id" }, { snapshot = snapshot })
  if res.code ~= 0 then
    return fail(res)
  end
  return trim(res.stdout)
end

function M.diff(repo, range)
  local args = { "diff", "--git" }
  if range.rev then
    vim.list_extend(args, { "-r", range.rev })
  else
    vim.list_extend(args, { "--from", range.from, "--to", range.to or "@" })
  end
  local res = jj(repo, args)
  if res.code ~= 0 then
    return fail(res)
  end
  return res.stdout
end

function M.base(_, range)
  return range.from or ((range.rev or "@") .. "-")
end

function M.show(repo, commit, rel)
  local res = jj(repo, { "file", "show", "-r", commit, "--", fileset(rel) })
  if res.code ~= 0 then
    return nil
  end
  return util.lines(res.stdout)
end

function M.restore(repo, commit, rels)
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

function M.workspace(repo, dir)
  local res = jj(repo, { "log", "-r", "@", "--no-graph", "-T", "working_copies" }, { cwd = dir })
  if res.code ~= 0 then
    return nil
  end
  return res.stdout:match("([^%s@]+)@")
end

---The repository store a workspace root uses. Workspaces of one repository
---share it: the main workspace holds .jj/repo as a directory, every other
---workspace a file with the path to it.
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

function M.same_repo(repo, dir)
  local other = vim.fs.root(dir, ".jj")
  if not other then
    return false
  end
  local mine = M.store(repo.root)
  return mine ~= nil and mine == M.store(util.normalize(other))
end

function M.workspace_add(repo, name, path)
  local res = jj(repo, { "workspace", "add", "--name", name, path }, { snapshot = true })
  if res.code ~= 0 then
    return fail(res)
  end
  return true
end

return M
