-- StrongDM Attractor pipelines and the Fabro engine: lint and navigate
-- pipeline files, watch runs, answer human gates, launch Fabro workflows,
-- and review what a Fabro run committed.

local api = require("tether.api")
local dot = require("tether.features.attractor.internal.dot")
local fabro = require("tether.features.attractor.internal.backend.fabro")
local lint = require("tether.features.attractor.internal.lint")
local outline = require("tether.features.attractor.internal.outline")
local run = require("tether.features.attractor.internal.run")

local M = {}

local ns = vim.api.nvim_create_namespace("tether.features.attractor.lint")

M.PATTERNS = { "*.dot", "*.gv", "*.fabro" }

function M.reset()
  run.reset()
end

M.is_pipeline = run.is_pipeline
M.parse = dot.parse
M.lint = lint.run
M.current_run = run.current

----------------------------------------------------------------------------
-- Diagnostics

local function to_diag(d)
  return {
    lnum = math.max((d.line or 1) - 1, 0),
    col = 0,
    severity = d.severity or vim.diagnostic.severity.ERROR,
    message = d.message,
    code = d.rule,
  }
end

---Lints a pipeline buffer; adds `fabro validate` findings for .fabro files.
function M.check(buf, done)
  local text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
  if not text:find("digraph", 1, true) then
    return
  end
  local diags = vim.tbl_map(to_diag, lint.run(dot.parse(text)))
  vim.diagnostic.set(ns, buf, diags, { source = "attractor" })
  local name = vim.api.nvim_buf_get_name(buf)
  if not name:match("%.fabro$") or vim.bo[buf].modified then
    if done then
      done(diags)
    end
    return
  end
  fabro.validate(name, function(findings)
    for _, f in ipairs(findings or {}) do
      local d = to_diag(f)
      d.source = "fabro"
      table.insert(diags, d)
    end
    if vim.api.nvim_buf_is_valid(buf) then
      vim.diagnostic.set(ns, buf, diags, { source = "attractor" })
    end
    if done then
      done(diags)
    end
  end)
end

----------------------------------------------------------------------------
-- Commands

local function pipeline_buf()
  local buf = vim.api.nvim_get_current_buf()
  if run.is_pipeline(buf) then
    return buf
  end
  local r = run.current()
  return r and r.buf
end

local function need_graph()
  local buf = pipeline_buf()
  if not buf then
    api.util.warn("not a pipeline buffer (.dot, .gv, .fabro)")
    return nil
  end
  return run.parse_buffer(buf), buf
end

---Opens a read-only review of branch fabro/run/<id> against its branch
---point.
function M.review_run(id)
  local repo = api.repo()
  if not repo then
    api.util.warn("not in a repository")
    return
  end
  local branch = "fabro/run/" .. id
  local from, to
  if repo.kind == "jj" then
    to = '"' .. branch .. '"'
    from = "fork_point(@ | " .. to .. ")"
  else
    local res = api.util.run({ "git", "merge-base", "HEAD", branch }, { cwd = repo.root })
    if res.code ~= 0 then
      api.util.warn("no branch " .. branch)
      return
    end
    from, to = vim.trim(res.stdout), branch
  end
  return api.ui.review(repo, "range", { from = from, to = to, label = "fabro run " .. id })
end

M.SUBCOMMANDS = {
  lint = function()
    local buf = pipeline_buf()
    if buf then
      M.check(buf, function(diags)
        api.util.notify(("%d finding%s"):format(#diags, #diags == 1 and "" or "s"))
      end)
    end
  end,
  outline = function()
    local graph, buf = need_graph()
    if graph then
      outline.open(graph, buf)
    end
  end,
  nodes = function()
    api.ui.pick("nodes")
  end,
  run = function(args)
    local target, err = run.parse_target(args)
    if not target then
      api.util.warn(err)
      return
    end
    run.attach(target, pipeline_buf())
    api.util.notify("attached " .. target.label)
  end,
  launch = function()
    local buf = pipeline_buf()
    local file = buf and vim.api.nvim_buf_get_name(buf)
    if not file or not file:match("%.fabro$") then
      api.util.warn("launch needs a .fabro workflow buffer")
      return
    end
    fabro.launch(file, function(id, err)
      if not id then
        api.util.warn("fabro run failed: " .. tostring(err))
        return
      end
      run.attach({ backend = "fabro", id = id, url = fabro.url(), label = "fabro " .. id }, buf)
      api.util.notify("launched fabro run " .. id)
    end)
  end,
  answer = function()
    run.answer()
  end,
  stop = function()
    run.reset()
    api.ui.refresh()
  end,
  review = function(args)
    local id = args[1] or (run.current() and run.current().backend == "fabro" and run.current().id)
    if not id then
      api.util.warn("usage: :Tether attractor review <fabro-run-id>")
      return
    end
    M.review_run(id)
  end,
}

----------------------------------------------------------------------------
-- Cockpit

local function section_rows()
  local r = run.current()
  if not r then
    return {}
  end
  local rows = {}
  local order = r.graph and dot.bfs(r.graph) or r.order
  for _, id in ipairs(order) do
    local status = r.statuses[id]
    if status then
      local node = r.graph and r.graph.nodes[id]
      table.insert(rows, {
        text = ("%-9s %s"):format(status, id),
        hl = status == "fail" and "TetherRejected" or status == "waiting" and "TetherWaiting" or nil,
        actions = {
          ["<CR>"] = function()
            local files = run.stage_files(id)
            if #files > 0 then
              api.ui.open_file(files[#files], 1)
            elseif node and r.buf then
              api.ui.open_file(vim.api.nvim_buf_get_name(r.buf), node.line)
            end
          end,
        },
      })
    end
  end
  for _, q in ipairs(r.questions or {}) do
    table.insert(rows, {
      text = "? " .. q.text,
      hl = "TetherWaiting",
      actions = { ["<CR>"] = run.answer },
    })
  end
  return rows
end

----------------------------------------------------------------------------
-- Integration

---@param tether_api table tether.api
function M.attach(tether_api)
  local group = vim.api.nvim_create_augroup("tether.features.attractor", { clear = true })
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
    group = group,
    pattern = M.PATTERNS,
    callback = function(args)
      M.check(args.buf)
      local r = run.current()
      if r and r.buf == args.buf then
        r.graph = run.parse_buffer(args.buf)
        require("tether.features.attractor.internal.view").render(r)
      end
    end,
  })
  vim.api.nvim_create_autocmd("BufReadPost", {
    group = group,
    pattern = "*.fabro",
    callback = function(args)
      vim.bo[args.buf].filetype = "dot"
    end,
  })

  tether_api.register.source({
    name = "nodes",
    desc = "Pipeline nodes",
    enabled = function()
      return pipeline_buf() ~= nil
    end,
    items = function()
      local graph, buf = need_graph()
      if not graph then
        return nil, "not a pipeline buffer"
      end
      local file = vim.api.nvim_buf_get_name(buf)
      local items = {}
      for _, id in ipairs(dot.bfs(graph)) do
        local node = graph.nodes[id]
        local prompt = node.attrs.prompt or node.attrs.label or ""
        table.insert(items, {
          text = ("%-16s [%s] %s"):format(id, node.handler, node.attrs.label or ""),
          file = file,
          lnum = node.line,
          preview = { lines = vim.split(prompt, "\n", { plain = true }), ft = "markdown" },
        })
      end
      return items
    end,
  })

  tether_api.register.section({
    name = "Pipeline",
    order = 35,
    summary = function()
      local r = run.current()
      if not r then
        return nil
      end
      return r.label .. (r.done and (" · " .. r.done) or "")
    end,
    rows = section_rows,
  })

  tether_api.register.command("attractor", {
    run = function(args)
      local sub = table.remove(args, 1) or "outline"
      local fn = M.SUBCOMMANDS[sub]
      if not fn then
        api.util.warn("unknown attractor subcommand " .. sub)
        return
      end
      fn(args)
    end,
    complete = function()
      local names = vim.tbl_keys(M.SUBCOMMANDS)
      table.sort(names)
      return names
    end,
  })
end

return M
