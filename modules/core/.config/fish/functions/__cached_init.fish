# Sources a tool's init script, such as `starship init fish`, from a cache
# file instead of spawning the tool on every shell start. The cache
# regenerates when the binary is newer than the cache file, which covers
# an upgrade. The file name holds the arguments, so an edited call misses.
#
#   __cached_init zoxide init fish --cmd z
function __cached_init
    set -l bin (command -s $argv[1]); or return
    set -l cache $XDG_CACHE_HOME/fish/init/(string join -- ' ' $argv |string escape --style=var).fish

    if not test -s $cache; or test $bin -nt $cache
        mkdir -p (path dirname $cache)
        # Shells that start together after an upgrade each write their
        # own file, so none moves another's partial output into place.
        set -l tmp $cache.$fish_pid.tmp
        if not $bin $argv[2..] >$tmp; or not test -s $tmp
            command rm -f $tmp
            return 1
        end
        command mv -f $tmp $cache
    end

    source $cache
end
