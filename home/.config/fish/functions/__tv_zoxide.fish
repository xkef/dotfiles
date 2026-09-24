function __tv_zoxide --description 'Jump to a visited directory (tv + zoxide)'
    set -l dir (tv --source-command 'zoxide query --list' \
        --preview-command "eza -T --color=always --icons --level=2 '{}'")
    if test -n "$dir"
        zoxide add $dir
        cd -- $dir
    end
    commandline -f repaint
end
