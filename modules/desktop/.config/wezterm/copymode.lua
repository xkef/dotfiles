-- Copy-mode selections and copies, after tmux's copy-mode.conf. keys.lua
-- binds these actions, and status.lua shows label() in the status line.
-- The actions refresh the status line through the update-status event, and
-- a copy emits "copied" with its size in characters.
local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

-- The mode label for each copy-mode selection mode, as tmux names them.
local SELECTION_LABELS = { Cell = "VISUAL", Line = "V-LINE", Block = "V-BLOCK" }

-- The copy-mode selection mode of each pane, by pane id, like @mode in
-- tmux's copy-mode.conf. WezTerm doesn't expose the mode, so select()
-- records it.
local selections = {}

local function refresh(window, pane)
  wezterm.emit("update-status", window, pane)
end

-- The mode label while copy mode is on, else nil. A selection that
-- select() didn't make, such as a search match, reads VISUAL. Leaving copy
-- mode ends its selection.
function M.label(window, pane)
  local id = pane:pane_id()
  if window:active_key_table() ~= "copy_mode" then
    selections[id] = nil
    return nil
  end
  return SELECTION_LABELS[selections[id]] or window:get_selection_text_for_pane(pane) ~= "" and "VISUAL" or "COPY"
end

-- Sets the copy-mode selection to mode, "Cell", "Line", or "Block", like
-- v, V, and C-v in tmux's copy-mode.conf. Without a selection it starts
-- one at the cursor, even over a search match that WezTerm selected. The
-- same mode again clears it, and another mode switches it. The label
-- updates at once.
function M.select(mode)
  return wezterm.action_callback(function(window, pane)
    local id = pane:pane_id()
    local current = selections[id]
    local action = act.CopyMode({ SetSelectionMode = mode })
    if current == mode then
      mode, action = nil, act.CopyMode("ClearSelectionMode")
    elseif not current then
      action = act.Multiple({ act.CopyMode("ClearSelectionMode"), action })
    end
    selections[id] = mode
    window:perform_action(action, pane)
    refresh(window, pane)
  end)
end

-- Performs action, a copy, and emits "copied" with the copied size, since
-- the copy gives no other sign. A copy ends the copy-mode selection.
function M.copy(action)
  return wezterm.action_callback(function(window, pane)
    selections[pane:pane_id()] = nil
    local text = window:get_selection_text_for_pane(pane)
    window:perform_action(action, pane)
    if text ~= "" then
      wezterm.emit("copied", window, pane, utf8.len(text))
    else
      refresh(window, pane)
    end
  end)
end

-- Clears the copy-mode selection when the wheel scrolls, as tmux does,
-- and puts the cursor on the middle row. Otherwise the next key scrolls
-- back to where the cursor was.
function M.scrolled()
  return wezterm.action_callback(function(window, pane)
    if window:active_key_table() ~= "copy_mode" then
      return
    end
    selections[pane:pane_id()] = nil
    window:perform_action(
      act.Multiple({ act.CopyMode("ClearSelectionMode"), act.CopyMode("MoveToViewportMiddle") }),
      pane
    )
    refresh(window, pane)
  end)
end

return M
