-- Review state that outlives the review buffer: hunks accepted or rejected,
-- keyed by content hash per repository root and kept for review.keep_days,
-- and the unreviewed count of the last computed turn.

local config = require("tether.config")
local util = require("tether.core.util")

local M = {}

-- { turn = id, unreviewed = n } of the last turn whose diff was computed.
M.last = {}

local store

local function path()
  return util.state_file("reviewed.json")
end

local function load()
  if store then
    return store
  end
  store = util.read_json(path()) or {}
  local cutoff = os.time() - config.options.review.keep_days * 86400
  for _, hashes in pairs(store) do
    for h, v in pairs(hashes) do
      if type(v) ~= "table" or (v.t or 0) < cutoff then
        hashes[h] = nil
      end
    end
  end
  return store
end

---"a" for accepted, "r" for rejected, nil for unreviewed.
function M.status_of(root, hash)
  local s = load()[root]
  return s and s[hash] and s[hash].s or nil
end

function M.mark(root, hash, status)
  local s = load()
  s[root] = s[root] or {}
  s[root][hash] = status and { s = status, t = os.time() } or nil
  util.write_json(path(), s)
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

function M.reset()
  store = nil
  M.last = {}
end

return M
