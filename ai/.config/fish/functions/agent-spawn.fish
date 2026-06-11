function agent-spawn -d "Spawn an isolated jj workspace agent" --wraps 'ai-agent spawn'
    exec ai-agent spawn $argv
end
