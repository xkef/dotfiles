-- Lint rules from attractor-spec.md section 7.2. Edge statements declare
-- their endpoints as nodes, as in Graphviz, so every edge target exists by
-- construction; the rules check the structure around them.

local dot = require("tether.features.attractor.internal.dot")

local M = {}

local ERROR, WARN = vim.diagnostic.severity.ERROR, vim.diagnostic.severity.WARN

M.HANDLERS = {
  start = true,
  exit = true,
  codergen = true,
  ["wait.human"] = true,
  conditional = true,
  parallel = true,
  ["parallel.fan_in"] = true,
  tool = true,
  ["stack.manager_loop"] = true,
  -- Fabro handler names.
  prompt = true,
  wait = true,
  agent = true,
  command = true,
  human = true,
}

M.FIDELITY = {
  full = true,
  truncate = true,
  compact = true,
  ["summary:low"] = true,
  ["summary:medium"] = true,
  ["summary:high"] = true,
}

---@param graph tether.dot.Graph
---@return {rule: string, severity: integer, message: string, line: integer, node?: string}[]
function M.run(graph)
  local out = {}
  local function add(rule, severity, line, message, node)
    table.insert(out, { rule = rule, severity = severity, line = line, message = message, node = node })
  end
  for _, e in ipairs(graph.errors) do
    add("parse", ERROR, e.line, e.message)
  end
  if #graph.errors > 0 then
    return out
  end

  local starts, exits = {}, {}
  for _, id in ipairs(graph.order) do
    local node = graph.nodes[id]
    if dot.is_start(node) then
      table.insert(starts, node)
    end
    if dot.is_exit(node) then
      table.insert(exits, node)
    end
  end
  if #starts ~= 1 then
    add(
      "start_node",
      ERROR,
      #starts > 1 and starts[2].line or graph.line,
      ("pipeline needs exactly one start node (shape=Mdiamond), found %d"):format(#starts)
    )
  end
  if #exits ~= 1 then
    add(
      "terminal_node",
      ERROR,
      #exits > 1 and exits[2].line or graph.line,
      ("pipeline needs exactly one exit node (shape=Msquare), found %d"):format(#exits)
    )
  end

  local incoming, outgoing = {}, {}
  for _, e in ipairs(graph.edges) do
    incoming[e.to] = (incoming[e.to] or 0) + 1
    outgoing[e.from] = (outgoing[e.from] or 0) + 1
    local f = e.attrs.fidelity
    if f and not M.FIDELITY[f] then
      add("fidelity_valid", WARN, e.line, ("unknown fidelity %q on edge %s -> %s"):format(f, e.from, e.to))
    end
  end
  if #starts == 1 then
    local s = starts[1]
    if incoming[s.id] then
      add("start_no_incoming", ERROR, s.line, "start node " .. s.id .. " has incoming edges", s.id)
    end
    local _, unreachable = dot.bfs(graph, true)
    for _, id in ipairs(unreachable) do
      local node = graph.nodes[id]
      add("reachability", ERROR, node.line, id .. " is not reachable from " .. s.id, id)
    end
  end
  for _, x in ipairs(exits) do
    if outgoing[x.id] then
      add("exit_no_outgoing", ERROR, x.line, "exit node " .. x.id .. " has outgoing edges", x.id)
    end
  end

  local function target_exists(line, owner, key, value)
    if value and value ~= "" and not graph.nodes[value] then
      add("retry_target_exists", WARN, line, ("%s %s names missing node %s"):format(owner, key, value), owner)
    end
  end
  for _, key in ipairs({ "retry_target", "fallback_retry_target" }) do
    target_exists(graph.line, "graph", key, graph.attrs[key])
  end
  local gf = graph.attrs.default_fidelity
  if gf and gf ~= "" and not M.FIDELITY[gf] then
    add("fidelity_valid", WARN, graph.line, ("unknown default_fidelity %q"):format(gf))
  end

  for _, id in ipairs(graph.order) do
    local node = graph.nodes[id]
    local a = node.attrs
    for _, key in ipairs({ "retry_target", "fallback_retry_target" }) do
      target_exists(node.line, id, key, a[key])
    end
    if a.goal_gate == "true" then
      local has = a.retry_target
        or a.fallback_retry_target
        or graph.attrs.retry_target
        or graph.attrs.fallback_retry_target
      if not has or has == "" then
        add("goal_gate_has_retry", WARN, node.line, id .. " is a goal gate without a retry target", id)
      end
    end
    if node.handler == "codergen" and not (a.prompt and a.prompt ~= "") and not (a.label and a.label ~= "") then
      add("prompt_on_llm_nodes", WARN, node.line, id .. " runs an LLM stage without a prompt or label", id)
    end
    if a.fidelity and not M.FIDELITY[a.fidelity] then
      add("fidelity_valid", WARN, node.line, ("unknown fidelity %q on %s"):format(a.fidelity, id), id)
    end
    if a.type and a.type ~= "" and not M.HANDLERS[a.type] then
      add("type_known", WARN, node.line, ("unknown handler type %q on %s"):format(a.type, id), id)
    end
  end
  return out
end

return M
