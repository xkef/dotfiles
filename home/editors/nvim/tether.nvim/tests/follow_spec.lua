local H = require("helpers")

local long = {}
for i = 1, 40 do
  long[i] = "line " .. i
end

local function agent_edit(dir, rel, lines, line)
  H.write(dir .. "/" .. rel, lines)
  local args = { "edit", "claude", rel }
  if line then
    table.insert(args, tostring(line))
  end
  H.trail(args, { cwd = dir })
  H.poll()
end

return {
  {
    "Buffer reloads",
    function()
      local dir = H.repo("jj", { ["a.txt"] = { "old" } })
      H.setup()
      vim.cmd("edit " .. dir .. "/a.txt")
      agent_edit(dir, "a.txt", { "new" })
      H.eq({ "new" }, H.buf_lines(0))
    end,
  },
  {
    "Unsaved changes are kept",
    function()
      local dir = H.repo("jj", { ["a.txt"] = { "old" } })
      H.setup()
      vim.cmd("edit " .. dir .. "/a.txt")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { "mine" })
      agent_edit(dir, "a.txt", { "agent" })
      H.eq({ "mine" }, H.buf_lines(0))
    end,
  },
  {
    "Jump to the changed line",
    function()
      local dir = H.repo("jj", { ["a.txt"] = long, ["other.txt"] = { "x" } })
      H.trail({ "turn", "claude" }, { cwd = dir })
      H.setup()
      vim.cmd("edit " .. dir .. "/other.txt")
      require("tether").follow(true)
      local changed = vim.deepcopy(long)
      changed[20] = "agent was here"
      agent_edit(dir, "a.txt", changed)
      H.eq(dir .. "/a.txt", vim.api.nvim_buf_get_name(0))
      H.eq(20, vim.fn.line("."))
    end,
  },
  {
    "Line from the event",
    function()
      local dir = H.repo("jj", { ["a.txt"] = long })
      H.setup()
      require("tether").follow(true)
      agent_edit(dir, "a.txt", long, 7)
      H.eq(dir .. "/a.txt", vim.api.nvim_buf_get_name(0))
      H.eq(7, vim.fn.line("."))
    end,
  },
  {
    "Deferred during insert",
    function()
      local dir = H.repo("jj", { ["a.txt"] = long, ["b.txt"] = long })
      H.setup()
      require("tether").follow(true)
      local follow = require("tether.ui.follow")
      local get_mode = vim.api.nvim_get_mode
      vim.api.nvim_get_mode = function()
        return { mode = "i", blocking = false }
      end
      agent_edit(dir, "a.txt", long, 5)
      agent_edit(dir, "b.txt", long, 9)
      H.eq("", vim.api.nvim_buf_get_name(0), "no jump while typing")
      vim.api.nvim_get_mode = get_mode
      follow.flush()
      H.eq(dir .. "/b.txt", vim.api.nvim_buf_get_name(0))
      H.eq(9, vim.fn.line("."))
    end,
  },
  {
    "Agent points at code",
    function()
      local dir = H.repo("jj", { ["src/a.lua"] = long })
      H.setup()
      H.trail({ "show", "src/a.lua", "5" }, { cwd = dir })
      H.poll()
      H.eq(dir .. "/src/a.lua", vim.api.nvim_buf_get_name(0))
      H.eq(5, vim.fn.line("."))
    end,
  },
  {
    "Turn finished",
    function()
      local dir = H.repo("jj", { ["a.txt"] = { "a" }, ["b.txt"] = { "b" } })
      H.setup()
      H.trail({ "turn", "claude" }, { cwd = dir })
      H.write(dir .. "/a.txt", { "A" })
      H.write(dir .. "/b.txt", { "B" })
      H.trail({ "stop", "claude" }, { cwd = dir })
      H.poll()
      H.contains(H.note_text(), "claude finished: 2 files changed")
    end,
  },
  {
    "Idle editor",
    function()
      H.repo("jj", {})
      H.setup()
      H.eq("", require("tether").status())
    end,
  },
  {
    "Status shows follow and busy agents",
    function()
      local dir = H.repo("jj", {})
      H.setup({ agent_state = H.agents({ { "wezterm-3", "claude", "busy", "Edit", "1", dir, "-" } }) })
      require("tether").follow(true)
      H.eq("1 busy follow", require("tether").status())
    end,
  },
}
