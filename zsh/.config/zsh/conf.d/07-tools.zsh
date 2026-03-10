# ── Tool initialization ──────────────────────────────

autoload -Uz zmv

auto-ls() {
  if (( $+commands[eza] )); then
    eza --group-directories-first
  elif [[ "$OSTYPE" == darwin* ]]; then
    command ls -G
  else
    command ls --color=auto
  fi
}
chpwd_functions+=( auto-ls )

# ── Cached init ──────────────────────────────────────
# Cache output of `tool init zsh` commands. Regenerates when
# the binary's mtime changes. Eliminates fork+exec on warm startup.
# Security: equivalent to `eval "$(cmd init zsh)"` — same code runs,
# just read from a user-owned cache file instead of a pipe. Directory
# is mode 700 to prevent other users from reading or writing.
_cached_source() {
  local cmd=$1; shift
  local bin=${commands[$cmd]:-}
  [[ -n "$bin" ]] || return
  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/eval-cache"
  local f="$cache/$cmd.zsh"
  if [[ ! -f "$f" || "$bin" -nt "$f" ]]; then
    mkdir -p -m 700 "$cache"
    "$cmd" "$@" > "$f"
  fi
  source "$f"
}

# zoxide (smart cd)
_cached_source zoxide init zsh --cmd z

# Starship prompt
_cached_source starship init zsh

# direnv
_cached_source direnv hook zsh

# atuin (smart shell history — Ctrl+R only, up arrow uses normal history)
_cached_source atuin init zsh --disable-up-arrow

# navi (interactive cheatsheet — Ctrl+G)
_cached_source navi widget zsh

# ── nvm (lazy-loaded) ────────────────────────────────
# nvm.sh is ~5000 lines of bash; sourcing it costs ~80-200ms.
# Stub functions defer the cost to first use of nvm/node/npm/npx.
export NVM_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  _nvm_load() {
    unfunction nvm node npm npx 2>/dev/null
    source "$NVM_DIR/nvm.sh"
    source "$NVM_DIR/bash_completion" 2>/dev/null
  }
  nvm()  { _nvm_load; nvm "$@" }
  node() { _nvm_load; node "$@" }
  npm()  { _nvm_load; npm "$@" }
  npx()  { _nvm_load; npx "$@" }
fi
