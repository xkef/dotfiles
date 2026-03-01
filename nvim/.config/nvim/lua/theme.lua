-- Theme system: reads ~/.config/theme/current to determine colorscheme.
-- Auto-reloads on FocusGained so `theme <name>` in another pane takes effect.

local M = {}

local themes = {
  ["catppuccin-mocha"]  = { colorscheme = "catppuccin-mocha", background = "dark" },
  ["catppuccin-latte"]  = { colorscheme = "catppuccin-latte", background = "light" },
  ["tokyonight"]        = { colorscheme = "tokyonight-night", background = "dark" },
  ["tokyonight-day"]    = { colorscheme = "tokyonight-day",   background = "light" },
  ["rose-pine"]         = { colorscheme = "rose-pine",        background = "dark" },
  ["rose-pine-dawn"]    = { colorscheme = "rose-pine-dawn",   background = "light" },
  ["gruvbox-dark"]      = { colorscheme = "gruvbox",          background = "dark" },
  ["gruvbox-light"]     = { colorscheme = "gruvbox",          background = "light" },
  ["nord"]              = { colorscheme = "nord",             background = "dark" },
}

local DEFAULT = "catppuccin-mocha"

function M.read()
  local path = vim.fn.expand("~/.config/theme/current")
  local f = io.open(path, "r")
  if not f then return DEFAULT end
  local name = f:read("*l")
  f:close()
  return (name and name ~= "") and vim.trim(name) or DEFAULT
end

function M.apply()
  local name = M.read()
  local cfg = themes[name] or themes[DEFAULT]
  vim.o.background = cfg.background
  local ok = pcall(vim.cmd.colorscheme, cfg.colorscheme)
  if not ok then
    vim.notify("theme: " .. cfg.colorscheme .. " not available", vim.log.levels.WARN)
  end
  vim.g._current_theme = name
end

function M.setup()
  M.apply()
  vim.api.nvim_create_autocmd("FocusGained", {
    group = vim.api.nvim_create_augroup("ThemeAutoSwitch", { clear = true }),
    callback = function()
      local name = M.read()
      if name ~= vim.g._current_theme then
        M.apply()
      end
    end,
  })
end

return M
