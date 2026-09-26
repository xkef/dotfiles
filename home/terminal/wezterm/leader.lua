-- Leader bindings for panes, tabs, workspaces, and pickers. `@key` comments
-- feed the `dots-keys` reference, which the leader's `?` opens. keys.lua
-- holds the Cmd and Ctrl-Shift bindings, and these add to them.
local wezterm = require("wezterm")
local act = wezterm.action
local keymap = require("keymap")
local lima = require("lima")
local picker = require("picker")
local workspaces = require("workspaces")

local M = {}

-- Repeatable bindings stay active for this long after each press without
-- the leader.
local REPEAT_MS = 500

-- Runs a program, or says it isn't installed before the split closes.
local REQUIRE_PROGRAM = 'command -v "$1" >/dev/null || { echo "$1 is not installed"; sleep 1; exit; }; exec "$@"'

-- Opens a program in a zoomed split, or a shell without arguments.
local function overlay(args)
  if args then
    args = { "sh", "-c", REQUIRE_PROGRAM, "sh", table.unpack(args) }
  end
  return wezterm.action_callback(function(window, pane)
    picker.split(window, pane, args)
  end)
end

-- Moves between panes, or hands Ctrl plus the key to Neovim or tv so that
-- smart-splits.nvim moves across Neovim's own splits first.
-- smart-splits.nvim sets the IS_NVIM user var, which works over the mux.
-- The process name covers tv in local panes.
local function is_vim(pane)
  if pane:get_user_vars().IS_NVIM == "true" then
    return true
  end
  local name = pane:get_foreground_process_name() or ""
  return name:match("n?vim$") ~= nil or name:match("/tv$") ~= nil
end

local function navigate(key, direction)
  return {
    key = key,
    mods = "LEADER",
    action = wezterm.action_callback(function(window, pane)
      if is_vim(pane) then
        window:perform_action(act.SendKey({ key = key, mods = "CTRL" }), pane)
      else
        window:perform_action(act.ActivatePaneDirection(direction), pane)
      end
    end),
  }
end

-- A leader binding plus the same key in the `repeat` table, which each
-- press keeps open for another REPEAT_MS.
local repeat_keys = {}
local function repeatable(key, action)
  local again = act.Multiple({
    action,
    act.ActivateKeyTable({
      name = "repeat",
      one_shot = false,
      replace_current = true,
      until_unknown = true,
      timeout_milliseconds = REPEAT_MS,
    }),
  })
  table.insert(repeat_keys, { key = key, action = again })
  return { key = key, mods = "LEADER", action = again }
end

local PICKERS = {
  workspaces = picker.open({ "mux-workspaces" }),
  tabs = picker.open({ "mux-tabs" }),
  agents = picker.open({ "mux-agents" }),
  urls = picker.open({ "mux-urls" }),
}

local TOOLS = {
  yazi = overlay({ "yazi" }),
  lazygit = overlay({ "lazygit" }),
  jjui = overlay({ "jjui" }),
  scooter = overlay({ "scooter" }),
  lazydocker = overlay({ "lazydocker" }),
  keys = overlay({ "dots-keys" }),
}

local LIMA_AGENT = act.SpawnCommandInNewTab({ args = { "lima-agent" } })

-- Command palette entries for the pickers and tools, so Cmd-Shift-P finds
-- them by name.
local PALETTE = {
  { brief = "Workspaces", icon = "cod_window", action = PICKERS.workspaces },
  { brief = "Tabs in every workspace", icon = "cod_list_flat", action = PICKERS.tabs },
  { brief = "Agents", icon = "cod_hubot", action = PICKERS.agents },
  { brief = "Open URL from scrollback", icon = "cod_link_external", action = PICKERS.urls },
  { brief = "Swap pane", icon = "cod_arrow_swap", action = act.PaneSelect({ mode = "SwapWithActive" }) },
  { brief = "Lima VM shell in a new tab", icon = "cod_vm", action = lima.shell_tab },
  { brief = "Claude Code in the Lima VM", icon = "cod_hubot", action = LIMA_AGENT },
  { brief = "Files (yazi)", icon = "cod_files", action = TOOLS.yazi },
  { brief = "Lazygit", icon = "cod_source_control", action = TOOLS.lazygit },
  { brief = "jj UI (jjui)", icon = "cod_source_control", action = TOOLS.jjui },
  { brief = "Search and replace (scooter)", icon = "cod_replace_all", action = TOOLS.scooter },
  { brief = "Lazydocker", icon = "cod_package", action = TOOLS.lazydocker },
  { brief = "Key reference", icon = "md_keyboard", action = TOOLS.keys },
}

function M.apply(config)
  config.leader = { key = keymap.key, mods = keymap.mods, timeout_milliseconds = 1000 }

  local keys = {
    -- @key wezterm :: leader twice :: Last tab
    { key = keymap.key, mods = "LEADER|" .. keymap.mods, action = act.ActivateLastTab },
    -- @key wezterm :: r :: Reload config
    { key = "r", mods = "LEADER", action = act.ReloadConfiguration },
    -- @key wezterm :: Ctrl-l :: Clear scrollback
    { key = "l", mods = "LEADER|CTRL", action = act.ClearScrollback("ScrollbackOnly") },

    -- @key wezterm :: h/j/k/l :: Navigate panes (and Neovim splits)
    navigate("h", "Left"),
    navigate("j", "Down"),
    navigate("k", "Up"),
    navigate("l", "Right"),
    -- @key wezterm :: H/J/K/L :: Resize pane (repeatable)
    repeatable("H", act.AdjustPaneSize({ "Left", 5 })),
    repeatable("J", act.AdjustPaneSize({ "Down", 5 })),
    repeatable("K", act.AdjustPaneSize({ "Up", 5 })),
    repeatable("L", act.AdjustPaneSize({ "Right", 5 })),

    -- @key wezterm :: | / - :: Split right / down
    { key = "|", mods = "LEADER", action = lima.split(act.SplitHorizontal({ domain = "CurrentPaneDomain" }), "Right") },
    { key = "-", mods = "LEADER", action = lima.split(act.SplitVertical({ domain = "CurrentPaneDomain" }), "Down") },
    -- @key wezterm :: z :: Toggle pane zoom
    { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
    -- @key wezterm :: x :: Close pane
    { key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
    -- @key wezterm :: q :: Jump to a pane by label
    { key = "q", mods = "LEADER", action = act.PaneSelect },
    -- @key wezterm :: m :: Swap the pane with a labeled one
    { key = "m", mods = "LEADER", action = act.PaneSelect({ mode = "SwapWithActive" }) },

    -- @key wezterm :: c :: New tab
    { key = "c", mods = "LEADER", action = lima.tab(act.SpawnTab("CurrentPaneDomain")) },
    -- @key wezterm :: v :: New tab in the Lima VM
    { key = "v", mods = "LEADER", action = lima.shell_tab },
    -- @key wezterm :: n / p :: Next / previous tab (repeatable)
    repeatable("n", act.ActivateTabRelative(1)),
    repeatable("p", act.ActivateTabRelative(-1)),
    -- @key wezterm :: Tab :: Last tab
    { key = "Tab", mods = "LEADER", action = act.ActivateLastTab },
    -- @key wezterm :: < / > :: Move tab left / right (repeatable)
    repeatable("<", act.MoveTabRelative(-1)),
    repeatable(">", act.MoveTabRelative(1)),

    -- @key wezterm :: * :: Overlay shell (zoomed split)
    { key = "*", mods = "LEADER", action = overlay() },
    -- @key wezterm :: e :: File manager (yazi)
    { key = "e", mods = "LEADER", action = TOOLS.yazi },
    -- @key wezterm :: g :: Lazygit
    { key = "g", mods = "LEADER", action = TOOLS.lazygit },
    -- @key wezterm :: G :: jj UI (jjui)
    { key = "G", mods = "LEADER", action = TOOLS.jjui },
    -- @key wezterm :: R :: Search and replace (scooter)
    { key = "R", mods = "LEADER", action = TOOLS.scooter },
    -- @key wezterm :: d :: Lazydocker
    { key = "d", mods = "LEADER", action = TOOLS.lazydocker },
    -- @key wezterm :: ? :: This reference
    { key = "?", mods = "LEADER", action = TOOLS.keys },

    -- @key wezterm :: f :: Workspace picker (workspaces, zoxide)
    { key = "f", mods = "LEADER", action = PICKERS.workspaces },
    -- @key wezterm :: F :: Last workspace
    { key = "F", mods = "LEADER", action = workspaces.last() },
    -- @key wezterm :: S :: New named workspace
    { key = "S", mods = "LEADER", action = workspaces.create() },
    -- @key wezterm :: s :: Browse workspaces
    { key = "s", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
    -- @key wezterm :: w :: Switch tab, all workspaces
    { key = "w", mods = "LEADER", action = PICKERS.tabs },
    -- @key wezterm :: a :: Agent picker (all workspaces)
    { key = "a", mods = "LEADER", action = PICKERS.agents },
    -- @key wezterm :: A :: Claude Code in the Lima VM, new tab
    { key = "A", mods = "LEADER", action = LIMA_AGENT },

    -- @key wezterm :: Enter :: Copy mode
    { key = "Enter", mods = "LEADER", action = act.ActivateCopyMode },
    -- @key wezterm :: / :: Search scrollback
    { key = "/", mods = "LEADER", action = act.Search({ CaseInSensitiveString = "" }) },
    -- @key wezterm :: o / i :: Jump to previous / next prompt
    { key = "o", mods = "LEADER", action = act.ScrollToPrompt(-1) },
    { key = "i", mods = "LEADER", action = act.ScrollToPrompt(1) },
    -- @key wezterm :: t :: Hint-copy visible text (quick select)
    { key = "t", mods = "LEADER", action = act.QuickSelect },
    -- @key wezterm :: u :: Open URL from scrollback (tv)
    { key = "u", mods = "LEADER", action = PICKERS.urls },
  }

  config.keys = config.keys or {}
  for _, binding in ipairs(keys) do
    table.insert(config.keys, binding)
  end
  config.key_tables = config.key_tables or {}
  config.key_tables["repeat"] = repeat_keys

  wezterm.on("augment-command-palette", function()
    return PALETTE
  end)
end

return M
