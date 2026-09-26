-- Spec-driven development with OpenSpec: diagnostics, navigation, the task
-- board, and links from agent turns to the changes they worked on. Stays
-- out of the way in projects without an openspec/ directory.

local api = require("tether.api")
local diagnose = require("tether.features.sdd.internal.diagnose")
local parse = require("tether.features.sdd.internal.parse")
local root = require("tether.features.sdd.internal.root")
local trace = require("tether.features.sdd.internal.trace")

local M = {}

function M.reset()
  root.reset()
  trace.reset()
  parse.reset()
end

M.root = root.get
M.check = diagnose.check
M.diagnose = diagnose.diagnose
M.trace = trace.trace
M.attribute = trace.attribute
M.attributed = trace.attributed

function M.active()
  return M.root() ~= nil
end

----------------------------------------------------------------------------
-- Tasks

---Toggles a task's checkbox on disk and in a loaded buffer.
function M.toggle(change, task)
  local path = change.tasks_path
  local lines, buf = api.util.content(path)
  if not lines or not lines[task.line] then
    return false
  end
  local line = lines[task.line]
  local new = line:gsub("^(%s*%- %[)([ xX])(%])", function(a, mark, b)
    return a .. (mark == " " and "x" or " ") .. b
  end, 1)
  if buf then
    vim.api.nvim_buf_set_lines(buf, task.line - 1, task.line, false, { new })
    vim.api.nvim_buf_call(buf, function()
      vim.cmd("silent noautocmd write")
    end)
  else
    lines[task.line] = new
    vim.fn.writefile(lines, path)
  end
  return true
end

function M.task_message(change, task)
  return (
    api.config().sdd.send_template:gsub("{(%w+)}", {
      change = change.id,
      id = task.id,
      text = task.text,
    })
  )
end

----------------------------------------------------------------------------
-- Integration

local function send_task(change, task)
  local repo = api.repo()
  if repo then
    api.ui.send(repo.root, M.task_message(change, task))
  end
end

local function task_rows(change)
  local rows = {}
  for _, task in ipairs(change.tasks) do
    local by = M.attributed(change.id, task.id)
    table.insert(rows, {
      text = ("[%s] %s %s%s"):format(task.done and "x" or " ", task.id, task.text, by and ("  ← " .. by.agent) or ""),
      hl = task.done and "TetherDim" or nil,
      actions = {
        ["<CR>"] = function()
          api.ui.open_file(change.tasks_path, task.line)
        end,
        x = function()
          M.toggle(change, task)
          api.ui.refresh()
        end,
        s = function()
          send_task(change, task)
        end,
      },
    })
  end
  return rows
end

function M.section_rows()
  local root = M.root()
  if not root then
    return {}
  end
  local rows = {}
  for _, change in ipairs(parse.changes(root)) do
    local done = 0
    for _, t in ipairs(change.tasks) do
      if t.done then
        done = done + 1
      end
    end
    table.insert(rows, {
      text = ("%s  %d/%d"):format(change.id, done, #change.tasks),
      id = "sdd:" .. change.id,
      hl = (#change.tasks > 0 and done == #change.tasks) and "TetherReviewed" or nil,
      children = task_rows(change),
      actions = {
        ["<CR>"] = function()
          api.ui.open_file(change.tasks_path, 1)
        end,
      },
    })
  end
  return rows
end

local function enabled()
  return M.active()
end

local function register_sources(register)
  register.source({
    name = "specs",
    desc = "OpenSpec capabilities",
    enabled = enabled,
    items = function()
      local items = {}
      for _, s in ipairs(parse.specs(M.root())) do
        table.insert(items, {
          text = ("%s  %d requirements"):format(s.capability, #s.spec.requirements),
          file = s.path,
          lnum = 1,
        })
      end
      return items
    end,
  })
  register.source({
    name = "requirements",
    desc = "OpenSpec requirements",
    enabled = enabled,
    items = function()
      local items = {}
      for _, s in ipairs(parse.specs(M.root())) do
        for _, req in ipairs(s.spec.requirements) do
          table.insert(items, {
            text = ("%s: %s  (%d scenarios)"):format(s.capability, req.name, #req.scenarios),
            file = s.path,
            lnum = req.line,
          })
        end
      end
      return items
    end,
  })
  register.source({
    name = "changes",
    desc = "OpenSpec changes in progress",
    enabled = enabled,
    items = function()
      local items = {}
      for _, c in ipairs(parse.changes(M.root())) do
        local done = #vim.tbl_filter(function(t)
          return t.done
        end, c.tasks)
        table.insert(items, {
          text = ("%s  %d/%d  %s"):format(c.id, done, #c.tasks, c.why or ""),
          file = c.proposal,
          lnum = 1,
        })
      end
      return items
    end,
  })
end

---@param tether_api table tether.api
function M.attach(tether_api)
  register_sources(tether_api.register)

  tether_api.register.section({
    name = "Tasks",
    order = 30,
    summary = function()
      local n = #parse.changes(M.root())
      return n > 0 and (n .. (n == 1 and " change" or " changes")) or nil
    end,
    rows = function()
      return M.section_rows()
    end,
  })

  tether_api.register.review_header(function(repo, scope, files)
    if not M.active() then
      return nil
    end
    local out = {}
    for _, tr in ipairs(M.trace(repo, files)) do
      if scope.turn then
        M.attribute(repo, scope.turn, files)
      end
      local line = "Change: " .. tr.change
      if #tr.checked > 0 then
        line = line .. " · checked " .. table.concat(tr.checked, ", ")
      end
      table.insert(out, line)
    end
    return out
  end)

  tether_api.on("stop", function(data)
    local repo = tether_api.repo()
    if repo and M.active() then
      M.attribute(repo, data.turn, data.files)
    end
  end)
  vim.api.nvim_create_augroup("tether.features.sdd", { clear = true })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = "tether.features.sdd",
    pattern = "*.md",
    callback = function(args)
      if M.active() then
        M.diagnose(args.buf)
      end
    end,
  })
  vim.api.nvim_create_autocmd("DirChanged", {
    group = "tether.features.sdd",
    callback = root.reset,
  })
end

return M
