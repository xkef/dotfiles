-- Formats a file the way the project's own `treefmt` or `dprint fmt` does.
-- When the project's config covers a file, that tool formats it in place of
-- the filetype's formatters and the language server. A file the config
-- excludes, such as a sops secret, stays as written. Other files fall
-- through to conform. :LazyFormatInfo shows which one applies.
--
-- A project's .nvim.lua can name a config outside the usual places. It
-- applies inside the repository that holds it:
--
--   vim.g.dprint_config = vim.fn.getcwd() .. "/shared/config/dprint.json"
local project = require("project")

local PROBE_TIMEOUT_MS = 5000
local FORMAT_TIMEOUT_MS = 3000

local Coverage = { FORMAT = "format", EXCLUDE = "exclude", NONE = "none" }

-- treefmt reports a file that a formatter's excludes drop the same way as a
-- file no formatter matches, so read the config. A formatter whose includes
-- and excludes both match the file excludes it.
local function treefmt_excludes(config, root, file)
  local sections, current = {}, nil
  for _, line in ipairs(vim.fn.readfile(config)) do
    line = line:gsub("#.*$", "")
    if line:match("^%s*%[") then
      current = line:match("^%s*%[formatter%.") and {} or nil
      table.insert(sections, current)
    elseif current then
      table.insert(current, line)
    end
  end

  local path = vim.fs.relpath(root, file)
  local function matches(text, key)
    for list in text:gmatch(key .. "%s*=%s*(%b[])") do
      for glob in list:gmatch("[\"']([^\"']+)[\"']") do
        if vim.fn.match(path, vim.fn.glob2regpat(glob)) ~= -1 then
          return true
        end
      end
    end
    return false
  end

  for _, lines in ipairs(sections) do
    local text = table.concat(lines, "\n")
    if matches(text, "includes") and matches(text, "excludes") then
      return true
    end
  end
  return false
end

-- treefmt fails on a file no formatter matches. Otherwise it reports how
-- many files it handed to a formatter, which is none for an excluded file.
local function treefmt_coverage(config, root, file)
  local probe = vim
    .system({
      "treefmt",
      "--no-cache",
      "--on-unmatched",
      "fatal",
      "--config-file",
      config,
      "--tree-root",
      root,
      "--stdin",
      file,
    }, { cwd = root, stdin = "", text = true })
    :wait(PROBE_TIMEOUT_MS)
  if probe.code ~= 0 then
    return treefmt_excludes(config, root, file) and Coverage.EXCLUDE or Coverage.NONE
  end

  return probe.stderr:find("emitted 1 files") and Coverage.FORMAT or Coverage.EXCLUDE
end

-- dprint formats an excluded file from stdin anyway, so the list of files
-- its config includes decides. The list leaves out a file not yet on disk.
local function dprint_coverage(config, root, file)
  local probe = vim
    .system({ "dprint", "output-file-paths", "--config", config, file }, { cwd = root, text = true })
    :wait(PROBE_TIMEOUT_MS)
  if probe.code ~= 0 or vim.trim(probe.stdout) == "" then
    return Coverage.NONE
  end

  return Coverage.FORMAT
end

local TOOLS = {
  {
    name = "treefmt",
    configs = { "treefmt.toml", ".treefmt.toml", ".config/treefmt.toml" },
    coverage = treefmt_coverage,
  },
  {
    name = "dprint",
    configs = {
      "dprint.json",
      "dprint.jsonc",
      ".dprint.json",
      ".dprint.jsonc",
      ".config/dprint.json",
      ".config/dprint.jsonc",
    },
    coverage = dprint_coverage,
  },
}

local function locate(tool, file)
  local override = vim.g[tool.name .. "_config"]
  if override then
    local root = vim.fs.root(override, { ".jj", ".git" })
    if root and vim.startswith(file, root .. "/") then
      return override, root
    end
  end

  return project.config(file, tool.configs)
end

-- Probes once per buffer and file name. A file not yet on disk is probed
-- again on each format, since dprint lists only files that exist.
local function resolve(buf)
  local file = vim.api.nvim_buf_get_name(buf)
  if file == "" or vim.bo[buf].buftype ~= "" then
    return { coverage = Coverage.NONE }
  end

  local cached = vim.b[buf].project_format
  if cached and cached.file == file then
    return cached
  end

  local found = { file = file, coverage = Coverage.NONE }
  for _, tool in ipairs(TOOLS) do
    local config, root = locate(tool, file)
    if config and vim.fn.executable(tool.name) == 1 then
      local coverage = tool.coverage(config, root, file)
      if coverage ~= Coverage.NONE then
        found = { file = file, coverage = coverage, tool = tool.name, config = config, root = root }
        break
      end
    end
  end

  if vim.uv.fs_stat(file) then
    vim.b[buf].project_format = found
  end
  return found
end

-- Registers outside conform's spec, whose init would replace the one in
-- which LazyVim registers conform itself.
LazyVim.on_very_lazy(function()
  LazyVim.format.register({
    name = "project",
    priority = 200,
    primary = true,
    sources = function(buf)
      local found = resolve(buf)
      if found.coverage == Coverage.FORMAT then
        return { found.tool }
      end
      if found.coverage == Coverage.EXCLUDE then
        return { found.tool .. " (excluded)" }
      end
      return {}
    end,
    format = function(buf)
      local found = resolve(buf)
      if found.coverage == Coverage.FORMAT then
        require("conform").format({ bufnr = buf, formatters = { found.tool }, timeout_ms = FORMAT_TIMEOUT_MS })
      end
    end,
  })
end)

return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        -- treefmt reads its input from a copy that conform writes next to
        -- the file. From stdin it would format a copy in /tmp, where a
        -- formatter such as rumdl misses the project's own config.
        treefmt = {
          args = function(_, ctx)
            local found = resolve(ctx.buf)
            return {
              "--quiet",
              "--no-cache",
              "--walk",
              "filesystem",
              "--config-file",
              found.config,
              "--tree-root",
              found.root,
              "$FILENAME",
            }
          end,
          cwd = function(_, ctx)
            return resolve(ctx.buf).root
          end,
        },
        -- dprint matches an absolute path against includes relative to the
        -- config's directory, which misses a file outside .config/.
        dprint = {
          args = function(_, ctx)
            local found = resolve(ctx.buf)
            return { "fmt", "--config", found.config, "--stdin", vim.fs.relpath(found.root, ctx.filename) }
          end,
          cwd = function(_, ctx)
            return resolve(ctx.buf).root
          end,
        },
      },
    },
  },
}
