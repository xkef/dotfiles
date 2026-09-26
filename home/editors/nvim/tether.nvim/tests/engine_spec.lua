local H = require("helpers")

-- A stub agent: records each call, saves the prompt, then runs
-- <behavior>/<stage>.sh when present, with $stage_dir set, inside the run's
-- working directory.
local function stub_agent()
  local dir = H.tmpdir("agent")
  local path = H.script(
    "agent",
    ([[
stage_dir=$1
prompt=$2
stage=$(basename "$stage_dir")
echo "$stage" >>'%s/calls'
printf '%%s\n' "$prompt" >'%s/prompt-'"$stage"
if [ -f '%s/'"$stage"'.sh' ]; then . '%s/'"$stage"'.sh'; fi
echo "done $stage"
]]):format(dir, dir, dir, dir)
  )
  return { path = path, dir = dir }
end

local function behave(agent, stage, body)
  H.write(vim.fs.joinpath(agent.dir, stage .. ".sh"), body)
end

local function calls(agent)
  local file = vim.fs.joinpath(agent.dir, "calls")
  return vim.fn.filereadable(file) == 1 and H.read(file) or {}
end

local function count(list, value)
  local n = 0
  for _, v in ipairs(list) do
    if v == value then
      n = n + 1
    end
  end
  return n
end

local function runner()
  return vim.fs.joinpath(H.root, "bin", "tether-run")
end

---A repository holding the pipeline, and a run directory configured for
---the stub agent.
local function setup_run(kind, pipeline, agent)
  local dir = H.repo(kind, { ["p.dot"] = vim.split(pipeline, "\n") })
  local logs = H.tmpdir("run")
  H.write(logs .. "/config.json", {
    vim.json.encode({
      attractor = {
        agent = "stub",
        agents = { stub = { agent.path, "{stage_dir}", "{prompt}" } },
        poll_ms = 50,
      },
    }),
  })
  return dir, logs
end

local function start(dir, logs, extra)
  local cmd = { runner(), "start", dir .. "/p.dot", "--logs", logs }
  vim.list_extend(cmd, extra or {})
  local out, res = H.sh(cmd, { cwd = dir, allow_fail = true })
  return res.code, out .. res.stderr
end

local function start_async(dir, logs)
  return vim.system({ runner(), "start", dir .. "/p.dot", "--logs", logs }, { cwd = dir, text = true })
end

local function checkpoint(logs)
  return vim.json.decode(table.concat(H.read(logs .. "/checkpoint.json"), "\n"))
end

local function wait_file(path)
  return H.wait(function()
    return vim.fn.filereadable(path) == 1
  end, 10000)
end

local LINEAR = [[
digraph P {
  graph [goal="a parser"]
  start [shape=Mdiamond]
  exit [shape=Msquare]
  plan [prompt="Plan $goal"]
  implement [prompt="Implement it"]
  start -> plan -> implement -> exit
}]]

local GATE = [[
digraph G {
  start [shape=Mdiamond]
  exit [shape=Msquare]
  review [shape=hexagon, label="Review the plan"]
  ship [prompt="ship"]
  fix [prompt="fix"]
  start -> review
  review -> ship [label="[A] Approve"]
  review -> fix [label="[F] Fix"]
  ship -> exit
  fix -> exit
}]]

return {
  {
    "Linear run completes",
    function()
      local agent = stub_agent()
      local dir, logs = setup_run("jj", LINEAR, agent)
      local code, out = start(dir, logs)
      H.eq(0, code, out)
      H.contains(out, "status success")
      local ckpt = checkpoint(logs)
      H.eq("success", ckpt.node_outcomes.plan)
      H.eq("success", ckpt.node_outcomes.implement)
      H.eq({ "plan", "implement" }, calls(agent))
    end,
  },
  {
    "Preferred label picks the edge",
    function()
      local agent = stub_agent()
      behave(agent, "plan", [[echo '{"status":"success","preferred_label":"Fix"}' >"$stage_dir/status.json"]])
      local dir, logs = setup_run(
        "jj",
        [[
digraph P {
  start [shape=Mdiamond]
  exit [shape=Msquare]
  plan [prompt="p"]
  ship [prompt="s"]
  fix [prompt="f"]
  start -> plan
  plan -> ship [label="Ship"]
  plan -> fix [label="Fix"]
  ship -> exit
  fix -> exit
}]],
        agent
      )
      H.eq(0, (start(dir, logs)))
      H.eq({ "plan", "fix" }, calls(agent))
    end,
  },
  {
    "Condition routes on outcome",
    function()
      local agent = stub_agent()
      local dir, logs = setup_run(
        "jj",
        [[
digraph P {
  start [shape=Mdiamond]
  exit [shape=Msquare]
  check [shape=parallelogram, tool_command="exit 1"]
  gate [shape=diamond]
  good [prompt="g"]
  bad [prompt="b"]
  start -> check
  check -> good [condition="outcome=success"]
  check -> gate [condition="outcome=fail"]
  gate -> good [condition="outcome=success"]
  gate -> bad [condition="outcome!=success"]
  good -> exit
  bad -> exit
}]],
        agent
      )
      H.eq(0, (start(dir, logs)))
      H.eq({ "bad" }, calls(agent))
    end,
  },
  {
    "Failure retries then takes the retry target",
    function()
      local agent = stub_agent()
      behave(agent, "work", "exit 1")
      local dir, logs = setup_run(
        "jj",
        [[
digraph P {
  start [shape=Mdiamond]
  exit [shape=Msquare]
  work [prompt="w", max_retries=2, retry_target=recover]
  recover [prompt="r"]
  start -> work -> exit
  recover -> exit
}]],
        agent
      )
      H.eq(0, (start(dir, logs)))
      H.eq(3, count(calls(agent), "work"))
      H.eq(1, count(calls(agent), "recover"))
    end,
  },
  {
    "Goal gate blocks exit",
    function()
      local agent = stub_agent()
      behave(
        agent,
        "check",
        ([[
if [ ! -f '%s/seen' ]; then
  touch '%s/seen'
  echo '{"status":"fail"}' >"$stage_dir/status.json"
fi]]):format(agent.dir, agent.dir)
      )
      local dir, logs = setup_run(
        "jj",
        [[
digraph P {
  start [shape=Mdiamond]
  exit [shape=Msquare]
  check [prompt="c", goal_gate=true, retry_target=fix]
  fix [prompt="f"]
  start -> check
  check -> exit [condition="outcome=fail"]
  check -> exit
  fix -> check
}]],
        agent
      )
      local code, out = start(dir, logs)
      H.eq(0, code, out)
      H.eq({ "check", "fix", "check" }, calls(agent))
    end,
  },
  {
    "Agent receives the prompt",
    function()
      local agent = stub_agent()
      local dir, logs = setup_run("jj", LINEAR, agent)
      H.eq(0, (start(dir, logs)))
      H.contains(H.read(agent.dir .. "/prompt-plan"), "Plan a parser")
      H.contains(H.read(logs .. "/plan/prompt.md"), "Plan a parser")
    end,
  },
  {
    "Tool exit code sets the outcome",
    function()
      local agent = stub_agent()
      local dir, logs = setup_run(
        "jj",
        [[
digraph P {
  start [shape=Mdiamond]
  exit [shape=Msquare]
  build [shape=parallelogram, tool_command="exit 3"]
  start -> build -> exit
}]],
        agent
      )
      local code = start(dir, logs)
      H.eq(1, code)
      local status = vim.json.decode(table.concat(H.read(logs .. "/build/status.json"), "\n"))
      H.eq("FAIL", status.status)
    end,
  },
  {
    "Answer file resumes the run",
    function()
      local agent = stub_agent()
      local dir, logs = setup_run("jj", GATE, agent)
      local proc = start_async(dir, logs)
      H.ok(wait_file(logs .. "/questions/review-1.json"), "question written")
      H.sh({ runner(), "answer", logs, "review-1", "A" })
      local res = proc:wait(20000)
      H.eq(0, res.code, res.stdout .. res.stderr)
      H.eq({ "ship" }, calls(agent))
    end,
  },
  {
    "Resume skips completed nodes",
    function()
      local agent = stub_agent()
      behave(agent, "implement", "exit 1")
      local dir, logs = setup_run("jj", LINEAR, agent)
      H.eq(1, (start(dir, logs)))
      os.remove(agent.dir .. "/implement.sh")
      local _, res = H.sh({ runner(), "resume", logs }, { cwd = dir, allow_fail = true })
      H.eq(0, res.code, res.stdout .. res.stderr)
      H.eq({ "plan", "implement", "implement" }, calls(agent))
    end,
  },
  {
    "Commit per stage in a workspace",
    function()
      local agent = stub_agent()
      behave(agent, "plan", "echo planned >plan.txt")
      behave(agent, "implement", "echo built >build.txt")
      local dir, logs = setup_run("jj", LINEAR, agent)
      local code, out = start(dir, logs, { "--workspace" })
      H.eq(0, code, out)
      local manifest = vim.json.decode(table.concat(H.read(logs .. "/manifest.json"), "\n"))
      local ws = manifest.isolation.path
      H.eq(1, vim.fn.filereadable(ws .. "/build.txt"))
      H.eq(0, vim.fn.filereadable(dir .. "/build.txt"), "main working copy unchanged")
      local log = H.sh({
        "jj",
        "--ignore-working-copy",
        "log",
        "--no-graph",
        "-r",
        manifest.isolation.base .. "::" .. manifest.isolation.name .. "@",
        "-T",
        'description ++ "\n"',
      }, { cwd = dir })
      local commits = 0
      for _ in log:gmatch("pipeline%(" .. vim.pesc(manifest.id) .. "%)") do
        commits = commits + 1
      end
      H.eq(2, commits)
    end,
  },
  {
    "Stage turns appear in tether",
    function()
      local agent = stub_agent()
      local dir, logs = setup_run("jj", LINEAR, agent)
      H.eq(0, (start(dir, logs)))
      H.setup()
      local pipeline = vim.tbl_filter(function(t)
        return t.agent == "pipeline"
      end, require("tether").turns())
      H.eq(2, #pipeline)
      H.eq(false, pipeline[1].stopped == nil)
    end,
  },
  {
    "Pending question marks the gate",
    function()
      local dir = H.repo("jj", { ["p.dot"] = vim.split(GATE, "\n") })
      local logs = H.tmpdir("run")
      H.write(
        logs .. "/questions/review-1.json",
        { vim.json.encode({ id = "review-1", text = "Review", kind = "choice", options = {}, stage = "review" }) }
      )
      H.setup({ attractor = { poll_ms = 50 } })
      vim.cmd("edit " .. dir .. "/p.dot")
      vim.cmd("Tether attractor run " .. logs)
      H.eq("waiting", require("tether.features.attractor").current_run().statuses.review)
      H.contains(H.virt_text(0), "waiting for you")
    end,
  },
  {
    "Answer an engine gate from Neovim",
    function()
      local agent = stub_agent()
      local dir, logs = setup_run("jj", GATE, agent)
      local proc = start_async(dir, logs)
      H.ok(wait_file(logs .. "/questions/review-1.json"), "question written")
      H.setup({ attractor = { poll_ms = 50 } })
      vim.cmd("edit " .. dir .. "/p.dot")
      vim.cmd("Tether attractor run " .. logs)
      H.select(function(o)
        return o.key == "A"
      end)
      vim.cmd("Tether attractor answer")
      H.ok(wait_file(logs .. "/answers/review-1.json"), "answer written")
      local res = proc:wait(20000)
      H.eq(0, res.code, res.stdout .. res.stderr)
      H.eq({ "ship" }, calls(agent))
    end,
  },
  {
    "Launch attaches the run",
    function()
      local agent = stub_agent()
      local dir = H.repo("jj", { ["p.dot"] = vim.split(LINEAR, "\n") })
      H.setup({
        attractor = { agent = "stub", agents = { stub = { agent.path, "{stage_dir}", "{prompt}" } }, poll_ms = 50 },
      })
      vim.cmd("edit " .. dir .. "/p.dot")
      vim.cmd("Tether attractor launch")
      local r = require("tether.features.attractor").current_run()
      H.ok(r and r.dir, "run attached")
      H.ok(
        H.wait(function()
          return r.statuses.implement == "success"
        end, 15000),
        "nodes reach success"
      )
      H.contains(H.virt_text(0), "✓ success")
    end,
  },
  {
    "Review a workspace run",
    function()
      local agent = stub_agent()
      behave(agent, "plan", "echo planned >>p.dot")
      local dir, logs = setup_run("jj", LINEAR, agent)
      H.eq(0, (start(dir, logs, { "--workspace" })))
      H.setup()
      vim.cmd("Tether attractor review " .. logs)
      local lines = H.buf_lines(0)
      H.contains(lines[1], "pipeline run")
      H.contains(lines, "+planned")
      for i, l in ipairs(lines) do
        if l == "+planned" then
          vim.api.nvim_win_set_cursor(0, { i, 0 })
        end
      end
      vim.api.nvim_feedkeys("x", "xt", false)
      H.contains(H.note_text(), "read-only")
    end,
  },
}
