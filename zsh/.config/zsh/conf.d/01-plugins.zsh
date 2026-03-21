# ── Zinit ──────────────────────────────────────────────
# Zinit is a flexible zsh plugin manager with support for turbo mode
# (deferred loading). Self-installs on first run.
# See: https://github.com/zdharma-continuum/zinit
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# ── Plugins ───────────────────────────────────────
# zsh-completions: additional completion definitions for hundreds of tools.
# `blockf` prevents zinit from modifying fpath (we handle compinit ourselves).
# See: https://github.com/zsh-users/zsh-completions
zinit ice blockf
zinit light zsh-users/zsh-completions

# Homebrew completions — must be in fpath before compinit runs.
# Homebrew installs completion functions to $HOMEBREW_PREFIX/share/zsh/site-functions.
[[ -d "${HOMEBREW_PREFIX:-}/share/zsh/site-functions" ]] && \
  fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)

# Initialize the zsh completion system (compinit).
# Rebuilds the completion dump daily; on other startups, loads from cache.
# The -C flag skips the security check (faster, safe for single-user machines).
# The dump file is compiled to .zwc bytecode in the background (&!).
# See: man zshcompsys "INITIALIZATION"
autoload -Uz compinit
local _zcd="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
[[ -d "${_zcd:h}" ]] || mkdir -p "${_zcd:h}"
# (Nm-24) glob qualifier: files modified within the last 24 hours
local -a _fresh=( "$_zcd"(Nm-24) )
if (( $#_fresh )); then
  compinit -C -d "$_zcd"
else
  compinit -d "$_zcd"
  { zcompile "$_zcd" } &!
fi
# cdreplay: replay any completion registrations that zinit deferred
zinit cdreplay -q

# eza has no built-in zsh completions; tell zsh to use file completion
(( $+commands[eza] )) && compdef _files eza

# fzf-tab: replaces zsh's default completion menu with an fzf-powered picker.
# Supports previews, multi-select, and fuzzy matching in the completion UI.
# Must load after compinit. `wait lucid` defers loading until first prompt
# to save ~5ms on startup.
# See: https://github.com/Aloxaf/fzf-tab
zinit wait lucid for Aloxaf/fzf-tab

# Deferred plugins (not needed at first prompt, loaded in background):
#   fast-syntax-highlighting: highlights commands as you type (red=invalid, green=valid)
#   zsh-autosuggestions: ghost-text suggestions from history (accept with →)
#   OMZP::git: git aliases (gst, gco, gp, etc.) from Oh My Zsh
#   OMZP::sudo: press Esc twice to prepend sudo to the current/previous command
#   OMZP::command-not-found: suggests package to install when a command isn't found
# See: https://github.com/zdharma-continuum/fast-syntax-highlighting
# See: https://github.com/zsh-users/zsh-autosuggestions
zinit wait lucid for \
  zdharma-continuum/fast-syntax-highlighting \
  zsh-users/zsh-autosuggestions \
  OMZP::git \
  OMZP::sudo \
  OMZP::command-not-found
