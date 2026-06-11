# AI tooling

The `ai` stow package owns the AI agent suite and its shell/tmux adapters.
It is stowed to `$HOME` with the rest of the full profile by `./install`,
`make stow`, and `dots update`.

## Layout

| Path                                 | Tool            | Purpose                          |
| ------------------------------------ | --------------- | -------------------------------- |
| `.claude/`                           | Claude Code     | agents, skills, settings         |
| `.pi/agent/`                         | pi              | agent rules, settings example    |
| `.config/nono/`                      | nono sandbox    | Seatbelt/Landlock profiles       |
| `.config/ai-shared/AGENTS.base.md`   | shared source   | base rules for all tools         |
| `.config/ai-shared/overlays/*.md`    | per-tool extras | appended to the base             |
| `.config/fish/functions/*.fish`      | fish adapters   | wrappers for Claude/pi/etc.      |
| `.config/tmux/conf.d/40-agents.conf` | tmux adapter    | agent popup/session bindings     |
| `.local/bin/ai-agent`                | workspace tool  | parallel agent workspace helper  |
| `.local/bin/ai-agents-render`        | generator       | renders tool AGENTS files        |
| `.local/bin/dots-skills`             | skills pipeline | installs/refreshes shared skills |

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

**Never hand-edit** `ai/.claude/CLAUDE.md` or `ai/.pi/agent/AGENTS.md` —
they carry a `<!-- Generated -->` header and will be overwritten.

pi `settings.json` is a local runtime file. It records machine paths,
trust decisions, changelog state, and other app-managed values, so it is
ignored. Use the adjacent `*.example.*` files as portable starting points
if you need to recreate a config.

## Fish and tmux adapters

The AI-owned fish wrappers live in `ai/.config/fish/functions/`:

- `claude.fish`
- `pi.fish`
- `sb.fish`
- `agent-*.fish`

The `sb` wrapper launches supported agents through nono sandbox profiles:

```sh
sb claude
sb pi
```

`ai/.config/tmux/conf.d/40-agents.conf` owns the tmux bindings for the
agent workspace UI. This file is sourced through the shared tmux
`conf.d` seam when the `ai` package is stowed.

## When to use which agent

| Agent       | Good for                                                        |
| ----------- | --------------------------------------------------------------- |
| Claude Code | Long-running refactors; skills/agents ecosystem; best reasoning |
| pi          | GitHub Copilot-backed coding agent                              |

All agents share sandbox profiles under `~/.config/nono/`.

## Skills

Local skills are tracked once under `.agents/skills/`:

- `commit/` — git/jj commit creation
- `jj/` — Jujutsu usage
- `research-repo/` — `gh`-based GitHub investigation
- `html-summary/` — single-file HTML summaries with diagrams

Claude sees those skills through the `.claude/skills` symlink. Pi loads
`~/.agents/skills` directly via the Agent Skills standard. After adding
shared skills, run `make restow` so `~/.agents/` exists on the host.

Everything else is pulled from upstream on first launch:

- [`mattpocock/skills`](https://github.com/mattpocock/skills)
- `find-skills` from `vercel-labs/skills`
- `html-visual` from `2ykwang/agent-skills` for interactive single-file
  HTML visualizations
- `architecture-diagram` from `Cocoon-AI/architecture-diagram-generator`
  for standalone HTML/SVG architecture diagrams

The fish wrappers call `dots-skills ensure <agent>`. dots-skills owns the
upstream source list and the install sentinel: it installs upstream skills
into `~/.agents/skills` once, then writes the sentinel so subsequent
launches skip the install. Agents that understand `.agents/skills` read
that tree directly; Claude reaches the same tree through `.claude/skills`.

Generated or upstream skills under `ai/.agents/skills/` are filtered out
via `.gitignore` and never get committed.

To force a refresh from upstream:

```sh
dots skills          # requires the ai package
# or, equivalently:
rm ~/.cache/dotfiles/skills.shared.*.installed   # next wrapped launch reinstalls
```
