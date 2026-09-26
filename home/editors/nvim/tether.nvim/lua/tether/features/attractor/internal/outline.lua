-- Outline buffer: the pipeline's nodes in breadth-first order from start.

local dot = require("tether.features.attractor.internal.dot")

local M = {}

---Lines of the outline and the node id of each line.
function M.lines(graph)
  local order = dot.bfs(graph)
  local lines, ids = {}, {}
  for i, id in ipairs(order) do
    local node = graph.nodes[id]
    local label = node.attrs.label and node.attrs.label ~= id and ("  " .. node.attrs.label) or ""
    table.insert(lines, ("%2d. %-16s [%s]%s"):format(i, id, node.handler, label))
    ids[#lines] = id
  end
  return lines, ids
end

---Opens the outline of the pipeline in src_buf in a split below.
function M.open(graph, src_buf)
  local src_win = vim.api.nvim_get_current_win()
  local lines, ids = M.lines(graph)
  vim.cmd("belowright split")
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_win_set_height(0, math.min(#lines + 1, 15))
  vim.keymap.set("n", "q", "<Cmd>close<CR>", { buffer = buf, nowait = true })
  vim.keymap.set("n", "<CR>", function()
    local id = ids[vim.fn.line(".")]
    local node = id and graph.nodes[id]
    if node and vim.api.nvim_win_is_valid(src_win) then
      vim.api.nvim_set_current_win(src_win)
      vim.api.nvim_win_set_buf(src_win, src_buf)
      vim.api.nvim_win_set_cursor(src_win, { node.line, 0 })
    end
  end, { buffer = buf, nowait = true })
  return buf
end

return M
