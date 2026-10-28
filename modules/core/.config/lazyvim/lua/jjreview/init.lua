-- Review jj changes and switch jj workspaces inside one Neovim. See
-- panel.lua for the layout and hunk.lua for the hunk commands.
local M = {}

function M.setup()
  require("jjreview.panel").setup()
  vim.api.nvim_create_user_command("JReview", function()
    require("jjreview.panel").toggle()
  end, { desc = "Toggle the jj review panel" })
end

return M
