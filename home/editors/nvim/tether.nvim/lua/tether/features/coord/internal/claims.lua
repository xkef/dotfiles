-- Claims: which agent works on which file. Files edited in a running turn
-- are claimed implicitly; `claim` events add explicit claims that end with
-- a `release`, the agent's pane closing, or coord.claim_ttl.

local api = require("tether.api")

local M = {}

M.CLAIM_TTL = 2 * 3600

---@class tether.Claim
---@field key string agent and session
---@field agent string
---@field pattern string absolute path or glob
---@field kind "edit"|"claim"
---@field epoch integer
---@field pane? string

local explicit = {}

function M.reset()
  explicit = {}
end

---Agent and session of an event, the identity claims use.
function M.key(ev)
  return (ev.agent or "?") .. "\0" .. (ev.session or "")
end

function M.match(pattern, path)
  if pattern == path then
    return true
  end
  if not pattern:find("[*?%[{]") then
    return false
  end
  local ok, lpeg = pcall(vim.glob.to_lpeg, pattern)
  return ok and lpeg:match(path) ~= nil
end

function M.is_glob(pattern)
  return pattern:find("[*?%[{]") ~= nil
end

local function alive_panes()
  if vim.fn.executable(api.config().agent_state) == 0 then
    return nil
  end
  local set = {}
  for _, a in ipairs(api.agents.list()) do
    if a.pane_id then
      set[a.pane_id] = true
    end
  end
  return set
end

---Records claim and release events.
function M.on_event(ev)
  local k = M.key(ev)
  if ev.kind == "claim" and ev.path then
    table.insert(explicit, {
      key = k,
      agent = ev.agent or "?",
      pattern = ev.path,
      kind = "claim",
      epoch = ev.epoch,
      pane = ev.pane,
    })
  elseif ev.kind == "release" then
    explicit = vim.tbl_filter(function(c)
      return not (c.key == k and (not ev.path or c.pattern == ev.path))
    end, explicit)
  end
end

---All live claims.
---@return tether.Claim[]
function M.all()
  local out = {}
  for k, t in pairs(api.turns.open()) do
    for path, info in pairs(t.files) do
      table.insert(out, { key = k, agent = t.agent, pattern = path, kind = "edit", epoch = info.epoch, pane = t.pane })
    end
  end
  local now = os.time()
  local panes
  local ttl = (api.config().coord or {}).claim_ttl or M.CLAIM_TTL
  explicit = vim.tbl_filter(function(c)
    if now - c.epoch > ttl then
      return false
    end
    if c.pane then
      panes = panes or alive_panes() or false
      if panes and not panes[c.pane] then
        return false
      end
    end
    return true
  end, explicit)
  vim.list_extend(out, explicit)
  return out
end

---Claims that cover path, optionally excluding one agent and session.
function M.covering(path, except_key)
  local out = {}
  for _, c in ipairs(M.all()) do
    if c.key ~= except_key and M.match(c.pattern, path) then
      table.insert(out, c)
    end
  end
  return out
end

---Distinct agent names of claims, in order.
function M.agents_of(list)
  local names, seen = {}, {}
  for _, c in ipairs(list) do
    if not seen[c.agent] then
      seen[c.agent] = true
      table.insert(names, c.agent)
    end
  end
  return names
end

return M
