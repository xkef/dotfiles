-- CLI agents that run codergen stages. A template is an argv list whose
-- items may hold {prompt}, {model}, and {stage_dir}.

local api = require("tether.api")

local M = {}

M.DEFAULTS = {
  claude = { "claude", "-p", "{prompt}" },
  codex = { "codex", "exec", "{prompt}" },
  pi = { "pi", "-p", "{prompt}" },
}

M.SUMMARY_CHARS = 2000

---The template for a node: its `agent` attribute, then the graph's, then
---attractor.agent.
function M.template(graph, node)
  local cfg = api.config().attractor or {}
  local name = node.attrs.agent or graph.attrs.agent or cfg.agent or "claude"
  local templates = vim.tbl_extend("force", M.DEFAULTS, cfg.agents or {})
  return templates[name], name
end

---The stage prompt: the node's prompt (or label) with $goal expanded, what
---the previous stage said, and how to report an outcome.
function M.prompt(run, node, context, stage_dir)
  local body = node.attrs.prompt
  if not body or body == "" then
    body = node.attrs.label or node.id
  end
  local goal = run.graph.attrs.goal or context.goal or ""
  body = body:gsub("%$goal", function()
    return goal
  end)
  local parts = { body }
  if context.last_stage and context.last_response and context.last_response ~= "" then
    table.insert(
      parts,
      ("Previous stage %s reported:\n%s"):format(context.last_stage, context.last_response:sub(1, M.SUMMARY_CHARS))
    )
  end
  table.insert(
    parts,
    table.concat({
      "This is stage " .. node.id .. " of an automated pipeline.",
      "To steer the pipeline, write " .. vim.fs.joinpath(stage_dir, "status.json"),
      'with {"status": "success"|"fail"|"retry"|"partial_success", "preferred_label": "<edge label>",',
      '"context_updates": {...}}. Without it, a zero exit code counts as success.',
    }, "\n")
  )
  return table.concat(parts, "\n\n")
end

---Runs the agent for a stage and returns the process result.
function M.run(run, node, prompt, stage_dir)
  local template, name = M.template(run.graph, node)
  if not template then
    error("no agent template named " .. tostring(name))
  end
  local values = { prompt = prompt, model = node.attrs.llm_model or "", stage_dir = stage_dir }
  local cmd = {}
  for _, item in ipairs(template) do
    local expanded = item:gsub("{([%w_]+)}", function(key)
      return values[key]
    end)
    table.insert(cmd, expanded)
  end
  if vim.fn.executable(cmd[1]) == 0 then
    error("agent command not found: " .. cmd[1])
  end
  return api.util.run(cmd, { cwd = run.workdir })
end

return M
