-- Live agents from `agent-state list`: pane, agent, state, tool, epoch,
-- cwd, and task per line, "-" for empty.

local config = require("tether.config")
local util = require("tether.util")

local M = {}

local cache = { t = 0, rows = {} }

M.TTL_MS = 1000

---@class tether.Agent
---@field pane string wezterm-<id>
---@field pane_id? string
---@field agent string
---@field state string
---@field tool? string
---@field epoch? integer
---@field cwd? string
---@field task? string

local function parse(stdout)
  local rows = {}
  for _, line in ipairs(util.lines(stdout)) do
    local f = vim.split(line, "\t", { plain = true })
    if #f >= 6 then
      local function v(i)
        return f[i] ~= "-" and f[i] ~= "" and f[i] or nil
      end
      table.insert(rows, {
        pane = f[1],
        pane_id = f[1]:match("(%d+)$"),
        agent = v(2) or "?",
        state = v(3) or "?",
        tool = v(4),
        epoch = tonumber(v(5) or ""),
        cwd = v(6) and util.normalize(v(6)) or nil,
        task = v(7),
      })
    end
  end
  return rows
end

---@return tether.Agent[]
function M.list(force)
  local now = vim.uv.now()
  if not force and now - cache.t < M.TTL_MS then
    return cache.rows
  end
  local cmd = config.options.agent_state
  if vim.fn.executable(cmd) == 0 then
    cache = { t = now, rows = {} }
    return {}
  end
  local res = util.run({ cmd, "list" })
  cache = { t = now, rows = res.code == 0 and parse(res.stdout) or {} }
  return cache.rows
end

---Agents whose cwd lies inside root.
function M.in_root(root, force)
  return vim.tbl_filter(function(a)
    return util.inside(a.cwd, root)
  end, M.list(force))
end

function M.reset()
  cache = { t = 0, rows = {} }
end

return M
