# Theme adapter (theme package): tell running Neovim instances to re-derive
# their colorscheme. Runs after 10-ghostty.fish, which writes the state file
# require('theme').apply() reads.
for nvim_sock_dir in $XDG_RUNTIME_DIR $TMPDIR /tmp
    test -n "$nvim_sock_dir" -a -d "$nvim_sock_dir" || continue
    for nvim_sock in $nvim_sock_dir/nvim.*.0
        test -S $nvim_sock || continue
        nvim --server $nvim_sock --remote-send \
            "<Cmd>lua pcall(function() require('theme').apply() end)<CR>" 2>/dev/null || true
    end
end
