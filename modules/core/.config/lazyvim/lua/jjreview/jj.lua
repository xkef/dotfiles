-- Runs jj for the review modules. Every command runs at the workspace
-- root of the current tab, and every path is relative to that root, so
-- results don't depend on the tab's working directory.
local M = {}

local NOTIFY_TITLE = "jjreview"

function M.root()
  return vim.fs.root(vim.fn.getcwd(), ".jj")
end

function M.notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = NOTIFY_TITLE })
end

-- Returns stdout, or nil after reporting stderr unless opts.silent. jj
-- gets no editor, so a command that would open one fails instead of
-- waiting on a terminal that doesn't exist. Word wrap stays off, since it
-- breaks template output that the modules parse line by line.
function M.run(args, opts)
  opts = opts or {}
  local root = opts.root or M.root()
  if not root then
    return nil
  end

  local cmd = { "jj", "--no-pager", "--color", "never", "--config", "ui.log-word-wrap=false" }
  vim.list_extend(cmd, args)
  local result = vim.system(cmd, { cwd = root, text = true, stdin = opts.stdin, env = { JJ_EDITOR = "false" } }):wait()
  if result.code ~= 0 then
    if not opts.silent then
      M.notify(vim.trim(result.stderr), vim.log.levels.ERROR)
    end
    return nil
  end
  return result.stdout
end

function M.fileset(path)
  return "root-file:" .. require("jj.core.args").fileset(path)
end

-- Lines of a file at a revision. A file the revision lacks has none.
function M.show(rev, path)
  local out = M.run({ "file", "show", "-r", rev, M.fileset(path) }, { silent = true })
  if not out or out == "" then
    return {}
  end
  return vim.split(out:gsub("\n$", ""), "\n", { plain = true })
end

-- Revisions in a revset, newest first, as { id, change, title, wc,
-- files }. id is the full change ID and change its short form. wc marks
-- the working copy of this workspace. files lists { status, path }, with
-- status one of jj's "modified", "added", "removed", "copied", or
-- "renamed".
function M.revisions(revset)
  local template = table.concat({
    "change_id",
    "change_id.shortest(8)",
    'if(current_working_copy, "@")',
    'coalesce(description.first_line(), "(no description)")',
    'diff.files().map(|f| f.status() ++ ":" ++ f.path()).join("\\x1f")',
  }, ' ++ "\\t" ++ ') .. ' ++ "\\n"'
  local out = M.run({ "log", "-r", revset, "--no-graph", "-T", template })

  local revs = {}
  for line in (out or ""):gmatch("[^\n]+") do
    local id, change, wc, title, files = unpack(vim.split(line, "\t", { plain = true }))
    local rev = { id = id, change = change, wc = wc == "@", title = title, files = {} }
    for entry in (files or ""):gmatch("[^\31]+") do
      local status, path = entry:match("^(%a+):(.*)$")
      table.insert(rev.files, { status = status, path = path })
    end
    table.insert(revs, rev)
  end
  return revs
end

-- The git commit of a revset that names exactly one revision, or nil for
-- several or a repo without git.
function M.commit(revset)
  local out = M.run({ "log", "-r", revset, "--no-graph", "-T", 'commit_id ++ "\n"' }, { silent = true })
  local ids = vim.split(vim.trim(out or ""), "\n")
  if #ids ~= 1 or ids[1] == "" then
    return nil
  end
  return ids[1]
end

return M
