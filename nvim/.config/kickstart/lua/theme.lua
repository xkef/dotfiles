-- Theme system: reads ~/.config/theme/current for colorscheme and variant.
-- The `theme` command writes this file; no duplicate table needed here.
-- Auto-reloads on FocusGained so `theme <name>` in another pane takes effect.

local M = {}

local DEFAULTS = { name = "catppuccin-frappe", nvim = "catppuccin-frappe", variant = "dark" }

function M.read()
  local path = vim.fn.expand("~/.config/theme/current")
  local f = io.open(path, "r")
  if not f then
    return DEFAULTS
  end
  local cfg = {}
  for line in f:lines() do
    local k, v = line:match("^(%S+)=(.+)$")
    if k == "name" then
      cfg.name = v
    elseif k == "variant" then
      cfg.variant = v
    elseif k == "nvim" then
      cfg.nvim = v
    end
  end
  f:close()
  return {
    name = cfg.name or DEFAULTS.name,
    nvim = cfg.nvim or DEFAULTS.nvim,
    variant = cfg.variant or DEFAULTS.variant,
  }
end

function M.apply()
  local cfg = M.read()
  vim.o.background = cfg.variant
  local ok = pcall(vim.cmd.colorscheme, cfg.nvim)
  if not ok then
    vim.notify("theme: " .. cfg.nvim .. " not available", vim.log.levels.WARN)
  end
  vim.g._current_theme = cfg.name
end

function M.setup()
  vim.api.nvim_create_autocmd("FocusGained", {
    group = vim.api.nvim_create_augroup("ThemeAutoSwitch", { clear = true }),
    callback = function()
      local cfg = M.read()
      if cfg.name ~= vim.g._current_theme then
        M.apply()
      end
    end,
  })
end

return M
