-- Follows the scheme that `theme` (tinty) applied. A scheme in COLORSCHEMES
-- uses its theme's own plugin, which colors far more than a Base16 or
-- Base24 palette can. Every other scheme renders through tinted-nvim.
-- Reloads on FocusGained, and tinty's nvim-theme hook reloads running
-- instances on a switch.

local M = {}

local DEFAULT_SCHEME = "base24-catppuccin-frappe"

-- tinty scheme names, without the base16- or base24- prefix, and the
-- plugin colorschemes they map to. `contrast` sets Everforest's background.
local COLORSCHEMES = {
  ["catppuccin-latte"] = { name = "catppuccin-latte", light = true },
  ["catppuccin-frappe"] = { name = "catppuccin-frappe" },
  ["catppuccin-macchiato"] = { name = "catppuccin-macchiato" },
  ["catppuccin-mocha"] = { name = "catppuccin-mocha" },
  ["tokyo-night-dark"] = { name = "tokyonight-night" },
  ["tokyo-night-storm"] = { name = "tokyonight-storm" },
  ["tokyo-night-moon"] = { name = "tokyonight-moon" },
  ["tokyo-night-light"] = { name = "tokyonight-day", light = true },
  ["rose-pine"] = { name = "rose-pine-main" },
  ["rose-pine-moon"] = { name = "rose-pine-moon" },
  ["rose-pine-dawn"] = { name = "rose-pine-dawn", light = true },
  ["kanagawa"] = { name = "kanagawa-wave" },
  ["kanagawa-dragon"] = { name = "kanagawa-dragon" },
  ["everforest"] = { name = "everforest", contrast = "medium" },
  ["everforest-dark-hard"] = { name = "everforest", contrast = "hard" },
  ["everforest-dark-medium"] = { name = "everforest", contrast = "medium" },
  ["everforest-dark-soft"] = { name = "everforest", contrast = "soft" },
  ["everforest-light-hard"] = { name = "everforest", contrast = "hard", light = true },
  ["everforest-light-medium"] = { name = "everforest", contrast = "medium", light = true },
  ["everforest-light-soft"] = { name = "everforest", contrast = "soft", light = true },
}

local function current_scheme_path()
  local data = os.getenv("XDG_DATA_HOME") or (os.getenv("HOME") .. "/.local/share")
  return data .. "/tinted-theming/tinty/current_scheme"
end

-- Applies the plugin colorscheme for a mapped scheme. Returns false when
-- the scheme has no mapping or the plugin fails to load.
local function apply_plugin(scheme)
  local entry = COLORSCHEMES[scheme:gsub("^base%d+%-", "")]
  if not entry then
    return false
  end

  vim.o.background = entry.light and "light" or "dark"
  if entry.contrast then
    local ok, everforest = pcall(require, "everforest")
    if ok then
      everforest.setup({ italics = true, background = entry.contrast })
    end
  end
  return pcall(vim.cmd.colorscheme, entry.name)
end

function M.read()
  local file = io.open(current_scheme_path(), "r")
  if not file then
    return DEFAULT_SCHEME
  end
  local scheme = file:read("l")
  file:close()
  return scheme ~= nil and scheme ~= "" and scheme or DEFAULT_SCHEME
end

function M.apply()
  local scheme = M.read()
  vim.g._current_theme = scheme
  if apply_plugin(scheme) then
    return
  end

  local ok, tinted = pcall(require, "tinted-nvim")
  if not (ok and pcall(tinted.load, scheme)) then
    pcall(vim.cmd.colorscheme, "default")
  end
end

function M.setup()
  vim.api.nvim_create_autocmd("FocusGained", {
    group = vim.api.nvim_create_augroup("ThemeAutoSwitch", { clear = true }),
    callback = function()
      if M.read() ~= vim.g._current_theme then
        M.apply()
      end
    end,
  })
end

return M
