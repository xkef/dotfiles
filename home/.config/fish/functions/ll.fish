function ll --description "long list with git status"
    if command -q eza
        ls -la --git $argv
    else
        ls -la $argv
    end
end
