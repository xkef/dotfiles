function ll --description "long list with git status"
    if command -q eza
        command eza --group-directories-first -la --git $argv
    else if test (uname) = Darwin
        command ls -Gla $argv
    else
        command ls -la $argv
    end
end
