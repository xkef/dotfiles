local H = require("helpers")

-- Module name and required modules of every Lua file of the plugin.
local function modules()
  local root = vim.fs.joinpath(H.root, "lua")
  local out = {}
  for _, path in ipairs(vim.fn.globpath(root, "**/*.lua", false, true)) do
    local name = path:sub(#root + 2):gsub("%.lua$", ""):gsub("/init$", ""):gsub("/", ".")
    local requires = {}
    for _, line in ipairs(vim.fn.readfile(path)) do
      for mod in line:gmatch("require%(%s*[\"']([%w%._]+)[\"']%s*%)") do
        table.insert(requires, mod)
      end
    end
    out[name] = requires
  end
  return out
end

local function feature_of(mod)
  return mod:match("^tether%.features%.([%w_]+)")
end

local PUBLIC = { tether = true, ["tether.api"] = true, ["tether.config"] = true, ["tether.types"] = true }

---Why mod may not require dep, or nil when it may.
local function violation(mod, dep)
  if not dep:match("^tether") then
    return nil
  end
  local own = feature_of(mod)
  local target = feature_of(dep)
  if target and dep:match("%.internal") and own ~= target then
    return "reaches into another feature's internals"
  end
  if mod:match("^tether%.core") then
    if not (dep:match("^tether%.core") or dep == "tether.config") then
      return "core may only require core and config"
    end
  elseif mod:match("^tether%.ui") then
    if not (dep:match("^tether%.core") or dep:match("^tether%.ui") or dep == "tether.config") then
      return "ui may only require core, ui, and config"
    end
  elseif own then
    if not (dep == "tether.api" or target == own) then
      return "a feature may only require tether.api and its own modules"
    end
  end
  return nil
end

local function public_names(mod)
  local out = {}
  for name, value in pairs(mod) do
    if type(name) == "string" and not name:match("^_") then
      table.insert(out, { name = name, value = value })
    end
  end
  return out
end

return {
  {
    "Features stay behind the API",
    function()
      local bad = {}
      for mod, requires in pairs(modules()) do
        for _, dep in ipairs(requires) do
          local why = violation(mod, dep)
          if why then
            table.insert(bad, ("%s -> %s: %s"):format(mod, dep, why))
          end
        end
      end
      table.sort(bad)
      H.eq({}, bad)
    end,
  },
  {
    "Every public function is documented",
    function()
      local doc = table.concat(vim.fn.readfile(vim.fs.joinpath(H.root, "doc", "tether.txt")), "\n")
      local missing = {}
      local internal = { ensure = true, command = true, completion = true, did_setup = true, features = true }
      for _, entry in ipairs(public_names(require("tether"))) do
        if not internal[entry.name] and not doc:find(entry.name, 1, true) then
          table.insert(missing, "tether." .. entry.name)
        end
      end
      for _, entry in ipairs(public_names(require("tether.api"))) do
        if not doc:find("api." .. entry.name, 1, true) then
          table.insert(missing, "tether.api." .. entry.name)
        end
        if type(entry.value) == "table" then
          for _, sub in ipairs(public_names(entry.value)) do
            if not doc:find(sub.name, 1, true) then
              table.insert(missing, ("tether.api.%s.%s"):format(entry.name, sub.name))
            end
          end
        end
      end
      table.sort(missing)
      H.eq({}, missing)
    end,
  },
  {
    "Public modules name their tier",
    function()
      for mod in pairs(modules()) do
        H.ok(
          PUBLIC[mod]
            or mod == "tether.health"
            or mod:match("^tether%.core")
            or mod:match("^tether%.ui")
            or feature_of(mod),
          mod .. " sits outside core, ui, features, and the public modules"
        )
      end
    end,
  },
}
