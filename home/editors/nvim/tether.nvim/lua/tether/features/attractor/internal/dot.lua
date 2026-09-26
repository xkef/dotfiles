-- Parser for the DOT subset StrongDM Attractor uses for pipelines
-- (attractor-spec.md, section 2): one digraph with graph attributes, node
-- and edge defaults scoped by subgraphs, node statements, and chained
-- edges. Records line numbers for diagnostics and navigation.

local M = {}

-- Shape to handler type, attractor-spec.md section 2.8.
M.SHAPES = {
  Mdiamond = "start",
  Msquare = "exit",
  box = "codergen",
  hexagon = "wait.human",
  diamond = "conditional",
  component = "parallel",
  tripleoctagon = "parallel.fan_in",
  parallelogram = "tool",
  house = "stack.manager_loop",
  -- Fabro extensions.
  tab = "prompt",
  insulator = "wait",
}

---@class tether.dot.Token
---@field kind "id"|"string"|"op"
---@field value string
---@field line integer

local function unescape(s)
  return (s:gsub("\\(.)", { n = "\n", t = "\t", ['"'] = '"', ["\\"] = "\\" }))
end

---@return tether.dot.Token[]?, string? err, integer? line
function M.tokenize(text)
  local tokens = {}
  local i, line, n = 1, 1, #text
  while i <= n do
    local c = text:sub(i, i)
    if c == "\n" then
      line = line + 1
      i = i + 1
    elseif c:match("%s") then
      i = i + 1
    elseif text:sub(i, i + 1) == "//" or (c == "#" and (i == 1 or text:sub(i - 1, i - 1) == "\n")) then
      local e = text:find("\n", i, true) or n + 1
      i = e
    elseif text:sub(i, i + 1) == "/*" then
      local e = text:find("*/", i + 2, true)
      if not e then
        return nil, "unterminated comment", line
      end
      local _, nl = text:sub(i, e):gsub("\n", "")
      line = line + nl
      i = e + 2
    elseif c == '"' then
      local j = i + 1
      local buf = {}
      local start = line
      while j <= n do
        local d = text:sub(j, j)
        if d == "\\" then
          table.insert(buf, text:sub(j, j + 1))
          j = j + 2
        elseif d == '"' then
          break
        else
          if d == "\n" then
            line = line + 1
          end
          table.insert(buf, d)
          j = j + 1
        end
      end
      if j > n then
        return nil, "unterminated string", start
      end
      table.insert(tokens, { kind = "string", value = unescape(table.concat(buf)), line = start })
      i = j + 1
    elseif text:sub(i, i + 1) == "->" or text:sub(i, i + 1) == "--" then
      table.insert(tokens, { kind = "op", value = text:sub(i, i + 1), line = line })
      i = i + 2
    elseif c:match("[%[%]{}=,;]") then
      table.insert(tokens, { kind = "op", value = c, line = line })
      i = i + 1
    else
      local word = text:match("^[%w_%.:%-]+", i)
      if not word then
        return nil, ("unexpected character %q"):format(c), line
      end
      table.insert(tokens, { kind = "id", value = word, line = line })
      i = i + #word
    end
  end
  return tokens
end

---@class tether.dot.Node
---@field id string
---@field line integer first definition, or first mention for implicit nodes
---@field implicit boolean only mentioned in edges
---@field attrs table<string, string>
---@field classes string[]
---@field handler string

---@class tether.dot.Edge
---@field from string
---@field to string
---@field line integer
---@field attrs table<string, string>

---@class tether.dot.Graph
---@field name? string
---@field line integer
---@field attrs table<string, string>
---@field nodes table<string, tether.dot.Node>
---@field order string[] node ids in definition order
---@field edges tether.dot.Edge[]
---@field errors {line: integer, message: string}[]

local function class_of(label)
  return (label:lower():gsub("%s+", "-"):gsub("[^%w%-]", ""))
end

function M.handler(node)
  local t = node.attrs.type
  if t and t ~= "" then
    return t
  end
  return M.SHAPES[node.attrs.shape or "box"] or "codergen"
end

---@return tether.dot.Graph
function M.parse(text)
  local graph = { attrs = {}, nodes = {}, order = {}, edges = {}, errors = {}, line = 1 }
  local tokens, err, eline = M.tokenize(text)
  if not tokens then
    table.insert(graph.errors, { line = eline or 1, message = err })
    return graph
  end
  local pos = 1
  local function peek(o)
    return tokens[pos + (o or 0)]
  end
  local function next_token()
    local t = tokens[pos]
    pos = pos + 1
    return t
  end
  local function is(t, value)
    return t and t.kind == "op" and t.value == value
  end
  local function fail(msg, t)
    error({ line = t and t.line or (tokens[#tokens] and tokens[#tokens].line) or 1, message = msg }, 0)
  end

  local function attr_block()
    local attrs = {}
    next_token() -- [
    while true do
      local t = next_token()
      if not t then
        fail("unterminated attribute list")
      end
      if is(t, "]") then
        break
      end
      if not is(t, ",") and not is(t, ";") then
        if t.kind == "op" then
          fail("expected an attribute name", t)
        end
        local eq = next_token()
        if not is(eq, "=") then
          fail("expected = after " .. t.value, eq or t)
        end
        local v = next_token()
        if not v or v.kind == "op" then
          fail("expected a value for " .. t.value, v or eq)
        end
        attrs[t.value] = v.value
      end
    end
    return attrs
  end

  local function ensure(id, line, defaults, classes, implicit)
    local node = graph.nodes[id]
    if not node then
      node =
        { id = id, line = line, implicit = implicit, attrs = vim.deepcopy(defaults), classes = vim.deepcopy(classes) }
      graph.nodes[id] = node
      table.insert(graph.order, id)
    elseif node.implicit and not implicit then
      node.implicit = false
      node.line = line
    end
    return node
  end

  local statements

  local function statement(scope)
    local t = peek()
    if is(t, ";") then
      next_token()
      return
    end
    if t.kind == "op" then
      fail("unexpected " .. t.value, t)
    end
    local word = t.value
    if (word == "graph" or word == "node" or word == "edge") and is(peek(1), "[") then
      next_token()
      local attrs = attr_block()
      local target = word == "graph" and (scope.top and graph.attrs or scope.attrs)
        or word == "node" and scope.node
        or scope.edge
      for k, v in pairs(attrs) do
        target[k] = v
      end
      return
    end
    if word == "subgraph" then
      next_token()
      if peek() and peek().kind ~= "op" then
        next_token()
      end
      if not is(next_token(), "{") then
        fail("expected { after subgraph", t)
      end
      local inner = {
        node = vim.deepcopy(scope.node),
        edge = vim.deepcopy(scope.edge),
        classes = vim.deepcopy(scope.classes),
        attrs = {},
      }
      statements(inner, "}")
      return
    end
    next_token()
    if is(peek(), "=") then
      next_token()
      local v = next_token()
      if not v or v.kind == "op" then
        fail("expected a value for " .. word, t)
      end
      if scope.top then
        graph.attrs[word] = v.value
      else
        scope.attrs[word] = v.value
        if word == "label" then
          table.insert(scope.classes, class_of(v.value))
        end
      end
      return
    end
    local chain = { t }
    while is(peek(), "->") or is(peek(), "--") do
      local op = next_token()
      if op.value == "--" then
        fail("undirected edges (--) are not allowed", op)
      end
      local target = next_token()
      if not target or target.kind == "op" then
        fail("expected a node after ->", op)
      end
      table.insert(chain, target)
    end
    local attrs = is(peek(), "[") and attr_block() or {}
    if #chain == 1 then
      local node = ensure(word, t.line, scope.node, scope.classes, false)
      for k, v in pairs(attrs) do
        node.attrs[k] = v
      end
      return
    end
    for _, c in ipairs(chain) do
      ensure(c.value, c.line, scope.node, scope.classes, true)
    end
    for i = 1, #chain - 1 do
      local e = vim.deepcopy(scope.edge)
      for k, v in pairs(attrs) do
        e[k] = v
      end
      table.insert(graph.edges, { from = chain[i].value, to = chain[i + 1].value, line = chain[i].line, attrs = e })
    end
  end

  function statements(scope, closer)
    while true do
      local t = peek()
      if not t then
        fail("missing " .. closer)
      end
      if is(t, closer) then
        next_token()
        return
      end
      statement(scope)
    end
  end

  local ok, perr = pcall(function()
    local t = next_token()
    if t and t.value == "strict" then
      fail("strict graphs are not allowed", t)
    end
    if not t or t.value ~= "digraph" then
      fail("expected digraph", t)
    end
    graph.line = t.line
    if peek() and peek().kind ~= "op" then
      graph.name = next_token().value
    end
    if not is(next_token(), "{") then
      fail("expected {", t)
    end
    statements({ top = true, node = {}, edge = {}, classes = {}, attrs = graph.attrs }, "}")
    if peek() then
      fail("only one graph per file", peek())
    end
  end)
  if not ok then
    if type(perr) == "table" then
      table.insert(graph.errors, perr)
    else
      table.insert(graph.errors, { line = 1, message = tostring(perr) })
    end
  end
  for _, node in pairs(graph.nodes) do
    if node.attrs.class then
      for c in node.attrs.class:gmatch("[^,%s]+") do
        table.insert(node.classes, c)
      end
    end
    node.handler = M.handler(node)
  end
  return graph
end

function M.is_start(node)
  return node.attrs.shape == "Mdiamond" or node.id == "start" or node.id == "Start"
end

function M.is_exit(node)
  return node.attrs.shape == "Msquare" or node.id == "exit" or node.id == "end"
end

---Node ids in breadth-first order from the start node, then unreachable
---ones in definition order. With follow_retries, retry targets count as
---edges too, since failures route there.
function M.bfs(graph, follow_retries)
  local start
  for _, id in ipairs(graph.order) do
    if M.is_start(graph.nodes[id]) then
      start = id
      break
    end
  end
  local out, seen = {}, {}
  local adj = {}
  for _, e in ipairs(graph.edges) do
    adj[e.from] = adj[e.from] or {}
    table.insert(adj[e.from], e.to)
  end
  if follow_retries then
    local function link(from, to)
      if to and graph.nodes[to] then
        adj[from] = adj[from] or {}
        table.insert(adj[from], to)
      end
    end
    for _, id in ipairs(graph.order) do
      local a = graph.nodes[id].attrs
      link(id, a.retry_target)
      link(id, a.fallback_retry_target)
      if a.goal_gate == "true" then
        -- A goal gate sends the run back from the exit node.
        for _, xid in ipairs(graph.order) do
          if M.is_exit(graph.nodes[xid]) then
            link(xid, a.retry_target or graph.attrs.retry_target)
          end
        end
      end
    end
  end
  local queue = { start }
  if start then
    seen[start] = true
  end
  local reached = {}
  while #queue > 0 do
    local id = table.remove(queue, 1)
    table.insert(out, id)
    reached[id] = true
    for _, to in ipairs(adj[id] or {}) do
      if not seen[to] then
        seen[to] = true
        table.insert(queue, to)
      end
    end
  end
  local unreachable = {}
  for _, id in ipairs(graph.order) do
    if not reached[id] then
      table.insert(out, id)
      table.insert(unreachable, id)
    end
  end
  return out, unreachable, start
end

return M
