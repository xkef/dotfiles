local H = require("helpers")

local function finish_turn(dir, file)
  H.trail({ "turn", "claude", "work" }, { cwd = dir })
  H.write(dir .. "/" .. file, { "changed" })
  H.trail({ "stop", "claude" }, { cwd = dir })
  H.poll()
end

return {
  {
    "Register a picker source",
    function()
      H.repo("jj", {})
      H.setup()
      local api = require("tether.api")
      local ran
      api.register.source({
        name = "demo",
        desc = "Demo",
        items = function()
          return {
            {
              text = "one",
              action = function()
                ran = true
              end,
            },
          }
        end,
      })
      H.select(function(it)
        return it.text == "one"
      end)
      vim.cmd("Tether pick demo")
      H.eq(true, ran)
    end,
  },
  {
    "Register a cockpit section",
    function()
      H.repo("jj", {})
      H.setup()
      require("tether.api").register.section({
        name = "Notes",
        order = 50,
        rows = function()
          return { { text = "remember the milk" } }
        end,
      })
      require("tether").cockpit()
      local lines = vim.api.nvim_buf_get_lines(vim.fn.bufnr("tether://cockpit"), 0, -1, false)
      H.contains(lines, "Notes")
      H.contains(lines, "remember the milk")
    end,
  },
  {
    "Register a review header",
    function()
      local dir = H.repo("jj", { ["a.txt"] = { "a" } })
      H.trail({ "turn", "claude" }, { cwd = dir })
      H.write(dir .. "/a.txt", { "b" })
      H.trail({ "stop", "claude" }, { cwd = dir })
      H.setup()
      require("tether.api").register.review_header(function()
        return "extra line"
      end)
      local buf = require("tether").review()
      H.contains(H.buf_lines(buf), "extra line")
    end,
  },
  {
    "Register a command",
    function()
      H.repo("jj", {})
      H.setup()
      local got
      require("tether.api").register.command("hello", {
        run = function(args)
          got = args
        end,
        complete = { "world" },
      })
      vim.cmd("Tether hello a b")
      H.eq({ "a", "b" }, got)
      H.contains(require("tether").completion("", "Tether "), "hello")
      H.eq({ "world" }, require("tether").completion("", "Tether hello "))
    end,
  },
  {
    "Subscribe to finished turns",
    function()
      local dir = H.repo("jj", { ["a.txt"] = { "a" } })
      H.setup()
      local got
      require("tether").on("stop", function(data)
        got = data
      end)
      finish_turn(dir, "a.txt")
      H.ok(got, "stop delivered")
      H.eq("claude", got.turn.agent)
      H.eq("a.txt", got.files[1].path)
    end,
  },
  {
    "Unsubscribe",
    function()
      local dir = H.repo("jj", { ["a.txt"] = { "a" }, ["b.txt"] = { "b" } })
      H.setup()
      local calls = 0
      local off = require("tether.api").on("stop", function()
        calls = calls + 1
      end)
      finish_turn(dir, "a.txt")
      off()
      finish_turn(dir, "b.txt")
      H.eq(1, calls)
    end,
  },
  {
    "Turn snapshots are copies",
    function()
      local dir = H.repo("jj", {})
      H.trail({ "turn", "claude", "original" }, { cwd = dir })
      H.setup()
      local tether = require("tether")
      tether.turns()[1].summary = "changed"
      H.eq("original", tether.turns()[1].summary)
    end,
  },
}
