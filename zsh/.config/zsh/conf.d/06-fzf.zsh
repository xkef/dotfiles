# ── FZF ──────────────────────────────────────────────
if ! command -v fzf &>/dev/null; then
  return
fi

# Use fd for file/dir search, sorted by recency (recent first, then rest, deduped)
if command -v fd &>/dev/null; then
  local dedup='awk "!seen[\$0]++"'

  # Ctrl-T: recently modified files first, then all files
  export FZF_CTRL_T_COMMAND="\
    { fd --type f --changed-within 1week --hidden --follow --exclude .git; \
      fd --type f --hidden --follow --exclude .git; \
    } | $dedup"

  # Alt-C: zoxide frecency dirs first, then all dirs from fd (deduped)
  if command -v zoxide &>/dev/null; then
    export FZF_ALT_C_COMMAND="\
      { zoxide query -l 2>/dev/null; \
        fd --type d --hidden --follow --exclude .git; \
      } | $dedup"
  else
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  fi

  # ** tab completion
  _fzf_compgen_path() { fd --hidden --follow --exclude .git . "$1"; }
  _fzf_compgen_dir() { fd --type d --hidden --follow --exclude .git . "$1"; }
fi

# Colors use ANSI references (0-15) so they follow the terminal theme automatically.
# No hardcoded hex — change ghostty theme and FZF adapts.
export FZF_DEFAULT_OPTS=" \
  --height 60% --layout=reverse --border --info=inline-right \
  --tiebreak=chunk,length \
  --color=fg:-1,bg:-1,hl:6,fg+:-1,bg+:8,hl+:6:bold \
  --color=info:5,prompt:4,pointer:4,marker:2,spinner:5,header:3,border:8,gutter:-1 \
  --bind 'ctrl-/:toggle-preview' \
  --bind 'ctrl-y:execute-silent(echo -n {+} | pbcopy 2>/dev/null || echo -n {+} | wl-copy 2>/dev/null || echo -n {+} | xclip -sel clip 2>/dev/null)' \
  --bind 'ctrl-d:half-page-down,ctrl-u:half-page-up'"

# Ctrl-T: file search with bat preview, path-aware scoring
export FZF_CTRL_T_OPTS=" \
  --scheme=path \
  --preview 'bat --color=always --style=numbers --line-range :300 {} 2>/dev/null || cat {}' \
  --preview-window 'right:50%:border-left' \
  --header 'CTRL-/ toggle preview │ CTRL-Y copy'"

# Alt-C: directory search with tree preview, path-aware scoring
export FZF_ALT_C_OPTS=" \
  --scheme=path \
  --preview 'eza -T --color=always --icons --level=2 {} 2>/dev/null || ls -la {}' \
  --preview-window 'right:50%:border-left'"

# Source fzf shell integration (cached — regenerates when fzf binary changes)
(){
  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/eval-cache"
  local bin=${commands[fzf]:-}
  local f="$cache/fzf.zsh"
  if [[ -n "$bin" ]]; then
    if [[ ! -f "$f" || "$bin" -nt "$f" ]]; then
      mkdir -p "$cache"
      fzf --zsh > "$f" 2>/dev/null
    fi
    source "$f"
  fi
}

# Directory picker: Ctrl-X d (alt-c broken on Swiss German Mac, Ctrl-G is navi)
bindkey '^Xd' fzf-cd-widget

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
  [ -n "$pid" ] && echo "$pid" | xargs kill -"${1:-15}"
}

# Interactive file open in editor
fe() {
  local file
  file=$(fzf --height 40% --reverse --scheme=path \
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
