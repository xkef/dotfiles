-- Delivers text to the agent working on the current repository.

local agents = require("tether.core.agents")
local config = require("tether.config")
local review = require("tether.ui.review")
local util = require("tether.core.util")

local M = {}

---Pastes text into a WezTerm pane, or copies it to the + register.
---@param agent? tether.Agent
function M.deliver(agent, text)
  local wezterm = config.options.send.wezterm
  if agent and agent.pane_id and vim.fn.executable(wezterm) == 1 then
    local res = util.run({ wezterm, "cli", "send-text", "--pane-id", agent.pane_id }, { stdin = text })
    if res.code == 0 then
      if config.options.send.submit then
        util.run({ wezterm, "cli", "send-text", "--pane-id", agent.pane_id, "--no-paste" }, { stdin = "\r" })
      end
      util.notify("sent to " .. agent.agent .. " (pane " .. agent.pane_id .. ")")
      return true
    end
    util.warn("wezterm send-text failed: " .. res.stderr)
  end
  local reg = M.copy(text)
  local where = "copied to the " .. reg .. " register"
  util.notify(agent and where or ("no agent in this repository; " .. where))
  return false
end

---Copies text to the clipboard register, or the unnamed one without a
---clipboard provider. Returns the register name.
function M.copy(text)
  vim.fn.setreg('"', text)
  if vim.fn.has("clipboard") == 1 and pcall(vim.fn.setreg, "+", text) and vim.fn.getreg("+") == text then
    return "+"
  end
  return '"'
end

---Resolves the target agent for a root and calls cb(agent or nil).
function M.target(root, cb, prefer)
  local list = agents.in_root(root, true)
  if prefer then
    for _, a in ipairs(list) do
      if a.pane == prefer.pane then
        return cb(a)
      end
    end
  end
  if #list <= 1 then
    return cb(list[1])
  end
  vim.ui.select(list, {
    prompt = "Send to agent",
    format_item = function(a)
      return ("%s  %s  %s"):format(a.agent, a.state, a.task or util.relative(a.cwd or "", root))
    end,
  }, function(choice)
    if choice then
      cb(choice)
    end
  end)
end

function M.text(root, text, prefer)
  M.target(root, function(agent)
    M.deliver(agent, text)
  end, prefer)
end

---Pending comments of a root as one message, or nil.
function M.comments_message(root)
  local mine = vim.tbl_filter(function(c)
    return c.root == root
  end, review.comments)
  if #mine == 0 then
    return nil
  end
  table.sort(mine, function(a, b)
    if a.path == b.path then
      return a.line < b.line
    end
    return a.path < b.path
  end)
  local out = { "Review comments:" }
  for _, c in ipairs(mine) do
    table.insert(out, ("%s:%d: %s"):format(util.relative(c.path, root), c.line, c.text))
    if c.snippet and vim.trim(c.snippet) ~= "" then
      table.insert(out, "  > " .. vim.trim(c.snippet))
    end
  end
  return table.concat(out, "\n") .. "\n"
end

---Reference to a range of the current buffer with its text.
function M.selection_message(root, buf, l1, l2)
  if l1 > l2 then
    l1, l2 = l2, l1
  end
  local path = util.relative(util.normalize(vim.api.nvim_buf_get_name(buf)), root)
  local lines = vim.api.nvim_buf_get_lines(buf, l1 - 1, l2, false)
  local ref = l1 == l2 and ("@%s#L%d"):format(path, l1) or ("@%s#L%d-%d"):format(path, l1, l2)
  local ft = vim.bo[buf].filetype
  return ref .. "\n```" .. ft .. "\n" .. table.concat(lines, "\n") .. "\n```\n"
end

---Sends comments when pending, else the selection or the current file.
---@param range? {[1]: integer, [2]: integer}
function M.send(repo, range)
  local root = repo.root
  local msg = M.comments_message(root)
  if msg then
    M.target(root, function(agent)
      M.deliver(agent, msg)
      review.clear_comments(root)
    end)
    return msg
  end
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].buftype ~= "" then
    util.warn("nothing to send from this buffer")
    return nil
  end
  if range then
    msg = M.selection_message(root, buf, range[1], range[2])
  else
    msg = "@" .. util.relative(util.normalize(vim.api.nvim_buf_get_name(buf)), root) .. " "
  end
  M.text(root, msg)
  return msg
end

return M
