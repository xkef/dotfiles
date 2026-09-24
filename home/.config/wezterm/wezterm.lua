-- WezTerm is the terminal, the multiplexer, and the status line in one
-- process. Each module in this directory owns one concern:
--
--   appearance.lua  font, window, and colors from tinty
--   keys.lua        leader bindings, the former tmux prefix table
--   workspaces.lua  project and tab pickers, the former sesh
--   agents.lua      coding-agent state, picker, and notifications
--   status.lua      tab titles and the status line
local wezterm = require("wezterm")
local config = wezterm.config_builder()

require("appearance").apply(config)
require("keys").apply(config)
require("agents").setup()
require("status").setup()

-- Panes live in a local mux server, so closing the window detaches, as in
-- tmux, instead of killing the shells. The next launch reattaches.
config.unix_domains = { { name = "unix" } }
config.default_gui_startup_args = { "connect", "unix" }

return config
