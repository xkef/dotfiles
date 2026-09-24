function mise --wraps mise --description 'mise with auto-reshim'
    command mise $argv
    set -l rc $status
    test $rc -eq 0; or return $rc
    switch $argv[1]
        case install use uninstall upgrade
            command mise reshim
    end
    return $rc
end
