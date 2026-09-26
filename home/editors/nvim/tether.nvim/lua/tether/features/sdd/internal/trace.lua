-- Traceability: which OpenSpec change a turn worked on, and which tasks it
-- checked off, read from the turn's diff.

local api = require("tether.api")
local root = require("tether.features.sdd.internal.root")

local M = {}

local attributed = {}

function M.reset()
  attributed = {}
end

---Changes a turn touched and the tasks it checked, from the turn's files.
---@param files tether.File[]
---@return {change: string, checked: string[]}[]
function M.trace(repo, files)
  local dir = root.get()
  if not dir or not api.util.inside(dir, repo.root) then
    return {}
  end
  local prefix = api.util.relative(dir, repo.root)
  prefix = prefix == repo.root and "" or (prefix .. "/")
  local by = {}
  local order = {}
  for _, f in ipairs(files) do
    local id, rest = f.path:match("^" .. vim.pesc(prefix) .. "changes/([^/]+)/(.*)$")
    if id and id ~= "archive" then
      if not by[id] then
        by[id] = { change = id, checked = {} }
        table.insert(order, id)
      end
      if rest == "tasks.md" then
        local before = {}
        for _, h in ipairs(f.hunks) do
          for _, l in ipairs(h.lines) do
            local tid = l:match("^%-%s*%- %[[xX]%]%s+(%d[%d%.]*)")
            if tid then
              before[tid:gsub("%.$", "")] = true
            end
          end
        end
        for _, h in ipairs(f.hunks) do
          for _, l in ipairs(h.lines) do
            local tid = l:match("^%+%s*%- %[[xX]%]%s+(%d[%d%.]*)")
            if tid then
              tid = tid:gsub("%.$", "")
              if not before[tid] then
                table.insert(by[id].checked, tid)
              end
            end
          end
        end
      end
    end
  end
  local out = {}
  for _, id in ipairs(order) do
    table.insert(out, by[id])
  end
  return out
end

---Records which agent checked which task, from a turn's files.
function M.attribute(repo, turn, files)
  for _, tr in ipairs(M.trace(repo, files)) do
    for _, tid in ipairs(tr.checked) do
      attributed[tr.change .. "\0" .. tid] = { agent = turn.agent, turn = turn.id }
    end
  end
end

function M.attributed(change_id, task_id)
  return attributed[change_id .. "\0" .. task_id]
end

return M
