function agent-list -d "List isolated jj workspace agents" --wraps 'ai-agent list'
    exec ai-agent list $argv
end
