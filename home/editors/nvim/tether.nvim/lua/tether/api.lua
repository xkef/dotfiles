-- The extension API. Features under tether.features and user configuration
-- build on this module and on the facade in tether/init.lua only; the
-- modules under tether.core and tether.ui are internal and may change.
--
-- Every entry is an explicit whitelist that forwards to the internal module
-- on first use, so requiring the API loads nothing.

local M = {}

---Forwards the listed functions of an internal module.
local function expose(module, names)
  local t = {}
  for _, name in ipairs(names) do
    t[name] = function(...)
      return require(module)[name](...)
    end
  end
  return t
end

---@return tether.Config
function M.config()
  return require("tether.config").options
end

---Applies options without the editor setup, for headless tools such as
---tether-run. Returns the resolved options.
---@return tether.Config
function M.configure(opts)
  return require("tether.config").setup(opts)
end

---The repository of the working directory.
---@return tether.Repo?
function M.repo()
  return require("tether.core.vcs").current()
end

M.util = expose("tether.core.util", {
  "run",
  "normalize",
  "inside",
  "relative",
  "lines",
  "read_lines",
  "content",
  "notify",
  "warn",
  "age",
  "debounce",
  "state_file",
  "read_json",
  "write_json",
})

M.vcs = expose("tether.core.vcs", {
  "detect",
  "checkpoint",
  "resolve",
  "head",
  "diff",
  "base",
  "show",
  "workspace",
  "same_repo",
  "workspace_add",
})

M.diff = expose("tether.core.diff", { "parse", "side", "first_change", "compare", "hash" })

---Turns are shared state: treat the returned tables as read-only.
M.turns = expose("tether.core.turns", {
  "list",
  "latest",
  "get",
  "running",
  "open",
  "open_turn",
  "trail",
  "scope",
  "files",
  "stats",
})

M.agents = expose("tether.core.agents", { "list", "in_root", "in_repo" })

M.review_state = expose("tether.core.store", { "status_of", "count" })

---Views features may drive.
M.ui = {
  open_file = function(file, lnum)
    return require("tether.ui.pick").open_file(file, lnum)
  end,
  ---@param scope string turn|change|checkpoint|since|workspace
  review = function(repo, scope, opts)
    return require("tether.ui.review").open(repo, scope, opts)
  end,
  ---Sends text to the agent working on root, or copies it.
  send = function(root, text)
    return require("tether.ui.send").text(root, text)
  end,
  ---Copies text to the clipboard register; returns the register name.
  copy = function(text)
    return require("tether.ui.send").copy(text)
  end,
  refresh = function()
    return require("tether.ui.cockpit").render()
  end,
  ---Opens a picker source by name in the current repository.
  pick = function(source)
    local repo = require("tether.core.vcs").current()
    if repo then
      return require("tether.ui.pick").pick(repo, source)
    end
  end,
}

---Subscribes to notifications. "event" delivers every event-log record;
---"stop" a finished turn as { turn, files }; "conflict" a coordination
---warning. Returns a function that unsubscribes.
---@param name "event"|"stop"|"conflict"
---@param fn fun(data: any)
---@return fun()
function M.on(name, fn)
  if name == "event" then
    return require("tether.core.events").subscribe(fn)
  end
  return require("tether.core.bus").on(name, fn)
end

---Publishes a notification to on() subscribers and its User autocmd.
function M.emit(name, data)
  require("tether.core.bus").emit(name, data)
end

M.register = {
  ---@param source tether.Source
  source = function(source)
    require("tether.core.registry").source(source)
  end,
  ---@param section tether.Section
  section = function(section)
    require("tether.core.registry").section(section)
  end,
  ---@param fn fun(repo: tether.Repo, scope: tether.Scope, files: tether.File[]): string|string[]|nil
  review_header = function(fn)
    require("tether.core.registry").review_header(fn)
  end,
  ---@param fn fun(repo: tether.Repo, agent: tether.Agent): string?
  agent_field = function(fn)
    require("tether.core.registry").agent_field(fn)
  end,
  ---@param fn fun(repo: tether.Repo, agent: tether.Agent): table<string, fun()>?
  agent_action = function(fn)
    require("tether.core.registry").agent_action(fn)
  end,
  ---Adds `:Tether {name}`.
  ---@param spec {run: fun(args: string[], cmd: table), complete?: string[]|fun(): string[], desc?: string}
  command = function(name, spec)
    require("tether.core.registry").command(name, spec)
  end,
}

return M
