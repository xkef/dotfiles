# PATH assembly — runs after /etc/zprofile (macOS path_helper),
# so Homebrew and user paths take precedence over system paths.
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

# GitHub token for mise and other tools that hit the GitHub API directly
if [[ -z "${GITHUB_TOKEN:-}" ]] && (( $+commands[gh] )); then
  export GITHUB_TOKEN="$(gh auth token 2>/dev/null)"
fi
