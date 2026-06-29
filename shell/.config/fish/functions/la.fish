function la --description "list all entries"
    if command -q eza
        command eza --group-directories-first -a $argv
    else if test (uname) = Darwin
        command ls -Ga $argv
    else
        command ls -a $argv
    end
end
