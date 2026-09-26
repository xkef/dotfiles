-- The key table, after the usual macOS terminal keys. WezTerm's own
-- defaults stay off, since several of them, such as Alt-Enter and
-- Ctrl-Shift-Space, take keys that the shell, Neovim, and agents use.
local wezterm = require("wezterm")
local act = wezterm.action
local lima = require("lima")

local M = {}

local IS_MAC = wezterm.target_triple:find("darwin") ~= nil

-- Clears the screen: drops the scrollback and lets the shell redraw.
local CLEAR_SCREEN = act.Multiple({
  act.ClearScrollback("ScrollbackAndViewport"),
  act.SendKey({ key = "l", mods = "CTRL" }),
})

-- Ctrl-Shift bindings, on every platform.
local SHARED = {
  { key = "c", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
  { key = "v", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },
  { key = "n", mods = "CTRL|SHIFT", action = act.SpawnWindow },
  { key = "t", mods = "CTRL|SHIFT", action = lima.tab(act.SpawnTab("CurrentPaneDomain")) },
  { key = "w", mods = "CTRL|SHIFT", action = act.CloseCurrentPane({ confirm = false }) },
  { key = "phys:Equal", mods = "CTRL|SHIFT", action = act.IncreaseFontSize },
  { key = "phys:Minus", mods = "CTRL|SHIFT", action = act.DecreaseFontSize },
  { key = "phys:0", mods = "CTRL|SHIFT", action = act.ResetFontSize },
  { key = "f", mods = "CTRL|SHIFT", action = act.ToggleFullScreen },
  { key = "Tab", mods = "CTRL", action = act.ActivateTabRelative(1) },
  { key = "Tab", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(-1) },
}

-- macOS Cmd bindings.
local MAC = {
  { key = "c", mods = "SUPER", action = act.CopyTo("Clipboard") },
  { key = "v", mods = "SUPER", action = act.PasteFrom("Clipboard") },
  { key = "v", mods = "SUPER|SHIFT", action = act.PasteFrom("PrimarySelection") },
  { key = "=", mods = "SUPER", action = act.IncreaseFontSize },
  { key = "+", mods = "SUPER", action = act.IncreaseFontSize },
  { key = "-", mods = "SUPER", action = act.DecreaseFontSize },
  { key = "0", mods = "SUPER", action = act.ResetFontSize },
  { key = ",", mods = "SUPER|SHIFT", action = act.ReloadConfiguration },
  { key = "p", mods = "SUPER|SHIFT", action = act.ActivateCommandPalette },
  { key = "i", mods = "SUPER|ALT", action = act.ShowDebugOverlay },

  { key = "n", mods = "SUPER", action = act.SpawnWindow },
  { key = "t", mods = "SUPER", action = lima.tab(act.SpawnTab("CurrentPaneDomain")) },
  { key = "w", mods = "SUPER", action = act.CloseCurrentPane({ confirm = false }) },
  { key = "w", mods = "SUPER|ALT", action = act.CloseCurrentTab({ confirm = false }) },
  { key = "q", mods = "SUPER", action = act.QuitApplication },
  { key = "h", mods = "SUPER", action = act.HideApplication },
  { key = "m", mods = "SUPER", action = act.Hide },
  { key = "Enter", mods = "SUPER", action = act.ToggleFullScreen },
  { key = "f", mods = "SUPER|CTRL", action = act.ToggleFullScreen },

  { key = "[", mods = "SUPER|SHIFT", action = act.ActivateTabRelative(-1) },
  { key = "]", mods = "SUPER|SHIFT", action = act.ActivateTabRelative(1) },
  { key = "{", mods = "SUPER|SHIFT", action = act.ActivateTabRelative(-1) },
  { key = "}", mods = "SUPER|SHIFT", action = act.ActivateTabRelative(1) },
  { key = "9", mods = "SUPER", action = act.ActivateTab(-1) },

  { key = "d", mods = "SUPER", action = lima.split(act.SplitHorizontal({ domain = "CurrentPaneDomain" }), "Right") },
  {
    key = "d",
    mods = "SUPER|SHIFT",
    action = lima.split(act.SplitVertical({ domain = "CurrentPaneDomain" }), "Bottom"),
  },
  { key = "Enter", mods = "SUPER|SHIFT", action = act.TogglePaneZoomState },
  { key = "[", mods = "SUPER", action = act.ActivatePaneDirection("Prev") },
  { key = "]", mods = "SUPER", action = act.ActivatePaneDirection("Next") },

  { key = "k", mods = "SUPER", action = CLEAR_SCREEN },
  { key = "f", mods = "SUPER", action = act.Search("CurrentSelectionOrEmptyString") },
  { key = "Home", mods = "SUPER", action = act.ScrollToTop },
  { key = "End", mods = "SUPER", action = act.ScrollToBottom },
  { key = "PageUp", mods = "SUPER", action = act.ScrollByPage(-1) },
  { key = "PageDown", mods = "SUPER", action = act.ScrollByPage(1) },
  { key = "UpArrow", mods = "SUPER", action = act.ScrollToPrompt(-1) },
  { key = "DownArrow", mods = "SUPER", action = act.ScrollToPrompt(1) },
  { key = "UpArrow", mods = "SUPER|SHIFT", action = act.ScrollToPrompt(-1) },
  { key = "DownArrow", mods = "SUPER|SHIFT", action = act.ScrollToPrompt(1) },

  -- Line editing: Cmd-Left and Cmd-Right send Ctrl-A and Ctrl-E, and
  -- Cmd-Backspace sends Ctrl-U. Option-Left and Option-Right move by word.
  { key = "LeftArrow", mods = "SUPER", action = act.SendString("\x01") },
  { key = "RightArrow", mods = "SUPER", action = act.SendString("\x05") },
  { key = "Backspace", mods = "SUPER", action = act.SendString("\x15") },
  { key = "LeftArrow", mods = "ALT", action = act.SendString("\x1bb") },
  { key = "RightArrow", mods = "ALT", action = act.SendString("\x1bf") },
}

-- Pane moves on Cmd-Alt-arrows and resizes on Cmd-Ctrl-arrows.
local DIRECTIONS = { UpArrow = "Up", DownArrow = "Down", LeftArrow = "Left", RightArrow = "Right" }
for key, direction in pairs(DIRECTIONS) do
  table.insert(MAC, { key = key, mods = "SUPER|ALT", action = act.ActivatePaneDirection(direction) })
  table.insert(MAC, { key = key, mods = "SUPER|CTRL", action = act.AdjustPaneSize({ direction, 10 }) })
end

for i = 1, 8 do
  table.insert(MAC, { key = tostring(i), mods = "SUPER", action = act.ActivateTab(i - 1) })
end

-- Cmd-click, or Ctrl-click off macOS, opens a link, and a plain click only
-- selects. The press does nothing, so Neovim doesn't see it. The
-- mouse_reporting copies apply while a program holds the mouse. A double
-- click copies the word and a triple click the line, also in Neovim and
-- other programs that hold the mouse.
local function mouse_bindings()
  local link_mods = IS_MAC and "SUPER" or "CTRL"
  local bindings = {
    {
      event = { Up = { streak = 1, button = "Left" } },
      mods = "NONE",
      action = act.CompleteSelection("ClipboardAndPrimarySelection"),
    },
  }
  for _, reporting in ipairs({ false, true }) do
    for streak, unit in pairs({ [2] = "Word", [3] = "Line" }) do
      table.insert(bindings, {
        event = { Down = { streak = streak, button = "Left" } },
        mods = "NONE",
        mouse_reporting = reporting,
        action = act.SelectTextAtMouseCursor(unit),
      })
      table.insert(bindings, {
        event = { Up = { streak = streak, button = "Left" } },
        mods = "NONE",
        mouse_reporting = reporting,
        action = act.CompleteSelection("ClipboardAndPrimarySelection"),
      })
    end
    table.insert(bindings, {
      event = { Up = { streak = 1, button = "Left" } },
      mods = link_mods,
      mouse_reporting = reporting,
      action = act.OpenLinkAtMouseCursor,
    })
    table.insert(bindings, {
      event = { Down = { streak = 1, button = "Left" } },
      mods = link_mods,
      mouse_reporting = reporting,
      action = act.Nop,
    })
  end
  return bindings
end

-- Search keys: Cmd-G and Cmd-Shift-G step through matches, and
-- Cmd-Shift-F closes the search.
local function search_mode()
  local keys = wezterm.gui.default_key_tables().search_mode
  table.insert(keys, { key = "g", mods = "SUPER", action = act.CopyMode("NextMatch") })
  table.insert(keys, { key = "g", mods = "SUPER|SHIFT", action = act.CopyMode("PriorMatch") })
  table.insert(keys, { key = "f", mods = "SUPER|SHIFT", action = act.CopyMode("Close") })
  return keys
end

-- Additions to WezTerm's vi-style copy mode: Y copies to
-- the end of the line, o and i jump between prompts, and / and ? search.
-- WezTerm's search starts upward, so Enter moves up and Ctrl-n down.
local COPY_MODE = {
  {
    key = "Y",
    mods = "SHIFT",
    action = act.Multiple({
      act.CopyMode({ SetSelectionMode = "Cell" }),
      act.CopyMode("MoveToEndOfLineContent"),
      act.CopyTo("ClipboardAndPrimarySelection"),
      act.CopyMode("Close"),
    }),
  },
  { key = "o", mods = "NONE", action = act.CopyMode({ MoveBackwardZoneOfType = "Prompt" }) },
  { key = "i", mods = "NONE", action = act.CopyMode({ MoveForwardZoneOfType = "Prompt" }) },
  { key = "/", mods = "NONE", action = act.CopyMode("EditPattern") },
  { key = "?", mods = "SHIFT", action = act.CopyMode("EditPattern") },
}

-- Identifies a binding by key and modifiers. WezTerm writes no modifiers
-- as nil, "", or "NONE".
local function binding_id(binding)
  local mods = binding.mods
  if mods == nil or mods == "" then
    mods = "NONE"
  end
  return binding.key .. "+" .. mods
end

-- WezTerm's copy_mode table with COPY_MODE replacing the bindings of the
-- same keys.
local function copy_mode()
  local taken = {}
  for _, binding in ipairs(COPY_MODE) do
    taken[binding_id(binding)] = true
  end

  local keys = {}
  for _, binding in ipairs(wezterm.gui.default_key_tables().copy_mode) do
    if not taken[binding_id(binding)] then
      table.insert(keys, binding)
    end
  end
  for _, binding in ipairs(COPY_MODE) do
    table.insert(keys, binding)
  end
  return keys
end

function M.apply(config)
  config.disable_default_key_bindings = true
  config.keys = config.keys or {}
  for _, binding in ipairs(SHARED) do
    table.insert(config.keys, binding)
  end
  if IS_MAC then
    for _, binding in ipairs(MAC) do
      table.insert(config.keys, binding)
    end
  end

  config.mouse_bindings = mouse_bindings()

  -- wezterm.gui is absent when a headless mux server loads the config.
  if wezterm.gui then
    config.key_tables = config.key_tables or {}
    config.key_tables.search_mode = search_mode()
    config.key_tables.copy_mode = copy_mode()
  end
end

return M
