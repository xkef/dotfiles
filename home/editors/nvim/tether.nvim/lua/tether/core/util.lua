local M = {}

M.TIMEOUT = 10000

---Runs a command and returns its result. With a callback it runs
---asynchronously and calls back on the main loop.
---@param cmd string[]
---@param opts? {cwd?: string, stdin?: string}
---@param cb? fun(res: {code: integer, stdout: string, stderr: string})
function M.run(cmd, opts, cb)
  opts = opts or {}
  local sys_opts = { cwd = opts.cwd, stdin = opts.stdin, text = true }
  local on_exit = cb
    and function(r)
      vim.schedule(function()
        cb({ code = r.code, stdout = r.stdout or "", stderr = r.stderr or "" })
      end)
    end
  local ok, proc = pcall(vim.system, cmd, sys_opts, on_exit)
  if not ok then
    local res = { code = 127, stdout = "", stderr = tostring(proc) }
    if cb then
      vim.schedule(function()
        cb(res)
      end)
      return
    end
    return res
  end
  if cb then
    return
  end
  local r = proc:wait(M.TIMEOUT)
  return { code = r.code, stdout = r.stdout or "", stderr = r.stderr or "" }
end

---@param path string
---@return string
function M.normalize(path)
  path = vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
  local real = vim.uv.fs_realpath(path)
  if real then
    return vim.fs.normalize(real)
  end
  -- A path that doesn't exist yet resolves through its parent, so a deleted
  -- file still compares equal to paths of the same directory.
  local parent = vim.uv.fs_realpath(vim.fs.dirname(path))
  if parent then
    return vim.fs.joinpath(vim.fs.normalize(parent), vim.fs.basename(path))
  end
  return (path:gsub("/$", ""))
end

---True when path equals dir or lies inside it. Both must be normalized.
function M.inside(path, dir)
  if not path or not dir then
    return false
  end
  return path == dir or path:sub(1, #dir + 1) == dir .. "/"
end

function M.relative(path, root)
  if M.inside(path, root) and path ~= root then
    return path:sub(#root + 2)
  end
  return path
end

function M.lines(text)
  if text == nil or text == "" then
    return {}
  end
  local lines = vim.split(text, "\n", { plain = true })
  if lines[#lines] == "" then
    lines[#lines] = nil
  end
  return lines
end

function M.read_lines(path)
  if vim.fn.filereadable(path) == 0 then
    return nil
  end
  return vim.fn.readfile(path)
end

---Current content of a file: the loaded buffer when there is one, else the
---file on disk.
function M.content(path)
  local buf = vim.fn.bufnr(path)
  if buf > 0 and vim.api.nvim_buf_is_loaded(buf) then
    return vim.api.nvim_buf_get_lines(buf, 0, -1, false), buf
  end
  return M.read_lines(path)
end

function M.notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "tether" })
end

function M.warn(msg)
  M.notify(msg, vim.log.levels.WARN)
end

function M.state_file(name)
  return vim.fs.joinpath(vim.fn.stdpath("state"), "tether", name)
end

function M.read_json(path)
  local lines = M.read_lines(path)
  if not lines then
    return nil
  end
  local ok, data = pcall(vim.json.decode, table.concat(lines, "\n"))
  return ok and data or nil
end

function M.write_json(path, data)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  local tmp = path .. ".tmp"
  vim.fn.writefile({ vim.json.encode(data) }, tmp)
  vim.uv.fs_rename(tmp, path)
end

---Human-readable age of an epoch.
function M.age(epoch)
  local d = os.time() - (epoch or 0)
  if d < 60 then
    return d .. "s"
  elseif d < 3600 then
    return math.floor(d / 60) .. "m"
  elseif d < 86400 then
    return math.floor(d / 3600) .. "h"
  end
  return math.floor(d / 86400) .. "d"
end

---Debounces fn: calls it once, ms after the last call.
function M.debounce(ms, fn)
  local timer
  return function(...)
    local args = { ... }
    if timer then
      timer:stop()
      timer:close()
    end
    timer = vim.uv.new_timer()
    timer:start(ms, 0, function()
      timer:stop()
      timer:close()
      timer = nil
      vim.schedule(function()
        fn(unpack(args))
      end)
    end)
  end
end

return M
