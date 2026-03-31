# ── Cached init ──────────────────────────────────────
# Many CLI tools require `eval "$(tool init zsh)"` which forks a process
# on every shell startup (~5-15ms each). _cached_source caches the output
# to a file keyed by the binary's real path and mtime. On warm startup,
# it sources the cached file (~0.1ms) instead of forking.
#
# Cache invalidation: regenerates when the binary changes (new version or
# different path after `brew upgrade`). The first line of each cache file
# stores "# /real/path/to/binary" for verification.
#
# Security: equivalent to `eval "$(cmd init zsh)"` — the same code runs,
# just read from a user-owned cache file (mode 700 directory) instead of
# a pipe. zcompile creates .zwc bytecode for even faster loading.
_cached_source() {
  local cmd=$1; shift
  # $commands is a zsh associative array mapping command names to paths.
  local bin=${commands[$cmd]:-}
  [[ -n "$bin" ]] || return
  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/eval-cache"
  local f="$cache/$cmd.zsh"
  # ${bin:A} resolves symlinks to the real path (like readlink -f).
  local realbin="${bin:A}"
  local stale=false
  if [[ ! -f "$f" || "$realbin" -nt "$f" ]]; then
    stale=true
  elif { read -r _line < "$f" } 2>/dev/null && [[ "$_line" != "# $realbin" ]]; then
    stale=true
  fi
  if $stale; then
    mkdir -p -m 700 "$cache"
    rm -f "$f" "$f.zwc"
    { echo "# $realbin"; "$cmd" "$@"; } > "$f"
    # Sanity check: if the command produced no output, don't cache it
    if (( $(wc -l < "$f") <= 1 )); then
      rm -f "$f"
      return 1
    fi
    zcompile "$f"
  fi
  source "$f"
}

# ── External tool initialization ─────────────────────

# mise: polyglot dev tool version manager (replaces asdf/nvm/pyenv/etc.).
# --shims mode adds ~/.local/share/mise/shims to PATH instead of hooking
# into every prompt (faster, no per-prompt overhead).
# See: https://mise.jdx.dev/
_cached_source mise activate zsh --shims

# Wrapper: after install/uninstall operations, regenerate shims so new
# binaries are immediately available without restarting the shell.
mise() {
  command mise "$@"
  case "$1" in
    install|use|uninstall|upgrade) command mise reshim ;;
  esac
}

# Register mise's tab completion
compdef _mise mise

# starship: cross-shell prompt with git status, language versions, etc.
# See: https://starship.rs/
_cached_source starship init zsh

# ── Deferred tool init ──────────────────────────────
# Tools not needed at the very first prompt are loaded on the first precmd
# (the hook that runs just before each prompt). This saves ~9ms on startup.
# precmd_functions is a zsh special array of functions called before each prompt.
# See: man zshmisc "SPECIAL FUNCTIONS"
_deferred_tool_init() {
  # unfunction removes this function so it only runs once
  unfunction _deferred_tool_init

  # fzf shell integration: sets up Ctrl-T (file search), Ctrl-R (history),
  # and Alt-C (cd) keybindings. These use the FZF_*_OPTS vars from 06-fzf.zsh.
  # Ctrl-R is later overridden by atuin (below).
  # See: https://github.com/junegunn/fzf#setting-up-shell-integration
  _cached_source fzf --zsh

  # zoxide: smarter cd that learns your most-used directories (frecency).
  # --cmd z: use `z` as the command name instead of `__zoxide_z`.
  # See: https://github.com/ajeetdsouza/zoxide
  _cached_source zoxide init zsh --cmd z

  # direnv: per-directory environment variables (auto-loads .envrc files).
  # See: https://direnv.net/
  _cached_source direnv hook zsh

  # atuin: searchable shell history with optional sync across machines.
  # --disable-up-arrow: don't override Up (we use up-line-or-beginning-search).
  # Overrides fzf's Ctrl-R with atuin's TUI history search.
  # See: https://atuin.sh/
  _cached_source atuin init zsh --disable-up-arrow

  # navi: interactive cheatsheet browser (Ctrl-G).
  # See: https://github.com/denisidoro/navi
  _cached_source navi widget zsh

  # 1Password CLI: tab completion for `op` commands.
  _cached_source op completion zsh
}
precmd_functions+=(_deferred_tool_init)

# ── Jujutsu: commit message length check ─────────────
# GitHub truncates subject lines beyond 72 characters. Warn after any
# command that sets a description so the author can fix it immediately.
jj() {
  command jj "$@"
  local rc=$?
  case "$1" in
    commit|describe)
      if (( rc == 0 )); then
        local rev subject
        [[ "$1" == commit ]] && rev='@-' || rev='@'
        subject=$(command jj log -r "$rev" --no-graph -T 'description.first_line()' 2>/dev/null)
        if (( ${#subject} > 72 )); then
          printf '\e[33mwarning:\e[0m subject is %d chars (GitHub truncates at 72)\n' ${#subject}
        fi
      fi
      ;;
  esac
  return $rc
}

# ── Yazi: cd-on-quit wrapper ─────────────────────────
# Yazi is a terminal file manager. This wrapper captures the directory yazi
# was in when you quit (via --cwd-file) and cds to it, enabling the
# "navigate in yazi, land in that directory" workflow.
# The `y` function is used by the Ctrl-S keybinding in 04-keys.zsh.
# See: https://yazi-rs.github.io/docs/quick-start#shell-wrapper
if (( $+commands[yazi] )); then
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
