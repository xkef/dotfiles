function ps --description "procs with ps fallback"
    if command -q procs
        command procs $argv
    else
        command ps $argv
    end
end
