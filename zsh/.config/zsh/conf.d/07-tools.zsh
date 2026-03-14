# ── Shell utilities ───────────────────────────────────

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
# Cache output of `tool init zsh` commands. Regenerates when the
# binary changes (mtime or path). Eliminates fork+exec on warm startup.
# Security: equivalent to `eval "$(cmd init zsh)"` — same code runs,
# just read from a user-owned cache file instead of a pipe. Directory
# is mode 700 to prevent other users from reading or writing.
_cached_source() {
  local cmd=$1; shift
  local bin=${commands[$cmd]:-}
  [[ -n "$bin" ]] || return
  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/eval-cache"
  local f="$cache/$cmd.zsh"
  local realbin="${bin:A}"
  local stale=false
  if [[ ! -f "$f" || "$realbin" -nt "$f" ]]; then
    stale=true
  elif { read -r _line < "$f" } 2>/dev/null && [[ "$_line" != "# $realbin" ]]; then
    stale=true
  fi
  if $stale; then
    mkdir -p -m 700 "$cache"
    { echo "# $realbin"; "$cmd" "$@"; } > "$f"
    zcompile "$f"
  fi
  source "$f"
}

# ── External tool initialization ─────────────────────
_cached_source mise activate zsh --shims

mise() {
  command mise "$@"
  case "$1" in
    install|use|uninstall|upgrade) command mise reshim ;;
  esac
}

compdef _mise mise
_cached_source zoxide init zsh --cmd z
_cached_source starship init zsh
_cached_source direnv hook zsh
_cached_source atuin init zsh --disable-up-arrow
_cached_source navi widget zsh

# ── Yazi: cd-on-quit wrapper ─────────────────────────
if command -v yazi &>/dev/null; then
  y() {
    local tmp
    tmp=$(mktemp -t "yazi-cwd.XXXXXX")
    yazi "$@" --cwd-file="$tmp"
    if cwd=$(command cat -- "$tmp") && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
      builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
  }
fi
