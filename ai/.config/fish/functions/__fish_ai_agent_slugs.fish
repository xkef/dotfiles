function __fish_ai_agent_slugs -d "Print ai-agent workspace slugs for completion"
    ai-agent list --format=ui 2>/dev/null | awk -F '\t' 'NF >= 2 { print $2 }'
end
