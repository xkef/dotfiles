-- Turns: agent activity between a `turn` and a `stop` event, bounded by the
-- VCS checkpoints those events carry.

local diff = require("tether.core.diff")
local util = require("tether.core.util")
local vcs = require("tether.core.vcs")

local M = {}

M.TRAIL_MAX = 500

---@class tether.Turn
---@field id integer
---@field key string agent and session
---@field agent string
---@field session? string
---@field pane? string
---@field cwd? string
---@field start_ref? string
---@field end_ref? string
---@field started integer
---@field stopped? integer
---@field summary? string
---@field files table<string, {line?: integer, epoch: integer}> edited paths
---@field reads table<string, {line?: integer, epoch: integer}>

local S

function M.reset()
  S = { turns = {}, open = {}, trail = {}, checkpoints = {}, seq = 0, cache = {} }
end
M.reset()

local function key(ev)
  return (ev.agent or "?") .. "\0" .. (ev.session or "")
end

---@param ev tether.Event
function M.on_event(ev)
  local k = key(ev)
  if ev.kind == "turn" then
    local prev = S.open[k]
    if prev then
      prev.end_ref = prev.end_ref or ev.ref
      prev.stopped = ev.epoch
    end
    S.seq = S.seq + 1
    local t = {
      id = S.seq,
      key = k,
      agent = ev.agent or "?",
      session = ev.session,
      pane = ev.pane,
      cwd = ev.cwd,
      start_ref = ev.ref,
      started = ev.epoch,
      summary = ev.text,
      files = {},
      reads = {},
    }
    table.insert(S.turns, t)
    S.open[k] = t
  elseif ev.kind == "stop" then
    local t = S.open[k]
    if t then
      t.end_ref = ev.ref
      t.stopped = ev.epoch
      S.open[k] = nil
    end
  elseif (ev.kind == "edit" or ev.kind == "read") and ev.path then
    local t = S.open[k]
    if t then
      local into = ev.kind == "edit" and t.files or t.reads
      into[ev.path] = { line = ev.line, epoch = ev.epoch }
    end
    table.insert(S.trail, ev)
    if #S.trail > M.TRAIL_MAX then
      table.remove(S.trail, 1)
    end
  end
end

---The turn an event belongs to, if it is running.
function M.open_turn(ev)
  return S.open[key(ev)]
end

local function in_root(t, root)
  if util.inside(t.cwd, root) then
    return true
  end
  for path in pairs(t.files) do
    if util.inside(path, root) then
      return true
    end
  end
  return false
end

---Turns of a repository, newest first.
---@return tether.Turn[]
function M.list(root, agent)
  local out = {}
  for i = #S.turns, 1, -1 do
    local t = S.turns[i]
    if in_root(t, root) and (not agent or t.agent == agent) then
      table.insert(out, t)
    end
  end
  return out
end

function M.latest(root, agent)
  return M.list(root, agent)[1]
end

function M.get(id)
  for _, t in ipairs(S.turns) do
    if t.id == id then
      return t
    end
  end
end

function M.running(t)
  return t.stopped == nil
end

---Running turns of every agent, keyed by agent and session.
function M.open()
  return S.open
end

---Edit and read events inside root, newest first.
function M.trail(root, limit)
  local out = {}
  for i = #S.trail, 1, -1 do
    local ev = S.trail[i]
    if util.inside(ev.path, root) then
      table.insert(out, ev)
      if limit and #out >= limit then
        break
      end
    end
  end
  return out
end

function M.set_checkpoint(root, ref)
  S.checkpoints[root] = ref
end

function M.checkpoint(root)
  return S.checkpoints[root]
end

---Records a manual checkpoint for the repository.
function M.mark(repo)
  local ref, err = vcs.checkpoint(repo)
  if not ref then
    return nil, err
  end
  M.set_checkpoint(repo.root, ref)
  return ref
end

---@class tether.Scope
---@field name string
---@field label string
---@field range tether.Range
---@field turn? tether.Turn
---@field readonly? boolean diff of another workspace; reject would edit the wrong files

---Resolves a scope name to a diff range. snapshot lets jj record the
---working copy first, for explicit reviews of work in progress.
---@param opts? {turn?: tether.Turn, snapshot?: boolean}
---@return tether.Scope?, string?
function M.scope(repo, name, opts)
  opts = opts or {}
  name = name or "turn"
  if name == "change" then
    if repo.kind == "jj" then
      if opts.snapshot then
        vcs.head(repo, true)
      end
      return { name = name, label = "working-copy change", range = { rev = "@" } }
    end
    return { name = name, label = "uncommitted changes", range = { from = "HEAD" } }
  end

  if name == "range" then
    if not (opts.from and opts.to) then
      return nil, "range needs from and to"
    end
    return {
      name = name,
      label = opts.label or (opts.from .. ".." .. opts.to),
      range = { from = opts.from, to = opts.to },
      readonly = true,
    }
  end

  if name == "workspace" then
    if not opts.workspace then
      return nil, "no workspace given"
    end
    return {
      name = name,
      label = "workspace " .. opts.workspace .. " vs trunk",
      range = { from = "trunk()", to = opts.workspace .. "@" },
      readonly = true,
    }
  end

  local from_ref, t
  if name == "checkpoint" then
    from_ref = M.checkpoint(repo.root)
    if not from_ref then
      return nil, "no checkpoint; run :Tether checkpoint first"
    end
  elseif name == "turn" or name == "since" then
    t = opts.turn or M.latest(repo.root)
    if not t then
      return nil, "no agent turn in " .. repo.root
    end
    from_ref = t.start_ref
  else
    return nil, "unknown scope " .. name
  end

  local from, err = vcs.resolve(repo, from_ref, t and t.cwd)
  if not from then
    return nil, err
  end
  local to
  if name == "turn" and t.end_ref then
    to, err = vcs.resolve(repo, t.end_ref, t.cwd)
    if not to then
      return nil, err
    end
  else
    to = vcs.head(repo, opts.snapshot)
  end

  local label
  if name == "checkpoint" then
    label = "since checkpoint"
  elseif name == "since" then
    label = ("since turn %d"):format(t.id)
  else
    label = ("turn %d%s"):format(t.id, M.running(t) and " (running)" or "")
  end
  return { name = name, label = label, range = { from = from, to = to }, turn = t }
end

---Files of a scope with parsed hunks.
---@return tether.File[]?, string?
function M.files(repo, scope)
  local text, err = vcs.diff(repo, scope.range)
  if not text then
    return nil, err
  end
  return diff.parse(text)
end

---Per-file line counts of a turn without snapshotting: a finished turn
---from its checkpoint diff, a running one from the edited files on disk.
---@return {path: string, added: integer, removed: integer}[]
function M.stats(repo, t)
  local cache_key = t.id .. ":" .. (t.end_ref or "running")
  if t.end_ref and S.cache[cache_key] then
    return S.cache[cache_key]
  end
  local out = {}
  if t.end_ref then
    local scope = M.scope(repo, "turn", { turn = t })
    local files = scope and M.files(repo, scope) or {}
    for _, f in ipairs(files) do
      table.insert(out, { path = vim.fs.joinpath(repo.root, f.path), added = f.added, removed = f.removed })
    end
    S.cache[cache_key] = out
    return out
  end
  local from = vcs.resolve(repo, t.start_ref, t.cwd)
  local paths = vim.tbl_keys(t.files)
  table.sort(paths)
  for _, path in ipairs(paths) do
    if util.inside(path, repo.root) then
      local old = from and vcs.show(repo, from, util.relative(path, repo.root)) or {}
      local added, removed = diff.compare(old, util.content(path) or {})
      table.insert(out, { path = path, added = added, removed = removed })
    end
  end
  return out
end

---Restores the files a turn changed to their content at its start.
---@return string[]? paths, string? err
function M.undo(repo, t, confirm)
  local scope, err = M.scope(repo, "turn", { turn = t, snapshot = true })
  if not scope then
    return nil, err
  end
  local files
  files, err = M.files(repo, scope)
  if not files then
    return nil, err
  end
  local rels = {}
  for _, f in ipairs(files) do
    table.insert(rels, f.path)
    if f.old_path ~= f.path then
      table.insert(rels, f.old_path)
    end
  end
  if #rels == 0 then
    return {}
  end
  if confirm and not confirm(rels) then
    return nil, "cancelled"
  end
  local ok
  ok, err = vcs.restore(repo, scope.range.from, rels)
  if not ok then
    return nil, err
  end
  for _, rel in ipairs(rels) do
    local buf = vim.fn.bufnr(vim.fs.joinpath(repo.root, rel))
    if buf > 0 and vim.api.nvim_buf_is_loaded(buf) and not vim.bo[buf].modified then
      vim.api.nvim_buf_call(buf, function()
        vim.cmd("silent! edit")
      end)
    end
  end
  return rels
end

return M
