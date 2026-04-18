# AI tooling

Configs for multiple AI coding agents, stowed to `$HOME`.

## Layout

| Path                               | Tool            | Purpose                      |
| ---------------------------------- | --------------- | ---------------------------- |
| `.claude/`                         | Claude Code     | agents, skills, settings     |
| `.codex/`                          | OpenAI Codex    | agent rules, `config.toml`   |
| `.config/opencode/`                | OpenCode        | agent rules, `opencode.json` |
| `.config/nono/`                    | nono sandbox    | Seatbelt/Landlock profiles   |
| `.config/ai-shared/AGENTS.base.md` | shared source   | base rules for all tools     |
| `.config/ai-shared/overlays/*.md`  | per-tool extras | appended to the base         |
| `.local/bin/ai-agents-render`      | generator       | renders tool AGENTS files    |

## Editing agent rules

Rules common to every agent (sandbox, `rg` > `grep`, `gh` > `curl`, be
concise) live in `ai/.config/ai-shared/AGENTS.base.md`. Tool-specific
guidance (Claude skills, trailing whitespace rules, etc.) lives in
`ai/.config/ai-shared/overlays/<tool>.append.md`.

Regenerate the per-tool files:

```sh
make ai-render
```

`make fmt` invokes it automatically, so drift gets caught.

**Never hand-edit** `ai/.claude/CLAUDE.md`, `ai/.codex/AGENTS.md`, or
`ai/.config/opencode/AGENTS.md` — they carry a `<!-- Generated -->` header
and will be overwritten.

## When to use which agent

| Agent       | Good for                                                        |
| ----------- | --------------------------------------------------------------- |
| Claude Code | Long-running refactors; skills/agents ecosystem; best reasoning |
| Codex       | GPT-4-class tasks; quick turnaround                             |
| OpenCode    | Local-friendly; multi-model; matches terminal workflow          |

All three share the same sandbox profiles under `~/.config/nono/` —
launch via `sb claude` / `sb codex` / `sb opencode` to enforce.
