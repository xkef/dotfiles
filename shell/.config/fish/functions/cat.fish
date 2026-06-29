function cat --description "bat -pp with cat fallback"
    if command -q bat
        command bat -pp $argv
    else
        command cat $argv
    end
end
