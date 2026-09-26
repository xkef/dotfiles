-- Tails the agent-trail event log and dispatches parsed events.
--
-- A record is one line of ten tab-separated fields, "-" for empty:
-- epoch kind agent session pane cwd path line ref text

local util = require("tether.util")

local M = {}

M.FIELDS = { "epoch", "kind", "agent", "session", "pane", "cwd", "path", "line", "ref", "text" }

---@class tether.Event
---@field epoch integer
---@field kind string
---@field agent? string
---@field session? string
---@field pane? string
---@field cwd? string
---@field path? string
---@field line? integer
---@field ref? string
---@field text? string
---@field replay? boolean

local subscribers = {}
local state = { offset = 0 }

---@return tether.Event?
function M.parse(line)
  local parts = vim.split(line, "\t", { plain = true })
  if #parts ~= #M.FIELDS then
    return nil
  end
  local ev = {}
  for i, name in ipairs(M.FIELDS) do
    local value = parts[i]
    if value ~= "-" and value ~= "" then
      ev[name] = value
    end
  end
  ev.epoch = tonumber(ev.epoch)
  if not ev.epoch or not ev.kind or not ev.kind:match("^%l+$") then
    return nil
  end
  ev.line = ev.line and tonumber(ev.line) or nil
  if ev.cwd then
    ev.cwd = util.normalize(ev.cwd)
  end
  if ev.path and not ev.path:find("[*?%[]") then
    ev.path = util.normalize(ev.path)
  end
  return ev
end

---Registers fn(event). Returns a function that removes it.
function M.subscribe(fn)
  table.insert(subscribers, fn)
  return function()
    for i, f in ipairs(subscribers) do
      if f == fn then
        table.remove(subscribers, i)
        return
      end
    end
  end
end

function M.dispatch(ev)
  for _, fn in ipairs(subscribers) do
    local ok, err = pcall(fn, ev)
    if not ok then
      util.warn("event handler failed: " .. tostring(err))
    end
  end
end

local function read_range(file, from, to)
  local fd = vim.uv.fs_open(file, "r", 438)
  if not fd then
    return nil
  end
  local data = vim.uv.fs_read(fd, to - from, from)
  vim.uv.fs_close(fd)
  return data
end

local function dispatch_text(text, replay)
  for _, line in ipairs(vim.split(text, "\n", { plain = true, trimempty = true })) do
    local ev = M.parse(line)
    if ev then
      ev.replay = replay or nil
      M.dispatch(ev)
    end
  end
end

---Reads complete lines appended since the last read.
function M.read(replay)
  local file = state.file
  if not file then
    return
  end
  local stat = vim.uv.fs_stat(file)
  if not stat then
    state.offset = 0
    return
  end
  -- A new inode means the log was rotated; a smaller size means it was
  -- truncated. Either way the unread part starts at zero.
  if state.ino and stat.ino ~= state.ino then
    -- Events appended to the old file after the last read now sit at the
    -- end of trail.log.1.
    local old = vim.uv.fs_stat(file .. ".1")
    if old and old.ino == state.ino and old.size > state.offset then
      local rest = read_range(file .. ".1", state.offset, old.size)
      if rest then
        dispatch_text(rest, replay)
      end
    end
    state.offset = 0
  elseif stat.size < state.offset then
    state.offset = 0
  end
  state.ino = stat.ino
  if stat.size == state.offset then
    return
  end
  local data = read_range(file, state.offset, stat.size)
  if not data then
    return
  end
  local last = data:match(".*()\n")
  if not last then
    return
  end
  state.offset = state.offset + last
  dispatch_text(data:sub(1, last), replay)
end

---Starts tailing the log: replays the rotated and current file, then
---watches the directory and polls as a fallback.
function M.start(file)
  M.stop()
  state.file = file
  state.offset = 0
  vim.fn.mkdir(vim.fs.dirname(file), "p")

  local old = util.read_lines(file .. ".1")
  if old then
    dispatch_text(table.concat(old, "\n"), true)
  end
  M.read(true)

  local name = vim.fs.basename(file)
  state.watcher = vim.uv.new_fs_event()
  if state.watcher then
    local ok = pcall(state.watcher.start, state.watcher, vim.fs.dirname(file), {}, function(err, fname)
      if not err and (fname == nil or fname == name) then
        vim.schedule(M.read)
      end
    end)
    if not ok then
      state.watcher:close()
      state.watcher = nil
    end
  end
  state.timer = vim.uv.new_timer()
  state.timer:start(1000, 1000, vim.schedule_wrap(M.read))
end

function M.stop()
  if state.watcher then
    state.watcher:stop()
    state.watcher:close()
    state.watcher = nil
  end
  if state.timer then
    state.timer:stop()
    state.timer:close()
    state.timer = nil
  end
  state.file = nil
end

function M.reset()
  M.stop()
  subscribers = {}
  state = { offset = 0 }
end

return M
