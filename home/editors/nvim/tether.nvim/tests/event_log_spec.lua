local H = require("helpers")

return {
  {
    "Edit event with a line",
    function()
      local dir = H.tmpdir("repo")
      H.trail({ "edit", "claude", "src/a.lua", "12" }, { cwd = dir, env = { WEZTERM_PANE = "7" } })
      local r = H.records()[1]
      H.eq(10, #r)
      H.eq("edit", r[2])
      H.eq("claude", r[3])
      H.eq("7", r[5])
      H.eq(dir, r[6])
      H.eq(dir .. "/src/a.lua", r[7])
      H.eq("12", r[8])
    end,
  },
  {
    "Value with a tab",
    function()
      H.trail({ "turn", "pi", "fix\tparser" }, { cwd = H.tmpdir("plain") })
      local r = H.records()[1]
      H.eq("fix parser", r[10])
      H.eq("-", r[9], "no VCS outside a repository")
    end,
  },
  {
    "Log path",
    function()
      local out = H.sh({ vim.fs.joinpath(H.root, "bin", "agent-trail"), "path" }, { env = { XDG_STATE_HOME = "/s" } })
      H.eq("/s/agents/trail.log\n", out)
    end,
  },
  {
    "Claude hook input",
    function()
      local payload = vim.json.encode({
        hook_event_name = "PostToolUse",
        tool_name = "Edit",
        session_id = "s1",
        cwd = "/r",
        tool_input = { file_path = "/r/x.lua" },
      })
      H.trail({ "hook", "claude" }, { stdin = payload })
      local r = H.records()[1]
      H.eq({ "edit", "claude", "s1", "/r/x.lua" }, { r[2], r[3], r[4], r[7] })
    end,
  },
  {
    "Claude prompt starts a turn",
    function()
      local prompt = "please refactor the parser module so it streams tokens\nand keeps line numbers everywhere"
      local payload = vim.json.encode({
        hook_event_name = "UserPromptSubmit",
        session_id = "s1",
        cwd = H.tmpdir("plain"),
        prompt = prompt,
      })
      H.trail({ "hook", "claude" }, { stdin = payload })
      local r = H.records()[1]
      H.eq("turn", r[2])
      H.eq(prompt:gsub("\n", " "):sub(1, 60), r[10])
    end,
  },
  {
    "Oversized log",
    function()
      local log = H.log_file()
      vim.fn.mkdir(vim.fs.dirname(log), "p")
      local big = {}
      for i = 1, 3000 do
        big[i] = string.rep("x", 100)
      end
      vim.fn.writefile(big, log)
      H.trail({ "show", "a.lua" })
      H.eq(3000, #H.read(log .. ".1"))
      H.eq(1, #H.read(log))
    end,
  },
  {
    "Appended event reaches subscribers",
    function()
      H.setup()
      local got = {}
      require("tether.core.events").subscribe(function(ev)
        table.insert(got, ev)
      end)
      H.trail({ "edit", "pi", "a.lua", "3" })
      H.ok(H.wait(function()
        return #got > 0
      end))
      H.eq("number", type(got[1].epoch))
      H.eq(3, got[1].line)
      H.eq(nil, got[1].replay)
    end,
  },
  {
    "Rotation while running",
    function()
      H.setup()
      local got = {}
      require("tether.core.events").subscribe(function(ev)
        table.insert(got, ev.kind .. ":" .. (ev.agent or ""))
      end)
      H.trail({ "edit", "a", "x.lua" })
      H.poll()
      local log = H.log_file()
      vim.uv.fs_rename(log, log .. ".1")
      H.trail({ "edit", "b", "y.lua" })
      H.poll()
      H.wait(function()
        return false
      end, 50)
      H.poll()
      H.eq({ "edit:a", "edit:b" }, got)
    end,
  },
  {
    "Turns survive a restart",
    function()
      local dir = H.repo("jj", { ["a.txt"] = { "a" } })
      H.trail({ "turn", "claude", "work" }, { cwd = dir })
      H.trail({ "stop", "claude" }, { cwd = dir })
      H.setup()
      local list = require("tether.core.turns").list(dir)
      H.eq(1, #list)
      H.eq(false, require("tether.core.turns").running(list[1]))
    end,
  },
}
