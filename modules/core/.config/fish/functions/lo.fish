function lo --description 'Project overview in a pager: repo, tree, and code statistics'
    set -l dir (test -n "$argv[1]"; and echo $argv[1]; or echo .)

    # The pager is not a terminal, so color, icons, and hyperlinks are
    # forced on. Two tree levels show the layout without flooding the page,
    # and .gitignore filtering keeps build output out.
    begin
        if command -q onefetch; and git -C $dir rev-parse 2>/dev/null >/dev/null
            # ANSI colors keep onefetch on the terminal palette. Its default
            # title takes the language color, such as Lua's navy. onefetch
            # has no default foreground, so values in color 7 become one,
            # since 7 is too pale on light themes. less -R prints
            # onefetch's line-wrap toggles as raw text.
            onefetch --include-hidden --no-color-palette --true-color never \
                --text-colors 4 8 8 4 8 7 $dir |
                string replace -ar '\e\[\?7[hl]' '' |
                string replace -a \e'[37m' \e'[39m'
        end

        eza -T -L2 -la --color=always --icons=always --hyperlink=always \
            --git --git-ignore --ignore-glob='.git|.jj' \
            --group-directories-first --no-permissions --no-user \
            --time-style=relative $dir

        if command -q tokei
            echo
            tokei -C -s code --hidden $dir
        end
    end | less
end
