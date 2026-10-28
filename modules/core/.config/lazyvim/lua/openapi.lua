-- An in-process language server that resolves `$ref` in OpenAPI and JSON
-- Schema files, which yamlls and jsonls can't follow. It answers
-- textDocument/definition and textDocument/references, so gd, gr, and the
-- pickers merge its results with the other servers'. A ref names a file
-- relative to the current one and a JSON pointer into it:
--   $ref: "./schemas/user.yaml#/components/schemas/User"
--   $ref: "#/components/schemas/User"
local M = {}

local MAPPING = { block_mapping = true, flow_mapping = true, object = true }
local SEQUENCE = { block_sequence = true, flow_sequence = true, array = true }
local PAIR = { block_mapping_pair = true, flow_pair = true, pair = true }
local SPEC_PATTERNS = { "^openapi%s*:", "^swagger%s*:", '^%s*"openapi"%s*:', '^%s*"swagger"%s*:' }
local SPEC_HEAD_LINES = 20

-- Reports whether a buffer holds an OpenAPI root document.
function M.is_spec(bufnr)
  for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, SPEC_HEAD_LINES, false)) do
    for _, pattern in ipairs(SPEC_PATTERNS) do
      if line:find(pattern) then
        return true
      end
    end
  end
  return false
end

local function ref_on(line)
  return line:match([["%$ref"%s*:%s*"([^"]+)"]]) or line:match([[%$ref%s*:%s*["']?([^"'%s]+)]])
end

local function unquote(text)
  return text:match([[^"(.*)"$]]) or text:match([[^'(.*)'$]]) or text
end

-- Splits "/a~1b/c%20d" into { "a/b", "c d" } as RFC 6901 decodes it.
local function segments(pointer)
  local result = {}
  for seg in pointer:gmatch("/([^/]*)") do
    seg = seg:gsub("%%(%x%x)", function(hex)
      return string.char(tonumber(hex, 16))
    end)
    result[#result + 1] = (seg:gsub("~1", "/"):gsub("~0", "~"))
  end
  return result
end

local function escape(seg)
  return (seg:gsub("~", "~0"):gsub("/", "~1"))
end

-- Resolves a ref against the file that holds it. Returns the target file
-- and pointer, or nil for a remote ref.
local function resolve(ref, from)
  local file, pointer = ref:match("^([^#]*)#?(.*)$")
  if file:find("^%a[%w+.-]*://") then
    return nil
  end
  if file == "" then
    return from, pointer
  end
  return vim.fs.normalize(vim.fs.joinpath(vim.fs.dirname(from), file)), pointer
end

local function root_of(bufnr)
  local lang = vim.api.nvim_buf_get_name(bufnr):find("%.json$") and "json" or "yaml"
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, lang)
  if not ok or not parser then
    return nil
  end
  return parser:parse()[1]:root()
end

-- Finds the first mapping or sequence at or below a node, which skips the
-- document, block_node, and flow_node wrappers around it.
local function container(node)
  if MAPPING[node:type()] or SEQUENCE[node:type()] then
    return node
  end
  for child in node:iter_children() do
    local found = child:named() and container(child)
    if found then
      return found
    end
  end
end

-- Returns the key and the value that a pointer segment selects below node.
local function step(bufnr, node, seg)
  local c = container(node)
  if not c then
    return nil
  end

  local index = SEQUENCE[c:type()] and tonumber(seg)
  for child in c:iter_children() do
    if PAIR[child:type()] then
      local key = child:field("key")[1]
      if key and unquote(vim.treesitter.get_node_text(key, bufnr)) == seg then
        return key, child:field("value")[1]
      end
    elseif index and child:named() and child:type() ~= "comment" then
      if index == 0 then
        return child, child
      end
      index = index - 1
    end
  end
end

local function location(file, node)
  local row, col = 0, 0
  if node then
    row, col = node:range()
  end
  local pos = { line = row, character = col }
  return { uri = vim.uri_from_fname(file), range = { start = pos, ["end"] = pos } }
end

local function definition(file, pointer)
  local bufnr = vim.fn.bufadd(file)
  vim.fn.bufload(bufnr)
  local node = root_of(bufnr)
  local key
  for _, seg in ipairs(segments(pointer)) do
    if not node then
      return nil
    end
    key, node = step(bufnr, node, seg)
  end
  if pointer ~= "" and not key then
    return nil
  end
  return location(file, key)
end

-- Builds the pointer of the key under the cursor from the pairs and
-- sequence items around it.
local function pointer_at(bufnr, row, col)
  local root = root_of(bufnr)
  local node = root and root:named_descendant_for_range(row, col, row, col)
  local parts = {}
  while node do
    local parent = node:parent()
    if PAIR[node:type()] then
      local key = node:field("key")[1]
      table.insert(parts, 1, escape(unquote(vim.treesitter.get_node_text(key, bufnr))))
    elseif parent and SEQUENCE[parent:type()] then
      local index = 0
      local sibling = node:prev_named_sibling()
      while sibling do
        index = sibling:type() == "comment" and index or index + 1
        sibling = sibling:prev_named_sibling()
      end
      table.insert(parts, 1, tostring(index))
    end
    node = parent
  end
  return #parts > 0 and "/" .. table.concat(parts, "/") or nil
end

-- Lists every ref under root that resolves to file and pointer.
local function references(root, file, pointer, callback)
  local cmd = { "rg", "--no-heading", "--line-number", "--fixed-strings", "--glob", "*.{yaml,yml,json}" }
  vim.list_extend(cmd, { "#" .. pointer, root })
  vim.system(cmd, { text = true }, function(out)
    local result = {}
    for line in vim.gsplit(out.stdout or "", "\n", { trimempty = true }) do
      local path, lnum, text = line:match("^(.-):(%d+):(.*)$")
      local ref = path and ref_on(text)
      local target, ptr
      if ref then
        target, ptr = resolve(ref, vim.fs.normalize(path))
      end
      if target == file and ptr == pointer then
        local col = text:find("$ref", 1, true) - 1
        local pos = { line = tonumber(lnum) - 1, character = col }
        result[#result + 1] = { uri = vim.uri_from_fname(path), range = { start = pos, ["end"] = pos } }
      end
    end
    vim.schedule(function()
      callback(nil, result)
    end)
  end)
end

local function handlers(config)
  return {
    initialize = function(_, callback)
      callback(nil, {
        capabilities = { positionEncoding = "utf-8", definitionProvider = true, referencesProvider = true },
      })
    end,

    shutdown = function(_, callback)
      callback(nil, nil)
    end,

    ["textDocument/definition"] = function(params, callback)
      local bufnr = vim.uri_to_bufnr(params.textDocument.uri)
      local line = vim.api.nvim_buf_get_lines(bufnr, params.position.line, params.position.line + 1, false)[1]
      local ref = line and ref_on(line)
      local file, pointer
      if ref then
        file, pointer = resolve(ref, vim.uri_to_fname(params.textDocument.uri))
      end
      callback(nil, file and definition(file, pointer) or nil)
    end,

    -- On a $ref, lists the refs to its target. Elsewhere, lists the refs to
    -- the key under the cursor.
    ["textDocument/references"] = function(params, callback)
      local bufnr = vim.uri_to_bufnr(params.textDocument.uri)
      local row, col = params.position.line, params.position.character
      local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
      local here = vim.uri_to_fname(params.textDocument.uri)
      local ref = line and ref_on(line)
      local file, pointer
      if ref then
        file, pointer = resolve(ref, here)
      else
        file, pointer = here, pointer_at(bufnr, row, col)
      end
      if not file or not pointer then
        callback(nil, {})
        return
      end
      references(config.root_dir or vim.fs.dirname(here), file, pointer, callback)
    end,
  }
end

-- Implements vim.lsp.rpc.PublicClient in Lua for vim.lsp.Config.cmd.
function M.cmd(dispatchers, config)
  local closing = false
  local id = 0
  local methods = handlers(config)
  return {
    request = function(method, params, callback)
      id = id + 1
      local handler = methods[method]
      if handler then
        handler(params, callback)
      else
        callback(nil, nil)
      end
      return true, id
    end,
    notify = function(method)
      if method == "exit" then
        dispatchers.on_exit(0, 0)
      end
      return true
    end,
    is_closing = function()
      return closing
    end,
    terminate = function()
      closing = true
    end,
  }
end

return M
