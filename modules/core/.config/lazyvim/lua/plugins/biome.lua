-- Biome diagnostics next to vtsls. lspconfig runs the project's
-- node_modules/.bin/biome when there is one.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        biome = {},
      },
    },
  },
}
