# ── FZF ──────────────────────────────────────────────
# Fish equivalents of the zsh fzf widgets in 06-fzf.zsh.
# @key tags omitted — these mirror the zsh bindings shown in `keys`.
command -q fzf || return

if command -q fd
    set -gx FZF_CTRL_T_COMMAND "\
        { fd --type f --changed-within 1week --hidden --follow --exclude .git; \
          fd --type f --hidden --follow --exclude .git; \
        } | awk '!seen[\$0]++'"
    set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --follow --exclude .git .'
end

set -gx FZF_DEFAULT_OPTS "\
    --height 60% --layout=reverse --border --info=inline-right \
    --tiebreak=chunk,length \
    --color=fg:-1,bg:-1,hl:6,fg+:-1,bg+:8,hl+:6:bold \
    --color=info:5,prompt:4,pointer:4,marker:2,spinner:5,header:3,border:8,gutter:-1 \
    --bind 'ctrl-/:toggle-preview' \
    --bind 'ctrl-y:execute-silent(echo -n {+} | pbcopy 2>/dev/null || echo -n {+} | wl-copy 2>/dev/null || echo -n {+} | xclip -sel clip 2>/dev/null)' \
    --bind 'ctrl-d:preview-half-page-down,ctrl-u:preview-half-page-up' \
    --bind 'ctrl-f:preview-page-down,ctrl-b:preview-page-up'"

set -gx FZF_CTRL_T_OPTS "\
    --scheme=path \
    --preview 'bat --color=always --style=numbers --line-range :300 {} 2>/dev/null || cat {}' \
    --preview-window 'right:50%:border-left' \
    --header 'CTRL-/ toggle preview │ CTRL-Y copy'"

set -gx FZF_ALT_C_OPTS "\
    --scheme=path \
    --preview 'eza -T --color=always --icons --level=2 {} 2>/dev/null || ls -la {}' \
    --preview-window 'right:50%:border-left'"

# fzf shell integration (Ctrl-T, Ctrl-R, Alt-C)
fzf --fish | source

# atuin replaces fzf's Ctrl-R history widget
if command -q atuin
    set -gx ATUIN_TMUX_POPUP false
    atuin init fish --disable-up-arrow | source
end

# Custom widgets
bind \ez __fzf_zoxide # Alt-Z: zoxide jump
bind \e/ __fzf_grep # Alt-/: live grep

if command -q tv
    bind \et __tv_smart # Alt-T: television
end
