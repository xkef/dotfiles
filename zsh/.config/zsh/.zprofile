# .zprofile — sourced for LOGIN shells only, after .zshenv.
# On macOS, /etc/zprofile runs `path_helper` which appends system paths,
# pushing our .zshenv entries to the end. This file re-prepends them so
# Homebrew and user bins take precedence over /usr/bin, /usr/sbin, etc.
# See: man path_helper, https://gist.github.com/Linerre/f11ad4a6a934dcf01ee8415c9457e7b2
typeset -U path
path=(
  "$HOME/.local/bin"
  "$CARGO_HOME/bin"
  "$GOPATH/bin"
  ${HOMEBREW_PREFIX:+"$HOMEBREW_PREFIX/bin"}
  ${HOMEBREW_PREFIX:+"$HOMEBREW_PREFIX/sbin"}
  "/usr/local/bin"
  $path
)
