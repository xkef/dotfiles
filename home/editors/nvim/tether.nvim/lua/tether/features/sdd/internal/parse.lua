-- Line-based parser for OpenSpec 1.x trees: specs, changes, tasks, and
-- delta specs. It needs no OpenSpec CLI.

local api = require("tether.api")

local M = {}

local cache = {}

local function cached(path, fn)
  local stat = vim.uv.fs_stat(path)
  if not stat then
    return nil
  end
  local key = stat.mtime.sec .. ":" .. stat.mtime.nsec .. ":" .. stat.size
  local hit = cache[path]
  if hit and hit.key == key then
    return hit.value
  end
  local value = fn(api.util.read_lines(path) or {})
  cache[path] = { key = key, value = value }
  return value
end

function M.reset()
  cache = {}
end

---@class tether.sdd.Requirement
---@field name string
---@field line integer
---@field text string[]
---@field normative boolean text holds SHALL or MUST
---@field scenarios {name: string, line: integer}[]
---@field op? string ADDED, MODIFIED, REMOVED, or RENAMED in delta specs

---@class tether.sdd.Spec
---@field path string
---@field purpose? string
---@field requirements tether.sdd.Requirement[]
---@field headings integer[] lines of every ### heading in requirement sections
---@field bad_scenarios integer[] lines of scenarios with three hashes

---Parses a spec or delta spec from lines.
---@return tether.sdd.Spec
function M.spec_lines(lines)
  local spec = { requirements = {}, headings = {}, bad_scenarios = {} }
  local section, req, in_purpose
  local purpose = {}
  for i, line in ipairs(lines) do
    local h2 = line:match("^##%s+(.-)%s*$")
    if h2 and not line:match("^###") then
      section = h2
      in_purpose = h2 == "Purpose"
      req = nil
      spec.op = nil
    elseif in_purpose then
      if vim.trim(line) ~= "" then
        table.insert(purpose, vim.trim(line))
      end
    end
    local in_reqs = section and (section == "Requirements" or section:match("Requirements$"))
    if in_reqs then
      local h3 = line:match("^###%s+(.-)%s*$")
      if h3 and not line:match("^####") then
        table.insert(spec.headings, i)
        local name = h3:match("^Requirement:%s*(.-)$")
        if name then
          req = {
            name = name,
            line = i,
            text = {},
            normative = false,
            scenarios = {},
            op = section:match("^(%u+) Requirements$"),
          }
          table.insert(spec.requirements, req)
        else
          if h3:match("^Scenario:") then
            table.insert(spec.bad_scenarios, i)
          end
          req = nil
        end
      elseif req then
        local scenario = line:match("^####%s+Scenario:%s*(.-)%s*$")
        if scenario then
          table.insert(req.scenarios, { name = scenario, line = i })
        elseif #req.scenarios == 0 and vim.trim(line) ~= "" then
          table.insert(req.text, line)
          if line:match("SHALL") or line:match("MUST") then
            req.normative = true
          end
        end
      end
    end
  end
  spec.purpose = #purpose > 0 and table.concat(purpose, " ") or nil
  return spec
end

---@return tether.sdd.Spec?
function M.spec(path)
  local spec = cached(path, M.spec_lines)
  if spec then
    spec.path = path
  end
  return spec
end

---@class tether.sdd.Task
---@field id string
---@field text string
---@field done boolean
---@field line integer
---@field group? string

---@return tether.sdd.Task[]
function M.tasks_lines(lines)
  local tasks, group = {}, nil
  for i, line in ipairs(lines) do
    local g = line:match("^##%s+(.-)%s*$")
    if g then
      group = g
    end
    local mark, rest = line:match("^%s*%- %[([ xX])%]%s+(.*)$")
    if mark then
      local id, text = rest:match("^(%d[%d%.]*)%s+(.*)$")
      table.insert(tasks, {
        id = id and id:gsub("%.$", "") or tostring(#tasks + 1),
        text = text or rest,
        done = mark ~= " ",
        line = i,
        group = group,
      })
    elseif #tasks > 0 and line:match("^%s+%S") and tasks[#tasks].line == i - 1 then
      -- Continuation line of a wrapped task.
      local t = tasks[#tasks]
      t.text = t.text .. " " .. vim.trim(line)
      t.line_end = i
    end
  end
  return tasks
end

function M.tasks(path)
  return cached(path, M.tasks_lines) or {}
end

---@class tether.sdd.Change
---@field id string
---@field dir string
---@field tasks tether.sdd.Task[]
---@field tasks_path string
---@field proposal string
---@field why? string
---@field deltas {capability: string, path: string}[]

local function why(path)
  return cached(path, function(lines)
    local in_why = false
    for _, l in ipairs(lines) do
      if l:match("^##%s+Why") then
        in_why = true
      elseif l:match("^##") then
        in_why = false
      elseif in_why and vim.trim(l) ~= "" then
        return vim.trim(l)
      end
    end
    return false
  end) or nil
end

local function scan(dir, pattern)
  local out = {}
  if vim.fn.isdirectory(dir) == 0 then
    return out
  end
  for name, kind in vim.fs.dir(dir, { depth = 8 }) do
    if kind == "file" and name:match(pattern) then
      table.insert(out, vim.fs.joinpath(dir, name))
    end
  end
  table.sort(out)
  return out
end

---@return tether.sdd.Change
function M.change(dir)
  local id = vim.fs.basename(dir)
  local tasks_path = vim.fs.joinpath(dir, "tasks.md")
  local proposal = vim.fs.joinpath(dir, "proposal.md")
  local deltas = {}
  local specs_dir = vim.fs.joinpath(dir, "specs")
  for _, path in ipairs(scan(specs_dir, "spec%.md$")) do
    table.insert(deltas, { capability = vim.fs.dirname(path):sub(#specs_dir + 2), path = path })
  end
  local w = why(proposal)
  return {
    id = id,
    dir = dir,
    tasks = M.tasks(tasks_path),
    tasks_path = tasks_path,
    proposal = proposal,
    why = w ~= false and w or nil,
    deltas = deltas,
  }
end

---Active changes (not archived), sorted by id.
---@return tether.sdd.Change[]
function M.changes(root)
  local out = {}
  local dir = vim.fs.joinpath(root, "changes")
  if vim.fn.isdirectory(dir) == 0 then
    return out
  end
  for name, kind in vim.fs.dir(dir) do
    if kind == "directory" and name ~= "archive" then
      table.insert(out, M.change(vim.fs.joinpath(dir, name)))
    end
  end
  table.sort(out, function(a, b)
    return a.id < b.id
  end)
  return out
end

---Capability specs, sorted by capability path.
---@return {capability: string, path: string, spec: tether.sdd.Spec}[]
function M.specs(root)
  local out = {}
  local dir = vim.fs.joinpath(root, "specs")
  for _, path in ipairs(scan(dir, "spec%.md$")) do
    table.insert(out, { capability = vim.fs.dirname(path):sub(#dir + 2), path = path, spec = M.spec(path) })
  end
  return out
end

return M
