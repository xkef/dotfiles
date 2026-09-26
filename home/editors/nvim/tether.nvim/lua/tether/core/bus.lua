-- Typed in-process notifications between tiers, mirrored as User autocmds
-- for configuration code: "stop" fires TetherTurnStop, "conflict" fires
-- TetherConflict.

local M = {}

M.AUTOCMDS = {
  stop = "TetherTurnStop",
  conflict = "TetherConflict",
}

local handlers = {}

---Registers fn(data) for a notification. Returns a function that removes it.
function M.on(name, fn)
  handlers[name] = handlers[name] or {}
  table.insert(handlers[name], fn)
  return function()
    handlers[name] = vim.tbl_filter(function(f)
      return f ~= fn
    end, handlers[name] or {})
  end
end

function M.emit(name, data)
  for _, fn in ipairs(handlers[name] or {}) do
    local ok, err = pcall(fn, data)
    if not ok then
      vim.notify("tether: " .. name .. " handler failed: " .. tostring(err), vim.log.levels.WARN)
    end
  end
  local pattern = M.AUTOCMDS[name]
  if pattern then
    vim.api.nvim_exec_autocmds("User", { pattern = pattern, data = data })
  end
end

function M.reset()
  handlers = {}
end

return M
