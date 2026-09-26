-- HTTP through curl: JSON GET and POST, and server-sent event streams.

local api = require("tether.api")

local M = {}

local function curl()
  return (api.config().attractor or {}).curl or "curl"
end

local function decode(text)
  if not text or vim.trim(text) == "" then
    return nil
  end
  local ok, data = pcall(vim.json.decode, text)
  return ok and data or nil
end

M.decode = decode

---GETs url and calls cb(data, err) with the decoded JSON body.
function M.get(url, cb)
  api.util.run({ curl(), "-sS", "-f", "-H", "Accept: application/json", url }, {}, function(res)
    if res.code ~= 0 then
      return cb(nil, vim.trim(res.stderr ~= "" and res.stderr or ("curl exited " .. res.code)))
    end
    cb(decode(res.stdout))
  end)
end

---POSTs body as JSON and calls cb(ok, err).
function M.post(url, body, cb)
  api.util.run({
    curl(),
    "-sS",
    "-f",
    "-X",
    "POST",
    "-H",
    "Content-Type: application/json",
    "--data-binary",
    "@-",
    url,
  }, { stdin = vim.json.encode(body) }, function(res)
    if res.code ~= 0 then
      return cb(false, vim.trim(res.stderr ~= "" and res.stderr or ("curl exited " .. res.code)))
    end
    cb(true)
  end)
end

---Feeds SSE text to a parser. Returns a function that takes chunks and
---calls on_event(data_text, event_name) for every complete event.
function M.sse_parser(on_event)
  local pending, data, event = "", {}, nil
  return function(chunk)
    pending = pending .. chunk
    while true do
      local nl = pending:find("\n", 1, true)
      if not nl then
        break
      end
      local line = pending:sub(1, nl - 1):gsub("\r$", "")
      pending = pending:sub(nl + 1)
      if line == "" then
        if #data > 0 then
          on_event(table.concat(data, "\n"), event)
        end
        data, event = {}, nil
      elseif line:sub(1, 1) ~= ":" then
        local field, value = line:match("^([^:]+):%s?(.*)$")
        if field == "data" then
          table.insert(data, value)
        elseif field == "event" then
          event = value
        end
      end
    end
  end
end

---Streams url as server-sent events. on_event(data_text, event_name) runs
---on the main loop; on_exit(code) when curl ends. Returns stop().
function M.stream(url, on_event, on_exit)
  local feed = M.sse_parser(function(data, event)
    vim.schedule(function()
      on_event(data, event)
    end)
  end)
  local ok, proc = pcall(vim.system, { curl(), "-sS", "-N", "-H", "Accept: text/event-stream", url }, {
    text = true,
    stdout = function(_, chunk)
      if chunk then
        feed(chunk)
      end
    end,
  }, function(res)
    -- A last event without a trailing blank line still counts.
    feed("\n\n")
    vim.schedule(function()
      if on_exit then
        on_exit(res.code)
      end
    end)
  end)
  if not ok then
    vim.schedule(function()
      if on_exit then
        on_exit(127)
      end
    end)
    return function() end
  end
  return function()
    pcall(proc.kill, proc, 15)
  end
end

return M
