-- Follows the theme that `theme` applied. Each theme is named after its
-- colorscheme, which sets the background too. Reloads on FocusGained, and
-- the nvim hook of `theme` reloads running instances on a switch.

local M = {}

local DEFAULT_THEME = "catppuccin-frappe"

local function current_path()
  local state = os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")
  return state .. "/theme/current"
end

function M.read()
  local file = io.open(current_path(), "r")
  if not file then
    return DEFAULT_THEME
  end
  local name = file:read("l")
  file:close()
  return name ~= nil and name ~= "" and name or DEFAULT_THEME
end

function M.apply()
  local name = M.read()
  vim.g._current_theme = name
  if not pcall(vim.cmd.colorscheme, name) then
    pcall(vim.cmd.colorscheme, DEFAULT_THEME)
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
