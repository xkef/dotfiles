# ── FZF ──────────────────────────────────────────────
command -q fzf || return

if command -q fd
    set -gx FZF_CTRL_T_COMMAND "\
        { fd --type f --changed-within 1week --hidden --follow --exclude .git; \
          fd --type f --hidden --follow --exclude .git; \
        } | awk '!seen[\$0]++'"
    set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --follow --exclude .git .'
end

# Default options apply to every fzf invocation. The per-mode options below
# add only --preview commands and headers. Layout and look live here, so one
# change restyles everything, and fzf adapts to narrow tmux popups.
set -gx FZF_DEFAULT_OPTS "\
    --height=60% --layout=reverse --info=inline-right \
    --tiebreak=chunk,length \
    --border=rounded --gap=0 --no-separator --scroll-off=3 \
    --prompt='❯ ' --pointer='▎' --marker='┃' \
    --scrollbar='│' --ellipsis='…' \
    --preview-window='right,55%,border-rounded,wrap,<80(down,55%,border-top,wrap)' \
    --color=fg:-1,bg:-1,hl:6,fg+:-1,bg+:8,hl+:6:bold \
    --color=info:5,prompt:4,pointer:4,marker:2,spinner:5,header:3,border:8,gutter:-1 \
    --bind 'ctrl-/:toggle-preview' \
    --bind 'ctrl-y:execute-silent(echo -n {+} | pbcopy 2>/dev/null || echo -n {+} | wl-copy 2>/dev/null || echo -n {+} | xclip -sel clip 2>/dev/null)' \
    --bind 'ctrl-d:preview-half-page-down,ctrl-u:preview-half-page-up' \
    --bind 'ctrl-f:preview-page-down,ctrl-b:preview-page-up'"

# Centered popup inside tmux.
set -gx FZF_TMUX_OPTS '-p 80%,70%'

set -gx FZF_CTRL_T_OPTS "\
    --scheme=path \
    --preview 'fzf-preview {}' \
    --header 'CTRL-/ toggle preview │ CTRL-Y copy'"

set -gx FZF_ALT_C_OPTS "\
    --scheme=path \
    --preview 'eza -T --color=always --icons --level=2 {} 2>/dev/null || ls -la {}'"

# Tab completion hides fish's tab-separated description from the list. The
# preview still receives the full token, and fzf-preview strips it.
set -gx FZF_COMPLETION_OPTS "\
    --no-multi \
    --bind 'tab:down,btab:up' \
    --with-nth=1 --delimiter='\t' \
    --preview 'fzf-preview {1}'"

# Scripts and tmux popups inherit the exported FZF_* variables above. The
# key bindings and widgets below serve a prompt, so scripts skip them.
status is-interactive; or return

# Ctrl-T, Ctrl-R, and Alt-C
fzf --fish | source

# atuin takes over Ctrl-R
if command -q atuin
    set -gx ATUIN_TMUX_POPUP false
    atuin init fish --disable-up-arrow | source
end

bind \t fzf_complete

bind \ez __fzf_zoxide
bind \e/ __fzf_grep
