function catn --description "bat (paging/decorations) with cat fallback"
    if command -q bat
        command bat $argv
    else
        command cat $argv
    end
end
