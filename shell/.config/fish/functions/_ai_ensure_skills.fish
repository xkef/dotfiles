function _ai_ensure_skills -d "Install agent skills on first launch (idempotent)"
    set -l skills_agent $argv[1]
    set -l sentinel "$HOME/.cache/dotfiles/skills.$skills_agent.installed"
    test -f $sentinel; and return 0
    command -q npx; or return 0

    printf '\033[33m(first launch: installing %s skills...)\033[0m\n' $skills_agent >&2
    npx --yes skills@latest add mattpocock/skills \
        --global --agent $skills_agent --skill '*' -y --copy
    or return $status
    npx --yes skills@latest add vercel-labs/skills \
        --global --agent $skills_agent --skill find-skills -y --copy
    or return $status

    mkdir -p (dirname $sentinel)
    touch $sentinel
end
