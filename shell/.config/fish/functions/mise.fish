function mise --wraps mise --description 'mise with auto-reshim'
    command mise $argv
    switch $argv[1]
        case install use uninstall upgrade
            command mise reshim
    end
end
