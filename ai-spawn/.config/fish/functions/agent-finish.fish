function agent-finish -d "Finish an isolated jj workspace agent" --wraps 'ai-agent finish'
    exec ai-agent finish $argv
end
