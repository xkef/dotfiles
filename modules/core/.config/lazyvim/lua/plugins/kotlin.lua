-- JetBrains' kotlin-lsp, built on IntelliJ, in place of the Kotlin extra's
-- community fwcd server, which fails to parse current Java versions.
-- kotlin-lsp imports Gradle and Maven builds, such as a Spring Boot
-- project's. Mason installs it on macOS. The AUR installs it on Arch,
-- since Mason's linux_arm64 entry, which the Lima VM needs, is broken.
local cmd = vim.fn.executable("intellij-server") == 1 and "intellij-server" or "kotlin-lsp"

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        kotlin_language_server = { enabled = false },
        kotlin_lsp = {
          mason = vim.fn.has("mac") == 1,
          cmd = { cmd, "--stdio" },
        },
      },
    },
  },
}
