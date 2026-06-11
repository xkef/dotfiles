function agent-cleanup -d "Clean up isolated jj workspace agents" --wraps 'ai-agent cleanup'
    exec ai-agent cleanup $argv
end
