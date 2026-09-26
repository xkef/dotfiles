-- Coordination between agents and the user: claims derived from the event
-- log, conflict warnings, and the jj workspace map. Nothing here needs the
-- agents' cooperation beyond the events they already emit.

local agents = require("tether.agents")
local config = require("tether.config")
local turns = require("tether.turns")
local util = require("tether.util")
local vcs = require("tether.vcs")

local M = {}

M.CLAIM_TTL = 2 * 3600

local ns = vim.api.nvim_create_namespace("tether.claims")

local C

function M.reset()
  C = { explicit = {}, warned = {}, workspaces = {}, unsubscribe = nil }
end
M.reset()

local function key(ev)
  return (ev.agent or "?") .. "\0" .. (ev.session or "")
end

---@class tether.Claim
---@field key string agent and session
---@field agent string
---@field pattern string absolute path or glob
---@field kind "edit"|"claim"
---@field epoch integer
---@field pane? string

local function glob_match(pattern, path)
  if pattern == path then
    return true
  end
  if not pattern:find("[*?%[{]") then
    return false
  end
  local ok, lpeg = pcall(vim.glob.to_lpeg, pattern)
  return ok and lpeg:match(path) ~= nil
end

local function alive_panes()
  if vim.fn.executable(config.options.agent_state) == 0 then
    return nil
  end
  local set = {}
  for _, a in ipairs(agents.list()) do
    if a.pane_id then
      set[a.pane_id] = true
    end
  end
  return set
end

---All claims: files edited in running turns, and explicit claims that are
---neither released, expired, nor held by a closed pane.
---@return tether.Claim[]
function M.claims()
  local out = {}
  for k, t in pairs(turns.open()) do
    for path, info in pairs(t.files) do
      table.insert(out, { key = k, agent = t.agent, pattern = path, kind = "edit", epoch = info.epoch, pane = t.pane })
    end
  end
  local now = os.time()
  local panes
  local ttl = (config.options.coord or {}).claim_ttl or M.CLAIM_TTL
  C.explicit = vim.tbl_filter(function(c)
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
  end, C.explicit)
  vim.list_extend(out, C.explicit)
  return out
end

---Claims that cover path, optionally excluding one agent and session.
function M.claimed(path, except_key)
  local out = {}
  for _, c in ipairs(M.claims()) do
    if c.key ~= except_key and glob_match(c.pattern, path) then
      table.insert(out, c)
    end
  end
  return out
end

local function agents_of(claims)
  local names, seen = {}, {}
  for _, c in ipairs(claims) do
    if not seen[c.agent] then
      seen[c.agent] = true
      table.insert(names, c.agent)
    end
  end
  return names
end

local function conflict(kind, data, msg)
  local id = kind .. "\0" .. data.id
  if C.warned[id] then
    return false
  end
  C.warned[id] = true
  util.warn(msg)
  data.kind = kind
  vim.api.nvim_exec_autocmds("User", { pattern = "TetherConflict", data = data })
  return true
end

----------------------------------------------------------------------------
-- Buffer markers

function M.mark_buffer(buf)
  if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) or vim.bo[buf].buftype ~= "" then
    return
  end
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" then
    return
  end
  local by = agents_of(M.claimed(util.normalize(name)))
  if #by > 0 and vim.api.nvim_buf_line_count(buf) > 0 then
    vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, {
      virt_text = { { " ⚑ " .. table.concat(by, ", "), "TetherClaim" } },
      virt_text_pos = "eol",
      hl_mode = "combine",
    })
  end
end

function M.mark_all()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    M.mark_buffer(buf)
  end
end

local mark_later = util.debounce(100, M.mark_all)

----------------------------------------------------------------------------
-- Events

---@param ev tether.Event
function M.on_event(ev)
  local k = key(ev)
  if ev.kind == "claim" and ev.path then
    table.insert(
      C.explicit,
      { key = k, agent = ev.agent or "?", pattern = ev.path, kind = "claim", epoch = ev.epoch, pane = ev.pane }
    )
  elseif ev.kind == "release" then
    C.explicit = vim.tbl_filter(function(c)
      return not (c.key == k and (not ev.path or c.pattern == ev.path))
    end, C.explicit)
  end
  if ev.replay then
    return
  end
  if ev.kind == "edit" and ev.path then
    local others = M.claimed(ev.path, k)
    if #others > 0 then
      local repo = require("tether").repo()
      local rel = repo and util.relative(ev.path, repo.root) or ev.path
      local holders = agents_of(others)
      conflict(
        "agents",
        {
          id = ev.path .. "\0" .. k .. "\0" .. table.concat(holders, ","),
          path = ev.path,
          agent = ev.agent,
          holders = holders,
        },
        ("%s edited %s, which %s %s working on"):format(
          ev.agent or "an agent",
          rel,
          table.concat(holders, " and "),
          #holders == 1 and "is" or "are"
        )
      )
    end
    local buf = vim.fn.bufnr(ev.path)
    if buf > 0 and vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].modified then
      conflict(
        "unsaved",
        { id = ev.path .. "\0" .. ev.epoch, path = ev.path, agent = ev.agent },
        ("%s wrote %s on disk under your unsaved changes"):format(
          ev.agent or "an agent",
          vim.fn.fnamemodify(ev.path, ":~:.")
        )
      )
    end
  end
  if ev.kind == "edit" or ev.kind == "stop" or ev.kind == "claim" or ev.kind == "release" or ev.kind == "turn" then
    mark_later()
  end
end

---Warns once per buffer and turn when the user edits a file an agent's
---running turn claims.
function M.on_user_change(buf)
  if not vim.bo[buf].modified or vim.bo[buf].buftype ~= "" then
    return
  end
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" then
    return
  end
  local path = util.normalize(name)
  local open = turns.open()
  for _, c in ipairs(M.claimed(path)) do
    local t = open[c.key]
    if t then
      conflict(
        "user",
        { id = buf .. "\0" .. t.id, path = path, holders = { c.agent } },
        ("%s is working on %s in its current turn"):format(c.agent, vim.fn.fnamemodify(path, ":~:."))
      )
      return
    end
  end
end

----------------------------------------------------------------------------
-- Workspaces

---The jj workspace an agent works in, from its cwd.
function M.workspace_of(repo, a)
  if not a.cwd then
    return nil
  end
  if C.workspaces[a.cwd] == nil then
    C.workspaces[a.cwd] = vcs.workspace(repo, a.cwd) or false
  end
  return C.workspaces[a.cwd] or nil
end

---Adds a jj workspace next to the repository for a new agent.
function M.add_workspace(repo, name)
  local function add(n)
    if not n or n == "" then
      return
    end
    local path = vim.fs.joinpath(vim.fs.dirname(repo.root), vim.fs.basename(repo.root) .. "-" .. n)
    local ok, err = vcs.workspace_add(repo, n, path)
    if not ok then
      util.warn(err)
      return
    end
    local reg = require("tether.send").copy(path)
    util.notify(("workspace %s at %s (path in the %s register); start an agent there"):format(n, path, reg))
    return path
  end
  if name then
    return add(name)
  end
  vim.ui.input({ prompt = "New workspace name: " }, add)
end

----------------------------------------------------------------------------
-- Integration

function M.attach()
  local events = require("tether.events")
  C.unsubscribe = events.subscribe(M.on_event)

  local group = vim.api.nvim_create_augroup("tether.coord", { clear = true })
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter" }, {
    group = group,
    callback = function(args)
      M.mark_buffer(args.buf)
    end,
  })
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = group,
    callback = function(args)
      M.on_user_change(args.buf)
    end,
  })

  local cockpit = require("tether.cockpit")
  table.insert(cockpit.agent_fields, function(repo, a)
    local parts = {}
    local ws = M.workspace_of(repo, a)
    if ws and ws ~= "default" then
      table.insert(parts, "[" .. ws .. "]")
    end
    local n = 0
    for _, c in ipairs(M.claims()) do
      if c.agent == a.agent and (not c.pane or c.pane == a.pane_id) then
        n = n + 1
      end
    end
    if n > 0 then
      table.insert(parts, "⚑" .. n)
    end
    return #parts > 0 and table.concat(parts, " ") or nil
  end)
  table.insert(cockpit.agent_actions, function(repo, a)
    local actions = {
      w = function()
        M.add_workspace(repo)
      end,
    }
    local ws = M.workspace_of(repo, a)
    if ws then
      actions.W = function()
        require("tether.review").open(repo, "workspace", { workspace = ws })
      end
      if not util.inside(a.cwd, repo.root) then
        -- The agent's turns live in its own workspace; its review is the
        -- workspace against trunk.
        actions.r = actions.W
      end
    end
    return actions
  end)

  require("tether.pick").register({
    name = "claims",
    desc = "Files agents are working on",
    items = function(repo)
      local items = {}
      for _, c in ipairs(M.claims()) do
        if vcs.same_repo(repo, vim.fs.dirname(c.pattern)) or util.inside(c.pattern, repo.root) then
          local glob = c.pattern:find("[*?%[{]") ~= nil
          table.insert(items, {
            text = ("%-7s %s  (%s, %s)"):format(
              c.agent,
              util.relative(c.pattern, repo.root),
              c.kind,
              util.age(c.epoch)
            ),
            file = not glob and c.pattern or nil,
          })
        end
      end
      return items
    end,
  })
end

function M.detach()
  if C.unsubscribe then
    C.unsubscribe()
  end
  pcall(vim.api.nvim_del_augroup_by_name, "tether.coord")
end

return M
