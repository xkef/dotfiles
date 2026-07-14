function __fish_toggle_sudo --description 'Toggle sudo prefix on command line'
    set -l buf (commandline -b)
    if string match -qr '^sudo ' $buf
        commandline -r (string replace -r '^sudo ' '' $buf)
    else
        commandline -r "sudo $buf"
    end
    commandline -f end-of-line
end
