local ok, theme = pcall(require, "theme")
if ok and type(theme.setup) == "function" then
  theme.setup()
end
