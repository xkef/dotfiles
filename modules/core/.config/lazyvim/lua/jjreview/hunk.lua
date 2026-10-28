-- Hunks of a buffer against the parent of the revision it shows: @ for a
-- working copy file, REV for a jj:// buffer. Navigation crosses into the
-- next file of the review panel. Move and split hand the chosen hunks to
-- jj through tool.lua, which jj runs as its diff editor.
local jj = require("jjreview.jj")
local panel = require("jjreview.panel")

local M = {}

local TOOL = vim.fs.joinpath(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)), "tool.lua")

-- The revision and root-relative path that a buffer shows.
local function target(buf)
  local root = jj.root()
  local name = vim.api.nvim_buf_get_name(buf)
  local change, path = require("jj.utils").parse_jj_uri(name)
  if change then
    return change, vim.fs.relpath(root, vim.fs.joinpath(vim.fn.getcwd(), path))
  end
  local rel = root and vim.fs.relpath(root, name)
  if rel then
    return "@", rel
  end
end

local function text(lines)
  return table.concat(lines, "\n") .. "\n"
end

-- Hunks as { base_start, base_count, buf_start, buf_count } from vim.diff,
-- with the base's lines and the buffer's lines they index. The base is
-- the revision's parent unless given.
local function diff(buf, base_rev)
  local rev, path = target(buf)
  if not rev then
    return nil
  end
  local base = jj.show(base_rev or rev .. "-", path)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local hunks = vim.diff(text(base), text(lines), { result_type = "indices" })
  return { rev = rev, path = path, base = base, lines = lines, hunks = hunks }
end

-- The buffer lines a hunk covers. A deletion covers the line it follows.
local function span(hunk)
  local start, count = hunk[3], hunk[4]
  if count == 0 then
    local line = math.max(start, 1)
    return line, line
  end
  return start, start + count - 1
end

-- The parent's lines with the selected hunks applied.
local function apply(d, selected)
  local out, next_base = {}, 1
  local function copy(lines, from, to)
    for i = from, to do
      table.insert(out, lines[i])
    end
  end

  for i, hunk in ipairs(d.hunks) do
    local base_start, base_count, buf_start, buf_count = unpack(hunk)
    -- vim.diff gives the line before an insertion as its start.
    local first = base_count == 0 and base_start + 1 or base_start
    copy(d.base, next_base, first - 1)
    if selected[i] then
      copy(d.lines, buf_start, buf_start + buf_count - 1)
    else
      copy(d.base, first, first + base_count - 1)
    end
    next_base = first + base_count
  end
  copy(d.base, next_base, #d.base)
  return out
end

local function jump(win, hunks, which)
  local hunk = which == "first" and hunks[1] or hunks[#hunks]
  if hunk then
    vim.api.nvim_win_set_cursor(win, { (span(hunk)), 0 })
  end
end

-- ]h and [h. With the panel open they run past the last hunk into the
-- next file of the selection, against the base the panel opened the
-- buffer with. Otherwise gitsigns navigates.
function M.nav(direction)
  if vim.wo.diff then
    vim.cmd.normal({ direction == "next" and "]c" or "[c", bang = true })
    return
  end
  if not panel.active() then
    require("gitsigns").nav_hunk(direction)
    return
  end

  local d = diff(0, vim.b.jjreview_base)
  if not d then
    return
  end
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local found
  for _, hunk in ipairs(d.hunks) do
    local line = span(hunk)
    if direction == "next" and line > row and not found then
      found = line
    elseif direction == "prev" and line < row then
      found = line
    end
  end
  if found then
    vim.api.nvim_win_set_cursor(0, { found, 0 })
    return
  end

  if panel.adjacent(d.path, direction == "next" and 1 or -1) then
    local opened = diff(0, vim.b.jjreview_base)
    jump(0, opened and opened.hunks or {}, direction == "next" and "first" or "last")
  end
end

-- The hunks that touch lines first..last, with the file that holds the
-- parent's lines plus those hunks.
local function selection(first, last)
  vim.cmd("silent update")
  local d = diff(0)
  if not d then
    jj.notify("Buffer is not in a jj workspace", vim.log.levels.WARN)
    return nil
  end

  local selected, any = {}, false
  for i, hunk in ipairs(d.hunks) do
    local from, to = span(hunk)
    if from <= last and to >= first then
      selected[i], any = true, true
    end
  end
  if not any then
    jj.notify("No hunk here", vim.log.levels.WARN)
    return nil
  end

  d.content = vim.fn.tempname()
  vim.fn.writefile(apply(d, selected), d.content, vim.bo.eol and "" or "b")
  return d
end

local function toml_string(s)
  return '"' .. s:gsub('[\\"]', "\\%0") .. '"'
end

local function tool_args(d)
  local edit_args = { "--clean", "-l", TOOL, "$left", "$right", d.path, d.content }
  local quoted = vim.tbl_map(toml_string, edit_args)
  return {
    "--config",
    "ui.diff-instructions=false",
    "--config",
    "merge-tools.jjreview.program=" .. toml_string(vim.v.progpath),
    "--config",
    "merge-tools.jjreview.edit-args=[" .. table.concat(quoted, ",") .. "]",
    "--interactive",
    "--tool",
    "jjreview",
  }
end

local function run(d, args)
  local out = jj.run(vim.list_extend(vim.list_extend(args, tool_args(d)), { jj.fileset(d.path) }))
  os.remove(d.content)
  if out then
    panel.on_change()
  end
end

-- Moves the hunks into a new change before their revision. `jj split`
-- would give the split-out part the revision's change ID, so this inserts
-- an empty change and squashes into it instead, and the revision keeps
-- its ID and description.
local function split_out(d)
  vim.ui.input({ prompt = "Description of the split-out change: " }, function(message)
    if not message then
      os.remove(d.content)
      return
    end
    if not jj.run({ "new", "--no-edit", "--insert-before", d.rev, "-m", message }) then
      os.remove(d.content)
      return
    end
    run(d, { "squash", "--from", d.rev, "--into", d.rev .. "-", "--use-destination-message" })
  end)
end

-- Moves the hunks on lines first..last into a mutable revision from the
-- panel's revset or next to the source, or into a new change, which is
-- always on offer.
function M.move(first, last)
  local d = selection(first, last)
  if not d then
    return
  end

  local revset = ("((%s) | %s- | %s+) & mutable() ~ %s"):format(panel.revset(), d.rev, d.rev, d.rev)
  local items = jj.revisions(revset)
  table.insert(items, { new = true, change = "new", title = "New change before " .. d.rev })
  vim.ui.select(items, {
    prompt = "Move hunk into",
    format_item = function(rev)
      return rev.change .. "  " .. rev.title
    end,
  }, function(rev)
    if not rev then
      os.remove(d.content)
    elseif rev.new then
      split_out(d)
    else
      run(d, { "squash", "--from", d.rev, "--into", rev.id, "--use-destination-message" })
    end
  end)
end

-- Splits the hunks on lines first..last out of their revision, into a new
-- change before it.
function M.split(first, last)
  local d = selection(first, last)
  if d then
    split_out(d)
  end
end

return M
