-- Where a run works. With a workspace, a jj workspace or Git worktree next
-- to the repository gets one commit per stage, in the style of Fabro's run
-- branches; without one, the run works in place between two checkpoints.

local api = require("tether.api")

local M = {}

local function run_cmd(cmd, cwd)
  local res = api.util.run(cmd, { cwd = cwd })
  if res.code ~= 0 then
    error(table.concat(cmd, " ") .. ": " .. vim.trim(res.stderr ~= "" and res.stderr or res.stdout))
  end
  return vim.trim(res.stdout)
end

---Prepares the working directory. Returns workdir and the isolation record
---kept in the manifest.
---@param repo tether.Repo?
function M.prepare(repo, id, workspace, fallback_dir)
  if not repo then
    return fallback_dir, { kind = "none" }
  end
  if not workspace then
    return repo.root, { kind = "inplace", base_ref = api.vcs.checkpoint(repo) }
  end
  local path = repo.root .. "-run-" .. id
  if repo.kind == "jj" then
    local name = "run-" .. id
    local ok, err = api.vcs.workspace_add(repo, name, path)
    if not ok then
      error(err)
    end
    local base = run_cmd({ "jj", "--color=never", "log", "-r", "@-", "--no-graph", "-T", "commit_id" }, path)
    return path, { kind = "jj", name = name, path = path, base = base }
  end
  local branch = "tether/run/" .. id
  local base = run_cmd({ "git", "rev-parse", "HEAD" }, repo.root)
  run_cmd({ "git", "worktree", "add", "-q", "-b", branch, path }, repo.root)
  return path, { kind = "git", branch = branch, path = path, base = base }
end

---Commits a finished stage in a workspace run.
function M.commit(iso, id, node, status)
  local msg = ("pipeline(%s): %s (%s)"):format(id, node, status)
  if iso.kind == "jj" then
    run_cmd({ "jj", "--color=never", "commit", "-m", msg }, iso.path)
  elseif iso.kind == "git" then
    run_cmd({ "git", "add", "-A" }, iso.path)
    run_cmd({ "git", "commit", "-q", "--allow-empty", "--no-verify", "-m", msg }, iso.path)
  end
end

---Records the end checkpoint of an in-place run.
function M.finish(repo, iso)
  if iso.kind == "inplace" and repo then
    iso.end_ref = api.vcs.checkpoint(repo)
  end
end

---The review range of a run: { from, to } in the repository.
function M.range(repo, iso)
  if iso.kind == "jj" then
    return { from = iso.base, to = iso.name .. "@" }
  elseif iso.kind == "git" then
    return { from = iso.base, to = iso.branch }
  elseif iso.kind == "inplace" then
    local from = api.vcs.resolve(repo, iso.base_ref)
    local to = iso.end_ref and api.vcs.resolve(repo, iso.end_ref) or api.vcs.head(repo)
    return { from = from, to = to }
  end
end

return M
