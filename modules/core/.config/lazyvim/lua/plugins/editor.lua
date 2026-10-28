return {
  {
    "mrjones2014/smart-splits.nvim",
    -- v3 moved the WezTerm and tmux support into separate backend plugins,
    -- and the WezTerm one is still unstable. v2 ships both.
    tag = "v2.1.1-final",
    -- Loads at startup to set the IS_NVIM user var and tmux's @pane-is-vim,
    -- which the WezTerm and tmux leader h/j/k/l read to hand the key to
    -- Neovim. A lazy load leaves them unset until the first move.
    lazy = false,
    keys = (function()
      local ss = "smart-splits"
      local keys = {}
      for _, m in ipairs({
        { "<C-h>", "move_cursor_left" },
        { "<C-j>", "move_cursor_down" },
        { "<C-k>", "move_cursor_up" },
        -- macOS takes Ctrl-arrows for Spaces, so LazyVim's resize keys never
        -- reach Neovim.
        { "<A-H>", "resize_left" },
        { "<A-J>", "resize_down" },
        { "<A-K>", "resize_up" },
        { "<A-L>", "resize_right" },
      }) do
        keys[#keys + 1] = {
          m[1],
          function()
            require(ss)[m[2]]()
          end,
        }
      end

      -- Clears multicursors while any exist, as the default CTRL-L mapping
      -- does (:h CTRL-L-default). Otherwise the key moves right like its
      -- siblings.
      local mc_ns = vim.api.nvim_create_namespace("nvim.multicursor")
      keys[#keys + 1] = {
        "<C-l>",
        function()
          if next(vim.api.nvim_buf_get_extmarks(0, mc_ns, 0, -1, { limit = 1 })) then
            vim.api.nvim_buf_clear_namespace(0, mc_ns, 0, -1)
            return
          end

          require(ss).move_cursor_right()
        end,
      }
      return keys
    end)(),
  },

  -- Collapses the harpoon2 extra's <leader>1-9 into one which-key row. The
  -- hidden keys still work.
  {
    "folke/which-key.nvim",
    opts = function(_, opts)
      opts.spec = opts.spec or {}
      table.insert(opts.spec, { "<leader>1", desc = "Harpoon to File 1-9" })
      for i = 2, 9 do
        table.insert(opts.spec, { "<leader>" .. i, hidden = true })
      end
    end,
  },

  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          files = { hidden = true },
          grep = { hidden = true },
        },
      },
    },
    init = function()
      -- Hide hunk headers in the Snacks diff renderer.
      local ok, diff = pcall(require, "snacks.picker.util.diff")
      if ok and diff.render then
        local orig = diff.render
        diff.render = function(buf, ns, d, opts)
          opts = vim.tbl_deep_extend("force", opts or {}, { hunk_header = false })
          return orig(buf, ns, d, opts)
        end
      end
    end,
  },
}
