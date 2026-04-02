function __fzf_zoxide --description 'Jump to visited directory (fzf + zoxide)'
    set -l dir (zoxide query --list --score 2>/dev/null |
        awk '{print $1, $2}' |
        fzf --scheme=default --no-sort --nth=2 \
            --preview 'eza -T --color=always --icons --level=2 {2} 2>/dev/null || ls -la {2}' \
            --preview-window 'right:50%:border-left' \
            --header 'Visited directories (zoxide)' |
        awk '{print $2}')
    if test -n "$dir"
        zoxide add "$dir"
        cd -- $dir
    end
    commandline -f repaint
end
