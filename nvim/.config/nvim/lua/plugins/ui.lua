return {
  {
    "akinsho/bufferline.nvim",
    opts = function(_, opts)
      opts.options = vim.tbl_deep_extend("force", opts.options or {}, {
        themable = false,
        style_preset = {
          require("bufferline").style_preset.no_bold,
        },
        indicator = { icon = "", style = "none" },
        separator_style = { "", "" },
        color_icons = true,
        offsets = {
          { filetype = "neo-tree", text = "", separator = false },
          { filetype = "snacks_layout_box" },
        },
      })
      local orig_hl = opts.highlights
      opts.highlights = function(config)
        local base = type(orig_hl) == "function" and orig_hl(config) or (orig_hl or {})
        base.fill = vim.tbl_deep_extend("force", base.fill or {}, {
          bg = { attribute = "bg", highlight = "NeoTreeNormal" },
        })
        return base
      end
    end,
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
