-- The generic Attractor backend: a run directory (attractor-spec 5.6) or a
-- server in HTTP mode (9.5). The spec leaves payloads open, so fields are
-- read tolerantly.

local api = require("tether.api")
local http = require("tether.features.attractor.internal.http")
local store = require("tether.features.attractor.internal.engine.store")

local M = { name = "spec" }

local STATUS = {
  success = "success",
  partial_success = "partial",
  fail = "fail",
  failed = "fail",
  retry = "retry",
  skipped = "skipped",
}

local function norm_status(s)
  return STATUS[tostring(s or ""):lower()] or "running"
end

local function read_json(path)
  local lines = api.util.read_lines(path)
  return lines and http.decode(table.concat(lines, "\n")) or nil
end

---Node statuses in a run directory.
function M.scan(dir)
  local out = {}
  local ckpt = read_json(vim.fs.joinpath(dir, "checkpoint.json")) or {}
  for _, id in ipairs(ckpt.completed_nodes or {}) do
    out[id] = "success"
  end
  for name, kind in vim.fs.dir(dir) do
    if kind == "directory" and name ~= "artifacts" then
      local status = read_json(vim.fs.joinpath(dir, name, "status.json"))
      if status then
        out[name] = norm_status(status.status or status.outcome)
      elseif not out[name] and name ~= "questions" and name ~= "answers" then
        out[name] = "running"
      end
    end
  end
  for _, q in ipairs(store.pending(dir)) do
    if q.stage then
      out[q.stage] = "waiting"
    end
  end
  return out
end

-- Stage event names (attractor-spec 9.6) to statuses.
local EVENTS = {
  StageStarted = "running",
  StageCompleted = "success",
  StageFailed = "fail",
  StageRetrying = "retry",
  InterviewStarted = "waiting",
}

local function field(t, ...)
  for _, k in ipairs({ ... }) do
    if t[k] ~= nil then
      return t[k]
    end
  end
end

---Maps one stream event to an update, or nil.
function M.map_event(data, event)
  local item = http.decode(data)
  if type(item) ~= "table" then
    return nil
  end
  local name = event or field(item, "type", "event", "kind")
  local node = field(item, "node_id", "stage", "name", "node")
  if name == "StageFailed" and item.will_retry then
    return { node = node, status = "retry" }
  end
  if name == "PipelineCompleted" or name == "PipelineFailed" then
    return { done = name }
  end
  local status = EVENTS[name]
  if status and node then
    return { node = node, status = status, question = name == "InterviewStarted" or nil }
  end
end

function M.start(run, emit)
  if run.dir then
    local last = {}
    local timer = vim.uv.new_timer()
    local function poll()
      for node, status in pairs(M.scan(run.dir)) do
        if last[node] ~= status then
          last[node] = status
          emit({ node = node, status = status })
        end
      end
    end
    poll()
    timer:start(run.poll_ms, run.poll_ms, vim.schedule_wrap(poll))
    return function()
      timer:stop()
      timer:close()
    end
  end
  return http.stream(run.url .. "/pipelines/" .. run.id .. "/events", function(data, event)
    local update = M.map_event(data, event)
    if update then
      emit(update)
    end
  end)
end

local KINDS = { YES_NO = "yes_no", CONFIRMATION = "yes_no", MULTIPLE_CHOICE = "choice", FREEFORM = "text" }

function M.questions(run, cb)
  if run.dir then
    local list = store.pending(run.dir)
    return vim.schedule(function()
      cb(list)
    end)
  end
  http.get(run.url .. "/pipelines/" .. run.id .. "/questions", function(data, err)
    if not data then
      return cb(nil, err)
    end
    local list = data.questions or data
    local out = {}
    for _, q in ipairs(list) do
      local options = {}
      for _, o in ipairs(q.options or {}) do
        table.insert(options, { key = o.key, label = o.label })
      end
      table.insert(out, {
        id = tostring(field(q, "id", "qid")),
        text = field(q, "text", "question") or "",
        kind = KINDS[tostring(q.type or ""):upper()] or (#options > 0 and "choice" or "text"),
        options = options,
        stage = q.stage,
      })
    end
    cb(out)
  end)
end

function M.answer(run, q, choice, cb)
  if run.dir then
    store.write_answer(run.dir, q.id, choice)
    return vim.schedule(function()
      cb(true)
    end)
  end
  local body
  if choice.kind == "yes" or choice.kind == "no" then
    body = { value = choice.kind:upper() }
  elseif choice.kind == "selected" then
    body = { value = choice.label, selected_option = { key = choice.key, label = choice.label } }
  else
    body = { value = choice.text, text = choice.text }
  end
  http.post(run.url .. "/pipelines/" .. run.id .. "/questions/" .. q.id .. "/answer", body, cb)
end

function M.stage_files(run, node)
  if not run.dir then
    return {}
  end
  local out = {}
  for _, name in ipairs({ "prompt.md", "response.md" }) do
    local path = vim.fs.joinpath(run.dir, node, name)
    if vim.fn.filereadable(path) == 1 then
      table.insert(out, path)
    end
  end
  return out
end

return M
