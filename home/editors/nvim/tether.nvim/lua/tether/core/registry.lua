-- Contributions from features to the UI: picker sources, cockpit sections,
-- review header lines, agent row fields and actions, and subcommands. The
-- UI reads from here, so it never requires a feature.

local M = {}

local R

function M.reset()
  R = {
    sources = {},
    source_order = {},
    sections = {},
    review_headers = {},
    agent_fields = {},
    agent_actions = {},
    commands = {},
  }
end
M.reset()

---@param source tether.Source
function M.source(source)
  if not R.sources[source.name] then
    table.insert(R.source_order, source.name)
  end
  R.sources[source.name] = source
end

function M.unsource(name)
  R.sources[name] = nil
  R.source_order = vim.tbl_filter(function(n)
    return n ~= name
  end, R.source_order)
end

function M.sources()
  local out = {}
  for _, name in ipairs(R.source_order) do
    table.insert(out, R.sources[name])
  end
  return out
end

function M.get_source(name)
  return R.sources[name]
end

---@param section tether.Section
function M.section(section)
  R.sections = vim.tbl_filter(function(s)
    return s.name ~= section.name
  end, R.sections)
  table.insert(R.sections, section)
  table.sort(R.sections, function(a, b)
    return a.order < b.order
  end)
end

function M.unsection(name)
  R.sections = vim.tbl_filter(function(s)
    return s.name ~= name
  end, R.sections)
end

function M.sections()
  return R.sections
end

function M.review_header(fn)
  table.insert(R.review_headers, fn)
end

function M.review_headers()
  return R.review_headers
end

function M.agent_field(fn)
  table.insert(R.agent_fields, fn)
end

function M.agent_fields()
  return R.agent_fields
end

function M.agent_action(fn)
  table.insert(R.agent_actions, fn)
end

function M.agent_actions()
  return R.agent_actions
end

---@param name string
---@param spec {run: fun(args: string[], cmd: table), complete?: string[]|fun(args: string[]): string[]}
function M.command(name, spec)
  R.commands[name] = spec
end

function M.commands()
  return R.commands
end

return M
