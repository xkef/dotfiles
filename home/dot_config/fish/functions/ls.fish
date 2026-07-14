function ls --description "eza ls with system fallback"
    if command -q eza
        command eza --group-directories-first $argv
    else if test (uname) = Darwin
        command ls -G $argv
    else
        command ls --color=auto $argv
    end
end
