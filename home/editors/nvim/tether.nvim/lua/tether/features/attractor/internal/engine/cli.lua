-- tether-run: run Attractor pipelines headless.
--
--   tether-run start <pipeline> [--goal G] [--logs DIR] [--workspace]
--   tether-run resume <run-dir>
--   tether-run answer <run-dir> <question-id> <key-or-label>
--   tether-run status <run-dir>
--
-- start prints `run <dir>` first, so callers can watch the run directory.
-- A config.json in the run directory ({ "attractor": { ... } }) configures
-- agents. Exit code 0 means the pipeline succeeded.

local api = require("tether.api")
local dot = require("tether.features.attractor.internal.dot")
local engine = require("tether.features.attractor.internal.engine")
local isolate = require("tether.features.attractor.internal.engine.isolate")
local lint = require("tether.features.attractor.internal.lint")
local store = require("tether.features.attractor.internal.engine.store")

local function out(...)
  io.stdout:write(table.concat({ ... }, " "), "\n")
  io.stdout:flush()
end

local function die(msg, code)
  io.stderr:write("tether-run: ", msg, "\n")
  os.exit(code or 2)
end

local function parse_args(argv)
  local pos, flags = {}, {}
  local i = 1
  while i <= #argv do
    local a = argv[i]
    if a == "--workspace" then
      flags.workspace = true
    elseif a == "--goal" or a == "--logs" then
      flags[a:sub(3)] = argv[i + 1]
      i = i + 1
    else
      table.insert(pos, a)
    end
    i = i + 1
  end
  return pos, flags
end

local function load_config(dir)
  local cfg = store.read_json(vim.fs.joinpath(dir, "config.json"))
  api.configure(cfg or {})
end

local function load_graph(path)
  local lines = api.util.read_lines(path)
  if not lines then
    die("cannot read " .. path)
  end
  local graph = dot.parse(table.concat(lines, "\n"))
  local errors = {}
  for _, d in ipairs(lint.run(graph)) do
    if d.severity == vim.diagnostic.severity.ERROR then
      table.insert(errors, ("%d: %s (%s)"):format(d.line, d.message, d.rule))
    end
  end
  if #errors > 0 then
    die("pipeline has errors:\n" .. table.concat(errors, "\n"))
  end
  return graph
end

local function new_id()
  math.randomseed(vim.uv.hrtime())
  return os.date("%Y%m%d-%H%M%S") .. ("-%04x"):format(math.random(0, 0xffff))
end

local function finish(status, reason)
  out("status", status, reason or "")
  os.exit(status == "success" and 0 or 1)
end

local commands = {}

function commands.start(pos, flags)
  local pipeline = pos[1] and vim.fn.fnamemodify(pos[1], ":p")
  if not pipeline then
    die("usage: tether-run start <pipeline> [--goal G] [--logs DIR] [--workspace]")
  end
  local id = new_id()
  local state = vim.env.XDG_STATE_HOME or vim.fs.joinpath(vim.env.HOME, ".local", "state")
  local dir = flags.logs and vim.fn.fnamemodify(flags.logs, ":p"):gsub("/$", "")
    or vim.fs.joinpath(state, "tether", "runs", id)
  vim.fn.mkdir(dir, "p")
  load_config(dir)
  local graph = load_graph(pipeline)
  if flags.goal then
    graph.attrs.goal = flags.goal
  end
  vim.fn.writefile(api.util.read_lines(pipeline), vim.fs.joinpath(dir, "pipeline.dot"))
  local repo = api.vcs.detect(vim.fs.dirname(pipeline))
  local ok, workdir, iso = pcall(isolate.prepare, repo, id, flags.workspace, vim.fs.dirname(pipeline))
  if not ok then
    die("cannot prepare the workspace: " .. tostring(workdir))
  end
  store.write_manifest({ dir = dir }, {
    id = id,
    pipeline = pipeline,
    goal = graph.attrs.goal,
    started = os.time(),
    status = "running",
    workdir = workdir,
    repo = repo and repo.root,
    isolation = iso,
  })
  out("run", dir)
  finish(engine.run({ dir = dir, graph = graph, repo = repo }))
end

function commands.resume(pos)
  local dir = pos[1] and vim.fn.fnamemodify(pos[1], ":p"):gsub("/$", "")
  local manifest = dir and store.manifest({ dir = dir })
  if not manifest then
    die("usage: tether-run resume <run-dir>")
  end
  load_config(dir)
  local graph = load_graph(vim.fs.joinpath(dir, "pipeline.dot"))
  if manifest.goal then
    graph.attrs.goal = manifest.goal
  end
  manifest.status = "running"
  store.write_manifest({ dir = dir }, manifest)
  out("run", dir)
  finish(
    engine.run({ dir = dir, graph = graph, repo = manifest.repo and api.vcs.detect(manifest.repo), resume = true })
  )
end

function commands.answer(pos)
  local dir, qid, value = pos[1], pos[2], pos[3]
  if not (dir and qid and value) then
    die("usage: tether-run answer <run-dir> <question-id> <key-or-label>")
  end
  local q = store.read_json(vim.fs.joinpath(dir, "questions", qid .. ".json"))
  if not q then
    die("no question " .. qid)
  end
  for _, o in ipairs(q.options or {}) do
    if o.key:lower() == value:lower() or o.label == value then
      store.write_answer(dir, qid, { kind = "selected", key = o.key, label = o.label })
      out("answered", qid, o.label)
      os.exit(0)
    end
  end
  store.write_answer(dir, qid, { kind = "text", text = value })
  out("answered", qid, value)
  os.exit(0)
end

function commands.status(pos)
  local dir = pos[1]
  local manifest = dir and store.manifest({ dir = dir })
  if not manifest then
    die("usage: tether-run status <run-dir>")
  end
  local ckpt = store.checkpoint({ dir = dir }) or {}
  out("status", manifest.status or "?")
  for _, id in ipairs(ckpt.completed_nodes or {}) do
    out("node", id, (ckpt.node_outcomes or {})[id] or "?")
  end
  for _, q in ipairs(store.pending(dir)) do
    out("question", q.id, q.text)
  end
  os.exit(0)
end

local argv = vim.deepcopy(_G.arg or {})
local name = table.remove(argv, 1)
local cmd = commands[name or ""]
if not cmd then
  die("usage: tether-run start|resume|answer|status ...")
end
local ok, err = xpcall(function()
  cmd(parse_args(argv))
end, debug.traceback)
if not ok then
  die(err, 3)
end
