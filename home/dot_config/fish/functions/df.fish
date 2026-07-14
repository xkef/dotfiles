function df --description "duf with df -h fallback"
    if command -q duf
        command duf $argv
    else
        command df -h $argv
    end
end
