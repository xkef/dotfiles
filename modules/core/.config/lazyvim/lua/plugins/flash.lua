-- Labeled jumps, like easymotion or hop. catppuccin integrates with flash.
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
