-- Runs Vitest suites through neotest. The Go and Rust extras bring their own
-- adapters.
return {
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = { "marilari88/neotest-vitest" },
    opts = {
      adapters = {
        ["neotest-vitest"] = {},
      },
    },
  },
}
