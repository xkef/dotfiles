-- tether.nvim: review, follow, and coordinate CLI agents from Neovim.

local config = require("tether.config")

local M = {}

M.did_setup = false

local repo_cache = {}

---The repository of the current working directory.
---@return tether.Repo?
function M.repo()
  local cwd = vim.fn.getcwd()
  if repo_cache.cwd ~= cwd then
    repo_cache = { cwd = cwd, repo = require("tether.vcs").detect(cwd) }
  end
  return repo_cache.repo
end

local function need_repo()
  local repo = M.repo()
  if not repo then
    require("tether.util").warn("not in a jj or Git repository")
  end
  return repo
end

local function highlights()
  for name, link in pairs({
    TetherFlash = "IncSearch",
    TetherDim = "Comment",
    TetherMuted = "NonText",
    TetherHeader = "Title",
    TetherReviewed = "DiagnosticOk",
    TetherRejected = "DiagnosticError",
    TetherComment = "DiagnosticInfo",
    TetherClaim = "DiagnosticWarn",
    TetherWaiting = "DiagnosticWarn",
  }) do
    vim.api.nvim_set_hl(0, name, { link = link, default = true })
  end
end

-- Modules loaded after the core; each may register sources, sections, and
-- event handlers through an `attach()` function.
M.extensions = { "tether.coord", "tether.sdd", "tether.attractor" }

---Resets all state. Used by tests.
function M._reset()
  for _, name in ipairs({ "events", "turns", "review", "follow", "cockpit", "agents" }) do
    local ok, mod = pcall(require, "tether." .. name)
    if ok and mod.reset then
      mod.reset()
    end
  end
  for _, name in ipairs(M.extensions) do
    local mod = package.loaded[name]
    if mod and mod.reset then
      mod.reset()
    end
  end
  repo_cache = {}
  M.did_setup = false
end

local function keys(prefix)
  local function map(mode, suffix, rhs, desc)
    vim.keymap.set(mode, prefix .. suffix, rhs, { desc = desc })
  end
  map("n", "a", function()
    M.cockpit()
  end, "Agent cockpit")
  map("n", "r", function()
    M.review()
  end, "Review agent turn")
  map("n", "f", function()
    M.follow()
  end, "Follow agent")
  map("n", "p", function()
    M.pick()
  end, "Pick (agents)")
  map("n", "s", function()
    M.send()
  end, "Send to agent")
  map("x", "s", function()
    local l1, l2 = vim.fn.line("v"), vim.fn.line(".")
    vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
    M.send({ l1, l2 })
  end, "Send selection to agent")
  map("n", "u", function()
    M.undo()
  end, "Undo agent turn")
end

function M.setup(opts)
  if M.did_setup then
    M._reset()
  end
  config.setup(opts)
  M.did_setup = true
  highlights()

  local events = require("tether.events")
  local turns = require("tether.turns")
  events.subscribe(turns.on_event)
  events.subscribe(function(ev)
    require("tether.follow").on_event(ev, M.repo())
  end)
  events.subscribe(require("tether.cockpit").on_event)

  for _, name in ipairs(M.extensions) do
    local ok, mod = pcall(require, name)
    if ok and mod.attach then
      mod.attach()
    end
  end

  local group = vim.api.nvim_create_augroup("tether", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = highlights })
  vim.api.nvim_create_autocmd("ModeChanged", {
    group = group,
    pattern = "*:n",
    callback = function()
      require("tether.follow").flush()
    end,
  })
  vim.api.nvim_create_autocmd("DirChanged", {
    group = group,
    callback = function()
      repo_cache = {}
      require("tether.cockpit").refresh()
    end,
  })

  if config.options.prefix then
    keys(config.options.prefix)
  end
  if config.options.follow.enabled then
    require("tether.follow").toggle(true)
  end

  events.start(config.options.log_file)
  return M
end

function M.ensure()
  if not M.did_setup then
    M.setup({})
  end
end

----------------------------------------------------------------------------
-- Actions

function M.cockpit()
  M.ensure()
  return require("tether.cockpit").toggle()
end

---@param scope? string turn|change|checkpoint|since
function M.review(scope, opts)
  M.ensure()
  local repo = need_repo()
  if repo then
    return require("tether.review").open(repo, scope, opts)
  end
end

---@param on? boolean
function M.follow(on)
  M.ensure()
  return require("tether.follow").toggle(on)
end

function M.pick(source)
  M.ensure()
  local repo = need_repo()
  if repo then
    return require("tether.pick").pick(repo, source)
  end
end

function M.send(range)
  M.ensure()
  local repo = need_repo()
  if repo then
    return require("tether.send").send(repo, range)
  end
end

function M.checkpoint()
  M.ensure()
  local repo = need_repo()
  if not repo then
    return
  end
  local ref, err = require("tether.turns").mark(repo)
  local util = require("tether.util")
  if ref then
    util.notify("checkpoint " .. ref:sub(1, 16))
  else
    util.warn(err)
  end
  return ref
end

function M.undo(turn)
  M.ensure()
  local repo = need_repo()
  if not repo then
    return
  end
  local turns = require("tether.turns")
  local util = require("tether.util")
  turn = turn or turns.latest(repo.root)
  if not turn then
    util.warn("no agent turn to undo")
    return
  end
  local paths, err = turns.undo(repo, turn, function(rels)
    local msg = ("Restore %d file%s to their state before turn %d (%s)?\n%s"):format(
      #rels,
      #rels == 1 and "" or "s",
      turn.id,
      turn.agent,
      table.concat(rels, "\n")
    )
    return vim.fn.confirm(msg, "&Restore\n&Cancel", 2) == 1
  end)
  if paths then
    util.notify(("restored %d file%s"):format(#paths, #paths == 1 and "" or "s"))
  elseif err ~= "cancelled" then
    util.warn(err)
  end
  return paths
end

function M.comment(text)
  M.ensure()
  local repo = need_repo()
  if repo then
    require("tether.review").comment_here(repo, text)
  end
end

function M.hunks()
  M.ensure()
  local repo = need_repo()
  if not repo then
    return
  end
  local turns = require("tether.turns")
  local scope, err = turns.scope(repo, "turn", { snapshot = true })
  local files = scope and turns.files(repo, scope)
  if not files then
    require("tether.util").warn(err or "no diff")
    return
  end
  local items = require("tether.review").quickfix(repo, files)
  if #items > 0 then
    vim.cmd("copen")
  end
  return items
end

---Statusline text: follow mode, busy agents, unreviewed hunks.
function M.status()
  if not M.did_setup then
    return ""
  end
  local parts = {}
  local repo = M.repo()
  if repo then
    local busy = 0
    for _, a in ipairs(require("tether.agents").in_root(repo.root)) do
      if a.state == "busy" or a.state == "running" then
        busy = busy + 1
      elseif a.state == "waiting" then
        table.insert(parts, a.agent .. "?")
      end
    end
    if busy > 0 then
      table.insert(parts, busy .. " busy")
    end
    local last = require("tether.review").last
    if last.unreviewed and last.unreviewed > 0 then
      table.insert(parts, "Δ" .. last.unreviewed)
    end
  end
  if require("tether.follow").enabled() then
    table.insert(parts, "follow")
  end
  return table.concat(parts, " ")
end

----------------------------------------------------------------------------
-- :Tether

M.commands = {
  cockpit = function()
    M.cockpit()
  end,
  review = function(args)
    M.review(args[1], { workspace = args[2] })
  end,
  follow = function(args)
    local on = args[1] == "on" and true or args[1] == "off" and false or nil
    M.follow(on)
  end,
  pick = function(args)
    M.pick(args[1])
  end,
  send = function(_, cmd)
    M.send(cmd.range > 0 and { cmd.line1, cmd.line2 } or nil)
  end,
  undo = function()
    M.undo()
  end,
  checkpoint = function()
    M.checkpoint()
  end,
  comment = function(args)
    M.comment(#args > 0 and table.concat(args, " ") or nil)
  end,
  hunks = function()
    M.hunks()
  end,
}

M.complete = {
  review = { "turn", "change", "checkpoint", "since", "workspace" },
  follow = { "on", "off" },
  pick = function()
    local repo = M.repo()
    return require("tether.pick").names(repo)
  end,
}

function M.command(cmd)
  local args = vim.split(vim.trim(cmd.args), "%s+", { trimempty = true })
  local name = table.remove(args, 1) or "cockpit"
  local fn = M.commands[name]
  if not fn then
    require("tether.util").warn("unknown subcommand " .. name)
    return
  end
  fn(args, cmd)
end

function M.completion(arglead, cmdline)
  M.ensure()
  local words = vim.split(cmdline, "%s+", { trimempty = true })
  local n = #words - (cmdline:match("%s$") and 0 or 1)
  local candidates
  if n <= 1 then
    candidates = vim.tbl_keys(M.commands)
  else
    local c = M.complete[words[2]]
    candidates = type(c) == "function" and c() or c or {}
  end
  table.sort(candidates)
  return vim.tbl_filter(function(c)
    return c:find(arglead, 1, true) == 1
  end, candidates)
end

return M
