-- Theme system: reads the current theme from the Ghostty config and derives
-- the neovim colorscheme from the Ghostty theme name via convention.
-- Auto-reloads on FocusGained so `theme <name>` in another pane takes effect.

local M = {}

local function ghostty_config_path()
  local xdg = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
  return xdg .. "/ghostty/config"
end

local function configure_colorscheme(ghostty_name)
  local normalized = ghostty_name:lower():gsub("%s+", "-")
  if normalized:find("light") or normalized:find("latte") or normalized:find("day") or normalized:find("dawn") then
    vim.o.background = "light"
  else
    vim.o.background = "dark"
  end

  if normalized:find("^everforest") then
    local ok, everforest = pcall(require, "everforest")
    if ok then
      everforest.setup({
        italics = true,
        disable_italic_comments = false,
        background = normalized:find("hard") and "hard" or normalized:find("soft") and "soft" or "medium",
      })
    end
  end
end

local function derive_colorscheme(ghostty_name)
  local normalized = ghostty_name:lower():gsub("%s+", "-")

  if normalized:find("^everforest") and pcall(vim.cmd.colorscheme, "everforest") then
    return "everforest"
  end

  local stripped = normalized:gsub("%-hard$", ""):gsub("%-med$", ""):gsub("%-soft$", "")
  if stripped ~= normalized and pcall(vim.cmd.colorscheme, stripped) then
    return stripped
  end

  if pcall(vim.cmd.colorscheme, normalized) then
    return normalized
  end

  local parts = vim.split(normalized, "-")
  for i = #parts - 1, 1, -1 do
    local prefix = table.concat(parts, "-", 1, i)
    if pcall(vim.cmd.colorscheme, prefix) then
      return prefix
    end
  end

  pcall(vim.cmd.colorscheme, "default")
  return "default"
end

function M.read()
  local f = io.open(ghostty_config_path(), "r")
  if not f then
    return { name = "Catppuccin Mocha" }
  end
  local name
  for line in f:lines() do
    local val = line:match("^%s*theme%s*=%s*(.+)$")
    if val then
      name = val:match("^(.-)%s*$")
    end
  end
  f:close()
  return { name = name or "Catppuccin Mocha" }
end

function M.apply()
  local cfg = M.read()
  configure_colorscheme(cfg.name)
  derive_colorscheme(cfg.name)
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
