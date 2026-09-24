-- Opens file:// links in Neovim, in a split. eza, ripgrep, and delta emit
-- them over OSC 8, and a ":<line>" suffix jumps to that line. Other links,
-- and paths that don't exist on this machine, such as ones printed inside a
-- VM, fall through to the default handler.
local wezterm = require("wezterm")

local M = {}

local function decode(text)
  return (text:gsub("%%(%x%x)", function(hex)
    return string.char(tonumber(hex, 16))
  end))
end

function M.setup()
  wezterm.on("open-uri", function(_, pane, uri)
    local path, line = uri:match("^file://[^/]*(/.-):?(%d*)$")
    if not path then
      return
    end

    path = decode(path)
    local file = io.open(path, "r")
    if not file then
      return
    end
    file:close()

    local jump = line ~= "" and ("+" .. line .. " ") or ""
    pane:split({
      args = { "fish", "-c", "nvim " .. jump .. wezterm.shell_quote_arg(path) },
      direction = "Right",
    })
    return false
  end)
end

return M
