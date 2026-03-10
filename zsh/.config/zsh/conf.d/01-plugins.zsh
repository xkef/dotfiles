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

# Initialize completion system
autoload -Uz compinit && compinit -C
zinit cdreplay -q

# Register missing completions (eza has no built-in zsh completions)
command -v eza &>/dev/null && compdef _files eza

# fzf-tab (must load after compinit)
zinit light Aloxaf/fzf-tab

# Syntax highlighting and autosuggestions (deferred for faster startup)
zinit wait lucid for \
  zdharma-continuum/fast-syntax-highlighting \
  zsh-users/zsh-autosuggestions

# Essential OMZ snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::command-not-found
