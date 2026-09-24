-- Coding-agent state. `agent-state` sets these user vars on the agent's
-- pane over OSC 1337, and WezTerm stores them with the pane:
--
--   agent         agent name, such as claude
--   agent_state   waiting, busy, or idle. Empty means no agent.
--   agent_detail  the tool in use, or the message that asks for input
--   agent_task    the summary the agent publishes for its goal
--
-- The state dies with the pane, so a closed pane needs no cleanup.
local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

-- Glyph weight encodes the state, so the status line needs no color. A
-- filled dot needs input, a ring works, a small dot idles.
local ICON = { waiting = "•", busy = "◦", idle = "·" }
local COLOR = { waiting = "Maroon", busy = "Olive", idle = "Grey" }
local ORDER = { "waiting", "busy", "idle" }
local RANK = { waiting = 1, busy = 2, idle = 3 }

local function state_of(vars)
  local state = vars.agent_state
  if state == nil or state == "" then
    return nil
  end
  return RANK[state] and state or "idle"
end

local function human_age(seconds)
  if seconds < 60 then
    return seconds .. "s"
  end
  if seconds < 3600 then
    return seconds // 60 .. "m"
  end
  return seconds // 3600 .. "h"
end

-- Every pane that runs an agent, across all windows and workspaces, with
-- waiting agents first.
function M.list()
  local since = wezterm.GLOBAL.agent_since or {}
  local agents = {}
  for _, window in ipairs(wezterm.mux.all_windows()) do
    for index, tab in ipairs(window:tabs()) do
      for _, pane in ipairs(tab:panes()) do
        local vars = pane:get_user_vars()
        local state = state_of(vars)
        if state then
          local id = pane:pane_id()
          table.insert(agents, {
            id = id,
            state = state,
            agent = vars.agent or "?",
            detail = vars.agent_detail or "",
            task = vars.agent_task or "",
            workspace = window:get_workspace(),
            tab = index,
            age = human_age(os.time() - (since[tostring(id)] or os.time())),
          })
        end
      end
    end
  end
  table.sort(agents, function(a, b)
    return RANK[a.state] < RANK[b.state]
  end)
  return agents
end

-- Status line segment such as "2• 1◦", empty when no agent runs.
function M.count()
  local counts = {}
  for _, agent in ipairs(M.list()) do
    counts[agent.state] = (counts[agent.state] or 0) + 1
  end
  local parts = {}
  for _, state in ipairs(ORDER) do
    if counts[state] then
      table.insert(parts, counts[state] .. ICON[state])
    end
  end
  return table.concat(parts, " ")
end

local function pad(text, width)
  return text .. string.rep(" ", width - wezterm.column_width(text))
end

-- Fuzzy picker over every agent. Enter switches to the agent's workspace
-- and pane.
function M.picker()
  return wezterm.action_callback(function(window, pane)
    local agents = M.list()
    if #agents == 0 then
      window:toast_notification("wezterm", "No agents running", nil, 2000)
      return
    end

    local width = { agent = 0, where = 0, task = 0 }
    for _, a in ipairs(agents) do
      a.where = a.workspace .. ":" .. a.tab
      width.agent = math.max(width.agent, #a.agent)
      width.where = math.max(width.where, #a.where)
      width.task = math.max(width.task, wezterm.column_width(a.task))
    end

    local choices = {}
    for _, a in ipairs(agents) do
      table.insert(choices, {
        id = tostring(a.id),
        label = wezterm.format({
          { Foreground = { AnsiColor = COLOR[a.state] } },
          { Text = ICON[a.state] .. " " .. pad(a.state, 7) },
          "ResetAttributes",
          { Text = "  " .. pad(a.agent, width.agent) .. "  " .. pad(a.where, width.where) },
          { Text = "  " .. pad(a.task, width.task) .. "  " .. a.detail },
          { Attribute = { Intensity = "Half" } },
          { Text = "  " .. a.age },
        }),
      })
    end

    window:perform_action(
      act.InputSelector({
        title = "agents",
        choices = choices,
        fuzzy = true,
        action = wezterm.action_callback(function(win, _, id)
          if id then
            require("workspaces").focus(win, wezterm.mux.get_pane(tonumber(id)))
          end
        end),
      }),
      pane
    )
  end)
end

-- Records when each agent entered its state, for the picker's age column.
function M.setup()
  wezterm.on("user-var-changed", function(_, pane, name)
    if name == "agent_state" then
      local since = wezterm.GLOBAL.agent_since or {}
      since[tostring(pane:pane_id())] = os.time()
      wezterm.GLOBAL.agent_since = since
    end
  end)
end

return M
