# AI tooling

Configs for multiple AI coding agents, stowed to `$HOME`.

## Layout

| Path                               | Tool            | Purpose                       |
| ---------------------------------- | --------------- | ----------------------------- |
| `.claude/`                         | Claude Code     | agents, skills, settings      |
| `.codex/`                          | OpenAI Codex    | agent rules, config example   |
| `.config/opencode/`                | OpenCode        | agent rules, `opencode.json`  |
| `.pi/agent/`                       | pi.dev          | agent rules, settings example |
| `.config/nono/`                    | nono sandbox    | Seatbelt/Landlock profiles    |
| `.config/ai-shared/AGENTS.base.md` | shared source   | base rules for all tools      |
| `.config/ai-shared/overlays/*.md`  | per-tool extras | appended to the base          |
| `.local/bin/ai-agents-render`      | generator       | renders tool AGENTS files     |

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

Codex `config.toml` and pi `settings.json` are local runtime files. They
record machine paths, trust decisions, changelog state, and other app-managed
values, so they are ignored. Use the adjacent `*.example.*` files as portable
starting points if you need to recreate a config.

## When to use which agent

| Agent       | Good for                                                        |
| ----------- | --------------------------------------------------------------- |
| Claude Code | Long-running refactors; skills/agents ecosystem; best reasoning |
| Codex       | OpenAI-model tasks; quick turnaround                            |
| OpenCode    | Local-friendly; multi-model; matches terminal workflow          |
| pi          | GitHub Copilot-backed coding agent                              |

All agents share sandbox profiles under `~/.config/nono/` — launch via
`sb claude` / `sb codex` / `sb opencode` / `sb pi` to enforce.

## Skills

Three local skills are tracked here under `.claude/skills/`:

- `commit/` — git/jj commit creation
- `research-repo/` — `gh`-based GitHub investigation
- `jujutsu/` — `jj` usage

Everything else is pulled from upstream
([`mattpocock/skills`](https://github.com/mattpocock/skills) plus
`find-skills` from `vercel-labs/skills`) **on first launch** of each
agent. The fish wrappers under
`shell/.config/fish/functions/{claude,pi,codex,opencode}.fish` call
the shared helper `_ai_ensure_skills <agent>`, which runs
`npx skills@latest add ... --copy` once and writes a sentinel at
`~/.cache/dotfiles/skills.<agent>.installed` so subsequent launches
skip the install.

Only fish-resolved invocations are wrapped — `sb claude` execs
`nono run -- claude` and nono spawns the binary directly, bypassing
the fish function. Run the agent once directly (`claude`, `pi`, etc.)
to trigger the install; sandboxed launches afterwards reuse the
result.

Stow folds the per-agent skill directories back into this repo, so
auto-installed trees physically land in `ai/.claude/skills/` and
`ai/.pi/agent/skills/`; both are filtered out via `.gitignore` and
never get committed.

To force a refresh from upstream:

```sh
rm ~/.cache/dotfiles/skills.*.installed   # next sb launch reinstalls
```
