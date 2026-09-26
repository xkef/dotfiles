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
}
