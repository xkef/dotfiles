-- Diagnostics for OpenSpec Markdown: `openspec validate --json` when the
-- CLI exists, built-in checks otherwise.

local api = require("tether.api")
local parse = require("tether.features.sdd.internal.parse")
local root = require("tether.features.sdd.internal.root")

local M = {}

local ns = vim.api.nvim_create_namespace("tether.features.sdd")

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
  local rel = api.util.relative(path, root)
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
  local dir = root.get()
  local path = api.util.normalize(vim.api.nvim_buf_get_name(buf))
  if not dir or not api.util.inside(path, dir) or not path:match("%.md$") then
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
  local cli = api.config().sdd.openspec or "openspec"
  local id, kind = M.item(dir, path)
  if id and vim.fn.executable(cli) == 1 then
    api.util.run({ cli, "validate", id, "--type", kind, "--strict", "--json", "--no-interactive" }, {
      cwd = vim.fs.dirname(dir),
    }, function(res)
      set(M.map_issues(res.stdout, lines) or M.check(lines))
    end)
    return
  end
  local is_spec = path:match("/spec%.md$")
  set(is_spec and M.check(lines) or {})
end

return M
