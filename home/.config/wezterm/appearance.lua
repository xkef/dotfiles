local wezterm = require("wezterm")

local M = {}

local FALLBACK_SCHEME = "Catppuccin Mocha"

-- `tinty apply` writes the scheme name to current_scheme, and the
-- tinted-terminal repo it cloned holds one WezTerm color file per scheme.
-- Watching current_scheme reloads the config, and with it the colors, on
-- every switch.
local function tinty_colors()
  local data = os.getenv("XDG_DATA_HOME") or (wezterm.home_dir .. "/.local/share")
  local tinty = data .. "/tinted-theming/tinty"
  local file = io.open(tinty .. "/current_scheme")
  if not file then
    return nil
  end

  local scheme = file:read("l")
  file:close()
  wezterm.add_to_config_reload_watch_list(tinty .. "/current_scheme")

  local path = tinty .. "/repos/tinted-terminal/themes/wezterm/" .. scheme .. ".toml"
  local ok, colors = pcall(wezterm.color.load_scheme, path)
  if ok then
    return colors
  end
end

function M.apply(config)
  config.font = wezterm.font("JetBrainsMono Nerd Font")
  config.font_size = 14
  config.line_height = 1.2
  config.bold_brightens_ansi_colors = false

  -- The tab bar takes the terminal background, like tmux's bg=default.
  local colors = tinty_colors() or wezterm.color.get_builtin_schemes()[FALLBACK_SCHEME]
  colors.tab_bar = { background = colors.background }
  config.colors = colors

  config.window_decorations = "RESIZE"
  config.window_padding = { left = 12, right = 12, top = 0, bottom = 0 }
  config.window_close_confirmation = "NeverPrompt"
  config.inactive_pane_hsb = { saturation = 0.9, brightness = 0.9 }

  -- The status line reads like the former tmux one: a plain bar at the
  -- bottom, styled by status.lua.
  config.use_fancy_tab_bar = false
  config.tab_bar_at_bottom = true
  config.show_new_tab_button_in_tab_bar = false
  config.tab_max_width = 32

  -- Agents raise desktop notifications over OSC 9. Only a pane out of
  -- view needs one.
  config.notification_handling = "SuppressFromFocusedPane"

  config.default_cursor_style = "SteadyBlock"
  config.scrollback_lines = 50000

  -- Left Option sends Alt for the shell and tv bindings. Right Option
  -- still types special characters such as @, [], and {}.
  config.send_composed_key_when_left_alt_is_pressed = false
  config.send_composed_key_when_right_alt_is_pressed = true
end

return M
