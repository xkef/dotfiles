-- Colors from the scheme that `theme` (tinty) last applied. tinty writes
-- the scheme name, such as base24-catppuccin-frappe, to current_scheme.
-- Watching it reloads the config, and with it the colors, on every switch.
--
-- A scheme in BUILTIN uses WezTerm's copy of the theme's official palette.
-- tinted-theming derives its palettes from 16 or 24 base colors, which
-- turns black into the background and changes the bright colors. Every
-- other scheme loads the WezTerm color file from the tinted-terminal repo
-- that tinty cloned.
local wezterm = require("wezterm")

local M = {}

local FALLBACK_SCHEME = "Catppuccin Frappe"

local DATA_HOME = os.getenv("XDG_DATA_HOME") or (wezterm.home_dir .. "/.local/share")
local TINTY = DATA_HOME .. "/tinted-theming/tinty"

-- tinty scheme names, without the base16- or base24- prefix, and the
-- built-in WezTerm schemes they map to.
local BUILTIN = {
  ["catppuccin-latte"] = "Catppuccin Latte",
  ["catppuccin-frappe"] = "Catppuccin Frappe",
  ["catppuccin-macchiato"] = "Catppuccin Macchiato",
  ["catppuccin-mocha"] = "Catppuccin Mocha",
  ["tokyo-night-dark"] = "Tokyo Night",
  ["tokyo-night-storm"] = "Tokyo Night Storm",
  ["tokyo-night-moon"] = "Tokyo Night Moon",
  ["tokyo-night-light"] = "Tokyo Night Day",
  ["rose-pine"] = "rose-pine",
  ["rose-pine-moon"] = "rose-pine-moon",
  ["rose-pine-dawn"] = "rose-pine-dawn",
  ["kanagawa"] = "Kanagawa (Gogh)",
  ["kanagawa-dragon"] = "Kanagawa Dragon (Gogh)",
  ["everforest"] = "Everforest Dark Medium (Gogh)",
  ["everforest-dark-hard"] = "Everforest Dark Hard (Gogh)",
  ["everforest-dark-medium"] = "Everforest Dark Medium (Gogh)",
  ["everforest-dark-soft"] = "Everforest Dark Soft (Gogh)",
  ["everforest-light-hard"] = "Everforest Light Hard (Gogh)",
  ["everforest-light-medium"] = "Everforest Light Medium (Gogh)",
  ["everforest-light-soft"] = "Everforest Light Soft (Gogh)",
}

local function tinty_colors()
  local current = TINTY .. "/current_scheme"
  wezterm.add_to_config_reload_watch_list(current)

  local file = io.open(current)
  if not file then
    return nil
  end
  local scheme = file:read("l")
  file:close()
  if not scheme or scheme == "" then
    return nil
  end

  local builtin = BUILTIN[scheme:gsub("^base%d+%-", "")]
  if builtin then
    return wezterm.color.get_builtin_schemes()[builtin]
  end

  local path = TINTY .. "/repos/tinted-terminal/themes/wezterm/" .. scheme .. ".toml"
  local ok, colors = pcall(wezterm.color.load_scheme, path)
  if ok then
    return colors
  end
end

-- Mixes two "#rrggbb" colors, with weight from 0 (all a) to 1 (all b).
function M.blend(a, b, weight)
  local mixed = {}
  for i = 2, 6, 2 do
    local x, y = tonumber(a:sub(i, i + 1), 16), tonumber(b:sub(i, i + 1), 16)
    table.insert(mixed, string.format("%02x", math.floor(x + (y - x) * weight + 0.5)))
  end
  return "#" .. table.concat(mixed)
end

-- Sets the colors on config and reloads it when `theme` switches.
function M.apply(config)
  config.colors = tinty_colors() or wezterm.color.get_builtin_schemes()[FALLBACK_SCHEME]
end

return M
