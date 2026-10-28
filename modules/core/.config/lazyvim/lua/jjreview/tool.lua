-- jj runs this as a diff editor through `nvim --clean -l tool.lua LEFT
-- RIGHT PATH CONTENT`. LEFT and RIGHT hold the changed files before and
-- after the revision. The tool resets RIGHT to LEFT, so jj selects
-- nothing, then writes CONTENT to PATH, so jj selects only the hunks that
-- CONTENT applies.
local left, right, path, content = unpack(arg)

local function files(root)
  local found = {}
  for name, kind in vim.fs.dir(root, { depth = math.huge }) do
    if kind ~= "directory" then
      found[name] = true
    end
  end
  return found
end

-- jj makes LEFT read-only, and a copy keeps the mode, so a second copy
-- onto the same file has to replace it.
local function copy(src, dst)
  vim.fn.mkdir(vim.fs.dirname(dst), "p")
  os.remove(dst)
  assert(vim.uv.fs_copyfile(src, dst))
end

local in_left = files(left)
for name in pairs(files(right)) do
  if not in_left[name] then
    assert(os.remove(vim.fs.joinpath(right, name)))
  end
end
for name in pairs(in_left) do
  copy(vim.fs.joinpath(left, name), vim.fs.joinpath(right, name))
end

copy(content, vim.fs.joinpath(right, path))
