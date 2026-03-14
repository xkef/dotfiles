# ── Zinit ──────────────────────────────────────────────
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# ── Plugins ───────────────────────────────────────
# Completions (blockf defers registration to compinit)
zinit ice blockf
zinit light zsh-users/zsh-completions

# Homebrew completions (must be in fpath before compinit)
[[ -d "${HOMEBREW_PREFIX:-}/share/zsh/site-functions" ]] && \
  fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)

# Initialize completion system (rebuild dump daily, cache otherwise)
autoload -Uz compinit
local _zcd="${ZDOTDIR:-$HOME}/.zcompdump"
local -a _fresh=( "$_zcd"(Nm-24) )
if (( $#_fresh )); then
  compinit -C -d "$_zcd"
else
  compinit -d "$_zcd"
  { zcompile "$_zcd" } &!
fi
zinit cdreplay -q

# Register missing completions (eza has no built-in zsh completions)
command -v eza &>/dev/null && compdef _files eza

# fzf-tab (must load after compinit)
zinit light Aloxaf/fzf-tab

# Syntax highlighting and autosuggestions (deferred for faster startup)
zinit wait lucid for \
  zdharma-continuum/fast-syntax-highlighting \
  zsh-users/zsh-autosuggestions

# Essential OMZ snippets (deferred — aliases and completions not needed at first prompt)
zinit wait lucid for \
  OMZP::git \
  OMZP::sudo \
  OMZP::command-not-found

# Notify when long-running commands finish (>30s)
zinit wait lucid for \
  atload'export AUTO_NOTIFY_THRESHOLD=30; export AUTO_NOTIFY_TITLE="Done: %command"; export AUTO_NOTIFY_IGNORE=(nvim vim less bat man tmux atuin navi yazi y)' \
  MichaelAquilina/zsh-auto-notify
