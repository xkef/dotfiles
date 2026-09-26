-- Coordination between agents and the user: claims derived from the event
-- log, conflict warnings, and the jj workspace map. Nothing here needs the
-- agents' cooperation beyond the events they already emit.

local api = require("tether.api")
local claims = require("tether.features.coord.internal.claims")

local M = {}

local ns = vim.api.nvim_create_namespace("tether.claims")

local C

function M.reset()
  C = { warned = {}, workspaces = {} }
  claims.reset()
end
M.reset()

M.claims = claims.all

---Claims that cover path, optionally excluding one agent and session.
M.claimed = claims.covering

local agents_of = claims.agents_of

local function conflict(kind, data, msg)
  local id = kind .. "\0" .. data.id
  if C.warned[id] then
    return false
  end
  C.warned[id] = true
  api.util.warn(msg)
  data.kind = kind
  api.emit("conflict", data)
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
  local by = agents_of(M.claimed(api.util.normalize(name)))
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

local mark_later = api.util.debounce(100, M.mark_all)

----------------------------------------------------------------------------
-- Events

---@param ev tether.Event
function M.on_event(ev)
  local k = claims.key(ev)
  claims.on_event(ev)
  if ev.replay then
    return
  end
  if ev.kind == "edit" and ev.path then
    local others = M.claimed(ev.path, k)
    if #others > 0 then
      local repo = api.repo()
      local rel = repo and api.util.relative(ev.path, repo.root) or ev.path
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
  local path = api.util.normalize(name)
  local open = api.turns.open()
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
    C.workspaces[a.cwd] = api.vcs.workspace(repo, a.cwd) or false
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
    local ok, err = api.vcs.workspace_add(repo, n, path)
    if not ok then
      api.util.warn(err)
      return
    end
    local reg = api.ui.copy(path)
    api.util.notify(("workspace %s at %s (path in the %s register); start an agent there"):format(n, path, reg))
    return path
  end
  if name then
    return add(name)
  end
  vim.ui.input({ prompt = "New workspace name: " }, add)
end

----------------------------------------------------------------------------
-- Integration

---@param tether_api table tether.api
function M.attach(tether_api)
  C.unsubscribe = tether_api.on("event", M.on_event)

  local group = vim.api.nvim_create_augroup("tether.features.coord", { clear = true })
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

  tether_api.register.agent_field(function(repo, a)
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
  tether_api.register.agent_action(function(repo, a)
    local actions = {
      w = function()
        M.add_workspace(repo)
      end,
    }
    local ws = M.workspace_of(repo, a)
    if ws then
      actions.W = function()
        api.ui.review(repo, "workspace", { workspace = ws })
      end
      if not api.util.inside(a.cwd, repo.root) then
        -- The agent's turns live in its own workspace; its review is the
        -- workspace against trunk.
        actions.r = actions.W
      end
    end
    return actions
  end)

  tether_api.register.source({
    name = "claims",
    desc = "Files agents are working on",
    items = function(repo)
      local items = {}
      for _, c in ipairs(M.claims()) do
        if api.vcs.same_repo(repo, vim.fs.dirname(c.pattern)) or api.util.inside(c.pattern, repo.root) then
          local glob = claims.is_glob(c.pattern)
          table.insert(items, {
            text = ("%-7s %s  (%s, %s)"):format(
              c.agent,
              api.util.relative(c.pattern, repo.root),
              c.kind,
              api.util.age(c.epoch)
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
  pcall(vim.api.nvim_del_augroup_by_name, "tether.features.coord")
end

return M
