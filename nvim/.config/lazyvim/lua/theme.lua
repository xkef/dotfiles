-- Theme system: reads the current theme from the Ghostty config and derives
-- the neovim colorscheme from the Ghostty theme name via convention.
-- Auto-reloads on FocusGained so `theme <name>` in another pane takes effect.

local M = {}

local OVERRIDES = {
  ["atom-one-dark"] = "onedark",
  ["atom-one-light"] = "onelight",
}

local function ghostty_config_path()
  local xdg = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
  return xdg .. "/ghostty/config"
end

local function ghostty_theme_dirs()
  local xdg = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
  local res = os.getenv("GHOSTTY_RESOURCES_DIR")
  local dirs = { xdg .. "/ghostty/themes" }
  if res then
    table.insert(dirs, res .. "/themes")
  end
  table.insert(dirs, "/Applications/Ghostty.app/Contents/Resources/ghostty/themes")
  return dirs
end

local function detect_variant(theme_name)
  for _, dir in ipairs(ghostty_theme_dirs()) do
    local path = dir .. "/" .. theme_name
    local f = io.open(path, "r")
    if f then
      for line in f:lines() do
        local hex = line:match("^%s*background%s*=%s*#?(%x%x%x%x%x%x)")
        if hex then
          f:close()
          local r = tonumber(hex:sub(1, 2), 16)
          local g = tonumber(hex:sub(3, 4), 16)
          local b = tonumber(hex:sub(5, 6), 16)
          local lum = 0.299 * r + 0.587 * g + 0.114 * b
          return lum > 128 and "light" or "dark"
        end
      end
      f:close()
    end
  end
  return "dark"
end

local function derive_colorscheme(ghostty_name)
  local normalized = ghostty_name:lower():gsub("%s+", "-")

  if OVERRIDES[normalized] then
    return OVERRIDES[normalized]
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
  vim.o.background = detect_variant(cfg.name)
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
