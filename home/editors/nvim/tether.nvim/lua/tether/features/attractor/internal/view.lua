-- Node status as virtual text on node definition lines.

local M = {}

local ns = vim.api.nvim_create_namespace("tether.features.attractor.status")

M.ICONS = {
  running = { "… running", "TetherWaiting" },
  waiting = { "? waiting for you", "TetherWaiting" },
  success = { "✓ success", "TetherReviewed" },
  partial = { "◐ partial", "TetherReviewed" },
  fail = { "✗ fail", "TetherRejected" },
  retry = { "↻ retry", "TetherWaiting" },
  skipped = { "⤼ skipped", "TetherMuted" },
}

---@param run table active run with buf, graph, statuses
function M.render(run)
  local buf = run and run.buf
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then
    return
  end
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  if not run.graph then
    return
  end
  local count = vim.api.nvim_buf_line_count(buf)
  for id, status in pairs(run.statuses) do
    local node = run.graph.nodes[id]
    local icon = M.ICONS[status]
    if node and icon and node.line <= count then
      vim.api.nvim_buf_set_extmark(buf, ns, node.line - 1, 0, {
        virt_text = { { "  " .. icon[1], icon[2] } },
        virt_text_pos = "eol",
      })
    end
  end
end

function M.clear(buf)
  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  end
end

return M
