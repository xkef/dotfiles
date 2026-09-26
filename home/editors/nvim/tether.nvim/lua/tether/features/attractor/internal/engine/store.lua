-- The run directory of attractor-spec section 5.6, extended with question
-- and answer files for human gates:
--
--   manifest.json  checkpoint.json  events.jsonl
--   <node>/prompt.md  <node>/response.md  <node>/status.json
--   questions/<id>.json  answers/<id>.json

local api = require("tether.api")

local M = {}

local function path(run, ...)
  return vim.fs.joinpath(run.dir, ...)
end

local function write_json(file, data)
  vim.fn.mkdir(vim.fs.dirname(file), "p")
  local tmp = file .. ".tmp"
  vim.fn.writefile({ vim.json.encode(data) }, tmp)
  vim.uv.fs_rename(tmp, file)
end

local function read_json(file)
  local lines = api.util.read_lines(file)
  if not lines then
    return nil
  end
  local ok, data = pcall(vim.json.decode, table.concat(lines, "\n"))
  return ok and data or nil
end

M.read_json = read_json
M.write_json = write_json

function M.manifest(run)
  return read_json(path(run, "manifest.json"))
end

function M.write_manifest(run, data)
  write_json(path(run, "manifest.json"), data)
end

function M.checkpoint(run)
  return read_json(path(run, "checkpoint.json"))
end

function M.write_checkpoint(run, state)
  write_json(path(run, "checkpoint.json"), {
    timestamp = os.time(),
    current_node = state.current,
    next_node = state.next,
    completed_nodes = state.completed,
    node_outcomes = state.outcomes,
    node_retries = state.retries,
    node_visits = state.visits,
    context = state.context,
    logs = state.logs,
  })
end

---Appends one event (attractor-spec 9.6 names) to events.jsonl.
function M.event(run, name, data)
  local record = vim.tbl_extend("force", { type = name, time = os.time() }, data or {})
  local fd = io.open(path(run, "events.jsonl"), "a")
  if fd then
    fd:write(vim.json.encode(record), "\n")
    fd:close()
  end
end

function M.stage_dir(run, node)
  local dir = path(run, node)
  vim.fn.mkdir(dir, "p")
  return dir
end

function M.write_text(run, node, name, text)
  vim.fn.writefile(vim.split(text or "", "\n", { plain = true }), vim.fs.joinpath(M.stage_dir(run, node), name))
end

---Writes <node>/status.json for an outcome.
function M.write_status(run, node, outcome)
  write_json(path(run, node, "status.json"), {
    status = (outcome.status or ""):upper(),
    preferred_label = outcome.preferred_label,
    failure_reason = outcome.failure_reason,
    notes = outcome.notes,
  })
end

---A status.json an agent wrote during its stage, if any.
function M.agent_status(run, node)
  return read_json(path(run, node, "status.json"))
end

function M.clear_status(run, node)
  os.remove(path(run, node, "status.json"))
end

function M.ask(run, question)
  write_json(path(run, "questions", question.id .. ".json"), question)
end

function M.answer(run, id)
  return read_json(path(run, "answers", id .. ".json"))
end

---Writes an answer; the run directory is all a caller needs.
function M.write_answer(dir, id, choice)
  write_json(vim.fs.joinpath(dir, "answers", id .. ".json"), choice)
end

---Questions without an answer yet.
function M.pending(dir)
  local out = {}
  local qdir = vim.fs.joinpath(dir, "questions")
  if vim.fn.isdirectory(qdir) == 0 then
    return out
  end
  for name in vim.fs.dir(qdir) do
    local id = name:match("^(.+)%.json$")
    if id and vim.fn.filereadable(vim.fs.joinpath(dir, "answers", name)) == 0 then
      local q = read_json(vim.fs.joinpath(qdir, name))
      if q then
        table.insert(out, q)
      end
    end
  end
  table.sort(out, function(a, b)
    return a.id < b.id
  end)
  return out
end

return M
