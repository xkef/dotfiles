-- Buffer-based file operations. Complements neo-tree (tree view) with an
-- editable buffer of the current directory.
return {
  {
    "stevearc/oil.nvim",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      default_file_explorer = false,
      view_options = {
        show_hidden = true,
        is_always_hidden = function(name)
          return name == ".." or name == ".git" or name == ".jj" or name == ".DS_Store"
        end,
      },
      keymaps = {
        ["g?"] = "actions.show_help",
        ["<CR>"] = "actions.select",
        ["<C-s>"] = { "actions.select", opts = { vertical = true } },
        ["<C-h>"] = { "actions.select", opts = { horizontal = true } },
        ["<C-p>"] = "actions.preview",
        ["<C-c>"] = "actions.close",
        ["-"] = "actions.parent",
        ["_"] = "actions.open_cwd",
        ["g."] = "actions.toggle_hidden",
      },
    },
    keys = {
      -- @key nvim :: - :: Open parent directory (oil)
      { "-", "<cmd>Oil<cr>", desc = "Open parent directory (oil)" },
    },
  },
}
