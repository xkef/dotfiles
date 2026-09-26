local H = require("helpers")

local function calls(log)
  if vim.fn.filereadable(log) == 0 then
    return {}
  end
  local out, cur = {}, nil
  for _, l in ipairs(H.read(log)) do
    if l:match("^ARGS ") then
      cur = { args = l:sub(6), stdin = {} }
      table.insert(out, cur)
    elseif l == "--" then
      cur = nil
    elseif cur then
      table.insert(cur.stdin, l)
    end
  end
  return out
end

return {
  {
    "Registered source",
    function()
      H.repo("jj", {})
      H.setup()
      local tether = require("tether")
      local picked
      tether.register.source({
        name = "demo",
        desc = "Demo",
        items = function()
          return {
            {
              text = "one",
              action = function()
                picked = "one"
              end,
            },
          }
        end,
      })
      H.contains(require("tether.ui.pick").names(tether.repo()), "demo")
      H.select(function(it)
        return it.text == "one"
      end)
      require("tether").pick("demo")
      H.eq("one", picked)
    end,
  },
  {
    "Trail order",
    function()
      local dir = H.repo("jj", { ["a.lua"] = { "a" }, ["b.lua"] = { "b" } })
      H.trail({ "edit", "claude", "a.lua" }, { cwd = dir })
      H.trail({ "edit", "claude", "b.lua" }, { cwd = dir })
      H.setup()
      local items = require("tether.core.registry").get_source("trail").items(require("tether").repo())
      H.contains(items[1].text, "b.lua")
      H.contains(items[2].text, "a.lua")
    end,
  },
  {
    "Turn opens its review",
    function()
      local dir = H.repo("jj", { ["a.txt"] = { "a" } })
      H.trail({ "turn", "claude", "first" }, { cwd = dir })
      H.write(dir .. "/a.txt", { "A" })
      H.trail({ "stop", "claude" }, { cwd = dir })
      H.trail({ "turn", "claude", "second" }, { cwd = dir })
      H.trail({ "stop", "claude" }, { cwd = dir })
      H.setup()
      H.select(function(it)
        return it.text:find("first", 1, true)
      end)
      require("tether").pick("turns")
      H.eq("tether://review", vim.api.nvim_buf_get_name(0))
      H.contains(H.buf_lines(0)[1], "turn 1")
      H.contains(H.buf_lines(0), "+A")
    end,
  },
  {
    "Without snacks",
    function()
      local dir = H.repo("jj", { ["a.lua"] = { "a" } })
      H.trail({ "edit", "claude", "a.lua", "1" }, { cwd = dir })
      H.setup()
      H.select(function(it)
        return it.file ~= nil
      end)
      require("tether").pick("trail")
      H.eq(1, #H.last_select)
      H.eq(dir .. "/a.lua", vim.api.nvim_buf_get_name(0))
    end,
  },
  {
    "One agent",
    function()
      local dir = H.repo("jj", { ["a.lua"] = { "a" } })
      local wez, log = H.wezterm()
      H.setup({
        agent_state = H.agents({ { "wezterm-4", "claude", "idle", "-", "1", dir, "-" } }),
        send = { wezterm = wez },
      })
      vim.cmd("edit " .. dir .. "/a.lua")
      require("tether").send()
      local c = calls(log)
      H.eq(1, #c)
      H.contains(c[1].args, "send-text --pane-id 4")
      H.contains(c[1].stdin, "@a.lua")
    end,
  },
  {
    "No agent",
    function()
      local dir = H.repo("jj", { ["a.lua"] = { "a" } })
      H.setup({ agent_state = H.agents({ { "wezterm-4", "claude", "idle", "-", "1", "/elsewhere", "-" } }) })
      vim.cmd("edit " .. dir .. "/a.lua")
      require("tether").send()
      H.eq("@a.lua ", vim.fn.getreg('"'))
      H.contains(H.note_text(), "no agent in this repository")
    end,
  },
  {
    "Paste without submit",
    function()
      local dir = H.repo("jj", { ["a.lua"] = { "a" } })
      local wez, log = H.wezterm()
      H.setup({
        agent_state = H.agents({ { "wezterm-4", "claude", "idle", "-", "1", dir, "-" } }),
        send = { wezterm = wez },
      })
      require("tether.ui.send").text(dir, "hello")
      local c = calls(log)
      H.eq(1, #c)
      H.eq(nil, c[1].args:find("--no-paste", 1, true))
      H.eq({ "hello" }, c[1].stdin)
    end,
  },
  {
    "Batched comments",
    function()
      local dir = H.repo("jj", { ["a.lua"] = { "a", "b" } })
      local wez, log = H.wezterm()
      H.setup({
        agent_state = H.agents({ { "wezterm-4", "claude", "idle", "-", "1", dir, "-" } }),
        send = { wezterm = wez },
      })
      local review = require("tether.ui.review")
      review.add_comment(dir, dir .. "/a.lua", 2, "b", "rename this")
      review.add_comment(dir, dir .. "/a.lua", 1, "a", "add a test")
      require("tether").send()
      local c = calls(log)
      H.eq(1, #c)
      H.contains(c[1].stdin, "a.lua:1: add a test")
      H.contains(c[1].stdin, "a.lua:2: rename this")
      H.eq(0, #review.comments)
    end,
  },
  {
    "Visual selection",
    function()
      local dir = H.repo("jj", { ["src/a.lua"] = { "1", "2", "3", "4", "5", "6" } })
      H.setup()
      vim.cmd("edit " .. dir .. "/src/a.lua")
      local msg = require("tether").send({ 3, 5 })
      H.eq(1, msg:find("@src/a.lua#L3-5", 1, true))
      H.contains(msg, "3\n4\n5")
    end,
  },
}
