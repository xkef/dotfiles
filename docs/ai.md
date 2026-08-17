# AI tooling

The AI agent suite has two concerns, both managed by chezmoi from
`home/`:

| Concern    | Owns                                                   | Depends on |
| ---------- | ------------------------------------------------------ | ---------- |
| agent base | agent rules, local skills, the `claude`/`pi` launchers | —          |
| sandbox    | nono Seatbelt/Landlock profiles and the `sb` wrapper   | `nono`     |

Everything lands in `$HOME` via `chezmoi apply`.

## Agent base — rules, skills, launchers

| Path (target)                                  | Purpose                                      |
| ---------------------------------------------- | -------------------------------------------- |
| `~/.claude/`                                   | Claude Code agents, settings, skills symlink |
| `~/.pi/agent/`                                 | pi agent rules + settings                    |
| `~/.config/fish/functions/{claude,pi}.fish`    | agent launchers                              |
| `~/.config/fish/functions/_ai_run_pinned.fish` | shared tmux window pinning for launchers     |
| `~/.local/bin/dots-skills`                     | skills pipeline (install/refresh)            |

### Editing agent rules

Rules common to every agent (sandbox, `rg` > `grep`, `gh` > `curl`, be
concise) live in `home/.chezmoitemplates/agents-base.md`. Tool-specific
additions live inline in the per-tool templates:

- `home/dot_claude/CLAUDE.md.tmpl` → `~/.claude/CLAUDE.md`
- `home/dot_pi/agent/AGENTS.md.tmpl` → `~/.pi/agent/AGENTS.md`

Edit the template, then `chezmoi apply`. **Never hand-edit** the rendered
files in `$HOME` — they carry a `<!-- Generated -->` header and are
overwritten on the next apply.

### Agent settings

Both agents own their `settings.json` at runtime, so neither file can be
managed outright. An ordinary `chezmoi apply` wipes state the agent needs.
Each one is a chezmoi `modify_` script instead: it reads whatever is on
disk, merges the committed keys over it with `jq`, and writes the result
back. Committed keys win on every apply, and runtime keys survive untouched.

| Target                      | Script                                      | Committed keys live in                        |
| --------------------------- | ------------------------------------------- | --------------------------------------------- |
| `~/.claude/settings.json`   | `home/dot_claude/modify_settings.json.tmpl` | `home/.chezmoitemplates/claude-settings.json` |
| `~/.pi/agent/settings.json` | `home/dot_pi/agent/modify_settings.json`    | the `managed` heredoc in the script           |

Claude Code writes a generated `autoMode.environment` profile into its
settings when auto mode is configured, and rewrites `enabledPlugins` as
plugins come and go. pi writes changelog state, trust decisions, and any
model or theme picked from the TUI. All of that is runtime state and stays
local.

Claude's committed set is a plain JSON file under `.chezmoitemplates/`, so it
stays diffable and lints as JSON. The script pulls it in with
`{{ template "claude-settings.json" }}`. pi's set is short enough to live
inline. Edit whichever one applies, then run `chezmoi apply`. After changing
pi's `packages`, run `pi update --extensions` to install them into
`~/.pi/agent/npm`.

## Sandbox — nono profiles + `sb`

`sb` launches a supported agent inside a [nono](https://nono.sh) sandbox
(Seatbelt on macOS, Landlock on Linux) using a matching profile under
`~/.config/nono/profiles/`:

```sh
sb claude
sb pi
```

nono is the OS-level boundary. For Claude, `sb` also disables Claude Code's
built-in bash sandbox (`--settings '{"sandbox":{"enabled":false}}'`) because
macOS cannot nest Seatbelt — without this, every Bash command inside `sb
claude` would fail with `sandbox_apply: Operation not permitted`. Plain
`claude` (no `sb`) keeps the built-in sandbox.

The two profiles grant the same toolchain surface. `claude.json` inherits
most of it from the registry-managed `claude-code` profile; `pi.json`
extends `default`, so it names the equivalent policy groups explicitly
(`git_config`, `mise_manager`, `node_runtime`, `user_caches_macos`,
`unlink_protection`). Both allow `~/Library/Keychains` for the `gh`
credential helper and read `~/.config/{gh,jj}` plus the mise data and state
directories. `pi.json` additionally allows `~/.agents`, without which pi
starts with no skills, and `~/.pi` covers pi's own npm package tree.

After editing a profile, check it with `nono profile validate pi` and
`nono profile show pi`.

## When to use which agent

| Agent       | Good for                                                        |
| ----------- | --------------------------------------------------------------- |
| Claude Code | Long-running refactors; skills/agents ecosystem; best reasoning |
| pi          | lightweight coding agent                                        |

Both share the nono profiles under `~/.config/nono/`.

## Skills

Local skills are tracked once under `home/dot_agents/skills/` and applied to
`~/.agents/skills/`:

- `commit/` — git/jj commit creation
- `create-gh-pr/` — opening pull requests
- `jj/` — Jujutsu usage
- `research-repo/` — `gh`-based GitHub investigation
- `html-summary/` — single-file HTML summaries with diagrams
- `explain-diff/`, `quiz-diff/`, `microworld/` — diff comprehension tools

Claude sees them through the `~/.claude/skills` symlink (managed by
chezmoi); pi loads `~/.agents/skills` directly via the Agent Skills
standard.

Everything else is pulled from upstream on first launch:

- [`mattpocock/skills`](https://github.com/mattpocock/skills)
- `find-skills` from `vercel-labs/skills`
- `html-visual` from `2ykwang/agent-skills`
- `architecture-diagram` from `Cocoon-AI/architecture-diagram-generator`

The launchers call `dots-skills ensure <agent>`. `dots-skills` owns the
upstream source list and the install sentinel: it installs upstream skills
into `~/.agents/skills` once, then writes the sentinel so later launches skip
it. Upstream skills never touch the repo — chezmoi only manages the tracked
ones.

To force a refresh from upstream:

```sh
dots-skills refresh
# or, equivalently:
rm ~/.cache/dotfiles/skills.shared.*.installed   # next launch reinstalls
```
