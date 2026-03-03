# ── Tool initialization ──────────────────────────────

# Homebrew
if [[ -f /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# zoxide (smart cd)
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh --cmd cd)"
fi

# Command duration tracking (exported for Starship env_var module)
_cmd_timer_preexec() { _cmd_timer_start=$EPOCHREALTIME }
_cmd_timer_precmd() {
  if [[ -n $_cmd_timer_start ]]; then
    local ms=$(( int(($EPOCHREALTIME - _cmd_timer_start) * 1000) ))
    if (( ms < 1000 )); then
      export PROMPT_DURATION="${ms}ms"
    else
      export PROMPT_DURATION="$(printf '%.1fs' $(( ms / 1000.0 )))"
    fi
    _cmd_timer_start=
  else
    unset PROMPT_DURATION
  fi
}
autoload -Uz add-zsh-hook
add-zsh-hook preexec _cmd_timer_preexec
add-zsh-hook precmd _cmd_timer_precmd

# Starship prompt
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

# direnv (if installed)
if command -v direnv &>/dev/null; then
  eval "$(direnv hook zsh)"
fi

# atuin (smart shell history — Ctrl+R only, up arrow uses normal history)
if command -v atuin &>/dev/null; then
  eval "$(atuin init zsh --disable-up-arrow)"
fi
