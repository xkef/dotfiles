function _ai_ensure_skills -d "Install shared agent skills on first launch (idempotent)"
    set -l skills_agent $argv[1]
    set -l sentinel "$HOME/.cache/dotfiles/skills.shared.v4.installed"
    test -f $sentinel; and return 0
    command -q npx; or return 0

    set -l shared_skills_target codex

    printf '\033[33m(first launch: installing shared skills for %s...)\033[0m\n' $skills_agent >&2
    npx --yes skills@latest add mattpocock/skills \
        --global --agent $shared_skills_target --skill '*' -y
    or return $status
    npx --yes skills@latest add vercel-labs/skills \
        --global --agent $shared_skills_target --skill find-skills -y
    or return $status
    npx --yes skills@latest add 2ykwang/agent-skills \
        --global --agent $shared_skills_target --skill html-visual -y
    or return $status
    npx --yes skills@latest add Cocoon-AI/architecture-diagram-generator \
        --global --agent $shared_skills_target --skill architecture-diagram -y
    or return $status

    mkdir -p (dirname $sentinel)
    touch $sentinel
end
