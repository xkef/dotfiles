return {
  {
    "mfussenegger/nvim-jdtls",
    ft = "java",
    dependencies = {
      "mfussenegger/nvim-dap",
    },
  },

  {
    "mfussenegger/nvim-dap",
    lazy = true,
    keys = {
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
      { "<leader>dc", function() require("dap").continue() end,         desc = "Continue" },
      { "<leader>do", function() require("dap").step_over() end,        desc = "Step over" },
      { "<leader>di", function() require("dap").step_into() end,        desc = "Step into" },
      { "<leader>dO", function() require("dap").step_out() end,         desc = "Step out" },
      { "<leader>dr", function() require("dap").repl.open() end,        desc = "REPL" },
      { "<leader>dl", function() require("dap").run_last() end,         desc = "Run last" },
      { "<leader>dt", function() require("dap").terminate() end,        desc = "Terminate" },
    },
  },

  {
    "nvim-neotest/neotest",
    lazy = true,
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "rcasia/neotest-java",
    },
    keys = {
      { "<leader>tn", function() require("neotest").run.run() end,                   desc = "Run nearest test" },
      { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run file tests" },
      { "<leader>ts", function() require("neotest").summary.toggle() end,            desc = "Test summary" },
      { "<leader>to", function() require("neotest").output.open() end,               desc = "Test output" },
      { "<leader>tp", function() require("neotest").output_panel.toggle() end,       desc = "Test output panel" },
      {
        "<leader>td",
        function() require("neotest").run.run({ strategy = "dap" }) end,
        desc = "Debug nearest test",
      },
    },
    config = function()
      require("neotest").setup({
        adapters = {
          require("neotest-java"),
        },
      })
    end,
  },
}
