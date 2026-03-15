vim.opt_local.shiftwidth = 2
vim.opt_local.tabstop = 2
vim.opt_local.makeprg = "mvnd clean compile"
vim.opt_local.errorformat = "[ERROR] %f:[%l\\,%c] %m"

-- Fold imports as a single block, delegate everything else to treesitter
_G._java_foldexpr = function()
  local line = vim.fn.getline(vim.v.lnum)
  if line:match("^import ") then
    local prev = vim.v.lnum > 1 and vim.fn.getline(vim.v.lnum - 1) or ""
    if not prev:match("^import ") then
      return ">1"
    end
    return "1"
  end
  return vim.treesitter.foldexpr()
end
vim.opt_local.foldexpr = "v:lua._java_foldexpr()"

local jdtls = require("jdtls")

local root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" })
if not root_dir then
  return
end

local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
local data_dir = vim.fn.stdpath("data") .. "/jdtls/" .. project_name

local jdtls_path = vim.fn.exepath("jdtls")
if jdtls_path == "" then
  vim.notify("jdtls not found on PATH", vim.log.levels.ERROR)
  return
end

local bundles = {}

local mason_path = vim.fn.stdpath("data") .. "/mason/packages"

local debug_jar =
  vim.fn.glob(mason_path .. "/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar")
if debug_jar ~= "" then
  table.insert(bundles, debug_jar)
end

local test_jars = vim.fn.glob(mason_path .. "/java-test/extension/server/*.jar", false, true)
for _, jar in ipairs(test_jars) do
  if not vim.endswith(jar, "com.microsoft.java.test.runner-jar-with-dependencies.jar") then
    table.insert(bundles, jar)
  end
end

local spring_boot_ok, spring_boot = pcall(require, "spring_boot")
if spring_boot_ok then
  vim.list_extend(bundles, spring_boot.java_extensions())
end

local lombok_jar = mason_path .. "/jdtls/lombok.jar"
local cmd = { "jdtls", "-data", data_dir }
if vim.uv.fs_stat(lombok_jar) then
  table.insert(cmd, "--jvm-arg=-javaagent:" .. lombok_jar)
end

local config = {
  cmd = cmd,
  root_dir = root_dir,
  capabilities = require("blink.cmp").get_lsp_capabilities(),

  settings = {
    java = {
      format = {
        settings = {
          profile = "GoogleStyle",
        },
      },
      signatureHelp = { enabled = true },
      contentProvider = { preferred = "fernflower" },
      completion = {
        favoriteStaticMembers = {
          "org.junit.Assert.*",
          "org.junit.jupiter.api.Assertions.*",
          "org.mockito.Mockito.*",
          "java.util.Objects.requireNonNull",
          "java.util.Objects.requireNonNullElse",
        },
      },
      sources = {
        organizeImports = {
          starThreshold = 9999,
          staticStarThreshold = 9999,
        },
      },
    },
  },

  init_options = {
    bundles = bundles,
  },

  on_attach = function(client, bufnr)
    vim.api.nvim_set_current_dir(root_dir)
    jdtls.setup_dap({ hotcodereplace = "auto" })

    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      callback = function()
        local params = vim.lsp.util.make_range_params()
        params.context = { only = { "source.organizeImports" } }
        local result = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", params, 3000)
        for _, res in pairs(result or {}) do
          for _, r in pairs(res.result or {}) do
            if r.edit then
              vim.lsp.util.apply_workspace_edit(r.edit, "utf-16")
            end
          end
        end
      end,
    })

    vim.schedule(function()
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      for i, line in ipairs(lines) do
        if line:match("^import ") then
          local saved = vim.api.nvim_win_get_cursor(0)
          vim.api.nvim_win_set_cursor(0, { i, 0 })
          pcall(vim.cmd, "normal! zc")
          vim.api.nvim_win_set_cursor(0, saved)
          break
        end
      end
    end)

    if not client._spring_dap_configured then
      client._spring_dap_configured = true
      local dap = require("dap")
      dap.configurations.java = dap.configurations.java or {}
      table.insert(dap.configurations.java, {
        type = "java",
        request = "attach",
        name = "Attach to Spring Boot (port 5005)",
        hostName = "127.0.0.1",
        port = 5005,
      })
    end

    local m = function(keys, func, desc)
      vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
    end
    m("<leader>co", jdtls.organize_imports, "Organize imports")
    m("<leader>cv", jdtls.extract_variable, "Extract variable")
    m("<leader>cc", jdtls.extract_constant, "Extract constant")
    vim.keymap.set("v", "<leader>cm", function()
      jdtls.extract_method(true)
    end, { buffer = bufnr, desc = "Extract method" })
    m("<leader>cT", jdtls.test_class, "Test class (jdtls)")
    m("<leader>ct", jdtls.test_nearest_method, "Test method (jdtls)")

    m("<leader>cR", function()
      vim.cmd("split | terminal cd " .. vim.fn.fnameescape(root_dir) .. " && mvnd clean spring-boot:run")
    end, "Run Spring Boot")

    m("<leader>cD", function()
      vim.cmd(
        "split | terminal cd "
          .. vim.fn.fnameescape(root_dir)
          .. " && mvnd clean spring-boot:run -Dspring-boot.run.jvmArguments='-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005'"
      )
    end, "Run Spring Boot (debug)")
  end,
}

jdtls.start_or_attach(config)
