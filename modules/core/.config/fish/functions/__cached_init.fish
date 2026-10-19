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
        if not $bin $argv[2..] >$cache.tmp; or not test -s $cache.tmp
            command rm -f $cache.tmp
            return 1
        end
        command mv -f $cache.tmp $cache
    end

    source $cache
end
