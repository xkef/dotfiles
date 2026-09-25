function __tv_cd --description 'Jump to a directory under cwd (tv)'
    set -l dir (tv dirs)
    test -n "$dir"; and cd -- $dir
    commandline -f repaint
end
