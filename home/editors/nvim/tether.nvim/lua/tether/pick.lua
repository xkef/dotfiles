-- One picker entry point. Sources produce items; snacks.nvim renders them
-- when it loads, vim.ui.select otherwise.

local diff = require("tether.diff")
local turns = require("tether.turns")
local util = require("tether.util")

local M = {}

---@class tether.PickItem
---@field text string
---@field file? string
---@field lnum? integer
---@field preview? {lines: string[], ft?: string}
---@field action? fun(item: tether.PickItem)

---@class tether.Source
---@field name string
---@field desc string
---@field items fun(repo: tether.Repo): tether.PickItem[]?, string?
---@field enabled? fun(repo: tether.Repo): boolean

---@type table<string, tether.Source>
M.sources = {}
local order = {}

function M.register(source)
  if not M.sources[source.name] then
    table.insert(order, source.name)
  end
  M.sources[source.name] = source
end

function M.unregister(name)
  M.sources[name] = nil
  order = vim.tbl_filter(function(n)
    return n ~= name
  end, order)
end

---Names of sources available for a repository.
function M.names(repo)
  return vim.tbl_filter(function(n)
    local s = M.sources[n]
    return s and (not s.enabled or not repo or s.enabled(repo))
  end, order)
end

function M.open_file(file, lnum)
  local win = vim.api.nvim_get_current_win()
  if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "tether-cockpit" then
    vim.cmd("wincmd p")
    if vim.api.nvim_get_current_win() == win then
      vim.cmd("leftabove vnew")
    end
  end
  vim.cmd("edit " .. vim.fn.fnameescape(file))
  if lnum then
    pcall(vim.api.nvim_win_set_cursor, 0, { lnum, 0 })
    vim.cmd("normal! zz")
  end
end

local function run(item)
  if item.action then
    item.action(item)
  elseif item.file then
    M.open_file(item.file, item.lnum)
  end
end

M.backend = nil -- "snacks" | "select"; nil detects

local function has_snacks()
  local ok, snacks = pcall(require, "snacks")
  return ok and snacks.picker ~= nil
end

function M.show(title, items)
  local backend = M.backend or (has_snacks() and "snacks" or "select")
  if backend == "snacks" then
    local Snacks = require("snacks")
    local list = {}
    for i, it in ipairs(items) do
      list[i] = {
        idx = i,
        text = it.text,
        file = it.file,
        pos = it.lnum and { it.lnum, 0 } or nil,
        tether = it,
      }
    end
    return Snacks.picker.pick({
      title = title,
      items = list,
      format = function(item)
        return { { item.text } }
      end,
      preview = function(ctx)
        local it = ctx.item.tether
        if it.preview then
          ctx.preview:reset()
          ctx.preview:set_lines(it.preview.lines)
          if it.preview.ft then
            ctx.preview:highlight({ ft = it.preview.ft })
          end
          return
        end
        if it.file then
          return Snacks.picker.preview.file(ctx)
        end
        ctx.preview:reset()
        ctx.preview:set_lines({ it.text })
      end,
      confirm = function(picker, item)
        picker:close()
        if item then
          vim.schedule(function()
            run(item.tether)
          end)
        end
      end,
    })
  end
  vim.ui.select(items, {
    prompt = title,
    format_item = function(it)
      return it.text
    end,
  }, function(choice)
    if choice then
      run(choice)
    end
  end)
end

function M.pick(repo, name)
  if not name or name == "" then
    local names = M.names(repo)
    vim.ui.select(names, {
      prompt = "tether",
      format_item = function(n)
        return ("%-13s %s"):format(n, M.sources[n].desc)
      end,
    }, function(choice)
      if choice then
        M.pick(repo, choice)
      end
    end)
    return
  end
  local source = M.sources[name]
  if not source then
    util.warn("unknown source " .. name)
    return
  end
  local items, err = source.items(repo)
  if not items then
    util.warn(err or ("no items in " .. name))
    return
  end
  if #items == 0 then
    util.notify("nothing in " .. name)
    return
  end
  return M.show(source.desc, items)
end

----------------------------------------------------------------------------
-- Built-in sources

local function file_diff_lines(f)
  local lines = { ("diff --git a/%s b/%s"):format(f.old_path, f.path) }
  for _, h in ipairs(f.hunks) do
    table.insert(lines, h.header)
    vim.list_extend(lines, h.lines)
  end
  return lines
end

local function latest_files(repo)
  local scope, err = turns.scope(repo, "turn", { snapshot = true })
  if not scope then
    return nil, err
  end
  local files
  files, err = turns.files(repo, scope)
  return files, err
end

M.register({
  name = "changed",
  desc = "Files of the latest turn",
  items = function(repo)
    local files, err = latest_files(repo)
    if not files then
      return nil, err
    end
    local items = {}
    for _, f in ipairs(files) do
      table.insert(items, {
        text = ("%s %s  +%d -%d"):format(f.status, f.path, f.added, f.removed),
        file = vim.fs.joinpath(repo.root, f.path),
        lnum = f.hunks[1] and diff.first_change(f.hunks[1]) or nil,
        preview = { lines = file_diff_lines(f), ft = "diff" },
      })
    end
    return items
  end,
})

M.register({
  name = "trail",
  desc = "Recent agent edits and reads",
  items = function(repo)
    local items = {}
    for _, ev in ipairs(turns.trail(repo.root, 200)) do
      local rel = util.relative(ev.path, repo.root)
      table.insert(items, {
        text = ("%-4s %-7s %s%s  %s"):format(
          ev.kind,
          ev.agent or "?",
          rel,
          ev.line and (":" .. ev.line) or "",
          util.age(ev.epoch)
        ),
        file = ev.path,
        lnum = ev.line,
      })
    end
    return items
  end,
})

M.register({
  name = "turns",
  desc = "Agent turns",
  items = function(repo)
    local items = {}
    for _, t in ipairs(turns.list(repo.root)) do
      table.insert(items, {
        text = ("#%d %-7s %s%s  %s"):format(
          t.id,
          t.agent,
          t.summary or "",
          turns.running(t) and " (running)" or "",
          util.age(t.started)
        ),
        action = function()
          require("tether.review").open(repo, "turn", { turn = t })
        end,
      })
    end
    return items
  end,
})

M.register({
  name = "hunks",
  desc = "Unreviewed hunks of the latest turn",
  items = function(repo)
    local files, err = latest_files(repo)
    if not files then
      return nil, err
    end
    local review = require("tether.review")
    local items = {}
    for _, f in ipairs(files) do
      for _, h in ipairs(f.hunks) do
        if not review.status_of(repo.root, h.hash) then
          local lnum, text = diff.first_change(h)
          local lines = { h.header }
          vim.list_extend(lines, h.lines)
          table.insert(items, {
            text = ("%s:%d %s"):format(f.path, lnum, vim.trim(text)),
            file = vim.fs.joinpath(repo.root, f.path),
            lnum = lnum,
            preview = { lines = lines, ft = "diff" },
          })
        end
      end
    end
    return items
  end,
})

return M
