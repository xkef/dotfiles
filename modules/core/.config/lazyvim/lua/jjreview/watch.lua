-- Watches a repo's operation heads, which change whenever any jj process
-- commits an operation, an agent in another pane included. Workspaces
-- share one repo, so one watcher covers all of them.
local M = {}

local DEBOUNCE_MS = 150

local watchers = {}

-- A secondary workspace's .jj/repo is a file that holds the path of the
-- main workspace's repo directory, relative to its .jj directory.
local function repo_dir(root)
  local repo = vim.fs.joinpath(root, ".jj", "repo")
  local stat = vim.uv.fs_stat(repo)
  if not stat then
    return nil
  end
  if stat.type == "directory" then
    return vim.uv.fs_realpath(repo)
  end

  local target = vim.trim(vim.fn.readfile(repo)[1] or "")
  if not vim.startswith(target, "/") then
    target = vim.fs.joinpath(root, ".jj", target)
  end
  return vim.uv.fs_realpath(target)
end

function M.start(root, on_change)
  local repo = repo_dir(root)
  if not repo or watchers[repo] then
    return
  end

  local event = assert(vim.uv.new_fs_event())
  local timer = assert(vim.uv.new_timer())
  event:start(vim.fs.joinpath(repo, "op_heads", "heads"), {}, function()
    timer:stop()
    timer:start(DEBOUNCE_MS, 0, vim.schedule_wrap(on_change))
  end)
  watchers[repo] = event
end

return M
