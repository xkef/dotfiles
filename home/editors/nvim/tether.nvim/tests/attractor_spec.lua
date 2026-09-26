local H = require("helpers")

local BRANCH = [[
digraph Branch {
    graph [goal="Implement and validate a feature"]
    rankdir=LR
    node [shape=box, timeout="900s"]

    start     [shape=Mdiamond, label="Start"]
    exit      [shape=Msquare, label="Exit"]
    plan      [label="Plan", prompt="Plan the implementation"]
    implement [label="Implement", prompt="Implement the plan"]
    validate  [label="Validate", prompt="Run tests"]
    gate      [shape=diamond, label="Tests passing?"]

    start -> plan -> implement -> validate -> gate
    gate -> exit      [label="Yes", condition="outcome=success"]
    gate -> implement [label="No", condition="outcome!=success"]
}
]]

local LINEAR = [[
digraph L {
  start [shape=Mdiamond]
  exit [shape=Msquare]
  plan [prompt="p"]
  implement [prompt="i"]
  review_gate [shape=hexagon, label="Review"]
  start -> plan -> implement -> exit
}
]]

local RUN_ID = "01J00000000000000000000000"

local function attractor()
  return require("tether.features.attractor")
end

local function errors(buf)
  return vim.diagnostic.get(buf, { severity = vim.diagnostic.severity.ERROR })
end

local function open_pipeline(dir, name, text)
  local path = vim.fs.joinpath(dir, name)
  H.write(path, vim.split(text, "\n"))
  vim.cmd("edit " .. path)
  return vim.api.nvim_get_current_buf(), path
end

---A curl stub: -N streams stream_lines, POST appends url and body to the
---log, anything else prints the questions JSON.
local function curl_stub(stream_lines, questions)
  local dir = H.tmpdir("curl")
  local stream, qfile, log = dir .. "/stream", dir .. "/questions", dir .. "/log"
  H.write(stream, stream_lines or {})
  H.write(qfile, { vim.json.encode(questions or {}) })
  local path = H.script(
    "curl",
    ([[
for a; do last=$a; done
case "$*" in
  *" -N "*) cat '%s' ;;
  *POST*) { printf 'POST %%s\n' "$last"; cat; printf '\n'; } >>'%s' ;;
  *) cat '%s' ;;
esac
]]):format(stream, log, qfile)
  )
  return path, log
end

local function posts(log)
  local out = {}
  if vim.fn.filereadable(log) == 0 then
    return out
  end
  local lines = H.read(log)
  for i, l in ipairs(lines) do
    local url = l:match("^POST (.+)$")
    if url then
      table.insert(out, { url = url, body = vim.json.decode(lines[i + 1]) })
    end
  end
  return out
end

local function status_text(buf)
  return H.virt_text(buf)
end

local function sse(event, data)
  local out = {}
  if event then
    table.insert(out, "event: " .. event)
  end
  table.insert(out, "data: " .. vim.json.encode(data))
  table.insert(out, "")
  return out
end

local function petri(seq, event, node)
  return sse(nil, {
    run_id = RUN_ID,
    stream_seq = seq,
    kind = "petri",
    id = "execution 1/" .. seq,
    item = { record = { body = { event = event, subject = node and { node = { name = node }, visit = 1 } or nil } } },
  })
end

return {
  {
    "Chained edges",
    function()
      local g = attractor().parse('digraph G { start -> plan -> exit [label="next"] }')
      H.eq(2, #g.edges)
      H.eq({ "next", "next" }, { g.edges[1].attrs.label, g.edges[2].attrs.label })
      H.eq({ "start", "plan" }, { g.edges[1].from, g.edges[2].from })
    end,
  },
  {
    "Handler from shape",
    function()
      local g = attractor().parse("digraph G { gate [shape=hexagon] step [shape=tab] }")
      H.eq("wait.human", g.nodes.gate.handler)
      H.eq("prompt", g.nodes.step.handler)
    end,
  },
  {
    "Subgraph defaults",
    function()
      local g = attractor().parse([[
digraph G {
  subgraph cluster_a {
    label = "Loop A"
    node [timeout="900s"]
    plan [label="Plan"]
  }
  other [label="Other"]
}]])
      H.eq("900s", g.nodes.plan.attrs.timeout)
      H.eq(nil, g.nodes.other.attrs.timeout)
      H.contains(g.nodes.plan.classes, "loop-a")
    end,
  },
  {
    "Missing exit",
    function()
      H.repo("jj", {})
      H.setup()
      local buf = open_pipeline(vim.fn.getcwd(), "p.dot", "digraph G {\n  start [shape=Mdiamond]\n  start -> work\n}")
      local rules = vim.tbl_map(function(d)
        return d.code
      end, errors(buf))
      H.contains(rules, "terminal_node")
    end,
  },
  {
    "Unreachable node",
    function()
      H.repo("jj", {})
      H.setup()
      local buf = open_pipeline(vim.fn.getcwd(), "p.dot", LINEAR)
      local found
      for _, d in ipairs(errors(buf)) do
        if d.code == "reachability" then
          found = d
        end
      end
      H.ok(found, "reachability error")
      H.eq(5, found.lnum, "on the review_gate line (0-based)")
    end,
  },
  {
    "Valid example",
    function()
      H.repo("jj", {})
      H.setup()
      local buf = open_pipeline(vim.fn.getcwd(), "branch.dot", BRANCH)
      H.eq({}, errors(buf))
    end,
  },
  {
    "Outline order",
    function()
      local g = attractor().parse(
        "digraph G { start [shape=Mdiamond] exit [shape=Msquare] start -> plan -> implement -> exit }"
      )
      local lines = require("tether.features.attractor.internal.outline").lines(g)
      local ids = vim.tbl_map(function(l)
        return l:match("^%s*%d+%.%s+(%S+)")
      end, lines)
      H.eq({ "start", "plan", "implement", "exit" }, ids)
    end,
  },
  {
    "Completed and failed nodes",
    function()
      local dir = H.repo("jj", {})
      local runs = H.tmpdir("run")
      H.write(runs .. "/checkpoint.json", { vim.json.encode({ completed_nodes = { "start" } }) })
      H.write(runs .. "/plan/status.json", { vim.json.encode({ status = "SUCCESS" }) })
      H.write(runs .. "/plan/prompt.md", { "plan it" })
      H.write(runs .. "/implement/status.json", { vim.json.encode({ status = "FAIL" }) })
      H.setup()
      local buf = open_pipeline(dir, "p.dot", LINEAR)
      vim.cmd("Tether attractor run " .. runs)
      local marks = status_text(buf)
      H.contains(marks, "✓ success")
      H.contains(marks, "✗ fail")
      local r = attractor().current_run()
      H.eq("success", r.statuses.plan)
      H.eq("fail", r.statuses.implement)
      H.eq({ runs .. "/plan/prompt.md" }, require("tether.features.attractor.internal.run").stage_files("plan"))
    end,
  },
  {
    "Stage started from a spec server",
    function()
      local dir = H.repo("jj", {})
      local curl = curl_stub(sse("StageStarted", { node_id = "plan", name = "plan", index = 1 }))
      H.setup({ attractor = { curl = curl } })
      local buf = open_pipeline(dir, "p.dot", LINEAR)
      vim.cmd("Tether attractor run http://localhost:9 p1")
      H.ok(H.wait(function()
        return attractor().current_run().statuses.plan == "running"
      end))
      H.contains(status_text(buf), "running")
    end,
  },
  {
    "Fabro stream updates nodes",
    function()
      local dir = H.repo("jj", {})
      local lines = {}
      vim.list_extend(lines, petri(1, "visit.started", "plan"))
      vim.list_extend(lines, petri(1, "visit.started", "plan"))
      vim.list_extend(lines, petri(2, "step.finished", "plan"))
      vim.list_extend(lines, petri(3, "run.finished"))
      local curl = curl_stub(lines)
      H.setup({ attractor = { curl = curl, fabro_url = "http://fabro.test" } })
      local buf = open_pipeline(dir, "w.fabro", LINEAR)
      vim.cmd("Tether attractor run fabro:" .. RUN_ID)
      H.ok(H.wait(function()
        local r = attractor().current_run()
        return r.done ~= nil
      end))
      H.eq("success", attractor().current_run().statuses.plan)
      H.contains(status_text(buf), "✓ success")
      require("tether").cockpit()
      require("tether.ui.cockpit").render()
      local cockpit = vim.api.nvim_buf_get_lines(vim.fn.bufnr("tether://cockpit"), 0, -1, false)
      H.contains(cockpit, "Pipeline")
      H.contains(cockpit, "fabro " .. RUN_ID)
    end,
  },
  {
    "Fabro stream resumes after a drop",
    function()
      H.repo("jj", {})
      local dir = H.tmpdir("resume")
      H.write(dir .. "/first", petri(1, "visit.started", "plan"))
      local second = {}
      vim.list_extend(second, petri(1, "visit.started", "plan"))
      vim.list_extend(second, petri(2, "step.finished", "plan"))
      vim.list_extend(second, petri(3, "run.finished"))
      H.write(dir .. "/second", second)
      local curl = H.script(
        "curl",
        ([[
case "$*" in
  *after=1*) echo "$*" >>'%s/urls'; cat '%s/second' ;;
  *" -N "*) echo "$*" >>'%s/urls'; cat '%s/first' ;;
esac
]]):format(dir, dir, dir, dir)
      )
      local fabro = require("tether.features.attractor.internal.backend.fabro")
      local delay = fabro.RECONNECT_MS
      fabro.RECONNECT_MS = 10
      H.setup({ attractor = { curl = curl, fabro_url = "http://fabro.test" } })
      vim.cmd("Tether attractor run fabro:" .. RUN_ID)
      local done = H.wait(function()
        return attractor().current_run().done ~= nil
      end)
      fabro.RECONNECT_MS = delay
      H.ok(done, "run finished after reconnecting")
      H.eq("success", attractor().current_run().statuses.plan)
      H.eq(2, #H.read(dir .. "/urls"))
    end,
  },
  {
    "Fabro server from settings",
    function()
      local home = H.tmpdir("home")
      H.write(home .. "/.fabro/settings.toml", {
        "[cli.output]",
        'format = "text"',
        "",
        "[cli.target]",
        'type = "http"',
        'url = "http://fabro.example:9000/"',
      })
      local old = vim.env.HOME
      vim.env.HOME = home
      local ok, err = pcall(function()
        H.repo("jj", {})
        H.setup()
        local target = require("tether.features.attractor.internal.run").parse_target({ RUN_ID })
        H.eq("fabro", target.backend)
        H.eq("http://fabro.example:9000", target.url)
      end)
      vim.env.HOME = old
      assert(ok, err)
    end,
  },
  {
    "Spec answer",
    function()
      H.repo("jj", {})
      local curl, log = curl_stub({}, {
        {
          id = "q1",
          text = "Review changes",
          type = "MULTIPLE_CHOICE",
          options = { { key = "A", label = "Approve" }, { key = "F", label = "Fix" } },
        },
      })
      H.setup({ attractor = { curl = curl } })
      vim.cmd("Tether attractor run http://srv p1")
      H.select(function(o)
        return o.label == "Approve"
      end)
      vim.cmd("Tether attractor answer")
      H.ok(H.wait(function()
        return #posts(log) > 0
      end))
      local p = posts(log)[1]
      H.eq("http://srv/pipelines/p1/questions/q1/answer", p.url)
      H.eq("Approve", p.body.value)
    end,
  },
  {
    "Fabro answer",
    function()
      H.repo("jj", {})
      local curl, log = curl_stub(petri(1, "run.finished"), {
        {
          id = "q-001",
          text = "Ship it?",
          question_type = "multiple_choice",
          options = { { key = "A", label = "Approve" }, { key = "R", label = "Revise" } },
        },
      })
      H.setup({ attractor = { curl = curl, fabro_url = "http://fabro.test" } })
      vim.cmd("Tether attractor run fabro:" .. RUN_ID)
      H.select(function(o)
        return o.key == "A"
      end)
      vim.cmd("Tether attractor answer")
      H.ok(H.wait(function()
        return #posts(log) > 0
      end))
      local p = posts(log)[1]
      H.eq("http://fabro.test/api/v1/runs/" .. RUN_ID .. "/questions/q-001/answer", p.url)
      H.eq({ kind = "selected", option_key = "A" }, p.body)
    end,
  },
  {
    "Fabro yes or no",
    function()
      H.repo("jj", {})
      local curl, log = curl_stub(petri(1, "run.finished"), {
        { id = "q-002", text = "Deploy?", question_type = "yes_no", options = {} },
      })
      H.setup({ attractor = { curl = curl, fabro_url = "http://fabro.test" } })
      vim.cmd("Tether attractor run fabro:" .. RUN_ID)
      H.select(function(o)
        return o == "Yes"
      end)
      vim.cmd("Tether attractor answer")
      H.ok(H.wait(function()
        return #posts(log) > 0
      end))
      H.eq({ kind = "yes" }, posts(log)[1].body)
    end,
  },
  {
    "Launch attaches",
    function()
      local dir = H.repo("jj", {})
      local fabro = H.script(
        "fabro",
        ([[
case "$1" in
  run) echo "Started run %s" ;;
  validate) exit 0 ;;
esac
]]):format(RUN_ID)
      )
      local curl = curl_stub(petri(1, "run.finished"))
      H.setup({ attractor = { curl = curl, fabro = fabro, fabro_url = "http://fabro.test" } })
      open_pipeline(dir, "w.fabro", LINEAR)
      vim.cmd("Tether attractor launch")
      H.ok(H.wait(function()
        local r = attractor().current_run()
        return r and r.id == RUN_ID
      end))
      H.eq("fabro", attractor().current_run().backend)
    end,
  },
  {
    "Review a Fabro run",
    function()
      local dir = H.repo("git", { ["a.txt"] = { "a" } })
      local branch = "fabro/run/" .. RUN_ID
      H.sh({ "git", "checkout", "-q", "-b", branch }, { cwd = dir })
      H.write(dir .. "/a.txt", { "from the run" })
      H.sh({ "git", "commit", "-qam", "fabro(" .. RUN_ID .. "): plan (success)" }, { cwd = dir })
      H.sh({ "git", "checkout", "-q", "-" }, { cwd = dir })
      H.setup()
      vim.cmd("Tether attractor review " .. RUN_ID)
      local lines = H.buf_lines(0)
      H.contains(lines[1], "fabro run " .. RUN_ID)
      H.contains(lines, "+from the run")
      for i, l in ipairs(lines) do
        if l == "+from the run" then
          vim.api.nvim_win_set_cursor(0, { i, 0 })
        end
      end
      vim.api.nvim_feedkeys("x", "xt", false)
      H.eq({ "a" }, H.read(dir .. "/a.txt"))
      H.contains(H.note_text(), "read-only")
    end,
  },
}
