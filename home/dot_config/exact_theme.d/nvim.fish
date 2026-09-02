# Theme adapter (nvim): tell running Neovim instances to re-derive their
# colorscheme from the state file `theme` wrote before sourcing adapters.
# Sockets live at <base>/nvim.<user>/<random>/<appname>.<pid>.0 (the flat
# nvim.<pid>.0 form covers older layouts).
for nvim_sock_dir in $XDG_RUNTIME_DIR $TMPDIR /tmp
    test -n "$nvim_sock_dir" -a -d "$nvim_sock_dir" || continue
    for nvim_sock in $nvim_sock_dir/nvim.*.0 $nvim_sock_dir/nvim.*/*/*.0
        test -S $nvim_sock || continue
        nvim --server $nvim_sock --remote-send \
            "<Cmd>lua pcall(function() require('theme').apply() end)<CR>" 2>/dev/null || true
    end
end
