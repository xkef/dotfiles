return {
  {
    "JavaHello/spring-boot.nvim",
    ft = { "java", "yaml", "jproperties" },
    dependencies = {
      "mfussenegger/nvim-jdtls",
    },
    config = function()
      local mason_path = vim.fn.stdpath("data") .. "/mason/packages/vscode-spring-boot-tools"
      local ls_jar = vim.fn.glob(mason_path .. "/extension/language-server/spring-boot-language-server-*.jar")
      if ls_jar == "" then
        vim.notify("spring-boot-tools not installed, run :MasonInstall spring-boot-tools", vim.log.levels.WARN)
        return
      end
      require("spring_boot").setup({
        ls_path = ls_jar,
        exploded_ls_jar_data = false,
      })
    end,
  },

  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "google-java-format",
        "vscode-spring-boot-tools",
      },
    },
  },

  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        java = { "google-java-format" },
      },
    },
  },
}
