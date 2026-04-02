function __fg_bg_toggle --description 'Toggle fg/bg or undo'
    if jobs -q
        fg
        commandline -f repaint
    else
        commandline -f undo
    end
end
