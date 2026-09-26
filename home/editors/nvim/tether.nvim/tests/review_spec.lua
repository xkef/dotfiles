local H = require("helpers")

-- A jj repository with one finished claude turn that changed files.
local function turn_repo(before, after)
  local dir = H.repo("jj", before)
  H.trail({ "turn", "claude", "the task" }, { cwd = dir })
  for rel, lines in pairs(after) do
    H.write(dir .. "/" .. rel, lines)
  end
  H.trail({ "stop", "claude" }, { cwd = dir })
  H.setup()
  return dir
end

local function find(lines, pattern)
  for i, l in ipairs(lines) do
    if l:find(pattern, 1, true) then
      return i
    end
  end
end

local function press(keys)
  vim.api.nvim_feedkeys(vim.keycode(keys), "xt", false)
end

local long = {}
for i = 1, 30 do
  long[i] = "line " .. i
end
local function edited(changes)
  local out = vim.deepcopy(long)
  for i, v in pairs(changes) do
    out[i] = v
  end
  return out
end

return {
  {
    "Latest turn by default",
    function()
      turn_repo({ ["a.txt"] = { "a" }, ["b.txt"] = { "b" } }, { ["a.txt"] = { "A" }, ["b.txt"] = { "B" } })
      local buf = require("tether").review()
      local lines = H.buf_lines(buf)
      H.contains(lines[1], "turn 1")
      H.contains(lines[1], "claude")
      H.contains(lines[1], "the task")
      H.contains(lines[2], "2 files")
      H.ok(find(lines, "b/a.txt") and find(lines, "b/b.txt"))
    end,
  },
  {
    "Empty scope",
    function()
      turn_repo({ ["a.txt"] = { "a" } }, {})
      local buf = require("tether").review()
      H.contains(H.buf_lines(buf), "Nothing to review.")
    end,
  },
  {
    "Skip reviewed hunks",
    function()
      turn_repo({ ["a.txt"] = long }, { ["a.txt"] = edited({ [2] = "X", [15] = "Y", [28] = "Z" }) })
      local buf = require("tether").review()
      local lines = H.buf_lines(buf)
      local first = find(lines, "@@")
      vim.api.nvim_win_set_cursor(0, { first, 0 })
      press("a")
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      press("]h")
      local cur = vim.fn.line(".")
      H.ok(cur > first, "moved past the accepted hunk")
      H.contains(H.buf_lines(buf)[cur], "@@")
      H.contains(table.concat(H.buf_lines(buf), "\n", cur, cur + 6), "+Y")
    end,
  },
  {
    "Accepted hunk stays accepted",
    function()
      turn_repo({ ["a.txt"] = long }, { ["a.txt"] = edited({ [2] = "X", [28] = "Z" }) })
      local tether = require("tether")
      local buf = tether.review()
      H.contains(H.buf_lines(buf)[2], "2 unreviewed")
      vim.api.nvim_win_set_cursor(0, { find(H.buf_lines(buf), "@@"), 0 })
      press("a")
      press("q")
      require("tether.review").reset()
      buf = tether.review()
      H.contains(H.buf_lines(buf)[2], "1 unreviewed")
      H.contains(H.virt_text(buf), "accepted")
    end,
  },
  {
    "Reject restores old lines",
    function()
      local dir = turn_repo({ ["a.txt"] = { "a", "b", "c" } }, { ["a.txt"] = { "a", "B", "c" } })
      local buf = require("tether").review()
      vim.api.nvim_win_set_cursor(0, { find(H.buf_lines(buf), "+B"), 0 })
      press("x")
      H.eq({ "a", "b", "c" }, H.read(dir .. "/a.txt"))
      H.contains(H.buf_lines(buf)[2], "0 unreviewed")
      H.contains(H.virt_text(buf), "rejected")
    end,
  },
  {
    "Reject after further edits",
    function()
      local dir = turn_repo({ ["a.txt"] = { "a", "b", "c" } }, { ["a.txt"] = { "a", "B", "c" } })
      local buf = require("tether").review()
      H.write(dir .. "/a.txt", { "a", "user", "c" })
      vim.api.nvim_win_set_cursor(0, { find(H.buf_lines(buf), "+B"), 0 })
      press("x")
      H.eq({ "a", "user", "c" }, H.read(dir .. "/a.txt"))
      H.contains(H.note_text(), "stale")
    end,
  },
  {
    "Reject in a loaded buffer",
    function()
      local dir = turn_repo({ ["a.txt"] = { "a", "b", "c" } }, { ["a.txt"] = { "a", "B", "c" } })
      vim.cmd("edit " .. dir .. "/a.txt")
      local fbuf = vim.api.nvim_get_current_buf()
      local buf = require("tether").review()
      vim.api.nvim_win_set_cursor(0, { find(H.buf_lines(buf), "+B"), 0 })
      press("x")
      H.eq({ "a", "b", "c" }, H.buf_lines(fbuf))
      H.eq({ "a", "b", "c" }, H.read(dir .. "/a.txt"))
    end,
  },
  {
    "Comment anchored to the new line number",
    function()
      local dir = turn_repo({ ["a.txt"] = long }, { ["a.txt"] = edited({ [12] = "changed" }) })
      local buf = require("tether").review()
      vim.api.nvim_win_set_cursor(0, { find(H.buf_lines(buf), "+changed"), 0 })
      H.input("why this?")
      press("c")
      local c = require("tether.review").comments[1]
      H.eq({ dir .. "/a.txt", 12, "why this?" }, { c.path, c.line, c.text })
    end,
  },
  {
    "Built-in diff tab",
    function()
      turn_repo({ ["a.txt"] = { "a", "b" } }, { ["a.txt"] = { "a", "B" } })
      local buf = require("tether").review()
      local tabs = vim.fn.tabpagenr("$")
      vim.api.nvim_win_set_cursor(0, { find(H.buf_lines(buf), "+B"), 0 })
      press("<CR>")
      H.eq(tabs + 1, vim.fn.tabpagenr("$"))
      local wins = vim.api.nvim_tabpage_list_wins(0)
      H.eq(2, #wins)
      local scratch
      for _, w in ipairs(wins) do
        H.eq(true, vim.wo[w].diff)
        local b = vim.api.nvim_win_get_buf(w)
        if vim.bo[b].buftype == "nofile" then
          scratch = b
        end
      end
      H.ok(scratch, "scratch base buffer")
      H.eq({ "a", "b" }, H.buf_lines(scratch))
      H.eq(2, vim.fn.line("."), "cursor on the changed line")
    end,
  },
  {
    "Hunks to quickfix",
    function()
      turn_repo({ ["a.txt"] = long }, { ["a.txt"] = edited({ [2] = "X", [15] = "Y", [28] = "Z" }) })
      local items = require("tether").hunks()
      H.eq(3, #items)
      local qf = vim.fn.getqflist()
      H.eq(3, #qf)
      H.eq({ 2, 15, 28 }, { qf[1].lnum, qf[2].lnum, qf[3].lnum })
    end,
  },
  {
    "Key help",
    function()
      turn_repo({ ["a.txt"] = { "a" } }, { ["a.txt"] = { "b" } })
      require("tether").review()
      press("g?")
      H.contains(H.note_text(), "accept hunk")
      H.contains(H.note_text(), "reject hunk")
    end,
  },
  {
    "Review of the working-copy change",
    function()
      local dir = H.repo("jj", { ["a.txt"] = { "a" } })
      H.write(dir .. "/a.txt", { "changed" })
      H.setup()
      local buf = require("tether").review("change")
      H.contains(H.buf_lines(buf), "+changed")
    end,
  },
  {
    "Review on Git",
    function()
      local dir = H.repo("git", { ["a.txt"] = { "a", "b" } })
      H.trail({ "turn", "pi" }, { cwd = dir })
      H.write(dir .. "/a.txt", { "a", "B" })
      H.setup()
      local buf = require("tether").review()
      H.contains(H.buf_lines(buf)[1], "running")
      H.contains(H.buf_lines(buf), "+B")
    end,
  },
}
