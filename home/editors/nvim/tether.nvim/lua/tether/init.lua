-- tether.nvim: review, follow, and coordinate CLI agents from Neovim.
--
-- This module is the public facade: setup, the user actions behind
-- :Tether and the keys, status(), turns(), and the extension entry points
-- on() and register, which forward to tether.api. Everything under
-- tether.core and tether.ui is internal.

local config = require("tether.config")

local M = {}

M.did_setup = false

---The extension API (tether.api).
M.api = require("tether.api")
M.on = M.api.on
M.register = M.api.register

---The repository of the current working directory.
---@return tether.Repo?
function M.repo()
  return require("tether.core.vcs").current()
end

---Snapshots of the turns in the current repository, newest first. The
---tables are copies; changing them changes nothing.
---@return tether.Turn[]
function M.turns()
  local repo = M.repo()
  if not repo then
    return {}
  end
  return vim.deepcopy(require("tether.core.turns").list(repo.root))
end

local function need_repo()
  local repo = M.repo()
  if not repo then
    require("tether.core.util").warn("not in a jj or Git repository")
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

-- Features attach after the core. Each exports attach(api) and reset(), and
-- reaches the core only through the api it receives.
M.features = { "tether.features.coord", "tether.features.sdd", "tether.features.attractor" }

local INTERNAL = {
  "tether.core.events",
  "tether.core.bus",
  "tether.core.registry",
  "tether.core.store",
  "tether.core.turns",
  "tether.core.agents",
  "tether.core.vcs",
  "tether.ui.review",
  "tether.ui.follow",
  "tether.ui.cockpit",
}

---Resets all state. Used by tests.
function M._reset()
  for _, name in ipairs(INTERNAL) do
    local ok, mod = pcall(require, name)
    if ok and mod.reset then
      mod.reset()
    end
  end
  for _, name in ipairs(M.features) do
    local mod = package.loaded[name]
    if mod and mod.reset then
      mod.reset()
    end
  end
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

  local events = require("tether.core.events")
  local turns = require("tether.core.turns")
  events.subscribe(turns.on_event)
  events.subscribe(function(ev)
    require("tether.ui.follow").on_event(ev, M.repo())
  end)
  events.subscribe(require("tether.ui.cockpit").on_event)

  require("tether.ui.pick").builtin()
  require("tether.ui.cockpit").builtin()
  for _, name in ipairs(M.features) do
    local ok, mod = pcall(require, name)
    if not ok then
      require("tether.core.util").warn("feature " .. name .. " failed to load: " .. tostring(mod))
    elseif mod.attach then
      mod.attach(M.api)
    end
  end

  local group = vim.api.nvim_create_augroup("tether", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = highlights })
  vim.api.nvim_create_autocmd("ModeChanged", {
    group = group,
    pattern = "*:n",
    callback = function()
      require("tether.ui.follow").flush()
    end,
  })
  vim.api.nvim_create_autocmd("DirChanged", {
    group = group,
    callback = function()
      require("tether.core.vcs").reset()
      require("tether.ui.cockpit").refresh()
    end,
  })

  if config.options.prefix then
    keys(config.options.prefix)
  end
  if config.options.follow.enabled then
    require("tether.ui.follow").toggle(true)
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
  return require("tether.ui.cockpit").toggle()
end

---@param scope? string turn|change|checkpoint|since
function M.review(scope, opts)
  M.ensure()
  local repo = need_repo()
  if repo then
    return require("tether.ui.review").open(repo, scope, opts)
  end
end

---@param on? boolean
function M.follow(on)
  M.ensure()
  return require("tether.ui.follow").toggle(on)
end

function M.pick(source)
  M.ensure()
  local repo = need_repo()
  if repo then
    return require("tether.ui.pick").pick(repo, source)
  end
end

function M.send(range)
  M.ensure()
  local repo = need_repo()
  if repo then
    return require("tether.ui.send").send(repo, range)
  end
end

function M.checkpoint()
  M.ensure()
  local repo = need_repo()
  if not repo then
    return
  end
  local ref, err = require("tether.core.turns").mark(repo)
  local util = require("tether.core.util")
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
  local turns = require("tether.core.turns")
  local util = require("tether.core.util")
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
    require("tether.ui.review").comment_here(repo, text)
  end
end

function M.hunks()
  M.ensure()
  local repo = need_repo()
  if not repo then
    return
  end
  local turns = require("tether.core.turns")
  local scope, err = turns.scope(repo, "turn", { snapshot = true })
  local files = scope and turns.files(repo, scope)
  if not files then
    require("tether.core.util").warn(err or "no diff")
    return
  end
  local items = require("tether.ui.review").quickfix(repo, files)
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
    for _, a in ipairs(require("tether.core.agents").in_root(repo.root)) do
      if a.state == "busy" or a.state == "running" then
        busy = busy + 1
      elseif a.state == "waiting" then
        table.insert(parts, a.agent .. "?")
      end
    end
    if busy > 0 then
      table.insert(parts, busy .. " busy")
    end
    local last = require("tether.core.store").last
    if last.unreviewed and last.unreviewed > 0 then
      table.insert(parts, "Δ" .. last.unreviewed)
    end
  end
  if require("tether.ui.follow").enabled() then
    table.insert(parts, "follow")
  end
  return table.concat(parts, " ")
end

----------------------------------------------------------------------------
-- :Tether

local commands = {
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

local complete = {
  review = { "turn", "change", "checkpoint", "since", "workspace" },
  follow = { "on", "off" },
  pick = function()
    local repo = M.repo()
    return require("tether.ui.pick").names(repo)
  end,
}

---Runs `:Tether {cmd.args}`: a built-in subcommand or one a feature
---registered.
function M.command(cmd)
  local args = vim.split(vim.trim(cmd.args), "%s+", { trimempty = true })
  local name = table.remove(args, 1) or "cockpit"
  local fn = commands[name]
  if not fn then
    local spec = require("tether.core.registry").commands()[name]
    fn = spec and spec.run
  end
  if not fn then
    require("tether.core.util").warn("unknown subcommand " .. name)
    return
  end
  fn(args, cmd)
end

function M.completion(arglead, cmdline)
  M.ensure()
  local words = vim.split(cmdline, "%s+", { trimempty = true })
  local n = #words - (cmdline:match("%s$") and 0 or 1)
  local candidates
  local registered = require("tether.core.registry").commands()
  if n <= 1 then
    candidates = vim.list_extend(vim.tbl_keys(commands), vim.tbl_keys(registered))
  else
    local c = complete[words[2]] or (registered[words[2]] or {}).complete
    candidates = type(c) == "function" and c(vim.list_slice(words, 3)) or c or {}
  end
  table.sort(candidates)
  return vim.tbl_filter(function(c)
    return c:find(arglead, 1, true) == 1
  end, candidates)
end

return M
