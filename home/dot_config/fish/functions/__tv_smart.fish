function __tv_smart --description 'Television channel picker'
    set -l result (tv 2>/dev/tty)
    if test -n "$result"
        commandline -i $result
    end
    commandline -f repaint
end
