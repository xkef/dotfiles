return {
  -- bufferline: underline indicator + thin separators (rose-pine-inspired).
  -- Highlights are driven entirely by the active colorscheme so this looks
  -- correct with every theme without any per-theme overrides.
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        indicator = { style = "underline" },
        separator_style = "thin",
        show_buffer_close_icons = false,
        show_close_icon = false,
        color_icons = true,
      },
    },
  },

  {
    "nvim-lualine/lualine.nvim",
    opts = {
      sections = {
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
  },

  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = function(_, opts)
      opts.filesystem = opts.filesystem or {}
      opts.filesystem.group_empty_dirs = true
      local fi = opts.filesystem.filtered_items or {}
      fi.visible = true
      fi.hide_dotfiles = false
      fi.hide_hidden = false
      fi.hide_gitignored = true
      fi.never_show = { ".DS_Store", ".git", ".jj", ".idea" }
      opts.filesystem.filtered_items = fi
    end,
  },

  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        ["<C-n>"] = { "show", "select_next", "fallback" },
        ["<C-p>"] = { "show", "select_prev", "fallback" },
      },
    },
  },
}
