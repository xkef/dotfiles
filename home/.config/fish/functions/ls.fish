function ls --description "eza ls with system fallback"
    if command -q eza
        eza $argv
    else if test (uname) = Darwin
        command ls -G $argv
    else
        command ls --color=auto $argv
    end
end
