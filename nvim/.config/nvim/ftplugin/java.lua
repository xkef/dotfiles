vim.opt_local.shiftwidth = 4
vim.opt_local.tabstop = 4

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

local config = {
  cmd = { "jdtls", "-data", data_dir },
  root_dir = root_dir,
  capabilities = require("blink.cmp").get_lsp_capabilities(),

  settings = {
    java = {
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

  on_attach = function(_, bufnr)
    jdtls.setup_dap({ hotcodereplace = "auto" })

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
  end,
}

jdtls.start_or_attach(config)
