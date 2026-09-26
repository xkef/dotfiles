-- The pipeline run loop (attractor-spec section 3): execute a node, retry
-- within its policy, record the outcome, checkpoint, and follow the next
-- edge until the exit node lets the run finish.

local api = require("tether.api")
local condition = require("tether.features.attractor.internal.engine.condition")
local dot = require("tether.features.attractor.internal.dot")
local handlers = require("tether.features.attractor.internal.engine.handlers")
local isolate = require("tether.features.attractor.internal.engine.isolate")
local store = require("tether.features.attractor.internal.engine.store")

local M = {}

M.MAX_VISITS = 20

-- Handlers whose stages are agent work: they become tether turns and, in a
-- workspace, commits.
local WORK = { codergen = true, tool = true, agent = true, prompt = true, command = true }

local function plugin_root()
  local src = debug.getinfo(1, "S").source:sub(2)
  return src:match("^(.*)/lua/tether/")
end

---Emits an agent-trail event for a stage, so tether sees it as a turn.
local function trail(run, kind, text)
  local bin = vim.fs.joinpath(plugin_root() or "", "bin", "agent-trail")
  if vim.fn.executable(bin) == 0 then
    return
  end
  local cmd = { bin, kind, "pipeline" }
  if text then
    table.insert(cmd, text)
  end
  vim.system(cmd, { cwd = run.workdir, env = { AGENT_TRAIL_SESSION = run.id }, text = true }):wait()
end

---Lowercases, trims, and strips accelerator prefixes such as "[Y] ".
function M.normalize_label(label)
  label = vim.trim((label or ""):lower())
  label = label:gsub("^%[%w%]%s*", ""):gsub("^%w%)%s*", ""):gsub("^%w %- ", "")
  return vim.trim(label)
end

local function outgoing(graph, id)
  local out = {}
  for _, e in ipairs(graph.edges) do
    if e.from == id then
      table.insert(out, e)
    end
  end
  return out
end

local function best(edges)
  table.sort(edges, function(a, b)
    local wa, wb = tonumber(a.attrs.weight) or 0, tonumber(b.attrs.weight) or 0
    if wa ~= wb then
      return wa > wb
    end
    return a.to < b.to
  end)
  return edges[1]
end

---Next edge by the spec's order: conditions, preferred label, suggested
---ids, weight, lexical target.
function M.select_edge(graph, id, outcome, context)
  local edges = outgoing(graph, id)
  local matched, plain = {}, {}
  for _, e in ipairs(edges) do
    if e.attrs.condition and e.attrs.condition ~= "" then
      if condition.eval(e.attrs.condition, outcome, context) then
        table.insert(matched, e)
      end
    else
      table.insert(plain, e)
    end
  end
  if #matched > 0 then
    return best(matched)
  end
  if outcome.status == "fail" then
    return nil
  end
  if outcome.preferred_label and outcome.preferred_label ~= "" then
    local want = M.normalize_label(outcome.preferred_label)
    for _, e in ipairs(plain) do
      if M.normalize_label(e.attrs.label) == want then
        return e
      end
    end
  end
  for _, sid in ipairs(outcome.suggested_next_ids or {}) do
    for _, e in ipairs(plain) do
      if e.to == sid then
        return e
      end
    end
  end
  if #plain > 0 then
    return best(plain)
  end
end

local function retry_target(graph, node)
  local t = node.attrs.retry_target
  if t and graph.nodes[t] then
    return t
  end
  t = node.attrs.fallback_retry_target
  if t and graph.nodes[t] then
    return t
  end
end

local function graph_retry_target(graph)
  for _, key in ipairs({ "retry_target", "fallback_retry_target" }) do
    local t = graph.attrs[key]
    if t and graph.nodes[t] then
      return t
    end
  end
end

local function max_attempts(graph, node)
  local n = tonumber(node.attrs.max_retries)
    or tonumber(graph.attrs.default_max_retries)
    or tonumber(graph.attrs.default_max_retry)
    or 0
  return math.max(n, 0) + 1
end

---@class tether.pipeline.Run
---@field id string
---@field dir string
---@field graph tether.dot.Graph
---@field workdir string
---@field poll_ms integer
---@field iso table
---@field state table

local function execute(run, node, visit, walk)
  local handler = handlers[node.handler]
  if not handler then
    return { status = "fail", failure_reason = "unknown handler type " .. node.handler }
  end
  local state = run.state
  local attempts = max_attempts(run.graph, node)
  local outcome
  for attempt = 1, attempts do
    local ok, result = pcall(handler, run, node, state.context, visit, walk)
    if not ok then
      outcome = { status = "fail", failure_reason = tostring(result) }
    else
      outcome = result
    end
    if outcome.status ~= "fail" and outcome.status ~= "retry" then
      return outcome
    end
    local retryable = not ok or outcome.status == "retry"
    if not retryable or attempt == attempts then
      break
    end
    state.retries[node.id] = (state.retries[node.id] or 0) + 1
    store.event(run, "StageRetrying", { node_id = node.id, attempt = attempt })
  end
  if outcome.status == "retry" then
    if node.attrs.allow_partial == "true" then
      return { status = "partial_success", notes = "retries exhausted, partial accepted" }
    end
    return { status = "fail", failure_reason = outcome.failure_reason or "max retries exceeded" }
  end
  return outcome
end

local finish

---Runs one node and returns the id of the next, or nil and a final status.
local function step(run, id, walk)
  local graph, state = run.graph, run.state
  local node = graph.nodes[id]
  if not node then
    return nil, "fail", "no node " .. tostring(id)
  end
  state.visits[id] = (state.visits[id] or 0) + 1
  if state.visits[id] > (tonumber(graph.attrs.max_node_visits) or M.MAX_VISITS) then
    return nil, "fail", "visit limit reached at " .. id
  end

  if dot.is_exit(node) then
    for gid, status in pairs(state.outcomes) do
      local gnode = graph.nodes[gid]
      if gnode and gnode.attrs.goal_gate == "true" and status ~= "success" and status ~= "partial_success" then
        local target = retry_target(graph, gnode) or graph_retry_target(graph)
        if not target then
          return nil, "fail", "goal gate " .. gid .. " unsatisfied"
        end
        store.event(run, "GoalGateRetry", { node_id = gid, target = target })
        return target
      end
    end
    store.write_status(run, id, { status = "success" })
    return nil, "success"
  end

  local work = WORK[node.handler]
  store.stage_dir(run, id)
  store.event(run, "StageStarted", { node_id = id, name = id })
  if work then
    trail(run, "turn", id .. ": " .. (node.attrs.label or id))
  end
  local outcome = execute(run, node, state.visits[id], walk)
  if work then
    trail(run, "stop")
  end

  table.insert(state.completed, id)
  state.outcomes[id] = outcome.status
  for k, v in pairs(outcome.context_updates or {}) do
    state.context[k] = v
  end
  state.context.outcome = outcome.status
  state.context.preferred_label = outcome.preferred_label
  store.write_status(run, id, outcome)
  store.event(
    run,
    outcome.status == "fail" and "StageFailed" or "StageCompleted",
    { node_id = id, name = id, status = outcome.status, error = outcome.failure_reason }
  )
  if work then
    isolate.commit(run.iso, run.id, id, outcome.status)
  end

  local next_id
  if outcome.jump then
    next_id = outcome.jump
  else
    local edge = M.select_edge(graph, id, outcome, state.context)
    next_id = edge and edge.to
    if not next_id and outcome.status == "fail" then
      next_id = retry_target(graph, node)
      if not next_id then
        return nil, "fail", outcome.failure_reason or ("stage " .. id .. " failed")
      end
    end
  end
  state.current, state.next = id, next_id
  store.write_checkpoint(run, state)
  if not next_id then
    return nil, outcome.status == "fail" and "fail" or "success"
  end
  return next_id
end

---Walks from a branch start until a fan-in node, for parallel handlers.
local function walker(run)
  local function walk(start)
    local id, last = start, nil
    while id do
      local node = run.graph.nodes[id]
      if not node or node.handler == "parallel.fan_in" then
        return id, last
      end
      local next_id = step(run, id, walk)
      last = { status = run.state.outcomes[id] }
      id = next_id
    end
    return nil, last
  end
  return walk
end

function finish(run, status, reason)
  local manifest = store.manifest(run) or {}
  isolate.finish(run.repo, run.iso)
  manifest.status = status
  manifest.reason = reason
  manifest.finished = os.time()
  manifest.isolation = run.iso
  store.write_manifest(run, manifest)
  store.event(run, status == "success" and "PipelineCompleted" or "PipelineFailed", { error = reason })
  return status, reason
end

---Runs (or resumes) a pipeline. Returns the final status and reason.
---@param opts {dir: string, graph: tether.dot.Graph, repo?: tether.Repo, resume?: boolean}
function M.run(opts)
  local manifest = store.manifest({ dir = opts.dir }) or {}
  local run = {
    id = manifest.id,
    dir = opts.dir,
    graph = opts.graph,
    repo = opts.repo,
    workdir = manifest.workdir,
    iso = manifest.isolation or { kind = "none" },
    poll_ms = (api.config().attractor or {}).poll_ms or 1000,
  }
  local ckpt = opts.resume and store.checkpoint(run) or nil
  run.state = {
    context = ckpt and ckpt.context or { goal = opts.graph.attrs.goal },
    completed = ckpt and ckpt.completed_nodes or {},
    outcomes = ckpt and ckpt.node_outcomes or {},
    retries = ckpt and ckpt.node_retries or {},
    visits = ckpt and ckpt.node_visits or {},
    logs = ckpt and ckpt.logs or {},
  }
  local id
  if ckpt then
    id = ckpt.next_node
    if not id then
      return finish(run, "success")
    end
  else
    local _, _, start = dot.bfs(opts.graph)
    if not start then
      return finish(run, "fail", "no start node")
    end
    id = start
    store.event(run, "PipelineStarted", { id = run.id, name = opts.graph.name })
  end
  local walk = walker(run)
  while true do
    local next_id, status, reason = step(run, id, walk)
    if not next_id then
      return finish(run, status, reason)
    end
    id = next_id
  end
end

return M
