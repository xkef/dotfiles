# ── Aliases ───────────────────────────────────────────
# Modern replacements
if (( $+commands[eza] )); then
  alias ls='eza --group-directories-first'
  alias ll='eza -la --group-directories-first --git'
  alias lt='eza -T --level=2'
  alias la='eza -a --group-directories-first'
elif [[ "$OSTYPE" == darwin* ]]; then
  alias ls='ls -G'
  alias ll='ls -Gla'
  alias la='ls -Ga'
else
  alias ls='ls --color=auto'
  alias ll='ls -la'
  alias la='ls -a'
fi

if (( $+commands[bat] )); then
  alias cat='bat -pp'
  alias catn='bat'
fi

# Quick edit
alias v='nvim'
alias vi='nvim'
alias vim='nvim'

# Tmux
alias t='tmux'
alias ta='tmux attach -t'
alias tn='tmux new -s'
alias tl='tmux list-sessions'

# Claude
alias claude='claude-sandboxed'

# Batch rename
alias mmv='noglob zmv -W'

# Misc
alias help='run-help'
alias reload='exec zsh'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias cls='clear'
alias mkdir='mkdir -pv'
alias grep='grep --color=auto'

if (( $+commands[dust] )); then alias du='dust'; else alias du='du -h'; fi
if (( $+commands[duf] )); then alias df='duf'; else alias df='df -h'; fi
if (( $+commands[procs] )); then alias ps='procs'; fi

# Universal extract/compress via ouch
if (( $+commands[ouch] )); then
  alias extract='ouch decompress'
  alias compress='ouch compress'
fi
