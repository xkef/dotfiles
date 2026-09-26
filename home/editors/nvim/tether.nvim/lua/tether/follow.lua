-- Keeps buffers current while agents edit, and in follow mode moves a
-- window to each edit.

local config = require("tether.config")
local diff = require("tether.diff")
local turns = require("tether.turns")
local util = require("tether.util")
local vcs = require("tether.vcs")

local M = {}

local ns = vim.api.nvim_create_namespace("tether.flash")

local F = {}

function M.reset()
  F = { enabled = false, win = nil, pending = nil, known = {} }
end
M.reset()

function M.enabled()
  return F.enabled
end

---@param on? boolean toggles when nil
function M.toggle(on)
  if on == nil then
    on = not F.enabled
  end
  F.enabled = on
  F.win = on and vim.api.nvim_get_current_win() or nil
  util.notify("follow " .. (on and "on" or "off"))
  return on
end

local function flash(buf, first, last)
  local ms = config.options.follow.flash_ms
  if not ms or ms <= 0 then
    return
  end
  local n = vim.api.nvim_buf_line_count(buf)
  first, last = math.max(1, math.min(first, n)), math.max(1, math.min(last, n))
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  vim.api.nvim_buf_set_extmark(buf, ns, first - 1, 0, {
    end_row = last,
    end_col = 0,
    hl_group = "TetherFlash",
    hl_eol = true,
    priority = 250,
  })
  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    end
  end, ms)
end

local function busy_mode()
  local mode = vim.api.nvim_get_mode().mode
  return mode:sub(1, 1) == "i" or mode:sub(1, 1) == "c" or mode:sub(1, 1) == "R"
end

---Shows path in the follow window (or the current one) at a line range.
function M.reveal(path, first, last, opts)
  opts = opts or {}
  local win = F.win
  if not (win and vim.api.nvim_win_is_valid(win)) then
    win = vim.api.nvim_get_current_win()
    if F.enabled then
      F.win = win
    end
  end
  if win == vim.api.nvim_get_current_win() and busy_mode() then
    F.pending = { path = path, first = first, last = last }
    return false
  end
  if vim.fn.filereadable(path) == 0 then
    return false
  end
  local buf = vim.fn.bufadd(path)
  vim.fn.bufload(buf)
  vim.bo[buf].buflisted = true
  vim.api.nvim_win_set_buf(win, buf)
  first = math.max(1, math.min(first or 1, vim.api.nvim_buf_line_count(buf)))
  vim.api.nvim_win_set_cursor(win, { first, 0 })
  vim.api.nvim_win_call(win, function()
    vim.cmd("normal! zz")
  end)
  flash(buf, first, last or first)
  return true
end

---Applies a jump deferred while the user typed.
function M.flush()
  local p = F.pending
  if p and not busy_mode() then
    F.pending = nil
    M.reveal(p.path, p.first, p.last)
  end
end

function M.pending()
  return F.pending
end

---Reloads a loaded, unmodified buffer. Returns its previous lines, or nil
---when the file isn't loaded. Returns false when unsaved changes block it.
local function reload(path)
  local buf = vim.fn.bufnr(path)
  if buf <= 0 or not vim.api.nvim_buf_is_loaded(buf) then
    return nil
  end
  if vim.bo[buf].modified then
    return false
  end
  local old = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  vim.api.nvim_buf_call(buf, function()
    vim.cmd("silent! edit")
  end)
  return old
end

-- Content before an edit when neither a buffer nor an earlier event holds
-- it: the file at the start of the agent's turn.
local function base_lines(path, ev)
  local repo = vcs.detect(vim.fs.dirname(path))
  local t = turns.open_turn(ev)
  if not (repo and t and t.start_ref) then
    return nil
  end
  local from = vcs.resolve(repo, t.start_ref, t.cwd)
  return from and vcs.show(repo, from, util.relative(path, repo.root)) or {}
end

---Handles a live edit event.
function M.on_edit(ev, root)
  local path = ev.path
  local old = reload(path)
  if old == false then
    return "modified"
  end
  local new = util.read_lines(path)
  old = old or F.known[path]
  F.known[path] = new
  if not (F.enabled and new) then
    return "reloaded"
  end
  local first, last
  if ev.line then
    first, last = ev.line, ev.line
  else
    old = old or base_lines(path, ev) or {}
    local _, _, range = diff.compare(old, new)
    if range then
      first, last = range[1], range[2]
    end
  end
  M.reveal(path, first or 1, last or first or 1)
  return "followed", root
end

function M.on_show(ev)
  return M.reveal(ev.path, ev.line or 1, ev.line or 1)
end

---Notifies about a finished turn with changed files and unreviewed hunks.
function M.on_stop(ev, repo)
  if not config.options.notify_stop then
    return
  end
  local t = turns.latest(repo.root, ev.agent)
  if not t or t.stopped ~= ev.epoch then
    return
  end
  local scope = turns.scope(repo, "turn", { turn = t })
  local files = scope and turns.files(repo, scope)
  if not files then
    return
  end
  local review = require("tether.review")
  local nfiles, _, open = review.count(repo.root, files)
  review.last = { turn = t.id, unreviewed = open }
  local prefix = config.options.prefix
  util.notify(
    ("%s finished: %d file%s changed, %d unreviewed hunk%s%s"):format(
      t.agent,
      nfiles,
      nfiles == 1 and "" or "s",
      open,
      open == 1 and "" or "s",
      prefix and (" · " .. prefix .. "r to review") or ""
    )
  )
  vim.api.nvim_exec_autocmds("User", { pattern = "TetherTurnStop", data = { turn = t, files = files } })
end

---Dispatches a live event for the current repository.
function M.on_event(ev, repo)
  if ev.replay or not repo then
    return
  end
  if ev.kind == "edit" and util.inside(ev.path, repo.root) then
    return M.on_edit(ev, repo.root)
  elseif ev.kind == "read" and config.options.follow.reads and F.enabled and util.inside(ev.path, repo.root) then
    M.reveal(ev.path, ev.line or 1, ev.line or 1)
  elseif ev.kind == "show" and util.inside(ev.path, repo.root) then
    return M.on_show(ev)
  elseif ev.kind == "stop" and util.inside(ev.cwd, repo.root) then
    M.on_stop(ev, repo)
  end
end

return M
