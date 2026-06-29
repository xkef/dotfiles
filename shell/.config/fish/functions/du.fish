function du --description "dust with du -h fallback"
    if command -q dust
        command dust $argv
    else
        command du -h $argv
    end
end
