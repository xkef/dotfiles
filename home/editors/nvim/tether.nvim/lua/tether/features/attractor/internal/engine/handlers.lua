-- Node handlers (attractor-spec section 4). A handler returns an outcome
-- { status, preferred_label?, suggested_next_ids?, context_updates?, notes?,
-- failure_reason?, jump? } or raises an error, which the run loop retries
-- within max_retries.

local agents = require("tether.features.attractor.internal.engine.agents")
local api = require("tether.api")
local store = require("tether.features.attractor.internal.engine.store")

local M = {}

M.RESPONSE_SUMMARY = 200

local STATUSES = {
  success = "success",
  partial_success = "partial_success",
  partial = "partial_success",
  retry = "retry",
  fail = "fail",
  failed = "fail",
  skipped = "skipped",
}

local function status_of(s)
  return STATUSES[tostring(s or ""):lower()] or "success"
end

local function duration_ms(s)
  if not s then
    return nil
  end
  local n, unit = tostring(s):match("^(%d+)(%a*)$")
  local mult = { ms = 1, s = 1000, m = 60000, h = 3600000, d = 86400000, [""] = 1000 }
  return n and mult[unit] and tonumber(n) * mult[unit] or nil
end

---Accelerator key of an edge label: [K] Label, K) Label, K - Label, or
---the first character.
function M.accelerator(label)
  return label:match("^%[(%w)%]") or label:match("^(%w)%)") or label:match("^(%w) %- ") or label:sub(1, 1):upper()
end

function M.start()
  return { status = "success" }
end

M.exit = M.start

---A routing point: it passes the previous outcome on, so edge conditions
---read the stage before it.
function M.conditional(_, _, context)
  return { status = context.outcome or "success" }
end

function M.codergen(run, node, context)
  local dir = store.stage_dir(run, node.id)
  store.clear_status(run, node.id)
  local prompt = agents.prompt(run, node, context, dir)
  store.write_text(run, node.id, "prompt.md", prompt)
  local res = agents.run(run, node, prompt, dir)
  store.write_text(run, node.id, "response.md", res.stdout)
  local reported = store.agent_status(run, node.id)
  local updates = {
    last_stage = node.id,
    last_response = res.stdout:sub(1, M.RESPONSE_SUMMARY),
  }
  if reported then
    for k, v in pairs(reported.context_updates or {}) do
      updates[k] = v
    end
    return {
      status = status_of(reported.status),
      preferred_label = reported.preferred_label,
      suggested_next_ids = reported.suggested_next_ids,
      context_updates = updates,
      notes = reported.notes,
      failure_reason = reported.failure_reason,
    }
  end
  if res.code ~= 0 then
    error(("agent exited %d: %s"):format(res.code, vim.trim(res.stderr):sub(1, 500)))
  end
  return { status = "success", context_updates = updates }
end

function M.tool(run, node)
  local command = node.attrs.tool_command
  if not command or command == "" then
    return { status = "fail", failure_reason = "no tool_command" }
  end
  store.write_text(run, node.id, "prompt.md", command)
  local res = api.util.run({ "sh", "-c", command }, { cwd = run.workdir })
  store.write_text(run, node.id, "response.md", res.stdout .. res.stderr)
  if res.code ~= 0 then
    error(("tool exited %d"):format(res.code))
  end
  return { status = "success", context_updates = { ["tool.output"] = res.stdout } }
end

---Asks through a question file and waits for the answer file.
M["wait.human"] = function(run, node, _, visit)
  local choices = {}
  for _, e in ipairs(run.graph.edges) do
    if e.from == node.id then
      local label = e.attrs.label or e.to
      table.insert(choices, { key = M.accelerator(label), label = label, to = e.to })
    end
  end
  if #choices == 0 then
    return { status = "fail", failure_reason = "no outgoing edges for human gate" }
  end
  local id = node.id .. "-" .. visit
  local options = vim.tbl_map(function(c)
    return { key = c.key, label = c.label }
  end, choices)
  store.ask(
    run,
    { id = id, text = node.attrs.label or "Select an option:", kind = "choice", options = options, stage = node.id }
  )
  store.event(run, "InterviewStarted", { node_id = node.id, question = id })
  local timeout = duration_ms(node.attrs.timeout)
  local waited = 0
  local answer
  while true do
    answer = store.answer(run, id)
    if answer then
      break
    end
    if timeout and waited >= timeout then
      break
    end
    vim.wait(run.poll_ms)
    waited = waited + run.poll_ms
  end
  local selected
  local wanted = answer and (answer.key or answer.label or answer.text) or node.attrs["human.default_choice"]
  if not wanted then
    store.event(run, "InterviewTimeout", { node_id = node.id, question = id })
    return { status = "retry", failure_reason = "human gate timeout, no default" }
  end
  for _, c in ipairs(choices) do
    if c.key:lower() == tostring(wanted):lower() or c.label == wanted or c.to == wanted then
      selected = c
      break
    end
  end
  selected = selected or choices[1]
  store.event(run, "InterviewCompleted", { node_id = node.id, question = id, answer = selected.label })
  return {
    status = "success",
    suggested_next_ids = { selected.to },
    context_updates = {
      ["human.gate.selected"] = selected.key,
      ["human.gate.label"] = selected.label,
      ["human.gate.text"] = answer and answer.text or nil,
    },
  }
end

---Parallel fan-out, run one branch after another (v1): each branch walks
---until it reaches a fan-in node, and the run continues there.
function M.parallel(run, node, context, _, walk)
  local fan_in, failed = nil, 0
  local branches = 0
  for _, e in ipairs(run.graph.edges) do
    if e.from == node.id then
      branches = branches + 1
      local reached, outcome = walk(e.to)
      fan_in = fan_in or reached
      if outcome and outcome.status == "fail" then
        failed = failed + 1
      end
    end
  end
  context["parallel.failed"] = failed
  return {
    status = failed == 0 and "success" or (failed < branches and "partial_success" or "fail"),
    jump = fan_in,
  }
end

M["parallel.fan_in"] = function(_, _, context)
  return { status = (context["parallel.failed"] or 0) == 0 and "success" or "partial_success" }
end

M["stack.manager_loop"] = function()
  return { status = "fail", failure_reason = "stack.manager_loop is not supported" }
end

-- Fabro-style names for the same handlers.
M.agent = M.codergen
M.prompt = M.codergen
M.command = M.tool
M.human = M["wait.human"]
M.wait = function()
  return { status = "success" }
end

return M
