local M = {}

---@class tether.Config
M.defaults = {
  -- Event log that agent-trail appends to. nil resolves to
  -- $XDG_STATE_HOME/agents/trail.log at setup.
  log_file = nil,
  -- Command that lists live agents (pane, agent, state, tool, epoch, cwd, task).
  agent_state = "agent-state",
  -- Key prefix for the six top-level keys. false disables the keys.
  prefix = "<leader>a",
  follow = {
    enabled = false,
    -- How long changed lines stay highlighted after a jump.
    flash_ms = 800,
    -- Follow read events too, not only edits.
    reads = false,
  },
  review = {
    -- Days a reviewed hunk stays remembered.
    keep_days = 30,
  },
  send = {
    wezterm = "wezterm",
    -- Press enter in the agent's prompt after pasting.
    submit = false,
  },
  cockpit = {
    side = "right",
    width = 46,
    -- Milliseconds between refreshes of the agent list while open.
    interval = 2000,
    trail = 8,
  },
  coord = {
    -- Seconds an explicit claim lasts without a release.
    claim_ttl = 7200,
  },
  -- Notify when an agent's turn in this repository ends.
  notify_stop = true,
  attractor = {
    curl = "curl",
    -- Agent for pipeline stages without an `agent` attribute.
    agent = "claude",
    -- Extra or replaced agent templates: name = argv with {prompt},
    -- {model}, and {stage_dir}. Built in: claude, codex, pi.
    agents = {},
    -- Milliseconds between scans of a run directory, and between checks
    -- for a human gate's answer.
    poll_ms = 1000,
  },
  sdd = {
    -- OpenSpec CLI for diagnostics; built-in checks apply without it.
    openspec = "openspec",
    send_template = "Work on task {id} of OpenSpec change {change}: {text}",
  },
}

---@type tether.Config
M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
  if not M.options.log_file then
    local state = vim.env.XDG_STATE_HOME
    if not state or state == "" then
      state = vim.fs.joinpath(vim.env.HOME or "~", ".local", "state")
    end
    M.options.log_file = vim.fs.joinpath(state, "agents", "trail.log")
  end
  return M.options
end

return M
