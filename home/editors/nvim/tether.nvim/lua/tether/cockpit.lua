-- The cockpit: one sidebar with sections from registered providers.

local agents = require("tether.agents")
local config = require("tether.config")
local turns = require("tether.turns")
local util = require("tether.util")

local M = {}

local ns = vim.api.nvim_create_namespace("tether.cockpit")

M.KEYS = {
  { "<CR>", "open: focus agent, review file, open trail entry" },
  { "r", "review the agent's latest turn" },
  { "s", "send text to the agent" },
  { "x", "toggle (tasks)" },
  { "w", "add a jj workspace for a new agent" },
  { "W", "review the agent's workspace against trunk" },
  { "<Tab>", "collapse or expand" },
  { "R", "refresh" },
  { "q", "close" },
  { "g?", "this help" },
}

---@class tether.CockpitRow
---@field text string
---@field hl? string
---@field id? string key for expansion state
---@field children? tether.CockpitRow[]
---@field actions? table<string, fun()>

---@class tether.Section
---@field name string
---@field order integer
---@field rows fun(repo: tether.Repo): tether.CockpitRow[]
---@field summary? fun(repo: tether.Repo): string?

---@type tether.Section[]
M.sections = {}

local C = { collapsed = {}, expanded = {}, items = {}, cache = {} }

function M.register(section)
  M.sections = vim.tbl_filter(function(s)
    return s.name ~= section.name
  end, M.sections)
  table.insert(M.sections, section)
  table.sort(M.sections, function(a, b)
    return a.order < b.order
  end)
end

function M.unregister(name)
  M.sections = vim.tbl_filter(function(s)
    return s.name ~= name
  end, M.sections)
end

function M.is_open()
  return C.win ~= nil and vim.api.nvim_win_is_valid(C.win)
end

local function repo()
  return require("tether").repo()
end

function M.render()
  local buf = C.buf
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then
    return
  end
  local r = repo()
  local lines, items, marks = {}, {}, {}
  if not r then
    lines = { "Not in a jj or Git repository." }
  else
    for _, section in ipairs(M.sections) do
      local ok, rows = pcall(section.rows, r)
      if not ok then
        rows = { { text = "error: " .. tostring(rows), hl = "DiagnosticError" } }
      end
      if rows and #rows > 0 then
        if #lines > 0 then
          table.insert(lines, "")
        end
        local collapsed = C.collapsed[section.name]
        local summary = section.summary and section.summary(r)
        table.insert(lines, (collapsed and "▸ " or "▾ ") .. section.name .. (summary and ("  " .. summary) or ""))
        items[#lines] = { section = section, header = true }
        table.insert(marks, { #lines, "TetherHeader" })
        if not collapsed then
          local function add(row, depth)
            table.insert(lines, string.rep("  ", depth) .. row.text)
            items[#lines] = { section = section, row = row }
            if row.hl then
              table.insert(marks, { #lines, row.hl })
            end
            if row.children and row.id and C.expanded[row.id] then
              for _, child in ipairs(row.children) do
                add(child, depth + 1)
              end
            end
          end
          for _, row in ipairs(rows) do
            add(row, 1)
          end
        end
      end
    end
    if #lines == 0 then
      lines = { "No agent activity in this repository yet." }
    end
  end
  local cursor = C.win and vim.api.nvim_win_is_valid(C.win) and vim.api.nvim_win_get_cursor(C.win)
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, m in ipairs(marks) do
    vim.api.nvim_buf_set_extmark(buf, ns, m[1] - 1, 0, { end_row = m[1], end_col = 0, hl_group = m[2], hl_eol = false })
  end
  C.items = items
  if cursor then
    pcall(vim.api.nvim_win_set_cursor, C.win, { math.min(cursor[1], #lines), cursor[2] })
  end
end

M.refresh = M.render

local debounced = util.debounce(150, function()
  if M.is_open() then
    M.render()
  end
end)

function M.on_event(ev)
  if not ev.replay then
    debounced()
  end
end

function M.item_at(lnum)
  return C.items[lnum]
end

function M.act(key)
  local item = C.items[vim.fn.line(".")]
  if not item then
    return
  end
  if key == "<Tab>" then
    if item.header then
      C.collapsed[item.section.name] = not C.collapsed[item.section.name] or nil
    elseif item.row.id and item.row.children then
      C.expanded[item.row.id] = not C.expanded[item.row.id] or nil
    end
    return M.render()
  end
  local fn = item.row and item.row.actions and item.row.actions[key]
  if fn then
    fn()
  end
end

function M.help()
  local out = {}
  for _, k in ipairs(M.KEYS) do
    table.insert(out, ("%-6s %s"):format(k[1], k[2]))
  end
  util.notify(table.concat(out, "\n"))
  return out
end

function M.close()
  if M.is_open() then
    pcall(vim.api.nvim_win_close, C.win, true)
  end
  C.win = nil
  if C.timer then
    C.timer:stop()
    C.timer:close()
    C.timer = nil
  end
end

function M.open()
  if M.is_open() then
    vim.api.nvim_set_current_win(C.win)
    return
  end
  local opts = config.options.cockpit
  if not (C.buf and vim.api.nvim_buf_is_valid(C.buf)) then
    C.buf = vim.api.nvim_create_buf(false, true)
    pcall(vim.api.nvim_buf_set_name, C.buf, "tether://cockpit")
    vim.bo[C.buf].filetype = "tether-cockpit"
    vim.bo[C.buf].bufhidden = "hide"
    for _, k in ipairs({ "<CR>", "r", "s", "x", "w", "W", "<Tab>" }) do
      vim.keymap.set("n", k, function()
        M.act(k)
      end, { buffer = C.buf, nowait = true })
    end
    vim.keymap.set("n", "R", M.render, { buffer = C.buf, nowait = true, desc = "Refresh" })
    vim.keymap.set("n", "q", M.close, { buffer = C.buf, nowait = true, desc = "Close cockpit" })
    vim.keymap.set("n", "g?", M.help, { buffer = C.buf, nowait = true, desc = "Cockpit keys" })
  end
  local cmd = (opts.side == "left" and "topleft" or "botright") .. " vertical " .. opts.width .. "split"
  vim.cmd(cmd)
  C.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(C.win, C.buf)
  for opt, value in pairs({
    number = false,
    relativenumber = false,
    signcolumn = "no",
    wrap = false,
    cursorline = true,
    winfixwidth = true,
    foldcolumn = "0",
    list = false,
  }) do
    vim.wo[C.win][opt] = value
  end
  M.render()
  C.timer = vim.uv.new_timer()
  C.timer:start(opts.interval, opts.interval, function()
    vim.schedule(function()
      if M.is_open() then
        M.render()
      else
        M.close()
      end
    end)
  end)
end

function M.toggle()
  if M.is_open() then
    M.close()
    return false
  end
  M.open()
  return true
end

function M.reset()
  M.close()
  if C.buf and vim.api.nvim_buf_is_valid(C.buf) then
    pcall(vim.api.nvim_buf_delete, C.buf, { force = true })
  end
  C = { collapsed = {}, expanded = {}, items = {}, cache = {} }
end

----------------------------------------------------------------------------
-- Built-in sections

local ICONS = { waiting = "●", busy = "◐", running = "◌", idle = "○" }

-- Files of a finished turn, cached per turn.
local function turn_files(r, t)
  local key = t.id .. ":" .. (t.end_ref or "")
  if not C.cache[key] then
    local scope = turns.scope(r, "turn", { turn = t })
    C.cache[key] = scope and turns.files(r, scope) or {}
  end
  return C.cache[key]
end

---Unreviewed hunks of an agent's latest finished turn, or nil.
function M.unreviewed(r, agent)
  local t = turns.latest(r.root, agent)
  if not t or turns.running(t) then
    return nil
  end
  local _, _, open = require("tether.review").count(r.root, turn_files(r, t))
  return open
end

-- Fields other modules add to agent rows: fn(repo, agent) -> string?
M.agent_fields = {}

function M.focus_pane(a)
  if not a.pane_id then
    return
  end
  util.run({ config.options.send.wezterm, "cli", "activate-pane", "--pane-id", a.pane_id })
end

M.register({
  name = "Agents",
  order = 10,
  summary = function(r)
    local n = #agents.in_root(r.root)
    return n > 0 and tostring(n) or nil
  end,
  rows = function(r)
    local rows = {}
    for _, a in ipairs(agents.in_root(r.root)) do
      local parts = { ICONS[a.state] or "·", ("%-7s"):format(a.agent), ("%-7s"):format(a.state) }
      if a.tool then
        table.insert(parts, a.tool)
      end
      if a.task then
        table.insert(parts, a.task)
      end
      local open = M.unreviewed(r, a.agent)
      if open and open > 0 then
        table.insert(parts, "Δ" .. open)
      end
      for _, fn in ipairs(M.agent_fields) do
        local ok, extra = pcall(fn, r, a)
        if ok and extra then
          table.insert(parts, extra)
        end
      end
      table.insert(rows, {
        text = table.concat(parts, " "),
        hl = a.state == "waiting" and "TetherWaiting" or nil,
        agent = a,
        actions = {
          ["<CR>"] = function()
            M.focus_pane(a)
          end,
          r = function()
            local t = turns.latest(r.root, a.agent)
            if t then
              require("tether.review").open(r, "turn", { turn = t })
            end
          end,
          s = function()
            vim.ui.input({ prompt = "Send to " .. a.agent .. ": " }, function(text)
              if text and text ~= "" then
                require("tether.send").deliver(a, text)
              end
            end)
          end,
        },
      })
    end
    return rows
  end,
})

M.register({
  name = "Turn",
  order = 20,
  summary = function(r)
    local t = turns.latest(r.root)
    if not t then
      return nil
    end
    return ("#%d %s%s%s"):format(
      t.id,
      t.agent,
      t.summary and (" · " .. t.summary) or "",
      turns.running(t) and " (running)" or ""
    )
  end,
  rows = function(r)
    local t = turns.latest(r.root)
    if not t then
      return {}
    end
    local stamp = 0
    for _, info in pairs(t.files) do
      stamp = math.max(stamp, info.epoch)
    end
    local key = "stats:" .. t.id .. ":" .. (t.end_ref or stamp)
    if not C.cache[key] then
      C.cache[key] = turns.stats(r, t)
    end
    local rows = {}
    for _, s in ipairs(C.cache[key]) do
      local rel = util.relative(s.path, r.root)
      table.insert(rows, {
        text = ("%s  +%d -%d"):format(rel, s.added, s.removed),
        actions = {
          ["<CR>"] = function()
            vim.cmd("wincmd p")
            require("tether.review").open(r, "turn", { turn = t })
            require("tether.review").goto_file(rel)
          end,
        },
      })
    end
    return rows
  end,
})

M.register({
  name = "Trail",
  order = 40,
  rows = function(r)
    local rows = {}
    for _, ev in ipairs(turns.trail(r.root, config.options.cockpit.trail)) do
      local rel = util.relative(ev.path, r.root)
      table.insert(rows, {
        text = ("%-4s %-7s %s%s %s"):format(
          ev.kind,
          ev.agent or "?",
          rel,
          ev.line and (":" .. ev.line) or "",
          util.age(ev.epoch)
        ),
        hl = ev.kind == "read" and "TetherMuted" or nil,
        actions = {
          ["<CR>"] = function()
            require("tether.pick").open_file(ev.path, ev.line)
          end,
        },
      })
    end
    return rows
  end,
})

return M
