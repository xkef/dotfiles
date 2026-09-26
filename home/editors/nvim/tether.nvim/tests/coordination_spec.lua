local H = require("helpers")

local function claimed_by(path)
  local names = {}
  for _, c in ipairs(require("tether.coord").claimed(path)) do
    names[c.agent] = true
  end
  return vim.tbl_keys(names)
end

local function warnings()
  local out = {}
  for _, n in ipairs(H.notes) do
    if n.level == vim.log.levels.WARN then
      table.insert(out, n.msg)
    end
  end
  return out
end

return {
  {
    "Claim a glob",
    function()
      local dir = H.tmpdir("repo")
      H.trail({ "claim", "pi", "src/*" }, { cwd = dir })
      local r = H.records()[1]
      H.eq("claim", r[2])
      H.eq(dir .. "/src/*", r[7])
    end,
  },
  {
    "Claim during a turn",
    function()
      local dir = H.repo("jj", { ["a.lua"] = { "a" } })
      H.trail({ "turn", "claude" }, { cwd = dir })
      H.trail({ "edit", "claude", "a.lua" }, { cwd = dir })
      H.setup()
      H.eq({ "claude" }, claimed_by(dir .. "/a.lua"))
    end,
  },
  {
    "Claim ends with the turn",
    function()
      local dir = H.repo("jj", { ["a.lua"] = { "a" } })
      H.trail({ "turn", "claude" }, { cwd = dir })
      H.trail({ "edit", "claude", "a.lua" }, { cwd = dir })
      H.trail({ "stop", "claude" }, { cwd = dir })
      H.setup()
      H.eq({}, claimed_by(dir .. "/a.lua"))
    end,
  },
  {
    "Glob claim",
    function()
      local dir = H.repo("jj", {})
      H.trail({ "claim", "pi", "src/parser/*" }, { cwd = dir })
      H.setup()
      H.eq({ "pi" }, claimed_by(dir .. "/src/parser/lexer.lua"))
      H.eq({}, claimed_by(dir .. "/src/other.lua"))
    end,
  },
  {
    "Release",
    function()
      local dir = H.repo("jj", {})
      H.trail({ "claim", "pi", "src/parser/*" }, { cwd = dir })
      H.trail({ "release", "pi" }, { cwd = dir })
      H.setup()
      H.eq({}, claimed_by(dir .. "/src/parser/lexer.lua"))
    end,
  },
  {
    "Claim expires",
    function()
      local dir = H.repo("jj", {})
      H.trail({ "claim", "pi", "a.lua" }, { cwd = dir })
      H.setup({ coord = { claim_ttl = -1 } })
      H.eq({}, claimed_by(dir .. "/a.lua"))
    end,
  },
  {
    "Claim ends when the pane closes",
    function()
      local dir = H.repo("jj", {})
      H.trail({ "claim", "pi", "a.lua" }, { cwd = dir, env = { WEZTERM_PANE = "9" } })
      H.setup({ agent_state = H.agents({ { "wezterm-3", "claude", "idle", "-", "1", dir, "-" } }) })
      H.eq({}, claimed_by(dir .. "/a.lua"))
    end,
  },
  {
    "Marker on a claimed buffer",
    function()
      local dir = H.repo("jj", { ["a.lua"] = { "a" } })
      H.setup()
      vim.cmd("edit " .. dir .. "/a.lua")
      H.trail({ "turn", "claude" }, { cwd = dir })
      H.trail({ "edit", "claude", "a.lua" }, { cwd = dir })
      H.poll()
      require("tether.coord").mark_all()
      H.contains(H.virt_text(0), "claude")
    end,
  },
  {
    "Two agents on one file",
    function()
      local dir = H.repo("jj", { ["a.lua"] = { "a" } })
      H.setup()
      local fired
      vim.api.nvim_create_autocmd("User", {
        pattern = "TetherConflict",
        once = true,
        callback = function(args)
          fired = args.data
        end,
      })
      H.trail({ "turn", "claude" }, { cwd = dir })
      H.trail({ "edit", "claude", "a.lua" }, { cwd = dir })
      H.trail({ "turn", "pi" }, { cwd = dir })
      H.trail({ "edit", "pi", "a.lua" }, { cwd = dir })
      H.poll()
      local w = warnings()
      H.eq(1, #w)
      H.contains(w[1], "pi edited a.lua")
      H.contains(w[1], "claude")
      H.eq("agents", fired and fired.kind)
    end,
  },
  {
    "Editing a claimed file",
    function()
      local dir = H.repo("jj", { ["a.lua"] = { "a" } })
      H.trail({ "turn", "claude" }, { cwd = dir })
      H.trail({ "edit", "claude", "a.lua" }, { cwd = dir })
      H.setup()
      vim.cmd("edit " .. dir .. "/a.lua")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { "mine" })
      vim.api.nvim_exec_autocmds("TextChanged", { buffer = 0 })
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { "mine again" })
      vim.api.nvim_exec_autocmds("TextChanged", { buffer = 0 })
      local w = warnings()
      H.eq(1, #w)
      H.contains(w[1], "claude is working on")
    end,
  },
  {
    "Agent writes under unsaved edits",
    function()
      local dir = H.repo("jj", { ["a.lua"] = { "a" } })
      H.setup()
      vim.cmd("edit " .. dir .. "/a.lua")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { "mine" })
      H.write(dir .. "/a.lua", { "agent" })
      H.trail({ "edit", "pi", "a.lua" }, { cwd = dir })
      H.poll()
      H.eq({ "mine" }, H.buf_lines(0))
      H.contains(warnings()[1], "pi wrote")
    end,
  },
  {
    "Agent in a second workspace",
    function()
      local dir = H.repo("jj", { ["a.lua"] = { "a" } })
      local ws = dir .. "-feat"
      H.sh({ "jj", "workspace", "add", "--name", "feat", ws }, { cwd = dir })
      H.setup()
      local repo = require("tether").repo()
      H.eq("feat", require("tether.coord").workspace_of(repo, { cwd = ws }))
      H.eq("default", require("tether.coord").workspace_of(repo, { cwd = dir }))
      H.eq(true, require("tether.vcs").same_repo(repo, ws))
    end,
  },
  {
    "Workspace on the row",
    function()
      local dir = H.repo("jj", { ["a.lua"] = { "a" } })
      local ws = dir .. "-feat"
      H.sh({ "jj", "workspace", "add", "--name", "feat", ws }, { cwd = dir })
      H.setup({ agent_state = H.agents({ { "wezterm-5", "pi", "busy", "-", "1", ws, "-" } }) })
      require("tether").cockpit()
      require("tether.cockpit").render()
      local lines
      for _, w in ipairs(vim.api.nvim_list_wins()) do
        local b = vim.api.nvim_win_get_buf(w)
        if vim.bo[b].filetype == "tether-cockpit" then
          lines = H.buf_lines(b)
        end
      end
      H.contains(lines, "pi")
      H.contains(lines, "[feat]")
    end,
  },
  {
    "Review a workspace against trunk",
    function()
      local dir = H.repo("jj", { ["a.lua"] = { "a" } })
      local ws = dir .. "-feat"
      H.sh({ "jj", "workspace", "add", "--name", "feat", ws }, { cwd = dir })
      H.write(ws .. "/a.lua", { "feature" })
      H.sh({ "jj", "st" }, { cwd = ws })
      H.setup()
      local buf = require("tether").review("workspace", { workspace = "feat" })
      H.contains(H.buf_lines(buf)[1], "workspace feat")
      H.contains(H.buf_lines(buf), "+feature")
    end,
  },
  {
    "Reject refuses in a workspace review",
    function()
      local dir = H.repo("jj", { ["a.lua"] = { "a" } })
      local ws = dir .. "-feat"
      H.sh({ "jj", "workspace", "add", "--name", "feat", ws }, { cwd = dir })
      H.write(ws .. "/a.lua", { "feature" })
      H.sh({ "jj", "st" }, { cwd = ws })
      H.setup()
      vim.cmd("Tether review workspace feat")
      local lines = H.buf_lines(0)
      for i, l in ipairs(lines) do
        if l == "+feature" then
          vim.api.nvim_win_set_cursor(0, { i, 0 })
        end
      end
      vim.api.nvim_feedkeys("x", "xt", false)
      H.eq({ "feature" }, H.read(ws .. "/a.lua"))
      H.eq({ "a" }, H.read(dir .. "/a.lua"))
      H.contains(H.note_text(), "another workspace")
    end,
  },
  {
    "Add a workspace",
    function()
      local dir = H.repo("jj", { ["a.lua"] = { "a" } })
      H.setup()
      local path = require("tether.coord").add_workspace(require("tether").repo(), "agent2")
      H.eq(dir .. "-agent2", path)
      H.eq(1, vim.fn.isdirectory(path .. "/.jj"))
    end,
  },
}
