-- Spec-driven development with OpenSpec: diagnostics, navigation, the task
-- board, and links from agent turns to the changes they worked on. Stays
-- out of the way in projects without an openspec/ directory.

local config = require("tether.config")
local parse = require("tether.sdd.parse")
local util = require("tether.util")

local M = {}

local ns = vim.api.nvim_create_namespace("tether.sdd")

local S

function M.reset()
  S = { roots = {}, attributed = {} }
  parse.reset()
end
M.reset()

---The openspec/ directory for the working directory: in it, in one of its
---parents, or at the repository root.
---@return string?
function M.root()
  local cwd = vim.fn.getcwd()
  if S.roots[cwd] == nil then
    local found = vim.fs.find("openspec", { upward = true, type = "directory", path = cwd, limit = 1 })[1]
    if not found then
      local repo = require("tether").repo()
      local at_root = repo and vim.fs.joinpath(repo.root, "openspec")
      if at_root and vim.fn.isdirectory(at_root) == 1 then
        found = at_root
      end
    end
    S.roots[cwd] = found and util.normalize(found) or false
  end
  return S.roots[cwd] or nil
end

function M.active()
  return M.root() ~= nil
end

----------------------------------------------------------------------------
-- Diagnostics

local function severity(level)
  level = (level or ""):upper()
  if level == "ERROR" then
    return vim.diagnostic.severity.ERROR
  elseif level == "WARNING" then
    return vim.diagnostic.severity.WARN
  end
  return vim.diagnostic.severity.INFO
end

---Built-in checks for a spec or delta spec.
function M.check(lines)
  local spec = parse.spec_lines(lines)
  local out = {}
  for _, req in ipairs(spec.requirements) do
    if req.op ~= "REMOVED" and req.op ~= "RENAMED" then
      if #req.scenarios == 0 then
        table.insert(out, {
          lnum = req.line - 1,
          col = 0,
          severity = vim.diagnostic.severity.ERROR,
          message = ("Requirement %q has no scenario (#### Scenario:)"):format(req.name),
        })
      end
      if not req.normative then
        table.insert(out, {
          lnum = req.line - 1,
          col = 0,
          severity = vim.diagnostic.severity.WARN,
          message = ("Requirement %q should state SHALL or MUST"):format(req.name),
        })
      end
    end
  end
  for _, l in ipairs(spec.bad_scenarios) do
    table.insert(out, {
      lnum = l - 1,
      col = 0,
      severity = vim.diagnostic.severity.ERROR,
      message = "Scenarios need four hashes: #### Scenario:",
    })
  end
  return out
end

---What `openspec validate` calls the item a file belongs to.
function M.item(root, path)
  local rel = util.relative(path, root)
  local change = rel:match("^changes/([^/]+)/")
  if change and change ~= "archive" then
    return change, "change"
  end
  local cap = rel:match("^specs/(.+)/spec%.md$")
  if cap then
    return cap, "spec"
  end
end

---Maps `openspec validate --json` issues to diagnostics. Requirement
---indexes in issue paths count the ### headings of requirement sections.
function M.map_issues(json, lines)
  local ok, data = pcall(vim.json.decode, json)
  if not ok or type(data) ~= "table" then
    return nil
  end
  local spec = parse.spec_lines(lines)
  local out, seen = {}, {}
  for _, item in ipairs(data.items or {}) do
    for _, issue in ipairs(item.issues or {}) do
      local idx = (issue.path or ""):match("^requirements[%.%[](%d+)")
      local line = idx and spec.headings[tonumber(idx) + 1] or 1
      local msg = (issue.message or ""):gsub("\n.*", "")
      local key = line .. msg
      if not seen[key] then
        seen[key] = true
        table.insert(out, { lnum = line - 1, col = 0, severity = severity(issue.level), message = msg })
      end
    end
  end
  return out
end

function M.diagnose(buf, done)
  local root = M.root()
  local path = util.normalize(vim.api.nvim_buf_get_name(buf))
  if not root or not util.inside(path, root) or not path:match("%.md$") then
    return
  end
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local function set(diags)
    if vim.api.nvim_buf_is_valid(buf) then
      vim.diagnostic.set(ns, buf, diags, { source = "openspec" })
    end
    if done then
      done(diags)
    end
  end
  local cli = config.options.sdd.openspec or "openspec"
  local id, kind = M.item(root, path)
  if id and vim.fn.executable(cli) == 1 then
    util.run({ cli, "validate", id, "--type", kind, "--strict", "--json", "--no-interactive" }, {
      cwd = vim.fs.dirname(root),
    }, function(res)
      set(M.map_issues(res.stdout, lines) or M.check(lines))
    end)
    return
  end
  local is_spec = path:match("/spec%.md$")
  set(is_spec and M.check(lines) or {})
end

----------------------------------------------------------------------------
-- Tasks

---Toggles a task's checkbox on disk and in a loaded buffer.
function M.toggle(change, task)
  local path = change.tasks_path
  local lines, buf = util.content(path)
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
    config.options.sdd.send_template:gsub("{(%w+)}", {
      change = change.id,
      id = task.id,
      text = task.text,
    })
  )
end

----------------------------------------------------------------------------
-- Traceability

---Changes a turn touched and the tasks it checked, from the turn's files.
---@param files tether.File[]
---@return {change: string, checked: string[]}[]
function M.trace(repo, files)
  local root = M.root()
  if not root or not util.inside(root, repo.root) then
    return {}
  end
  local prefix = util.relative(root, repo.root)
  prefix = prefix == repo.root and "" or (prefix .. "/")
  local by = {}
  local order = {}
  for _, f in ipairs(files) do
    local id, rest = f.path:match("^" .. vim.pesc(prefix) .. "changes/([^/]+)/(.*)$")
    if id and id ~= "archive" then
      if not by[id] then
        by[id] = { change = id, checked = {} }
        table.insert(order, id)
      end
      if rest == "tasks.md" then
        local before = {}
        for _, h in ipairs(f.hunks) do
          for _, l in ipairs(h.lines) do
            local tid = l:match("^%-%s*%- %[[xX]%]%s+(%d[%d%.]*)")
            if tid then
              before[tid:gsub("%.$", "")] = true
            end
          end
        end
        for _, h in ipairs(f.hunks) do
          for _, l in ipairs(h.lines) do
            local tid = l:match("^%+%s*%- %[[xX]%]%s+(%d[%d%.]*)")
            if tid then
              tid = tid:gsub("%.$", "")
              if not before[tid] then
                table.insert(by[id].checked, tid)
              end
            end
          end
        end
      end
    end
  end
  local out = {}
  for _, id in ipairs(order) do
    table.insert(out, by[id])
  end
  return out
end

---Records which agent checked which task, from a turn's files.
function M.attribute(repo, turn, files)
  for _, tr in ipairs(M.trace(repo, files)) do
    for _, tid in ipairs(tr.checked) do
      S.attributed[tr.change .. "\0" .. tid] = { agent = turn.agent, turn = turn.id }
    end
  end
end

function M.attributed(change_id, task_id)
  return S.attributed[change_id .. "\0" .. task_id]
end

----------------------------------------------------------------------------
-- Integration

local function send_task(change, task)
  local repo = require("tether").repo()
  if repo then
    require("tether.send").text(repo.root, M.task_message(change, task))
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
          require("tether.pick").open_file(change.tasks_path, task.line)
        end,
        x = function()
          M.toggle(change, task)
          require("tether.cockpit").render()
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
          require("tether.pick").open_file(change.tasks_path, 1)
        end,
      },
    })
  end
  return rows
end

local function enabled()
  return M.active()
end

local function register_sources()
  local pick = require("tether.pick")
  pick.register({
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
  pick.register({
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
  pick.register({
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

function M.attach()
  register_sources()

  require("tether.cockpit").register({
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

  table.insert(require("tether.review").header_providers, function(repo, scope, files)
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

  vim.api.nvim_create_autocmd("User", {
    group = vim.api.nvim_create_augroup("tether.sdd", { clear = true }),
    pattern = "TetherTurnStop",
    callback = function(args)
      local repo = require("tether").repo()
      if repo and M.active() then
        M.attribute(repo, args.data.turn, args.data.files)
      end
    end,
  })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = "tether.sdd",
    pattern = "*.md",
    callback = function(args)
      if M.active() then
        M.diagnose(args.buf)
      end
    end,
  })
  vim.api.nvim_create_autocmd("DirChanged", {
    group = "tether.sdd",
    callback = function()
      S.roots = {}
    end,
  })
end

return M
