-- lualine extension for the review panel's log, in place of the editor
-- sections that mean nothing there.
return {
  filetypes = { "jjreview_log" },
  sections = {
    lualine_a = {
      function()
        return "jj log"
      end,
    },
    lualine_b = {
      function()
        return require("jjreview.panel").summary()
      end,
    },
  },
}
