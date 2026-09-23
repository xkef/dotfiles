function lt --description "eza tree (2 levels) with ls fallback"
    if command -q eza
        eza -T --level=2 $argv
    else
        command ls $argv
    end
end
