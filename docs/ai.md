# AI tooling

The AI agent suite is split into three stow packages so each concern can be
adopted on its own:

| Package      | Owns                                                         | Depends on              |
| ------------ | ------------------------------------------------------------ | ----------------------- |
| `ai-base`    | agent rules, local skills, the `claude`/`pi` launchers       | —                       |
| `ai-sandbox` | nono Seatbelt/Landlock profiles and the `sb` wrapper         | `ai-base`, `nono`       |
| `ai-spawn`   | the `ai-agent` parallel jj-workspace orchestrator + adapters | `ai-base`, jj, tmux, gh |

All three stow to `$HOME` with the rest of the full profile via `./install`,
`make stow`, and `dots update`. Stow just one to take that concern alone
(e.g. `stow ai-sandbox` for only the nono profiles + `sb`).

## ai-base — rules, skills, launchers

| Path                                          | Purpose                                      |
| --------------------------------------------- | -------------------------------------------- |
| `.claude/`                                    | Claude Code agents, settings, skills symlink |
| `.pi/agent/`                                  | pi agent rules + settings example            |
| `.config/ai-shared/AGENTS.base.md`            | base rules shared by every agent             |
| `.config/ai-shared/overlays/<tool>.append.md` | per-tool additions appended to the base      |
| `.config/fish/functions/{claude,pi}.fish`     | agent launchers                              |
| `.config/fish/functions/_ai_run_pinned.fish`  | shared tmux window pinning for launchers     |
| `.local/bin/ai-agents-render`                 | renders the per-tool rule files              |
| `.local/bin/dots-skills`                      | skills pipeline (install/refresh)            |

### Editing agent rules

Rules common to every agent (sandbox, `rg` > `grep`, `gh` > `curl`, be
concise) live in `ai-base/.config/ai-shared/AGENTS.base.md`. Tool-specific
guidance lives in `ai-base/.config/ai-shared/overlays/<tool>.append.md`.

Regenerate the per-tool files:

```sh
make ai-render
```

`make fmt` invokes it automatically, so drift gets caught.

**Never hand-edit** `ai-base/.claude/CLAUDE.md` or
`ai-base/.pi/agent/AGENTS.md` — they carry a `<!-- Generated -->` header and
are overwritten on the next render.

pi `settings.json` is a local runtime file (machine paths, trust decisions,
changelog state), so it is ignored. Use the adjacent `*.example.*` files as
portable starting points.

## ai-sandbox — nono profiles + `sb`

`sb` launches a supported agent inside a [nono](https://nono.sh) sandbox
(Seatbelt on macOS, Landlock on Linux) using a matching profile under
`.config/nono/profiles/`:

```sh
sb claude
sb pi
```

nono is the OS-level boundary. For Claude, `sb` also disables Claude Code's
built-in bash sandbox (`--settings '{"sandbox":{"enabled":false}}'`) because
macOS cannot nest Seatbelt — without this, every Bash command inside `sb
claude` would fail with `sandbox_apply: Operation not permitted`. Plain
`claude` (no `sb`) keeps the built-in sandbox.

## ai-spawn — parallel agent workspaces

`ai-agent` spawns parallel coding agents, each in its own jj workspace and
bookmark (`agent/<slug>`), sibling directory (`<repo>.agents/<slug>`), and
tmux window (tagged with the `@agent-slug` option). See
`ai-spawn/.local/share/ai-agent/docs/multi-agent.md` for the full workflow.
The tmux fragment `.config/tmux/conf.d/40-agents.conf` carries the agent UI
bindings, sourced through the shared tmux `conf.d` seam when `ai-spawn` is
stowed.

## When to use which agent

| Agent       | Good for                                                        |
| ----------- | --------------------------------------------------------------- |
| Claude Code | Long-running refactors; skills/agents ecosystem; best reasoning |
| pi          | lightweight coding agent                                        |

Both share the nono profiles under `~/.config/nono/` when `ai-sandbox` is
stowed.

## Skills

Local skills are tracked once under `ai-base/.agents/skills/`:

- `commit/` — git/jj commit creation
- `create-gh-pr/` — opening pull requests
- `jj/` — Jujutsu usage
- `research-repo/` — `gh`-based GitHub investigation
- `html-summary/` — single-file HTML summaries with diagrams

Claude sees them through the `ai-base/.claude/skills` symlink; pi loads
`~/.agents/skills` directly via the Agent Skills standard. After adding a
shared skill, run `make restow` so `~/.agents/` exists on the host.

Everything else is pulled from upstream on first launch:

- [`mattpocock/skills`](https://github.com/mattpocock/skills)
- `find-skills` from `vercel-labs/skills`
- `html-visual` from `2ykwang/agent-skills`
- `architecture-diagram` from `Cocoon-AI/architecture-diagram-generator`

The launchers call `dots-skills ensure <agent>`. `dots-skills` owns the
upstream source list and the install sentinel: it installs upstream skills
into `~/.agents/skills` once, then writes the sentinel so later launches skip
it. Generated/upstream skills under `~/.agents/skills/` are git-ignored and
never committed.

To force a refresh from upstream:

```sh
dots skills          # requires the ai-base package
# or, equivalently:
rm ~/.cache/dotfiles/skills.shared.*.installed   # next launch reinstalls
```
