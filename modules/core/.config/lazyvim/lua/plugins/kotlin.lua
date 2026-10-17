-- JetBrains' kotlin-lsp, built on IntelliJ, in place of the Kotlin extra's
-- community fwcd server, which fails to parse current Java versions.
-- kotlin-lsp imports Gradle and Maven builds, such as a Spring Boot
-- project's. Homebrew and the AUR install it, since Mason's download link
-- is broken. The Homebrew cask links only the older kotlin-lsp wrapper.
local cmd = vim.fn.executable("intellij-server") == 1 and "intellij-server" or "kotlin-lsp"

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        kotlin_language_server = { enabled = false },
        kotlin_lsp = {
          mason = false,
          cmd = { cmd, "--stdio" },
        },
      },
    },
  },
}
