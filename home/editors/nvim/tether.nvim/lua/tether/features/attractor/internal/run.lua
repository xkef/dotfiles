-- The attached pipeline run: which backend feeds it, node statuses, and
-- pending questions. One run at a time.

local api = require("tether.api")
local dot = require("tether.features.attractor.internal.dot")
local view = require("tether.features.attractor.internal.view")

local M = {}

M.backends = {
  spec = require("tether.features.attractor.internal.backend.spec"),
  fabro = require("tether.features.attractor.internal.backend.fabro"),
}

local R

function M.reset()
  if R and R.stop then
    R.stop()
  end
  if R then
    view.clear(R.buf)
  end
  R = nil
end

function M.current()
  return R
end

local ULID = "^%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w$"

---Reads a :Tether attractor run target: a run directory, a spec server URL
---and pipeline id, `fabro:<id>`, or a bare Fabro run id.
function M.parse_target(args)
  local a, b = args[1], args[2]
  if not a then
    return nil, "usage: :Tether attractor run <dir> | <url> <id> | fabro:<run-id>"
  end
  local fabro_id = a:match("^fabro:(.+)$") or (a:match(ULID) and a)
  if fabro_id then
    return { backend = "fabro", id = fabro_id, url = M.backends.fabro.url(), label = "fabro " .. fabro_id }
  end
  if a:match("^https?://") then
    if not b then
      return nil, "a spec server needs a pipeline id"
    end
    return { backend = "spec", url = a:gsub("/+$", ""), id = b, label = b .. " @ " .. a }
  end
  local dir = vim.fn.fnamemodify(a, ":p"):gsub("/$", "")
  if vim.fn.isdirectory(dir) == 1 then
    return { backend = "spec", dir = dir, label = vim.fs.basename(dir) }
  end
  return nil, "not a directory, URL, or Fabro run id: " .. a
end

function M.is_pipeline(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  return name:match("%.dot$") or name:match("%.gv$") or name:match("%.fabro$") or vim.bo[buf].filetype == "dot"
end

function M.parse_buffer(buf)
  return dot.parse(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"))
end

local function refresh()
  view.render(R)
  api.ui.refresh()
end

function M.fetch_questions(cb)
  if not R then
    return cb and cb(nil, "no run attached")
  end
  local run = R
  M.backends[run.backend].questions(run, function(list, err)
    if run ~= R then
      return
    end
    run.questions = list
    refresh()
    if cb then
      cb(list, err)
    end
  end)
end

local function on_update(run, u)
  if run ~= R then
    return
  end
  if u.node then
    if not run.statuses[u.node] then
      table.insert(run.order, u.node)
    end
    run.statuses[u.node] = u.status
    local node = run.graph and run.graph.nodes[u.node]
    local gate = u.status == "waiting"
      or u.question
      or (u.status == "running" and node and node.handler == "wait.human")
    if gate then
      run.statuses[u.node] = "waiting"
      M.fetch_questions(function(list)
        if list and #list > 0 then
          api.util.notify(("pipeline waits for you at %s: :Tether attractor answer"):format(u.node))
        end
      end)
    end
  end
  if u.answered then
    run.questions = nil
  end
  if u.done then
    run.done = u.done
    api.util.notify("pipeline " .. run.label .. ": " .. u.done)
  end
  refresh()
end

---Attaches a run described by parse_target, drawing on buf when it holds
---the pipeline.
function M.attach(target, buf)
  M.reset()
  local cfg = api.config().attractor or {}
  R = vim.tbl_extend("force", target, {
    statuses = {},
    order = {},
    poll_ms = cfg.poll_ms or 1000,
  })
  if buf and M.is_pipeline(buf) then
    R.buf = buf
    R.graph = M.parse_buffer(buf)
  end
  local run = R
  run.stop = M.backends[run.backend].start(run, function(u)
    on_update(run, u)
  end)
  refresh()
  return run
end

---Asks the user one question and returns the choice through cb.
function M.ask(q, cb)
  if q.kind == "yes_no" then
    vim.ui.select({ "Yes", "No" }, { prompt = q.text }, function(choice)
      if choice then
        cb({ kind = choice == "Yes" and "yes" or "no" })
      end
    end)
  elseif q.kind == "choice" then
    local items = vim.deepcopy(q.options)
    if q.freeform then
      table.insert(items, { key = false, label = "Other…" })
    end
    vim.ui.select(items, {
      prompt = q.text,
      format_item = function(o)
        return o.key and ("[" .. o.key .. "] " .. o.label) or o.label
      end,
    }, function(o)
      if not o then
        return
      end
      if o.key == false then
        vim.ui.input({ prompt = q.text .. " " }, function(text)
          if text and text ~= "" then
            cb({ kind = "text", text = text })
          end
        end)
      else
        cb({ kind = "selected", key = o.key, label = o.label })
      end
    end)
  else
    vim.ui.input({ prompt = q.text .. " " }, function(text)
      if text and text ~= "" then
        cb({ kind = "text", text = text })
      end
    end)
  end
end

---Fetches pending questions and answers the first.
function M.answer()
  if not R then
    api.util.warn("no pipeline run attached")
    return
  end
  local run = R
  M.fetch_questions(function(list, err)
    if not list then
      api.util.warn(err or "no questions")
      return
    end
    local q = list[1]
    if not q then
      api.util.notify("no pending questions")
      return
    end
    M.ask(q, function(choice)
      M.backends[run.backend].answer(run, q, choice, function(ok, perr)
        if ok then
          api.util.notify("answered: " .. (choice.label or choice.text or choice.kind))
          run.questions = nil
          if run.statuses[q.stage or ""] == "waiting" then
            run.statuses[q.stage] = "running"
          end
          refresh()
        else
          api.util.warn("answer failed: " .. tostring(perr))
        end
      end)
    end)
  end)
end

---Stage files of a node, for backends that expose them.
function M.stage_files(node)
  local b = R and M.backends[R.backend]
  return b and b.stage_files and b.stage_files(R, node) or {}
end

return M
