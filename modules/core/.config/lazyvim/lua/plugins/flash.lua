-- Labeled jumps, like easymotion or hop.
return {
  {
    "folke/flash.nvim",
    opts = {
      modes = {
        char = { jump_labels = true },
      },
    },
  },
}
