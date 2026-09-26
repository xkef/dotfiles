-- Fabro backend (github.com/fabro-sh/fabro). Fabro documents its run
-- directory as unstable, so this backend talks to the HTTP API only:
-- GET /api/v1/runs/{id}/attach streams RunStreamItem events, and human
-- gates go through /api/v1/runs/{id}/questions.

local api = require("tether.api")
local http = require("tether.features.attractor.internal.http")

local M = { name = "fabro" }

M.DEFAULT_URL = "http://127.0.0.1:32276"
M.RECONNECT_MS = 2000

---The URL of [cli.target] in settings.toml, if it names an HTTP server.
function M.settings_url(path)
  path = path or vim.fs.joinpath(vim.env.HOME or "~", ".fabro", "settings.toml")
  local section
  for _, line in ipairs(api.util.read_lines(path) or {}) do
    local s = line:match("^%s*%[([^%]]+)%]%s*$")
    if s then
      section = s
    elseif section == "cli.target" then
      local url = line:match('^%s*url%s*=%s*"([^"]+)"')
      if url then
        return url
      end
    end
  end
end

---Server URL: configured, from Fabro's settings, or Fabro's default.
function M.url()
  local cfg = api.config().attractor or {}
  return (cfg.fabro_url or M.settings_url() or M.DEFAULT_URL):gsub("/+$", "")
end

local function dig(t, ...)
  for _, k in ipairs({ ... }) do
    if type(t) ~= "table" then
      return nil
    end
    t = t[k]
  end
  return t
end

-- Petri event names to statuses.
local EVENTS = {
  ["visit.started"] = "running",
  ["step.started"] = "running",
  ["step.finished"] = "success",
  ["visit.finished"] = "success",
  ["step.failed"] = "fail",
  ["visit.failed"] = "fail",
}

---Maps one RunStreamItem to an update, or nil.
function M.map_item(item)
  local body = dig(item, "item", "record", "body") or dig(item, "item") or {}
  if item.kind == "platform" then
    local kind = dig(item, "item", "record", "kind")
    if kind == "interview.answered" then
      return { answered = true }
    end
    return nil
  end
  local event = body.event
  if event == "run.finished" then
    return { done = "run finished" }
  end
  local status = EVENTS[event]
  if not status then
    return nil
  end
  local outcome = tostring(body.outcome or body.status or ""):lower()
  if status == "success" and (outcome:find("fail") or outcome:find("error")) then
    status = "fail"
  end
  local node = dig(body, "subject", "node", "name") or dig(body, "subject", "node")
  if type(node) ~= "string" then
    return nil
  end
  return { node = node, status = status }
end

function M.start(run, emit)
  local stopped, stop_stream = false, nil
  local seq, seen = nil, {}
  local function connect()
    if stopped then
      return
    end
    local url = run.url .. "/api/v1/runs/" .. run.id .. "/attach"
    if seq then
      url = url .. "?after=" .. seq
    end
    stop_stream = http.stream(url, function(data)
      local item = http.decode(data)
      if type(item) ~= "table" then
        return
      end
      if item.id then
        if seen[item.id] then
          return
        end
        seen[item.id] = true
      end
      seq = item.stream_seq or seq
      local update = M.map_item(item)
      if update then
        if update.done then
          stopped = true
        end
        emit(update)
      end
    end, function()
      if not stopped then
        vim.defer_fn(connect, M.RECONNECT_MS)
      end
    end)
  end
  connect()
  return function()
    stopped = true
    if stop_stream then
      stop_stream()
    end
  end
end

local KINDS = {
  yes_no = "yes_no",
  confirmation = "yes_no",
  multiple_choice = "choice",
  single_select = "choice",
  freeform = "text",
}

function M.questions(run, cb)
  http.get(run.url .. "/api/v1/runs/" .. run.id .. "/questions", function(data, err)
    if not data then
      return cb(nil, err)
    end
    local out = {}
    for _, q in ipairs(data.questions or data) do
      local options = {}
      for _, o in ipairs(q.options or {}) do
        table.insert(options, { key = o.key, label = o.label })
      end
      local kind = KINDS[tostring(q.question_type or ""):lower()]
      if not kind then
        kind = #options > 0 and "choice" or "text"
      end
      table.insert(out, {
        id = tostring(q.id),
        text = q.text or "",
        kind = kind,
        options = options,
        stage = q.stage,
        freeform = q.allow_freeform,
      })
    end
    cb(out)
  end)
end

function M.answer(run, q, choice, cb)
  local body
  if choice.kind == "yes" or choice.kind == "no" then
    body = { kind = choice.kind }
  elseif choice.kind == "selected" then
    body = { kind = "selected", option_key = choice.key }
  else
    body = { kind = "text", text = choice.text }
  end
  http.post(run.url .. "/api/v1/runs/" .. run.id .. "/questions/" .. q.id .. "/answer", body, cb)
end

---Starts a workflow with `fabro run -d` and calls cb(run_id, err).
function M.launch(file, cb)
  local fabro = (api.config().attractor or {}).fabro or "fabro"
  if vim.fn.executable(fabro) == 0 then
    return cb(nil, fabro .. " not found")
  end
  api.util.run({ fabro, "run", "-d", file }, { cwd = vim.fs.dirname(file) }, function(res)
    local id = (res.stdout .. "\n" .. res.stderr):match(
      "%f[%w](%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w)%f[%W]"
    )
    if res.code ~= 0 or not id then
      return cb(nil, vim.trim(res.stderr ~= "" and res.stderr or res.stdout))
    end
    cb(id:upper())
  end)
end

---Findings of `fabro validate` as { line, message }, or nil without fabro.
function M.validate(file, cb)
  local fabro = (api.config().attractor or {}).fabro or "fabro"
  if vim.fn.executable(fabro) == 0 then
    return cb(nil)
  end
  api.util.run({ fabro, "validate", file }, { cwd = vim.fs.dirname(file) }, function(res)
    if res.code == 0 then
      return cb({})
    end
    local out = {}
    for _, line in ipairs(api.util.lines(res.stdout .. "\n" .. res.stderr)) do
      local lnum = line:match(":(%d+):") or line:match("[Ll]ine (%d+)")
      if lnum or line:lower():find("error") then
        table.insert(out, { line = tonumber(lnum) or 1, message = vim.trim(line) })
      end
    end
    if #out == 0 then
      table.insert(out, { line = 1, message = "fabro validate failed" })
    end
    cb(out)
  end)
end

return M
