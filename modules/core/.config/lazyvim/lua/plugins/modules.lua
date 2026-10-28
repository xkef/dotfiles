-- Badges build modules in the neo-tree filesystem view, and gm moves to
-- the module that holds the node. lua/modules.lua detects the modules.
return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = function(_, opts)
      local modules = require("modules")
      opts.filesystem = opts.filesystem or {}
      local fs = opts.filesystem

      fs.components = vim.tbl_extend("force", fs.components or {}, {
        -- The root line has no room left for a badge.
        module = function(_, node, state)
          local kind = node.type == "directory" and node.path ~= state.path and modules.kind(node.path)
          if not kind then
            return {}
          end
          return { text = " " .. kind, highlight = "NeoTreeDimText" }
        end,
      })

      -- A source renderer replaces the default one, so the badge goes into
      -- a copy of the default, right after the name.
      local directory = vim.deepcopy(require("neo-tree.defaults").renderers.directory)
      for _, component in ipairs(directory) do
        if component[1] == "container" then
          table.insert(component.content, 2, { "module", zindex = 10 })
        end
      end
      fs.renderers = vim.tbl_extend("force", fs.renderers or {}, { directory = directory })

      fs.window = fs.window or {}
      fs.window.mappings = vim.tbl_extend("force", fs.window.mappings or {}, {
        ["gm"] = {
          function(state)
            local root = modules.root(state.tree:get_node().path)
            if root and vim.startswith(root, state.path) then
              require("neo-tree.sources.filesystem").navigate(state, state.path, root)
            end
          end,
          desc = "go to module",
        },
      })

      -- A build file that appears or changes can add or drop a module.
      opts.event_handlers = opts.event_handlers or {}
      for _, event in ipairs({ "fs_event", "file_added", "file_deleted", "file_moved", "file_renamed" }) do
        table.insert(opts.event_handlers, { event = event, handler = modules.reset })
      end
    end,
  },
}
