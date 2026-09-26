-- Parses unified diffs (jj diff --git, git diff) into files and hunks.

local M = {}

---@class tether.Hunk
---@field path string
---@field old_start integer
---@field old_count integer
---@field new_start integer
---@field new_count integer
---@field header string
---@field lines string[] body lines with their " ", "-", "+" prefix
---@field hash string

---@class tether.File
---@field path string
---@field old_path string
---@field status "A"|"M"|"D"|"R"
---@field hunks tether.Hunk[]
---@field added integer
---@field removed integer

local function unquote(p)
  if p:sub(1, 1) == '"' then
    p = p:sub(2, -2):gsub('\\"', '"'):gsub("\\\\", "\\")
  end
  return p
end

local function strip(p)
  p = unquote(p)
  return (p:gsub("^[ab]/", ""))
end

---Hash of a hunk's changed lines. It survives line shifts.
function M.hash(path, lines)
  local changed = { path }
  for _, l in ipairs(lines) do
    local c = l:sub(1, 1)
    if c == "+" or c == "-" then
      table.insert(changed, l)
    end
  end
  return vim.fn.sha256(table.concat(changed, "\n")):sub(1, 16)
end

---@return tether.File[]
function M.parse(text)
  local files = {}
  local file, hunk
  local function finish_hunk()
    if hunk then
      hunk.hash = M.hash(file.path, hunk.lines)
      hunk = nil
    end
  end
  for _, line in ipairs(vim.split(text or "", "\n", { plain = true })) do
    local a, b = line:match("^diff %-%-git (%S+) (%S+)$")
    if not a then
      a, b = line:match('^diff %-%-git (".-") (".-")$')
    end
    if a then
      finish_hunk()
      file = { path = strip(b), old_path = strip(a), status = "M", hunks = {}, added = 0, removed = 0 }
      table.insert(files, file)
    elseif file and not hunk and line:match("^new file mode") then
      file.status = "A"
    elseif file and not hunk and line:match("^deleted file mode") then
      file.status = "D"
    elseif file and not hunk and line:match("^rename from") then
      file.status = "R"
    elseif file and line:match("^@@ ") then
      finish_hunk()
      local os, oc, ns, nc = line:match("^@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@")
      hunk = {
        path = file.path,
        old_start = tonumber(os),
        old_count = oc == "" and 1 or tonumber(oc),
        new_start = tonumber(ns),
        new_count = nc == "" and 1 or tonumber(nc),
        header = line,
        lines = {},
      }
      table.insert(file.hunks, hunk)
    elseif hunk then
      local c = line:sub(1, 1)
      if c == "+" then
        file.added = file.added + 1
        table.insert(hunk.lines, line)
      elseif c == "-" then
        file.removed = file.removed + 1
        table.insert(hunk.lines, line)
      elseif c == " " then
        table.insert(hunk.lines, line)
      elseif c ~= "\\" then
        finish_hunk()
      end
    end
  end
  finish_hunk()
  return files
end

---The hunk's lines on the old or new side.
function M.side(hunk, new)
  local keep = new and "+" or "-"
  local out = {}
  for _, l in ipairs(hunk.lines) do
    local c = l:sub(1, 1)
    if c == " " or c == keep then
      table.insert(out, l:sub(2))
    end
  end
  return out
end

---First changed line on the new side, and its text.
function M.first_change(hunk)
  local lnum = hunk.new_start
  for _, l in ipairs(hunk.lines) do
    local c = l:sub(1, 1)
    if c == "+" or c == "-" then
      return math.max(lnum, 1), l:sub(2)
    end
    lnum = lnum + 1
  end
  return math.max(hunk.new_start, 1), ""
end

---Line counts for a range compared with vim.diff: added, removed, and the
---first changed range on the new side.
function M.compare(old, new)
  local a = table.concat(old or {}, "\n") .. "\n"
  local b = table.concat(new or {}, "\n") .. "\n"
  local ok, indices = pcall(vim.diff, a, b, { result_type = "indices" })
  local added, removed, first = 0, 0, nil
  if not ok or not indices then
    return 0, 0, nil
  end
  for _, h in ipairs(indices) do
    removed = removed + h[2]
    added = added + h[4]
    if not first then
      local start = h[4] > 0 and h[3] or math.max(h[3], 1)
      first = { start, start + math.max(h[4], 1) - 1 }
    end
  end
  return added, removed, first
end

return M
