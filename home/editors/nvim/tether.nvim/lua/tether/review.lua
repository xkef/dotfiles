-- The review buffer: one diff of a scope, grouped by file, with accept,
-- reject, and comments per hunk.

local diff = require("tether.diff")
local turns = require("tether.turns")
local util = require("tether.util")
local vcs = require("tether.vcs")

local M = {}

local ns = vim.api.nvim_create_namespace("tether.review")
local ns_comments = vim.api.nvim_create_namespace("tether.comments")

M.KEYS = {
  { "a", "accept hunk" },
  { "A", "accept file" },
  { "x", "reject hunk (revert it in the working file)" },
  { "X", "reject file" },
  { "]h", "next unreviewed hunk" },
  { "[h", "previous unreviewed hunk" },
  { "c", "comment on the line" },
  { "<CR>", "side-by-side diff of the file" },
  { "gq", "unreviewed hunks to quickfix" },
  { "R", "refresh" },
  { "q", "close" },
  { "g?", "this help" },
}

-- Review state of the open buffer.
local R = {}

-- Pending comments: { root, path, line, text, snippet }.
M.comments = {}

-- Unreviewed hunks of the latest computed turn, for the statusline.
M.last = {}

----------------------------------------------------------------------------
-- Reviewed store: root -> hash -> { s = "a"|"r", t = epoch }

local store

local function store_path()
  return util.state_file("reviewed.json")
end

local function load_store()
  if store then
    return store
  end
  store = util.read_json(store_path()) or {}
  local cutoff = os.time() - require("tether.config").options.review.keep_days * 86400
  for _, hashes in pairs(store) do
    for h, v in pairs(hashes) do
      if type(v) ~= "table" or (v.t or 0) < cutoff then
        hashes[h] = nil
      end
    end
  end
  return store
end

function M.status_of(root, hash)
  local s = load_store()[root]
  return s and s[hash] and s[hash].s or nil
end

function M.mark(root, hash, status)
  local s = load_store()
  s[root] = s[root] or {}
  s[root][hash] = status and { s = status, t = os.time() } or nil
  util.write_json(store_path(), s)
end

function M.reset()
  store = nil
  R = {}
  M.comments = {}
  M.last = {}
end

---Counts files, hunks, and unreviewed hunks.
function M.count(root, files)
  local hunks, open = 0, 0
  for _, f in ipairs(files) do
    for _, h in ipairs(f.hunks) do
      hunks = hunks + 1
      if not M.status_of(root, h.hash) then
        open = open + 1
      end
    end
  end
  return #files, hunks, open
end

----------------------------------------------------------------------------
-- Reverting a hunk in the working file

local function match_at(cur, s, block)
  if s < 1 or s + #block - 1 > #cur then
    return false
  end
  for i, l in ipairs(block) do
    if cur[s + i - 1] ~= l then
      return false
    end
  end
  return true
end

local function find_unique(cur, block)
  local found
  for s = 1, #cur - #block + 1 do
    if match_at(cur, s, block) then
      if found then
        return nil
      end
      found = s
    end
  end
  return found
end

local function write(path, lines, buf)
  if buf then
    vim.api.nvim_buf_call(buf, function()
      vim.cmd("silent noautocmd write")
    end)
    return
  end
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile(lines, path)
end

---Replaces the hunk's new lines in the working file with its old lines.
---@return boolean ok, string? err
function M.revert(root, hunk)
  local path = vim.fs.joinpath(root, hunk.path)
  local new, old = diff.side(hunk, true), diff.side(hunk, false)
  local cur, buf = util.content(path)
  if buf and vim.bo[buf].modified then
    return false, hunk.path .. " has unsaved changes"
  end
  cur = cur or {}
  local s
  if #new == 0 then
    s = hunk.new_start + 1
    if s - 1 > #cur then
      return false, "hunk is stale; refresh the review"
    end
  else
    s = match_at(cur, hunk.new_start, new) and hunk.new_start or find_unique(cur, new)
    if not s then
      return false, "hunk is stale; refresh the review"
    end
  end
  if buf then
    vim.api.nvim_buf_set_lines(buf, s - 1, s - 1 + #new, false, old)
    write(path, nil, buf)
    return true
  end
  local out = {}
  vim.list_extend(out, cur, 1, s - 1)
  vim.list_extend(out, old)
  vim.list_extend(out, cur, s + #new)
  write(path, out)
  return true
end

---Reverts a whole file: removes an added file, restores a deleted one,
---and reverts every hunk bottom-up otherwise.
function M.revert_file(root, file)
  local path = vim.fs.joinpath(root, file.path)
  if file.status == "A" then
    local buf = vim.fn.bufnr(path)
    if buf > 0 then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
    os.remove(path)
    return true
  end
  for i = #file.hunks, 1, -1 do
    local ok, err = M.revert(root, file.hunks[i])
    if not ok then
      return false, err
    end
  end
  return true
end

----------------------------------------------------------------------------
-- Rendering

local function hl(buf, line, col_start, col_end, group, prio)
  vim.api.nvim_buf_set_extmark(buf, ns, line, col_start, {
    end_row = col_end and line or line + 1,
    end_col = col_end or 0,
    hl_group = group,
    hl_eol = col_end == nil,
    priority = prio or 150,
  })
end

local function render_comments(buf)
  vim.api.nvim_buf_clear_namespace(buf, ns_comments, 0, -1)
  for lnum, entry in pairs(R.map or {}) do
    for _, c in ipairs(M.comments) do
      if c.root == R.repo.root and c.path == entry.abs and c.line == entry.new then
        vim.api.nvim_buf_set_extmark(buf, ns_comments, lnum - 1, 0, {
          virt_lines = { { { "  💬 " .. c.text, "TetherComment" } } },
        })
      end
    end
  end
end

local function render()
  local buf = R.buf
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then
    return
  end
  local root = R.repo.root
  local scope, files = R.scope, R.files
  local lines, map, hunks, file_lines = {}, {}, {}, {}
  local t = scope.turn
  local title = "Review: " .. scope.label
  if t then
    title = title .. " · " .. t.agent .. (t.summary and (" · " .. t.summary) or "")
  end
  local nfiles, nhunks, open = M.count(root, files)
  if t then
    M.last = { turn = t.id, unreviewed = open }
  end
  table.insert(lines, title)
  local range = scope.range
  local span = range.rev and ("rev " .. range.rev)
    or ((range.from or "?"):sub(1, 8) .. ".." .. (range.to and range.to:sub(1, 8) or "working copy"))
  table.insert(lines, ("%d files · %d hunks · %d unreviewed · %s"):format(nfiles, nhunks, open, span))
  for _, extra in ipairs(R.header or {}) do
    table.insert(lines, extra)
  end
  table.insert(lines, "")
  if #files == 0 then
    table.insert(lines, "Nothing to review.")
  end
  for _, f in ipairs(files) do
    table.insert(lines, ("diff --git a/%s b/%s"):format(f.old_path, f.path))
    file_lines[#lines] = f
    local abs = vim.fs.joinpath(root, f.path)
    for _, h in ipairs(f.hunks) do
      table.insert(lines, h.header)
      local entry = { hunk = h, file = f, first = #lines }
      map[#lines] = { hunk = h, file = f, abs = abs, new = diff.first_change(h) }
      local o, n = h.old_start, h.new_start
      for _, l in ipairs(h.lines) do
        table.insert(lines, l)
        local c = l:sub(1, 1)
        local m = { hunk = h, file = f, abs = abs }
        if c == " " then
          m.old, m.new = o, n
          o, n = o + 1, n + 1
        elseif c == "-" then
          m.old, m.anchor = o, math.max(n - 1, 1)
          o = o + 1
        else
          m.new = n
          n = n + 1
        end
        map[#lines] = m
      end
      entry.last = #lines
      table.insert(hunks, entry)
    end
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].modified = false
  R.map, R.hunks, R.file_lines = map, hunks, file_lines

  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  hl(buf, 0, 0, nil, "TetherHeader")
  hl(buf, 1, 0, nil, "TetherMuted")
  for lnum, f in pairs(file_lines) do
    vim.api.nvim_buf_set_extmark(buf, ns, lnum - 1, 0, {
      virt_text = { { ("  +%d -%d  %s"):format(f.added, f.removed, f.status), "TetherMuted" } },
    })
  end
  for _, e in ipairs(hunks) do
    local s = M.status_of(root, e.hunk.hash)
    if s then
      vim.api.nvim_buf_set_extmark(buf, ns, e.first - 1, 0, {
        virt_text = {
          s == "a" and { "  ✓ accepted", "TetherReviewed" } or { "  ✗ rejected", "TetherRejected" },
        },
      })
      for l = e.first + 1, e.last do
        hl(buf, l - 1, 0, nil, "TetherDim", 200)
      end
    end
  end
  render_comments(buf)
end

local function compute(opts)
  opts = opts or {}
  local scope, err = turns.scope(R.repo, R.scope_name, { turn = R.turn, snapshot = opts.snapshot ~= false })
  if not scope then
    return nil, err
  end
  local files
  files, err = turns.files(R.repo, scope)
  if not files then
    return nil, err
  end
  R.scope, R.files = scope, files
  R.header = {}
  for _, fn in ipairs(M.header_providers) do
    local ok, extra = pcall(fn, R.repo, scope, files)
    if ok and extra then
      vim.list_extend(R.header, type(extra) == "table" and extra or { extra })
    end
  end
  return true
end

-- Functions (repo, scope, files) -> string|string[] adding header lines.
M.header_providers = {}

function M.refresh(opts)
  if not R.buf then
    return
  end
  local ok, err = compute(opts)
  if not ok then
    util.warn(err)
    return
  end
  render()
end

----------------------------------------------------------------------------
-- Actions

local function entry_at(lnum)
  if not R.map then
    return nil
  end
  return R.map[lnum]
end

local function file_at(lnum)
  local e = entry_at(lnum)
  if e then
    return e.file
  end
  return R.file_lines and R.file_lines[lnum]
end

local function goto_hunk(dir, from)
  local list = {}
  for _, e in ipairs(R.hunks or {}) do
    if not M.status_of(R.repo.root, e.hunk.hash) then
      table.insert(list, e)
    end
  end
  if #list == 0 then
    return false
  end
  local target
  if dir > 0 then
    for _, e in ipairs(list) do
      if e.first > from then
        target = e
        break
      end
    end
    target = target or list[1]
  else
    for i = #list, 1, -1 do
      if list[i].first < from then
        target = list[i]
        break
      end
    end
    target = target or list[#list]
  end
  local win = vim.fn.bufwinid(R.buf)
  if win ~= -1 then
    vim.api.nvim_win_set_cursor(win, { target.first, 0 })
  end
  return true
end

function M.next_hunk()
  goto_hunk(1, vim.fn.line("."))
end

function M.prev_hunk()
  goto_hunk(-1, vim.fn.line("."))
end

local function set_status(hunks, status)
  for _, h in ipairs(hunks) do
    M.mark(R.repo.root, h.hash, status)
  end
end

function M.accept(whole_file)
  local lnum = vim.fn.line(".")
  local e = entry_at(lnum)
  local f = file_at(lnum)
  if whole_file and f then
    set_status(f.hunks, "a")
  elseif e then
    set_status({ e.hunk }, "a")
  else
    return
  end
  render()
  goto_hunk(1, lnum)
end

function M.reject(whole_file)
  local lnum = vim.fn.line(".")
  local e = entry_at(lnum)
  local f = file_at(lnum)
  local ok, err
  if whole_file and f then
    ok, err = M.revert_file(R.repo.root, f)
    if ok then
      set_status(f.hunks, "r")
    end
  elseif e then
    ok, err = M.revert(R.repo.root, e.hunk)
    if ok then
      set_status({ e.hunk }, "r")
    end
  else
    return
  end
  if not ok then
    util.warn(err)
    return
  end
  M.refresh()
  local win = vim.fn.bufwinid(R.buf)
  if win ~= -1 then
    vim.api.nvim_win_set_cursor(win, { math.min(lnum, vim.api.nvim_buf_line_count(R.buf)), 0 })
  end
end

---Adds a pending comment. Without text it prompts.
function M.add_comment(root, path, line, snippet, text)
  local function add(t)
    if not t or t == "" then
      return
    end
    table.insert(M.comments, { root = root, path = path, line = line, text = t, snippet = snippet })
    if R.buf and vim.api.nvim_buf_is_valid(R.buf) then
      render_comments(R.buf)
    end
    local buf = vim.fn.bufnr(path)
    if buf > 0 and vim.api.nvim_buf_is_loaded(buf) and line <= vim.api.nvim_buf_line_count(buf) then
      vim.api.nvim_buf_set_extmark(buf, ns_comments, line - 1, 0, {
        virt_lines = { { { "  💬 " .. t, "TetherComment" } } },
      })
    end
  end
  if text then
    add(text)
  else
    vim.ui.input({ prompt = ("Comment on %s:%d: "):format(util.relative(path, root), line) }, add)
  end
end

function M.comment(text)
  local lnum = vim.fn.line(".")
  local e = entry_at(lnum)
  if not e then
    return
  end
  local line = e.new or e.anchor
  local body = vim.api.nvim_buf_get_lines(R.buf, lnum - 1, lnum, false)[1] or ""
  M.add_comment(R.repo.root, e.abs, line, body:sub(2), text)
end

---Comment on the cursor line of a file buffer.
function M.comment_here(repo, text)
  local path = util.normalize(vim.api.nvim_buf_get_name(0))
  local line = vim.fn.line(".")
  M.add_comment(repo.root, path, line, vim.api.nvim_get_current_line(), text)
end

function M.clear_comments(root)
  M.comments = vim.tbl_filter(function(c)
    return c.root ~= root
  end, M.comments)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    vim.api.nvim_buf_clear_namespace(buf, ns_comments, 0, -1)
  end
end

local diff_seq = 0

---Opens a tab with the file's base content and the working file in diff
---mode.
function M.split(repo, range, file, lnum)
  local abs = vim.fs.joinpath(repo.root, file.path)
  local base = {}
  if file.status ~= "A" then
    base = vcs.show(repo, vcs.base(repo, range), file.old_path) or {}
  end
  vim.cmd("tabnew " .. vim.fn.fnameescape(abs))
  local right = vim.api.nvim_get_current_win()
  vim.cmd("leftabove vnew")
  local sbuf = vim.api.nvim_get_current_buf()
  diff_seq = diff_seq + 1
  pcall(vim.api.nvim_buf_set_name, sbuf, ("tether://base/%d/%s"):format(diff_seq, file.old_path))
  vim.api.nvim_buf_set_lines(sbuf, 0, -1, false, base)
  vim.bo[sbuf].buftype = "nofile"
  vim.bo[sbuf].bufhidden = "wipe"
  vim.bo[sbuf].modifiable = false
  local ft = vim.filetype.match({ filename = abs })
  if ft then
    vim.bo[sbuf].filetype = ft
  end
  vim.cmd("diffthis")
  vim.keymap.set("n", "q", "<Cmd>tabclose<CR>", { buffer = sbuf, desc = "Close diff" })
  vim.api.nvim_set_current_win(right)
  vim.cmd("diffthis")
  local rbuf = vim.api.nvim_get_current_buf()
  vim.api.nvim_create_autocmd({ "BufReadPost", "FileChangedShellPost", "BufWritePost" }, {
    buffer = rbuf,
    group = vim.api.nvim_create_augroup("tether.split." .. rbuf, { clear = true }),
    callback = function()
      pcall(vim.cmd, "diffupdate")
    end,
  })
  if lnum then
    pcall(vim.api.nvim_win_set_cursor, right, { lnum, 0 })
  end
  return sbuf, rbuf
end

function M.open_split()
  local lnum = vim.fn.line(".")
  local f = file_at(lnum)
  if not f then
    return
  end
  local e = entry_at(lnum)
  M.split(R.repo, R.scope.range, f, e and (e.new or e.anchor))
end

---Quickfix items for unreviewed hunks.
function M.qf_items(root, files)
  local items = {}
  for _, f in ipairs(files) do
    for _, h in ipairs(f.hunks) do
      if not M.status_of(root, h.hash) then
        local lnum, text = diff.first_change(h)
        table.insert(items, { filename = vim.fs.joinpath(root, f.path), lnum = lnum, text = text })
      end
    end
  end
  return items
end

function M.quickfix(repo, files)
  local items = M.qf_items(repo.root, files)
  vim.fn.setqflist({}, " ", { title = "tether: unreviewed hunks", items = items })
  return items
end

function M.help()
  local out = {}
  for _, k in ipairs(M.KEYS) do
    table.insert(out, ("%-5s %s"):format(k[1], k[2]))
  end
  util.notify(table.concat(out, "\n"))
  return out
end

function M.close()
  if R.buf and vim.api.nvim_buf_is_valid(R.buf) then
    if vim.fn.tabpagenr("$") > 1 and vim.fn.bufwinid(R.buf) == vim.api.nvim_get_current_win() then
      vim.cmd("tabclose")
    end
    pcall(vim.api.nvim_buf_delete, R.buf, { force = true })
  end
  R.buf = nil
end

local function setup_buffer(buf)
  local function map(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true, desc = desc })
  end
  map("a", function()
    M.accept(false)
  end, "Accept hunk")
  map("A", function()
    M.accept(true)
  end, "Accept file")
  map("x", function()
    M.reject(false)
  end, "Reject hunk")
  map("X", function()
    M.reject(true)
  end, "Reject file")
  map("]h", M.next_hunk, "Next unreviewed hunk")
  map("[h", M.prev_hunk, "Previous unreviewed hunk")
  map("c", function()
    M.comment()
  end, "Comment")
  map("<CR>", M.open_split, "Side-by-side diff")
  map("gq", function()
    M.quickfix(R.repo, R.files)
    vim.cmd("copen")
  end, "Hunks to quickfix")
  map("R", function()
    M.refresh()
  end, "Refresh")
  map("q", M.close, "Close review")
  map("g?", M.help, "Review keys")
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "diff"
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = buf,
    callback = function()
      if R.buf == buf then
        R.buf = nil
      end
    end,
  })
end

---Opens the review buffer for a scope.
---@param opts? {turn?: tether.Turn, tab?: boolean}
function M.open(repo, scope_name, opts)
  opts = opts or {}
  R.repo, R.scope_name, R.turn = repo, scope_name or "turn", opts.turn
  local ok, err = compute({ snapshot = true })
  if not ok then
    util.warn(err)
    return
  end
  if not (R.buf and vim.api.nvim_buf_is_valid(R.buf)) then
    if opts.tab ~= false then
      vim.cmd("tabnew")
    end
    R.buf = vim.api.nvim_get_current_buf()
    pcall(vim.api.nvim_buf_set_name, R.buf, "tether://review")
    setup_buffer(R.buf)
    vim.wo.foldmethod = "expr"
    vim.wo.foldexpr = "v:lua.require'tether.review'.foldexpr(v:lnum)"
    vim.wo.foldlevel = 99
    vim.wo.number = false
    vim.wo.relativenumber = false
  else
    local win = vim.fn.bufwinid(R.buf)
    if win ~= -1 then
      vim.api.nvim_set_current_win(win)
    end
  end
  render()
  goto_hunk(1, 0)
  return R.buf
end

---Moves the review cursor to a file's diff.
function M.goto_file(rel)
  for lnum, f in pairs(R.file_lines or {}) do
    if f.path == rel then
      local win = vim.fn.bufwinid(R.buf)
      if win ~= -1 then
        vim.api.nvim_win_set_cursor(win, { lnum, 0 })
      end
      return true
    end
  end
  return false
end

function M.foldexpr(lnum)
  local line = vim.fn.getline(lnum)
  if line:match("^diff %-%-git ") then
    return ">1"
  elseif line:match("^@@ ") then
    return ">2"
  end
  return "="
end

---Internal state for tests and other modules.
function M.state()
  return R
end

return M
