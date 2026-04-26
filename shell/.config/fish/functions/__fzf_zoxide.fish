function __fzf_zoxide --description 'Jump to visited directory (fzf + zoxide)'
    set -l dir (zoxide query --list 2>/dev/null |
        fzf --scheme=path --no-sort \
            --preview 'eza -T --color=always --icons --level=2 {} 2>/dev/null || ls -la {}' \
            --header 'Visited directories (zoxide)')
    if test -n "$dir"
        zoxide add "$dir"
        cd -- $dir
    end
    commandline -f repaint
end
