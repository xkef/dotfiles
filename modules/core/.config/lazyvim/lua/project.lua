local M = {}

-- Finds the config nearest to a file from a list of names relative to a
-- project directory, such as ".config/dprint.json". Returns the config and
-- the project directory. The search stops below $HOME so a user-level
-- config such as ~/.config/vale/.vale.ini never counts as a project config.
function M.config(file, names)
  for dir in vim.fs.parents(file) do
    if dir == vim.env.HOME then
      return nil
    end

    for _, name in ipairs(names) do
      local path = vim.fs.joinpath(dir, name)
      if vim.uv.fs_stat(path) then
        return path, dir
      end
    end
  end
end

return M
