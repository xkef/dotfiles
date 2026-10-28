-- neo-tree source "jj": the files that the review panel's selection
-- changes, or that @ changes without a panel. Opening a file goes through
-- the panel, which picks the working copy file or a jj:// buffer.
local cc = require("neo-tree.sources.common.commands")
local manager = require("neo-tree.sources.manager")

local M = {
  name = "jj",
  display_name = " 󰘬 jj ",
}

local SYMBOLS = {
  added = "A",
  modified = "M",
  removed = "D",
  renamed = "R",
  copied = "C",
}

local HIGHLIGHTS = {
  added = "NeoTreeGitAdded",
  modified = "NeoTreeGitModified",
  removed = "NeoTreeGitDeleted",
  renamed = "NeoTreeGitRenamed",
  copied = "NeoTreeGitAdded",
}

M.default_config = {
  renderers = {
    directory = {
      { "indent" },
      { "icon" },
      { "name" },
    },
    file = {
      { "indent" },
      { "icon" },
      {
        "container",
        content = {
          { "name", zindex = 10 },
          { "jj_status", zindex = 20, align = "right" },
        },
      },
    },
  },
}

function M.navigate(state, _, _, callback)
  local file_items = require("neo-tree.sources.common.file-items")
  local jj = require("jjreview.jj")
  local root = jj.root()
  state.path = root or vim.fn.getcwd()

  local context = file_items.create_context()
  context.state = state
  local top = file_items.create_item(context, state.path, "directory")
  top.loaded = true
  context.folders[top.path] = top

  local title, files = require("jjreview.panel").load()
  top.name = title
  for _, file in ipairs(files) do
    local item = file_items.create_item(context, vim.fs.joinpath(state.path, file.path), "file")
    item.extra = { jj_file = file }
  end

  state.default_expanded_nodes = vim.tbl_keys(context.folders)
  file_items.advanced_sort(top.children, state)
  require("neo-tree.ui.renderer").show_nodes({ top }, state)
  if callback then
    vim.schedule(callback)
  end
end

function M.refresh()
  manager.refresh(M.name)
end

function M.setup(_, global_config)
  if global_config.enable_refresh_on_write then
    manager.subscribe(M.name, {
      event = require("neo-tree.events").VIM_BUFFER_CHANGED,
      handler = M.refresh,
    })
  end
end

M.components = vim.tbl_extend("force", require("neo-tree.sources.common.components"), {
  jj_status = function(_, node)
    local file = node.extra and node.extra.jj_file
    if not file then
      return {}
    end
    return { text = " " .. SYMBOLS[file.status] .. " ", highlight = HIGHLIGHTS[file.status] }
  end,
})

-- Directories toggle. Files open through the panel, in the window that
-- neo-tree would pick, after the given split command. Without such a
-- window the file opens in a new one right of the tree.
local function opener(split)
  return function(state)
    local node = state.tree:get_node()
    if node.type == "directory" then
      cc.toggle_node(state)
      return
    end

    local win, is_tree = require("neo-tree.utils").get_appropriate_window(state, true)
    if is_tree then
      vim.cmd("rightbelow vnew")
    else
      vim.api.nvim_set_current_win(win)
    end
    local panel = require("jjreview.panel")
    panel.open(node.extra.jj_file, split)
    panel.keep(vim.api.nvim_get_current_buf())
  end
end

M.commands = vim.tbl_extend("force", cc, {
  open = opener(nil),
  open_split = opener("split"),
  open_vsplit = opener("vsplit"),
  open_tabnew = opener("tabnew"),
  refresh = M.refresh,
})

return M
