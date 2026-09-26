-- The condition language of attractor-spec section 10: clauses joined by
-- &&, each `key = literal`, `key != literal`, or a bare key that must be
-- non-empty.

local M = {}

local function literal(s)
  s = vim.trim(s)
  local quoted = s:match('^"(.*)"$')
  return quoted or s
end

---Value of a key against an outcome and context, as a string.
function M.resolve(key, outcome, context)
  key = vim.trim(key)
  if key == "outcome" then
    return outcome.status or ""
  elseif key == "preferred_label" then
    return outcome.preferred_label or ""
  end
  local value = context[key]
  if value == nil and key:match("^context%.") then
    value = context[key:sub(9)]
  end
  return value == nil and "" or tostring(value)
end

function M.clause(clause, outcome, context)
  local key, value = clause:match("^(.-)!=(.*)$")
  if key then
    return M.resolve(key, outcome, context) ~= literal(value)
  end
  key, value = clause:match("^(.-)=(.*)$")
  if key then
    return M.resolve(key, outcome, context) == literal(value)
  end
  return M.resolve(clause, outcome, context) ~= ""
end

---True when every clause holds. An empty condition always holds.
function M.eval(condition, outcome, context)
  if not condition or vim.trim(condition) == "" then
    return true
  end
  for clause in (condition .. "&&"):gmatch("(.-)&&") do
    clause = vim.trim(clause)
    if clause ~= "" and not M.clause(clause, outcome, context) then
      return false
    end
  end
  return true
end

return M
