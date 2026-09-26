local H = require("helpers")

local SPEC = {
  "# demo Specification",
  "",
  "## Purpose",
  "",
  "Demo capability for tests, long enough to satisfy the purpose length rule.",
  "",
  "## Requirements",
  "",
  "### Requirement: Greets",
  "",
  "The plugin SHALL greet.",
  "",
  "#### Scenario: Morning",
  "",
  "- **WHEN** it is morning",
  "- **THEN** it says good morning",
  "",
  "#### Scenario: Evening",
  "",
  "- **WHEN** it is evening",
  "- **THEN** it says good evening",
}

local TASKS = {
  "# Tasks",
  "",
  "## 1. Parser",
  "",
  "- [x] 1.1 A",
  "- [ ] 1.2 B",
  "- [ ] 1.3 C that wraps",
  "      onto a second line",
  "",
  "## 2. More",
  "",
  "- [x] 2.1 D",
  "- [ ] 2.2 E",
}

local function openspec_repo(extra)
  local files = {
    ["openspec/config.yaml"] = { "schema: spec-driven" },
    ["openspec/specs/demo/spec.md"] = SPEC,
    ["openspec/changes/add-x/proposal.md"] = { "# Proposal", "", "## Why", "", "Because.", "" },
    ["openspec/changes/add-x/tasks.md"] = TASKS,
  }
  for k, v in pairs(extra or {}) do
    files[k] = v
  end
  return H.repo("jj", files)
end

local function cockpit_lines()
  require("tether.ui.cockpit").render()
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    local b = vim.api.nvim_win_get_buf(w)
    if vim.bo[b].filetype == "tether-cockpit" then
      return H.buf_lines(b), w
    end
  end
end

local function cursor_to(win, lines, needle)
  for i, l in ipairs(lines) do
    if l:find(needle, 1, true) then
      vim.api.nvim_win_set_cursor(win, { i, 0 })
      return i
    end
  end
  error("not found: " .. needle)
end

return {
  {
    "Project without OpenSpec",
    function()
      H.repo("jj", { ["a.lua"] = { "a" } })
      H.setup({ agent_state = H.agents({}) })
      require("tether").cockpit()
      local lines = cockpit_lines()
      H.eq(nil, table.concat(lines, "\n"):find("Tasks", 1, true))
      local names = require("tether.ui.pick").names(require("tether").repo())
      H.eq(false, vim.tbl_contains(names, "specs"))
      H.eq(false, vim.tbl_contains(names, "changes"))
    end,
  },
  {
    "Requirement with scenarios",
    function()
      local spec = require("tether.features.sdd.internal.parse").spec_lines(SPEC)
      H.eq(1, #spec.requirements)
      H.eq("Greets", spec.requirements[1].name)
      H.eq(9, spec.requirements[1].line)
      H.eq({ { name = "Morning", line = 13 }, { name = "Evening", line = 18 } }, spec.requirements[1].scenarios)
      H.eq(true, spec.requirements[1].normative)
    end,
  },
  {
    "Task list",
    function()
      local tasks = require("tether.features.sdd.internal.parse").tasks_lines({ "- [x] 1.1 A", "- [ ] 1.2 B" })
      H.eq(2, #tasks)
      H.eq({ "1.1", "A", true, 1 }, { tasks[1].id, tasks[1].text, tasks[1].done, tasks[1].line })
      H.eq({ "1.2", false }, { tasks[2].id, tasks[2].done })
      local wrapped = require("tether.features.sdd.internal.parse").tasks_lines(TASKS)
      H.eq("C that wraps onto a second line", wrapped[3].text)
    end,
  },
  {
    "Missing scenario",
    function()
      local dir = openspec_repo()
      H.setup({ sdd = { openspec = "/nonexistent/openspec" } })
      vim.cmd("edit " .. dir .. "/openspec/specs/demo/spec.md")
      vim.api.nvim_buf_set_lines(0, -1, -1, false, { "", "### Requirement: Bare", "", "The plugin SHALL x." })
      vim.cmd("write")
      local diags = vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
      H.eq(1, #diags)
      H.eq(#SPEC + 1, diags[1].lnum)
      H.contains(diags[1].message, "no scenario")
    end,
  },
  {
    "Scenario with three hashes",
    function()
      local diags = require("tether.features.sdd").check({
        "## Requirements",
        "### Requirement: X",
        "The plugin does x.",
        "### Scenario: wrong",
      })
      local messages = vim.tbl_map(function(d)
        return d.message
      end, diags)
      H.contains(messages, "no scenario")
      H.contains(messages, "SHALL or MUST")
      H.contains(messages, "four hashes")
    end,
  },
  {
    "Diagnostics from the OpenSpec CLI",
    function()
      local dir = openspec_repo()
      local json = vim.json.encode({
        items = {
          {
            id = "demo",
            issues = {
              { level = "ERROR", path = "requirements.0.scenarios", message = "Requirement must have a scenario" },
            },
          },
        },
      })
      local data = vim.fs.joinpath(H.tmpdir("os"), "out.json")
      H.write(data, { json })
      local cli = H.script("openspec", ("cat '%s'\n"):format(data))
      H.setup({ sdd = { openspec = cli } })
      vim.cmd("edit " .. dir .. "/openspec/specs/demo/spec.md")
      local got
      require("tether.features.sdd").diagnose(0, function(d)
        got = d
      end)
      H.ok(H.wait(function()
        return got ~= nil
      end))
      H.eq(1, #got)
      H.eq(8, got[1].lnum, "on the requirement heading")
      H.eq(vim.diagnostic.severity.ERROR, got[1].severity)
    end,
  },
  {
    "Jump to a requirement",
    function()
      local dir = openspec_repo()
      H.setup()
      H.select(function(it)
        return it.text:find("Greets", 1, true)
      end)
      require("tether").pick("requirements")
      H.eq(dir .. "/openspec/specs/demo/spec.md", vim.api.nvim_buf_get_name(0))
      H.eq(9, vim.fn.line("."))
    end,
  },
  {
    "Progress",
    function()
      openspec_repo()
      H.setup()
      require("tether").cockpit()
      H.contains(cockpit_lines(), "add-x  2/5")
    end,
  },
  {
    "Toggle a task",
    function()
      local dir = openspec_repo()
      H.setup()
      require("tether").cockpit()
      local cockpit = require("tether.ui.cockpit")
      local lines, win = cockpit_lines()
      cursor_to(win, lines, "  add-x  ")
      cockpit.act("<Tab>")
      lines = cockpit_lines()
      cursor_to(win, lines, "1.2 B")
      cockpit.act("x")
      H.eq("- [x] 1.2 B", H.read(dir .. "/openspec/changes/add-x/tasks.md")[6])
      H.contains(cockpit_lines(), "add-x  3/5")
    end,
  },
  {
    "Send a task",
    function()
      local dir = openspec_repo()
      local wez, log = H.wezterm()
      H.setup({
        agent_state = H.agents({ { "wezterm-4", "claude", "idle", "-", "1", dir, "-" } }),
        send = { wezterm = wez },
      })
      require("tether").cockpit()
      local cockpit = require("tether.ui.cockpit")
      local lines, win = cockpit_lines()
      cursor_to(win, lines, "  add-x  ")
      cockpit.act("<Tab>")
      lines = cockpit_lines()
      cursor_to(win, lines, "1.2 B")
      cockpit.act("s")
      H.contains(H.read(log), "Work on task 1.2 of OpenSpec change add-x: B")
    end,
  },
  {
    "Task checked by an agent",
    function()
      local dir = openspec_repo()
      H.setup()
      H.trail({ "turn", "claude", "do 1.2" }, { cwd = dir })
      local tasks = vim.deepcopy(TASKS)
      tasks[6] = "- [x] 1.2 B"
      H.write(dir .. "/openspec/changes/add-x/tasks.md", tasks)
      H.trail({ "stop", "claude" }, { cwd = dir })
      H.poll()
      local buf = require("tether").review()
      H.contains(H.buf_lines(buf), "Change: add-x · checked 1.2")
      vim.cmd("tabclose")
      require("tether").cockpit()
      local cockpit = require("tether.ui.cockpit")
      local lines, win = cockpit_lines()
      cursor_to(win, lines, "  add-x  ")
      cockpit.act("<Tab>")
      H.contains(cockpit_lines(), "[x] 1.2 B  ← claude")
    end,
  },
}
