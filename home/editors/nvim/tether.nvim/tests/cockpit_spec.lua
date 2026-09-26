local H = require("helpers")

local function cockpit_lines()
  local cockpit = require("tether.cockpit")
  cockpit.render()
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    local b = vim.api.nvim_win_get_buf(w)
    if vim.bo[b].filetype == "tether-cockpit" then
      return H.buf_lines(b), w
    end
  end
end

return {
  {
    "Toggle",
    function()
      H.repo("jj", {})
      H.setup()
      local tether = require("tether")
      H.eq(true, tether.cockpit())
      H.eq(2, #vim.api.nvim_list_wins())
      H.eq(false, tether.cockpit())
      H.eq(1, #vim.api.nvim_list_wins())
    end,
  },
  {
    "Empty sections hidden",
    function()
      H.repo("jj", {})
      H.setup()
      require("tether").cockpit()
      local lines = cockpit_lines()
      H.eq(nil, table.concat(lines, "\n"):find("Agents", 1, true))
    end,
  },
  {
    "Agent row",
    function()
      local dir = H.repo("jj", {})
      H.setup({ agent_state = H.agents({ { "wezterm-2", "claude", "busy", "Edit", "1", dir, "fix it" } }) })
      require("tether").cockpit()
      local lines = cockpit_lines()
      H.contains(lines, "Agents")
      H.contains(lines, "claude")
      H.contains(lines, "busy")
    end,
  },
  {
    "Changed file row",
    function()
      local dir = H.repo("jj", { ["a.lua"] = { "a" } })
      H.trail({ "turn", "claude" }, { cwd = dir })
      H.write(dir .. "/a.lua", { "a", "b", "c", "d" })
      H.trail({ "stop", "claude" }, { cwd = dir })
      H.setup()
      require("tether").cockpit()
      H.contains(cockpit_lines(), "a.lua  +3 -0")
    end,
  },
  {
    "Changed file row while running",
    function()
      local dir = H.repo("jj", { ["a.lua"] = { "a" } })
      H.trail({ "turn", "claude" }, { cwd = dir })
      H.write(dir .. "/a.lua", { "a", "b" })
      H.trail({ "edit", "claude", "a.lua" }, { cwd = dir })
      H.setup()
      require("tether").cockpit()
      H.contains(cockpit_lines(), "a.lua  +1 -0")
    end,
  },
  {
    "Open from the trail",
    function()
      local dir = H.repo("jj", { ["b.lua"] = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "10" } })
      H.trail({ "edit", "claude", "b.lua", "9" }, { cwd = dir })
      H.setup()
      local main = vim.api.nvim_get_current_win()
      require("tether").cockpit()
      local lines, win = cockpit_lines()
      for i, l in ipairs(lines) do
        if l:find("b.lua:9", 1, true) then
          vim.api.nvim_win_set_cursor(win, { i, 0 })
        end
      end
      require("tether.cockpit").act("<CR>")
      H.eq(main, vim.api.nvim_get_current_win())
      H.eq(dir .. "/b.lua", vim.api.nvim_buf_get_name(0))
      H.eq(9, vim.fn.line("."))
    end,
  },
}
