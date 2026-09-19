# AI tooling

chezmoi manages the AI agent setup from `home/`. It has two parts:

| Part       | Holds                                                            | Depends on |
| ---------- | ---------------------------------------------------------------- | ---------- |
| agent base | agent rules, local skills, the `claude`, `codex`, `pi` launchers | none       |
| sandbox    | nono Seatbelt and Landlock profiles and the `sb` wrapper         | `nono`     |

`chezmoi apply` writes both into `$HOME`.

## Agent base: rules, skills, launchers

### Agent registry

`home/.chezmoidata/agents.toml` declares each agent once: a description,
how the launcher installs it, what the launcher runs before starting it,
the arguments `sb` passes inside the sandbox, and the nono profile data.
These files render from it:

| Rendered target                        | Source                                               |
| -------------------------------------- | ---------------------------------------------------- |
| `~/.config/fish/conf.d/agents.fish`    | `home/dot_config/fish/exact_conf.d/agents.fish.tmpl` |
| `~/.config/fish/functions/sb.fish`     | `home/dot_config/fish/functions/sb.fish.tmpl`        |
| `~/.config/fish/completions/sb.fish`   | `home/dot_config/fish/completions/sb.fish.tmpl`      |
| `~/.config/nono/profiles/<agent>.json` | `home/.chezmoitemplates/nono-profile.tmpl`           |

Adding an agent means one entry in `agents.toml`, a one-line
`profiles/<agent>.json.tmpl`, a rules template, and a settings merge
script. chezmoi needs a source file per target, so the last three can't
fold into the registry.

| Path (target)                                  | Purpose                                   |
| ---------------------------------------------- | ----------------------------------------- |
| `~/.claude/`                                   | Claude Code settings and skills symlink   |
| `~/.codex/`                                    | Codex rules and config                    |
| `~/.pi/agent/`                                 | pi rules, settings, and status extensions |
| `~/.config/fish/conf.d/agents.fish`            | agent launchers, one per registry entry   |
| `~/.config/fish/functions/_ai_run_pinned.fish` | shared tmux window pinning for launchers  |
| `~/.local/bin/agent-notify`                    | desktop notification shared by the agents |
| `~/.local/bin/codex-notify`                    | Codex turn-complete notification          |
| `~/.local/bin/dots-skills`                     | skill install and refresh                 |

### Editing agent rules

Rules shared by every agent, such as the sandbox notes, `rg` over `grep`,
`gh` over `curl`, and concision, sit in
`home/.chezmoitemplates/agents-base.md`. Tool-specific additions go inline
in the per-tool templates:

- `home/dot_claude/CLAUDE.md.tmpl` → `~/.claude/CLAUDE.md`
- `home/dot_codex/AGENTS.md.tmpl` → `~/.codex/AGENTS.md`
- `home/dot_pi/agent/AGENTS.md.tmpl` → `~/.pi/agent/AGENTS.md`

Edit the template, then run `chezmoi apply`. **Never hand-edit** the
rendered files in `$HOME`. They carry a `<!-- Generated -->` header, and the
next apply overwrites them.

### Agent settings

All three agents write their settings file at runtime, so chezmoi can't
manage any of them outright. An ordinary `chezmoi apply` would wipe state
the agent needs. Each one runs as a chezmoi `modify_` script instead. The
script reads the file on disk, merges the committed keys over it, and
writes the result back. Committed keys win on every apply. Runtime keys
survive untouched.

| Target                      | Script                                        | Committed keys live in                        |
| --------------------------- | --------------------------------------------- | --------------------------------------------- |
| `~/.claude/settings.json`   | `home/dot_claude/modify_settings.json.tmpl`   | `home/.chezmoitemplates/claude-settings.json` |
| `~/.codex/config.toml`      | `home/dot_codex/modify_config.toml.tmpl`      | the `managed` heredoc in the script           |
| `~/.pi/agent/settings.json` | `home/dot_pi/agent/modify_settings.json.tmpl` | `home/.chezmoitemplates/pi-settings.json`     |

Claude Code writes a generated `autoMode.environment` profile into its
settings once auto mode exists, and rewrites `enabledPlugins` as plugins
come and go. Codex writes back the model, the reasoning effort, the
permission profile, and the memories settings picked in its UI. pi writes
changelog state, trust decisions, and any model or theme picked in its UI.
That runtime state stays local.

The two JSON files merge with `jq` through the shared
`home/.chezmoitemplates/merge-json.sh`, which each `modify_` script calls
with its committed JSON. Codex's TOML script replaces managed keys in the
top-level section and the `[tui]` table. It preserves other settings,
including project trust and the model picked in the UI.

Codex's committed set pins `model_reasoning_effort`, `approval_policy`,
`sandbox_mode`, `service_tier`, `approvals_reviewer`, and `notify`. The
`[tui]` block sets the status line items and enables their colors.
`notify` points at `~/.local/bin/codex-notify`, which hands the
turn-complete message to `agent-notify`, the script the Claude
Notification hook calls too. Codex runs that command directly, so the
script renders an absolute path rather than relying on `PATH`.

Claude's and pi's committed sets are plain JSON files under
`.chezmoitemplates/`, so they stay diffable and lint as JSON. Codex's set
fits inline. Edit whichever one applies, then run `chezmoi apply`. After
changing pi's `packages`, run `pi update --extensions` to install them into
`~/.pi/agent/npm`.

### Agent overview

`prefix a` opens the agent picker across tmux sessions. Claude and pi
publish detailed activity states. Codex panes appear as `running`, based
on their live process, and count toward the agent total in the status line.

Each agent's row includes a short task summary. The shared agent rules
ask the main agent to run `agent-task "short task summary"` at task start
and when the goal changes. New sessions load these rules. You can also run
the command by hand in a pane. Summaries go under
`/tmp/tmux-agent-tasks-<uid>`, which agent sandboxes can write.

### Usage status

The pi footer follows the selected provider. GitHub Copilot shows used and
allocated AI credits. OpenAI Codex shows remaining subscription allowance and
its credit balance, using the account signed in through pi. Other providers,
including API-key OpenAI, don't show a balance.

Usage refreshes at session start, on model selection, and after the agent
settles. Offline mode skips requests. Codex uses ChatGPT's internal usage
endpoint, so changes to that endpoint can make the status unavailable.

### Theming

Ghostty, tmux, delta, and Neovim all follow `theme <name>` because they read
the terminal palette or an adapter fragment. pi does neither. It picks a
theme by name from its own JSON files, so
`home/dot_config/exact_theme.d/pi.fish` renders one.

The fragment runs with the parsed palette in scope, `$t_palette`, `$t_bg`,
and `$t_fg`, and writes all 55 color tokens to
`~/.pi/agent/themes/dots.json`, which the tracked `"theme": "dots"` setting
selects. Palette colors map to the semantic roles, such as red for errors and
removed lines, green for success and added lines, and cyan for the accent.
Grays blend
toward the foreground instead of using the ANSI bright-black slot, so the
ramp inverts by itself under a light theme.

pi watches the active custom theme file, so rewriting it recolors running pi
sessions rather than waiting for the next launch.

The fragment generates the file per machine, so it stays untracked, like
the delta adapter's `delta.gitconfig`. That leaves a gap on a machine that hasn't
switched themes since install. No theme file exists yet, and pi falls back to
its built-in dark theme without reporting it. The `pi` launcher closes the
gap by applying the current theme again when the file is missing.

## Sandbox: nono profiles and `sb`

`sb` launches a supported agent inside a [nono](https://nono.sh) sandbox,
Seatbelt on macOS or Landlock on Linux, with a matching profile under
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

The profiles render from `home/.chezmoitemplates/nono-profile.tmpl` and
the `nono` table of each agent in `agents.toml`. All extend `default`. The
template declares the shared toolchain surface once:

- The policy groups `git_config`, `mise_manager`, `node_runtime`,
  `user_caches_macos`, and `unlink_protection`.
- Write access to `~/.agents`, without which the agent starts without
  skills, and to `~/.local/state/agents`, where the status hook and
  extensions publish state for the `tmux-agents` picker.
- Read access to `~/.config/gh`, `~/.config/git`, `~/.ssh/*.pub`, and the
  mise data and state directories.
- `~/Library/Keychains` for the `gh` credential helper.
- Connect access to the 1Password agent socket, so `ssh-keygen -Y sign`
  can sign commits from inside the sandbox.

Each agent adds its own state directories under `nono.allow`, such as
`~/.codex` and `~/.pi`.

`claude` also embeds the registry pack `always-further/claude` profile,
with its extra groups, lock files, `open_urls`, and `rollback`, because the
pack still uses the `undo` field that nono 0.75 renamed to `rollback`, so
nono rejects it. Once the pack updates, drop `groups`, `allow_file`, and
`extra` from its `nono` table and set `extends: "claude-code"`.

After editing the registry, run `chezmoi apply`, then check the result with
`nono profile validate codex` and `nono profile show codex`.

## When to use which agent

| Agent       | Good for                                                            |
| ----------- | ------------------------------------------------------------------- |
| Claude Code | Long refactors, the skill and subagent tooling, strongest reasoning |
| Codex       | ChatGPT subscription work, a second opinion on a Claude answer      |
| pi          | Lightweight coding agent                                            |

All three share the nono profiles under `~/.config/nono/`.

## Skills

The repo tracks local skills once under `home/dot_agents/skills/` and
applies them to `~/.agents/skills/`:

- `commit/`: git and jj commit creation
- `create-gh-pr/`: opening pull requests
- `jj/`: Jujutsu usage
- `research-repo/`: GitHub research with `gh`
- `html-summary/`: single-file HTML summaries with diagrams
- `explain-diff/`, `quiz-diff/`, `microworld/`: diff comprehension tools

Claude reads them through the chezmoi-managed `~/.claude/skills` symlink.
Codex and pi load `~/.agents/skills` through the Agent Skills standard.

The first launch pulls everything else from upstream:

- [`mattpocock/skills`](https://github.com/mattpocock/skills)
- `find-skills` from `vercel-labs/skills`
- `html-visual` from `2ykwang/agent-skills`
- `architecture-diagram` from `Cocoon-AI/architecture-diagram-generator`
- `humanizer` from `blader/humanizer`

The launchers call `dots-skills ensure <agent>`. `dots-skills` holds the
upstream source list and the install sentinel. It installs upstream skills
into `~/.agents/skills` once, then writes the sentinel so later launches skip
it. Upstream skills never enter the repo. chezmoi manages only the tracked
ones.

To force a refresh from upstream:

```sh
dots-skills refresh
# or, equivalently:
rm ~/.cache/dotfiles/skills.shared.*.installed   # next launch reinstalls
```
