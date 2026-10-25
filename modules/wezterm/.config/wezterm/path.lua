-- A GUI app launched from the Dock inherits launchd's PATH,
-- /usr/bin:/bin:/usr/sbin:/sbin, which misses Homebrew and ~/.local/bin.
-- Panes get this PATH, so leader overlays such as lazygit resolve, and
-- helpers that WezTerm runs itself, such as mux-sysstat, run through `env`
-- with it.
local wezterm = require("wezterm")

local M = {}

M.PATH = table.concat({
  wezterm.home_dir .. "/.local/bin",
  "/opt/homebrew/bin",
  "/usr/local/bin",
  os.getenv("PATH") or "/usr/bin:/bin:/usr/sbin:/sbin",
}, ":")

-- Whether another package deployed the program to ~/.local/bin, as the
-- agents package deploys `agents`.
function M.deployed(name)
  local file = io.open(wezterm.home_dir .. "/.local/bin/" .. name)
  if file then
    file:close()
  end
  return file ~= nil
end

-- Arguments for wezterm.run_child_process that run a command with PATH.
function M.command(args)
  return { "/usr/bin/env", "PATH=" .. M.PATH, table.unpack(args) }
end

return M
