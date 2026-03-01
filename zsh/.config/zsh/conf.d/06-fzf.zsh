# ── FZF ──────────────────────────────────────────────
if ! command -v fzf &>/dev/null; then
  return
fi

# Use fd for everything when available
if command -v fd &>/dev/null; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

  # Use fd for ** path completion (e.g. vim **<tab>)
  _fzf_compgen_path() { fd --hidden --follow --exclude .git . "$1"; }
  _fzf_compgen_dir() { fd --type d --hidden --follow --exclude .git . "$1"; }
fi

# Colors use ANSI references (0-15) so they follow the terminal theme automatically.
# No hardcoded hex — change ghostty theme and FZF adapts.
export FZF_DEFAULT_OPTS=" \
  --height 60% --layout=reverse --border --info=inline-right \
  --color=fg:-1,bg:-1,hl:6,fg+:-1,bg+:8,hl+:6:bold \
  --color=info:5,prompt:4,pointer:4,marker:2,spinner:5,header:3,border:8,gutter:-1 \
  --bind 'ctrl-/:toggle-preview' \
  --bind 'ctrl-y:execute-silent(echo -n {+} | pbcopy 2>/dev/null || echo -n {+} | xclip -sel clip 2>/dev/null)' \
  --bind 'ctrl-d:half-page-down,ctrl-u:half-page-up'"

# Ctrl-T: file search with bat preview
export FZF_CTRL_T_OPTS=" \
  --preview 'bat --color=always --style=numbers --line-range :300 {} 2>/dev/null || cat {}' \
  --preview-window 'right:50%:border-left' \
  --header 'CTRL-/ toggle preview │ CTRL-Y copy'"

# Ctrl-R: history search with command preview
export FZF_CTRL_R_OPTS=" \
  --preview 'echo {}' --preview-window 'up:3:wrap:hidden' \
  --bind 'ctrl-/:toggle-preview' \
  --header 'CTRL-/ toggle preview'"

# Alt-C: directory search with tree preview
export FZF_ALT_C_OPTS=" \
  --preview 'eza -T --color=always --icons --level=2 {} 2>/dev/null || ls -la {}' \
  --preview-window 'right:50%:border-left'"

# Source fzf shell integration (keybindings + completion)
# Modern fzf (0.48+) has a single init command
if [[ "$(fzf --version 2>/dev/null | cut -d. -f1-2)" > "0.47" ]]; then
  source <(fzf --zsh 2>/dev/null)
else
  # Fallback for older fzf
  [[ -f /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
  [[ -f /usr/share/fzf/completion.zsh ]] && source /usr/share/fzf/completion.zsh
  [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]] && source /usr/share/doc/fzf/examples/key-bindings.zsh
  [[ -f /usr/share/doc/fzf/examples/completion.zsh ]] && source /usr/share/doc/fzf/examples/completion.zsh
  [[ -f "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/fzf/shell/key-bindings.zsh" ]] && source "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/fzf/shell/key-bindings.zsh"
  [[ -f "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/fzf/shell/completion.zsh" ]] && source "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/fzf/shell/completion.zsh"
fi

# ── FZF-powered functions ────────────────────────────

# Interactive git branch switch
fbr() {
  local branch
  branch=$(git for-each-ref --sort=-committerdate refs/heads/ \
    --format='%(refname:short) %(committerdate:relative) %(subject)' |
    fzf --height 40% --reverse --nth=1 \
      --preview 'git log --oneline --graph --color=always {1} -- | head -20' |
    awk '{print $1}')
  [ -n "$branch" ] && git switch "$branch"
}

# Interactive git log browser
flog() {
  git log --oneline --graph --color=always --decorate |
    fzf --ansi --no-sort --reverse --height 80% \
      --preview 'echo {} | grep -o "[a-f0-9]\{7,\}" | head -1 | xargs git show --color=always' \
      --bind 'enter:execute(echo {} | grep -o "[a-f0-9]\{7,\}" | head -1 | xargs git show --color=always | less -R)'
}

# Interactive process kill
fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf --height 40% --reverse -m | awk '{print $2}')
  [ -n "$pid" ] && echo "$pid" | xargs kill -"${1:-9}"
}

# Interactive file open in editor
fe() {
  local file
  file=$(fzf --height 40% --reverse \
    --preview 'bat --color=always --style=numbers --line-range :200 {} 2>/dev/null || cat {}')
  [ -n "$file" ] && ${EDITOR:-nvim} "$file"
}

# Interactive ripgrep → fzf → editor (live grep)
frg() {
  local file line
  rg --color=always --line-number --no-heading "${@:-.}" |
    fzf --ansi --delimiter ':' \
      --preview 'bat --color=always --highlight-line {2} --line-range {2}: {1} 2>/dev/null' \
      --preview-window 'right:50%:+{2}-5' |
    IFS=':' read -r file line _
  [ -n "$file" ] && ${EDITOR:-nvim} "$file" +"$line"
}
