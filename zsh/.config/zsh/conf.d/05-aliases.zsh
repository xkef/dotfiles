# ── Aliases ───────────────────────────────────────────
# Modern replacements
if command -v eza &>/dev/null; then
  alias ls='eza --group-directories-first'
  alias ll='eza -la --group-directories-first --git'
  alias lt='eza -T --level=2'
  alias la='eza -a --group-directories-first'
else
  alias ls='ls --color=auto'
  alias ll='ls -la'
  alias la='ls -a'
fi

if command -v bat &>/dev/null; then
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

# Misc
alias reload='exec zsh'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias cls='clear'
alias df='df -h'
alias du='du -h'
alias mkdir='mkdir -pv'
alias grep='grep --color=auto'
