-- Workspaces replace tmux sessions: one per project, named after its
-- directory. The picker lists open workspaces first, then zoxide's
-- directories, so a project opens by name wherever it lives.
local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

-- Remembers the workspace being left, for `last`.
local function switch(window, pane, action)
  wezterm.GLOBAL.last_workspace = window:active_workspace()
  window:perform_action(action, pane)
end

-- Switches to the workspace, tab, and pane of a mux pane.
function M.focus(window, pane)
  if not pane then
    return
  end
  local tab, mux_window = pane:tab(), pane:window()
  if mux_window:get_workspace() ~= window:active_workspace() then
    switch(window, window:active_pane(), act.SwitchToWorkspace({ name = mux_window:get_workspace() }))
  end
  tab:activate()
  pane:activate()
end

function M.picker()
  return wezterm.action_callback(function(window, pane)
    local choices, seen = {}, {}
    for _, name in ipairs(wezterm.mux.get_workspace_names()) do
      seen[name] = true
      table.insert(choices, { id = name, label = " " .. name })
    end

    local ok, dirs = wezterm.run_child_process({ "zoxide", "query", "--list" })
    for dir in (ok and dirs or ""):gmatch("[^\n]+") do
      local name = dir:match("([^/]+)/?$")
      if name and not seen[name] then
        seen[name] = true
        local label = dir:sub(1, #wezterm.home_dir) == wezterm.home_dir and "~" .. dir:sub(#wezterm.home_dir + 1) or dir
        table.insert(choices, { id = dir, label = " " .. label })
      end
    end

    window:perform_action(
      act.InputSelector({
        title = "workspaces",
        choices = choices,
        fuzzy = true,
        action = wezterm.action_callback(function(win, p, id)
          if not id then
            return
          end
          local name = id:match("([^/]+)/?$")
          switch(win, p, act.SwitchToWorkspace({ name = name, spawn = { cwd = id } }))
        end),
      }),
      pane
    )
  end)
end

function M.last()
  return wezterm.action_callback(function(window, pane)
    local name = wezterm.GLOBAL.last_workspace
    if name then
      switch(window, pane, act.SwitchToWorkspace({ name = name }))
    end
  end)
end

function M.create()
  return act.PromptInputLine({
    description = "New workspace:",
    action = wezterm.action_callback(function(window, pane, name)
      if name and name ~= "" then
        switch(window, pane, act.SwitchToWorkspace({ name = name }))
      end
    end),
  })
end

-- Fuzzy picker over every tab in every workspace, the former tmux
-- choose-window across sessions.
function M.tabs()
  return wezterm.action_callback(function(window, pane)
    local choices = {}
    for _, mux_window in ipairs(wezterm.mux.all_windows()) do
      for index, tab in ipairs(mux_window:tabs()) do
        local active = tab:active_pane()
        table.insert(choices, {
          id = tostring(active:pane_id()),
          label = mux_window:get_workspace() .. ":" .. index .. " " .. active:get_title(),
        })
      end
    end

    window:perform_action(
      act.InputSelector({
        title = "tabs",
        choices = choices,
        fuzzy = true,
        action = wezterm.action_callback(function(win, _, id)
          if id then
            M.focus(win, wezterm.mux.get_pane(tonumber(id)))
          end
        end),
      }),
      pane
    )
  end)
end

return M
