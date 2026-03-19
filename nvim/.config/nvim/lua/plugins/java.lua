return {
  {
    "JavaHello/spring-boot.nvim",
    ft = { "java", "yaml", "jproperties" },
    dependencies = { "mfussenegger/nvim-jdtls" },
    config = function()
      local ls_jar = vim.fn.glob(
        "$MASON/packages/vscode-spring-boot-tools/extension/language-server/spring-boot-language-server-*.jar"
      )
      if ls_jar == "" then
        vim.notify("spring-boot-tools not installed, run :MasonInstall spring-boot-tools", vim.log.levels.WARN)
        return
      end
      require("spring_boot").setup({ ls_path = ls_jar, exploded_ls_jar_data = false })
    end,
  },

  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "google-java-format", "vscode-spring-boot-tools" } },
  },

  {
    "stevearc/conform.nvim",
    opts = { formatters_by_ft = { java = { "google-java-format" } } },
  },

  {
    "mfussenegger/nvim-jdtls",
    opts = {
      jdtls = function(config)
        local ok, spring_boot = pcall(require, "spring_boot")
        if ok then
          vim.list_extend(config.init_options.bundles, spring_boot.java_extensions())
        end
        return config
      end,

      settings = {
        java = {
          format = { settings = { profile = "GoogleStyle" } },
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

      on_attach = function(args)
        local bufnr = args.buf
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        local root_dir = client and client.config.root_dir

        if root_dir then
          vim.api.nvim_set_current_dir(root_dir)
        end

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

        if root_dir then
          local mvn = vim.fn.executable("mvnd") == 1 and "mvnd" or "mvn"
          local m = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
          end
          m("<leader>cR", function()
            vim.cmd("split | terminal cd " .. vim.fn.fnameescape(root_dir) .. " && " .. mvn .. " clean spring-boot:run")
          end, "Run Spring Boot")
          m("<leader>cD", function()
            vim.cmd(
              "split | terminal cd "
                .. vim.fn.fnameescape(root_dir)
                .. " && "
                .. mvn
                .. " clean spring-boot:run -Dspring-boot.run.jvmArguments='-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005'"
            )
          end, "Run Spring Boot (debug)")
        end
      end,
    },
  },
}
