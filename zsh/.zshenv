# XDG Base Directories
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Zsh config directory
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Homebrew (macOS only) — static exports avoid ~15ms fork+exec of
# `brew shellenv` on every zsh invocation (including non-interactive
# scripts/subshells).
if [[ -d /opt/homebrew ]]; then
  export HOMEBREW_PREFIX="/opt/homebrew"
  export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
  export HOMEBREW_REPOSITORY="/opt/homebrew"
  export MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:"
  export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"
fi

# Editor
export EDITOR="nvim"
export VISUAL="nvim"

# Pager
export PAGER="less"
export LESS="-R --mouse"

# Man pager (use bat for colorful manpages)
if command -v bat &>/dev/null; then
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  export MANROFFOPT="-c"
fi

# XDG-compliant tool homes
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export GOPATH="$XDG_DATA_HOME/go"
export LESSHISTFILE="$XDG_STATE_HOME/less/history"
export NODE_REPL_HISTORY="$XDG_DATA_HOME/node_repl_history"

# Dotfiles
if [[ -z "${DOTFILES_DIR:-}" && -f "$HOME/.config/dotfiles/dir" ]]; then
  export DOTFILES_DIR="$(<"$HOME/.config/dotfiles/dir")"
fi

# Path — also re-asserted in .zprofile to override macOS path_helper.
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

