-- Detects the build modules that the neo-tree badge marks: a directory
-- that holds a build file, a Java source root with module-info.java, or a
-- Spring Modulith application module. Results stay cached until reset,
-- since the tree asks for every visible directory on every render.
local M = {}

-- The first marker that a directory holds names its kind.
local MARKERS = {
  { "pom.xml", "maven" },
  { "build.gradle.kts", "gradle" },
  { "build.gradle", "gradle" },
  { "Cargo.toml", "cargo" },
  { "package.json", "node" },
  { "go.mod", "go" },
  { "pyproject.toml", "python" },
  { "module-info.java", "jpms" },
}

local BUILD_FILES = { "pom.xml", "build.gradle.kts", "build.gradle" }
local SOURCE_ROOT = "/src/main/java/"

local cache = {}

local function memo(key, fn)
  if cache[key] == nil then
    cache[key] = fn()
  end
  return cache[key]
end

local function contains(path, text)
  local f = io.open(path)
  if not f then
    return false
  end

  local found = f:read("*a"):find(text, 1, true) ~= nil
  f:close()
  return found
end

local function boot_package(dir)
  for name, type in vim.fs.dir(dir) do
    if type == "file" and name:match("%.java$") and contains(vim.fs.joinpath(dir, name), "@SpringBootApplication") then
      return true
    end
  end
  return false
end

local function uses_modulith(root)
  for _, name in ipairs(BUILD_FILES) do
    if contains(vim.fs.joinpath(root, name), "spring-modulith") then
      return true
    end
  end
  return false
end

-- Spring Modulith treats each direct subpackage of the package that holds
-- the @SpringBootApplication class as a module, and so does a package
-- whose package-info.java carries @ApplicationModule, imported or fully
-- qualified. Only projects whose build file names spring-modulith count.
local function modulith(dir)
  if not dir:find(SOURCE_ROOT, 1, true) then
    return false
  end

  local root = vim.fs.root(dir, BUILD_FILES)
  if not root or not memo("modulith:" .. root, function()
    return uses_modulith(root)
  end) then
    return false
  end

  if contains(vim.fs.joinpath(dir, "package-info.java"), "ApplicationModule") then
    return true
  end
  local parent = vim.fs.dirname(dir)
  return memo("boot:" .. parent, function()
    return boot_package(parent)
  end)
end

-- Returns the module kind of a directory, such as "maven" or "modulith",
-- or false.
function M.kind(dir)
  return memo(dir, function()
    if dir:find("/node_modules/", 1, true) then
      return false
    end

    for _, marker in ipairs(MARKERS) do
      if vim.uv.fs_stat(vim.fs.joinpath(dir, marker[1])) then
        return marker[2]
      end
    end
    return modulith(dir) and "modulith"
  end)
end

-- Returns the closest directory above path that is a module, so repeated
-- calls on the result walk up the module hierarchy.
function M.root(path)
  for dir in vim.fs.parents(path) do
    if M.kind(dir) then
      return dir
    end
  end
end

function M.reset()
  cache = {}
end

return M
