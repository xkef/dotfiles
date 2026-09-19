# AI tooling

The AI agent suite has two concerns, both managed by chezmoi from
`home/`:

| Concern    | Owns                                                           | Depends on |
| ---------- | -------------------------------------------------------------- | ---------- |
| agent base | agent rules, local skills, the `claude`/`codex`/`pi` launchers | —          |
| sandbox    | nono Seatbelt/Landlock profiles and the `sb` wrapper           | `nono`     |

Everything lands in `$HOME` via `chezmoi apply`.

## Agent base — rules, skills, launchers

| Path (target)                                     | Purpose                                   |
| ------------------------------------------------- | ----------------------------------------- |
| `~/.claude/`                                      | Claude Code settings and skills symlink   |
| `~/.codex/`                                       | Codex rules and config                    |
| `~/.pi/agent/`                                    | pi rules, settings, and status extensions |
| `~/.config/fish/functions/{claude,codex,pi}.fish` | agent launchers                           |
| `~/.config/fish/functions/_ai_run_pinned.fish`    | shared tmux window pinning for launchers  |
| `~/.local/bin/agent-notify`                       | desktop notification shared by the agents |
| `~/.local/bin/codex-notify`                       | Codex turn-complete notification          |
| `~/.local/bin/dots-skills`                        | skills pipeline (install/refresh)         |

### Editing agent rules

Rules common to every agent (sandbox, `rg` > `grep`, `gh` > `curl`, be
concise) live in `home/.chezmoitemplates/agents-base.md`. Tool-specific
additions live inline in the per-tool templates:

- `home/dot_claude/CLAUDE.md.tmpl` → `~/.claude/CLAUDE.md`
- `home/dot_codex/AGENTS.md.tmpl` → `~/.codex/AGENTS.md`
- `home/dot_pi/agent/AGENTS.md.tmpl` → `~/.pi/agent/AGENTS.md`

Edit the template, then `chezmoi apply`. **Never hand-edit** the rendered
files in `$HOME` — they carry a `<!-- Generated -->` header and are
overwritten on the next apply.

### Agent settings

All three agents own their settings file at runtime, so none of them can be
managed outright. An ordinary `chezmoi apply` wipes state the agent needs.
Each one is a chezmoi `modify_` script instead: it reads whatever is on
disk, merges the committed keys over it, and writes the result back.
Committed keys win on every apply, and runtime keys survive untouched.

| Target                      | Script                                      | Committed keys live in                        |
| --------------------------- | ------------------------------------------- | --------------------------------------------- |
| `~/.claude/settings.json`   | `home/dot_claude/modify_settings.json.tmpl` | `home/.chezmoitemplates/claude-settings.json` |
| `~/.codex/config.toml`      | `home/dot_codex/modify_config.toml.tmpl`    | the `managed` heredoc in the script           |
| `~/.pi/agent/settings.json` | `home/dot_pi/agent/modify_settings.json`    | the `managed` heredoc in the script           |

Claude Code writes a generated `autoMode.environment` profile into its
settings when auto mode is configured, and rewrites `enabledPlugins` as
plugins come and go. Codex writes back the model, the reasoning effort, the
permission profile, and the memories settings picked from the TUI. pi writes
changelog state, trust decisions, and any model or theme picked from the TUI.
All of that is runtime state and stays local.

The two JSON files merge with `jq`. Codex's TOML script replaces managed
keys in the top-level section and the `[tui]` table. It preserves other
settings, including project trust and the model selected in the TUI.

Codex's committed set pins `model_reasoning_effort`, `approval_policy`,
`sandbox_mode`, `service_tier`, `approvals_reviewer`, and `notify`. The
`[tui]` block sets the status line items and enables their colors.
`notify` points at `~/.local/bin/codex-notify`, which hands the
turn-complete message to `agent-notify`, the script the Claude
Notification hook calls too. Codex runs that command directly, so the
script renders an absolute path rather than relying on `PATH`.

Claude's committed set is a plain JSON file under `.chezmoitemplates/`, so it
stays diffable and lints as JSON. The script pulls it in with
`{{ template "claude-settings.json" }}`. Codex's and pi's sets are short
enough to live inline. Edit whichever one applies, then run `chezmoi apply`.
After changing pi's `packages`, run `pi update --extensions` to install them
into `~/.pi/agent/npm`.

### Agent overview

`prefix a` opens the agent picker across tmux sessions. Claude and pi
publish detailed activity states. Codex panes appear as `running`, based
on their live process, and contribute to the status bar agent count.

Each agent's row includes a short task summary. Shared agent instructions
ask the main agent to run `agent-task "short task summary"` at task start
and when the objective changes. New sessions load these instructions.
You can also run the command manually in a pane. Summaries are stored
under `/tmp/tmux-agent-tasks-<uid>`, which is writable from agent sandboxes.

### Usage status

The pi footer follows the selected provider. GitHub Copilot shows used and
allocated AI credits. OpenAI Codex shows remaining subscription allowance and
its credit balance, using the account signed in through pi. Other providers,
including API-key OpenAI, show no account balance.

Usage refreshes at session start, on model selection, and after the agent
settles. Offline mode skips requests. Codex uses ChatGPT's internal usage
endpoint, so changes to that endpoint can make the status unavailable.

### Theming

Ghostty, tmux, delta, and Neovim all follow `theme <name>` because they read
the terminal palette or an adapter fragment. pi does neither: it picks a theme
by name from its own JSON files. So `home/dot_config/exact_theme.d/pi.fish`
renders one.

The fragment runs with the parsed palette in scope (`$t_palette`, `$t_bg`,
`$t_fg`) and writes all 55 color tokens to `~/.pi/agent/themes/dots.json`,
which the tracked `"theme": "dots"` setting selects. Palette colors map to the
roles that carry meaning (red for errors and removed lines, green for success
and added lines, cyan for the accent). Grays are blends toward the foreground
rather than the ANSI bright-black slot, so the ramp inverts by itself under a
light theme.

pi watches the active custom theme file, so rewriting it recolors running pi
sessions rather than waiting for the next launch.

The file is generated and machine-local, so it stays untracked, the same way
the delta adapter's `delta.gitconfig` does. That leaves a gap on a machine
that has not switched themes since install: no theme file exists yet and pi
falls back to its built-in dark without reporting it. The `pi` launcher closes
the gap by re-applying the current theme once when the file is missing.

## Sandbox — nono profiles + `sb`

`sb` launches a supported agent inside a [nono](https://nono.sh) sandbox
(Seatbelt on macOS, Landlock on Linux) using a matching profile under
`~/.config/nono/profiles/`. The `claude`, `codex`, and `pi` fish functions
route through it, so a plain `claude` is already `sb claude`. Bypass the
sandbox with `command claude`:

```sh
claude            # same as: sb claude
command claude    # no sandbox
```

nono is the OS-level boundary. Two of the agents nest their own Seatbelt
policy inside it, which macOS refuses, so `sb` turns each one off. Claude
Code gets `--settings '{"sandbox":{"enabled":false}}'`, without which every
Bash command inside `sb claude` fails with `sandbox_apply: Operation not
permitted`. Codex gets `-s danger-full-access`, which relaxes only its
sandbox: the `on-request` approval policy still applies. Only `command
claude` and `command codex` keep the agents' own sandboxes.

The three profiles grant the same toolchain surface. All extend `default`.
`claude.json` inlines the registry pack `always-further/claude` profile
(groups, `~/.claude`, lock files, `open_urls`) because the pack still uses
the `undo` field that nono 0.75 renamed to `rollback`, which makes it
unparseable. Drop the inlined part and `extends: "claude-code"` again once
the pack is fixed. `codex.json` and `pi.json` name the equivalent policy
groups explicitly: `git_config`, `mise_manager`, `node_runtime`,
`user_caches_macos`, and `unlink_protection`. All three allow
`~/Library/Keychains` for the `gh` credential helper, and all three read
`~/.config/gh`, `~/.config/jj`, and the mise data and state directories,
and all three write `~/.local/state/agents`, where the status hook and
extensions publish state for the `tmux-agents` picker.
`codex.json` and `pi.json` also allow `~/.agents`, without which the agent
starts with no skills, plus `~/.codex` and `~/.pi` for each agent's own
state.

After editing a profile, check it with `nono profile validate codex` and
`nono profile show codex`.

## When to use which agent

| Agent       | Good for                                                        |
| ----------- | --------------------------------------------------------------- |
| Claude Code | Long-running refactors; skills/agents ecosystem; best reasoning |
| Codex       | ChatGPT subscription work; second opinion on a Claude answer    |
| pi          | lightweight coding agent                                        |

All three share the nono profiles under `~/.config/nono/`.

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
chezmoi); Codex and pi load `~/.agents/skills` directly via the Agent Skills
standard.

Everything else is pulled from upstream on first launch:

- [`mattpocock/skills`](https://github.com/mattpocock/skills)
- `find-skills` from `vercel-labs/skills`
- `html-visual` from `2ykwang/agent-skills`
- `architecture-diagram` from `Cocoon-AI/architecture-diagram-generator`
- `humanizer` from `blader/humanizer`

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
