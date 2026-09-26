local M = {}

function M.check()
  local health = vim.health
  local config = require("tether.config").options

  health.start("tether: core")
  if vim.fn.has("nvim-0.11") == 1 then
    health.ok("Neovim " .. tostring(vim.version()))
  else
    health.error("Neovim 0.11 or newer required")
  end
  for _, tool in ipairs({ "jj", "git" }) do
    if vim.fn.executable(tool) == 1 then
      health.ok(tool .. " found")
    else
      health.warn(tool .. " not found")
    end
  end
  local repo = require("tether").repo()
  if repo then
    health.ok(("repository %s (%s)"):format(repo.root, repo.kind))
  else
    health.info("current directory is not a jj or Git repository")
  end

  health.start("tether: agents")
  if vim.fn.executable("agent-trail") == 1 then
    health.ok("agent-trail on PATH")
  else
    health.warn("agent-trail not on PATH", { "Link bin/agent-trail from the plugin into a PATH directory" })
  end
  local log = config.log_file or "?"
  if vim.uv.fs_stat(log) then
    health.ok("event log " .. log)
  else
    health.info("no event log yet at " .. log .. "; agents create it on their first event")
  end
  if vim.fn.executable(config.agent_state) == 1 then
    health.ok(config.agent_state .. " found")
  else
    health.info(config.agent_state .. " not found; the cockpit lists no live agents")
  end
  if vim.fn.executable(config.send.wezterm) == 1 then
    health.ok("wezterm found; send pastes into agent panes")
  else
    health.info("wezterm not found; send copies to the + register")
  end

  health.start("tether: optional")
  if pcall(require, "snacks") then
    health.ok("snacks.nvim picker")
  else
    health.info("snacks.nvim not found; pickers use vim.ui.select")
  end
  if vim.fn.executable("openspec") == 1 then
    health.ok("openspec CLI for spec diagnostics")
  else
    health.info("openspec CLI not found; built-in spec checks apply")
  end
  if vim.fn.executable("curl") == 1 then
    health.ok("curl for Attractor event streams")
  else
    health.info("curl not found; Attractor runs read from directories only")
  end
end

return M
