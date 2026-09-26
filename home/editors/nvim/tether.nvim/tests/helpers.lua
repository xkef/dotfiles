local H = {}

H.notes = {}

local seq = 0

function H.tmpdir(name)
  seq = seq + 1
  local dir = vim.fs.joinpath(vim.env.TETHER_TEST_TMP, ("%s-%d"):format(name or "t", seq))
  vim.fn.mkdir(dir, "p")
  return vim.uv.fs_realpath(dir)
end

function H.sh(cmd, opts)
  opts = opts or {}
  local res = vim.system(cmd, { cwd = opts.cwd, env = opts.env, stdin = opts.stdin, text = true }):wait()
  if res.code ~= 0 and not opts.allow_fail then
    error(("command failed (%d): %s\n%s%s"):format(res.code, table.concat(cmd, " "), res.stdout, res.stderr), 2)
  end
  return res.stdout, res
end

function H.write(path, lines)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile(type(lines) == "string" and vim.split(lines, "\n") or lines, path)
end

function H.read(path)
  return vim.fn.readfile(path)
end

---Creates a repository with files and makes it the working directory.
---@param kind "jj"|"git"
function H.repo(kind, files)
  local dir = H.tmpdir(kind)
  if kind == "jj" then
    H.sh({ "jj", "git", "init" }, { cwd = dir })
  else
    H.sh({ "git", "init", "-q" }, { cwd = dir })
  end
  for rel, lines in pairs(files or {}) do
    H.write(vim.fs.joinpath(dir, rel), lines)
  end
  if kind == "git" then
    H.sh({ "git", "add", "-A" }, { cwd = dir })
    H.sh({ "git", "commit", "-qm", "init", "--allow-empty" }, { cwd = dir })
  else
    H.sh({ "jj", "commit", "-m", "init" }, { cwd = dir })
  end
  vim.cmd.cd(dir)
  return dir
end

function H.log_file()
  return vim.fs.joinpath(vim.env.XDG_STATE_HOME, "agents", "trail.log")
end

---Runs bin/agent-trail.
function H.trail(args, opts)
  opts = opts or {}
  local env = { XDG_STATE_HOME = vim.env.XDG_STATE_HOME }
  for k, v in pairs(opts.env or {}) do
    env[k] = v
  end
  local cmd = { vim.fs.joinpath(H.root, "bin", "agent-trail") }
  vim.list_extend(cmd, args)
  return H.sh(cmd, { cwd = opts.cwd or vim.fn.getcwd(), env = env, stdin = opts.stdin })
end

function H.records()
  local out = {}
  for _, line in ipairs(vim.fn.filereadable(H.log_file()) == 1 and H.read(H.log_file()) or {}) do
    table.insert(out, vim.split(line, "\t", { plain = true }))
  end
  return out
end

---Writes an executable script and returns its path.
function H.script(name, body)
  local path = vim.fs.joinpath(H.tmpdir("bin"), name)
  H.write(path, "#!/bin/sh\n" .. body)
  vim.uv.fs_chmod(path, 493)
  return path
end

---Stub for `agent-state list` printing rows of
---{pane, agent, state, tool, epoch, cwd, task}.
function H.agents(rows)
  local lines = {}
  for _, r in ipairs(rows) do
    table.insert(lines, table.concat(r, "\t"))
  end
  local data = vim.fs.joinpath(H.tmpdir("agents"), "rows")
  H.write(data, lines)
  return H.script("agent-state", ("cat '%s'\n"):format(data))
end

---Stub for wezterm that records each call: args, then stdin, then "--".
function H.wezterm()
  local log = vim.fs.joinpath(H.tmpdir("wez"), "calls")
  local path = H.script("wezterm", ("{ printf 'ARGS %%s\\n' \"$*\"; cat; printf '\\n--\\n'; } >>'%s'\n"):format(log))
  return path, log
end

function H.setup(opts)
  require("tether")._reset()
  local defaults = {
    log_file = H.log_file(),
    agent_state = H.agents({}),
    send = { wezterm = "/nonexistent/wezterm" },
    follow = { flash_ms = 0 },
  }
  require("tether").setup(vim.tbl_deep_extend("force", defaults, opts or {}))
  require("tether.ui.pick").backend = "select"
  return require("tether")
end

---Reads new events synchronously.
function H.poll()
  require("tether.core.events").read()
end

function H.eq(expected, actual, msg)
  if not vim.deep_equal(expected, actual) then
    error(("%sexpected %s, got %s"):format(msg and (msg .. ": ") or "", vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

function H.ok(value, msg)
  if not value then
    error(msg or "expected a truthy value", 2)
  end
  return value
end

function H.contains(haystack, needle, msg)
  if type(haystack) == "table" then
    haystack = table.concat(haystack, "\n")
  end
  if not tostring(haystack):find(needle, 1, true) then
    error(("%sexpected %q in:\n%s"):format(msg and (msg .. ": ") or "", needle, haystack), 2)
  end
end

function H.wait(cond, ms)
  return vim.wait(ms or 2000, cond, 10)
end

function H.buf_lines(buf)
  return vim.api.nvim_buf_get_lines(buf or 0, 0, -1, false)
end

---All virtual text and virtual lines of a buffer, joined.
function H.virt_text(buf)
  local out = {}
  for _, m in ipairs(vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, { details = true })) do
    for _, chunk in ipairs(m[4].virt_text or {}) do
      table.insert(out, chunk[1])
    end
    for _, vl in ipairs(m[4].virt_lines or {}) do
      for _, chunk in ipairs(vl) do
        table.insert(out, chunk[1])
      end
    end
  end
  return table.concat(out, "\n")
end

---Makes vim.ui.select pick the first item matching pred.
function H.select(pred)
  vim.ui.select = function(items, _, on_choice)
    H.last_select = items
    for _, it in ipairs(items) do
      if pred(it) then
        return on_choice(it)
      end
    end
    on_choice(nil)
  end
end

function H.input(text)
  vim.ui.input = function(_, on_confirm)
    on_confirm(text)
  end
end

local orig = { notify = vim.notify, select = vim.ui.select, input = vim.ui.input, confirm = vim.fn.confirm }

function H.before()
  H.notes = {}
  vim.notify = function(msg, level)
    table.insert(H.notes, { msg = msg, level = level })
  end
  H.select(function()
    return false
  end)
  H.input(nil)
  vim.fn.confirm = function()
    return 1
  end
  os.remove(H.log_file())
  os.remove(H.log_file() .. ".1")
  os.remove(vim.fs.joinpath(vim.fn.stdpath("state"), "tether", "reviewed.json"))
end

function H.after()
  require("tether")._reset()
  vim.notify, vim.ui.select, vim.ui.input, vim.fn.confirm = orig.notify, orig.select, orig.input, orig.confirm
  vim.cmd("silent! tabonly!")
  vim.cmd("silent! only!")
  vim.cmd("silent! %bwipeout!")
  vim.fn.setqflist({}, "r")
end

function H.note_text()
  local out = {}
  for _, n in ipairs(H.notes) do
    table.insert(out, n.msg)
  end
  return table.concat(out, "\n")
end

return H
