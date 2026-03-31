# .zshenv — sourced for EVERY zsh instance (interactive, login, script, subshell).
# Keep this fast and side-effect-free: only exports and PATH.
# See: man zsh "STARTUP/SHUTDOWN FILES", https://zsh.sourceforge.io/Intro/intro_3.html

# XDG Base Directories — freedesktop.org standard for config/data/cache/state paths.
# Most CLI tools respect these, keeping $HOME clean.
# Spec: https://specifications.freedesktop.org/basedir-spec/latest/
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# ZDOTDIR tells zsh where to find .zshrc, .zprofile, etc.
# Without this, zsh looks in $HOME (cluttering it with dotfiles).
# See: man zshall "ZDOTDIR"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Homebrew (macOS only) — static exports avoid ~15ms fork+exec of
# `brew shellenv` on every zsh invocation (including non-interactive
# scripts/subshells). These match the output of `brew shellenv`.
if [[ -d /opt/homebrew ]]; then
  export HOMEBREW_PREFIX="/opt/homebrew"
  export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
  export HOMEBREW_REPOSITORY="/opt/homebrew"
  export MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:"
  export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"
fi

# Editor — used by git commit, crontab -e, sudoedit, etc.
# VISUAL is for full-screen editors, EDITOR for line-mode fallback.
export EDITOR="nvim"
export VISUAL="nvim"

# NVIM_APPNAME selects which config directory neovim uses (~/.config/$NVIM_APPNAME).
# "lazyvim" is the default; kickstart is available via the `knvim` wrapper.
# See: :help NVIM_APPNAME
export NVIM_APPNAME="lazyvim"

# Man pager — nvim's :Man plugin provides treesitter syntax highlighting,
# search, tag navigation (Ctrl-]), and persistent scrollback.
# MANWIDTH=999 prevents hard-wrapping so nvim can soft-wrap to window width.
# See: :help man.vim
if command -v nvim &>/dev/null; then
  export MANPAGER='nvim +Man!'
  export MANWIDTH=999
fi

# XDG-compliant tool homes — redirect tools that default to ~/.<tool>
# into XDG directories. Check each tool's docs for the env var name.
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export GOPATH="$XDG_DATA_HOME/go"
export LESSHISTFILE="$XDG_STATE_HOME/less/history"
export NODE_REPL_HISTORY="$XDG_DATA_HOME/node_repl_history"

# Zoxide exclusions — prevent macOS sandbox app directories, trash, and
# tmp from polluting the frecency database. Colon-separated glob patterns.
# See: https://github.com/ajeetdsouza/zoxide#environment-variables
export _ZO_EXCLUDE_DIRS="$HOME/Library/*:$HOME/.Trash/*:/tmp/*"

# Podman compatibility — on Linux the socket path is stable; on macOS it
# lives in a temp dir that changes per boot, so we resolve it lazily via a
# wrapper function to avoid forking `podman machine inspect` on every shell.
if command -v podman &>/dev/null; then
  if [[ "$OSTYPE" == darwin* ]]; then
    lazydocker() {
      local sock
      sock=$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' 2>/dev/null)
      DOCKER_HOST="unix://$sock" command lazydocker "$@"
    }
  else
    export DOCKER_HOST="unix://${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/podman/podman.sock"
  fi
fi

# GitHub token — used by mise, gh, and other tools that hit the GitHub API.
# Without this, unauthenticated requests are limited to 60/hour (vs 5,000).
# Placed in .zshenv (not .zprofile) so it's available in non-login shells
# like tmux panes, neovim terminals, and CI subshells.
if [[ -z "${GITHUB_TOKEN:-}" ]] && command -v gh &>/dev/null; then
  GITHUB_TOKEN="$(gh auth token 2>/dev/null)"
  export GITHUB_TOKEN
fi

# HuggingFace token — used by parry-guard (prompt injection scanner) to
# download ML models. Token is stored by `huggingface-cli login`.
if [[ -z "${HF_TOKEN:-}" && -r "${XDG_CACHE_HOME:-$HOME/.cache}/huggingface/token" ]]; then
  HF_TOKEN="$(<"${XDG_CACHE_HOME:-$HOME/.cache}/huggingface/token")"
  export HF_TOKEN
fi

# Dotfiles directory — read from a marker file written by ./install.
# Used by shell functions, neovim pickers, and the theme system.
if [[ -z "${DOTFILES_DIR:-}" && -f "$HOME/.config/dotfiles/dir" ]]; then
  DOTFILES_DIR="$(<"$HOME/.config/dotfiles/dir")"
  export DOTFILES_DIR
fi

# PATH — typeset -U deduplicates entries (unique array).
# Order matters: earlier entries win. User bins first, then language
# toolchains, then Homebrew, then system defaults.
# See: man zshbuiltins "typeset"
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

# GitHub token — used by mise, gh, and other tools that hit the GitHub API.
# Without this, unauthenticated requests are limited to 60/hour (vs 5,000).
# Placed in .zshenv (not .zprofile) so it's available in non-login shells
# like tmux panes, neovim terminals, and CI subshells.
# Must come after PATH so `gh` is findable.
if [[ -z "${GITHUB_TOKEN:-}" ]] && command -v gh &>/dev/null; then
  GITHUB_TOKEN="$(gh auth token 2>/dev/null)"
  export GITHUB_TOKEN
fi

# HuggingFace token — used by parry-guard (prompt injection scanner) to
# download ML models. Token is stored by `huggingface-cli login`.
if [[ -z "${HF_TOKEN:-}" && -r "${XDG_CACHE_HOME:-$HOME/.cache}/huggingface/token" ]]; then
  HF_TOKEN="$(<"${XDG_CACHE_HOME:-$HOME/.cache}/huggingface/token")"
  export HF_TOKEN
fi
