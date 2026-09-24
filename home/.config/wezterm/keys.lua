-- Leader bindings, the former tmux prefix table. `@key` comments feed the
-- `dots-keys` reference, which the leader's `?` opens.
local wezterm = require("wezterm")
local act = wezterm.action
local agents = require("agents")
local workspaces = require("workspaces")

local M = {}

-- Repeatable bindings stay active for this long after each press without
-- the leader, like tmux's `bind -r`.
local REPEAT_MS = 500

-- Opens a program in a zoomed split. WezTerm has no floating panes, and a
-- zoomed split stands in for one: it covers the tab, `z` reveals the panes
-- beneath, and the split closes when the program exits. The command runs
-- through fish, so it sees the shell's environment, such as $EDITOR. No
-- command opens a shell.
local function overlay(command)
  return wezterm.action_callback(function(window, pane)
    local cwd = pane:get_current_working_dir()
    local args = command and { "fish", "-c", command }
    local split = pane:split({ args = args, cwd = cwd and cwd.file_path, direction = "Bottom" })
    window:perform_action(act.SetPaneZoomState(true), split)
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

local function open_url(window, pane)
  local url = window:get_selection_text_for_pane(pane)
  wezterm.open_with(url)
end

function M.apply(config)
  -- Ctrl-Space pairs with the Neovim leader, Space, after wincent, so one
  -- physical key serves both. Ctrl-A and Ctrl-B stay free for readline.
  config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1000 }

  config.keys = {
    -- @key wezterm :: Ctrl-Space :: Last tab (double-tap)
    { key = "Space", mods = "LEADER|CTRL", action = act.ActivateLastTab },
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
    { key = "|", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
    { key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
    -- @key wezterm :: z :: Toggle pane zoom
    { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
    -- @key wezterm :: x :: Close pane
    { key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },

    -- @key wezterm :: c :: New tab
    { key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
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
    { key = "e", mods = "LEADER", action = overlay("yazi") },
    -- @key wezterm :: g :: Lazygit
    { key = "g", mods = "LEADER", action = overlay("lazygit") },
    -- @key wezterm :: G :: jj UI (jjui)
    { key = "G", mods = "LEADER", action = overlay("jjui") },
    -- @key wezterm :: R :: Search and replace (scooter)
    { key = "R", mods = "LEADER", action = overlay("scooter") },
    -- @key wezterm :: d :: Lazydocker
    { key = "d", mods = "LEADER", action = overlay("lazydocker") },
    -- @key wezterm :: ? :: This reference
    { key = "?", mods = "LEADER", action = overlay("dots-keys") },

    -- @key wezterm :: f :: Workspace picker (workspaces + zoxide)
    { key = "f", mods = "LEADER", action = workspaces.picker() },
    -- @key wezterm :: F :: Last workspace
    { key = "F", mods = "LEADER", action = workspaces.last() },
    -- @key wezterm :: S :: New named workspace
    { key = "S", mods = "LEADER", action = workspaces.create() },
    -- @key wezterm :: s :: Browse workspaces
    { key = "s", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
    -- @key wezterm :: w :: Switch tab, all workspaces
    { key = "w", mods = "LEADER", action = workspaces.tabs() },
    -- @key wezterm :: a :: Agent picker (all workspaces)
    { key = "a", mods = "LEADER", action = agents.picker() },

    -- @key wezterm :: Enter :: Copy mode
    { key = "Enter", mods = "LEADER", action = act.ActivateCopyMode },
    -- @key wezterm :: / :: Search scrollback
    { key = "/", mods = "LEADER", action = act.Search({ CaseInSensitiveString = "" }) },
    -- @key wezterm :: o / i :: Jump to previous / next prompt
    { key = "o", mods = "LEADER", action = act.ScrollToPrompt(-1) },
    { key = "i", mods = "LEADER", action = act.ScrollToPrompt(1) },
    -- @key wezterm :: O :: Select the last command's output (copy mode)
    {
      key = "O",
      mods = "LEADER",
      action = act.Multiple({
        act.ActivateCopyMode,
        act.CopyMode({ MoveBackwardZoneOfType = "Output" }),
        act.CopyMode({ SetSelectionMode = "SemanticZone" }),
      }),
    },
    -- @key wezterm :: D :: Open a tab on another host (SSH, Lima)
    { key = "D", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|DOMAINS" }) },
    -- @key wezterm :: t :: Hint-copy visible text (quick select)
    { key = "t", mods = "LEADER", action = act.QuickSelect },
    -- @key wezterm :: u :: Open URL on screen (quick select)
    {
      key = "u",
      mods = "LEADER",
      action = act.QuickSelectArgs({
        label = "open url",
        patterns = { "https?://\\S+" },
        action = wezterm.action_callback(open_url),
      }),
    },
  }

  config.key_tables = { ["repeat"] = repeat_keys }

  -- A triple click selects a whole command output or prompt, from the
  -- OSC 133 marks fish writes, instead of one line.
  config.mouse_bindings = {
    {
      event = { Down = { streak = 3, button = "Left" } },
      mods = "NONE",
      action = act.SelectTextAtMouseCursor("SemanticZone"),
    },
  }
end

return M
