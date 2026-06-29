# Multi-agent jj workspaces

`ai-agent` runs parallel AI coding agents against one repository without
sharing a working copy. Each agent gets a sibling `jj workspace` and its own
tmux window. Agents do not coordinate live; they converge through commits,
pushed bookmarks, and PRs.

## Naming scheme

| Thing              | Pattern                | Example                      |
| ------------------ | ---------------------- | ---------------------------- |
| Task slug          | kebab-case             | `lint-fix`                   |
| Workspace dir      | `<repo>.agents/<slug>` | `~/dotfiles.agents/lint-fix` |
| jj workspace ID    | `agent-<slug>`         | `agent-lint-fix`             |
| jj bookmark        | `agent/<slug>`         | `agent/lint-fix`             |
| tmux window option | `@agent-slug=<slug>`   | `@agent-slug=lint-fix`       |

The tmux window option is the source of truth. Agent wrappers may rename the
window; `ai-agent` still finds it through `@agent-slug`.

## Bookmark invariant

Every slug owns exactly one local bookmark, `agent/<slug>`.

Spawn creates the bookmark at `trunk()` or `--from <rev>`, then moves the
workspace to an empty descendant of that bookmark. The agent should:

```sh
# edit and test
jj commit <paths...>   # or use the commit skill
jj tug                 # move agent/<slug> to the completed commit
```

`ai-agent finish <slug>` refuses to run if:

- the workspace has uncommitted edits on `@`, or
- commits exist above `agent/<slug>` because the agent forgot `jj tug`.

This prevents pushing an empty or stale bookmark.

## CLI

```sh
ai-agent spawn <slug> \
  [--agent claude|codex|opencode|pi] \
  [--brief "task"] \
  [--from <rev>] \
  [--sandbox]
ai-agent list [--format=human|ui] [--only=all|live|dirty|merged]
ai-agent finish <slug>
ai-agent cleanup [--force] [<slug>]
ai-agent ui [spawn]
ai-agent preview <slug>
```

### `spawn`

Creates the sibling workspace, bookmark, and tmux window:

```sh
ai-agent spawn lint-fix --brief "tighten fish_indent on shell/"
ai-agent spawn readme-tweak \
  --agent codex \
  --brief "rewrite README intro"
ai-agent spawn old-base \
  --from 'main@origin' \
  --brief "test from a fixed base"
```

Collision checks happen before side effects:

- `agent/<slug>` must not already exist locally or remotely.
- `<repo>.agents/<slug>` must not already exist.
- no tmux window may already have `@agent-slug=<slug>`.

If `--brief` is present, the task is written to `.claude-notes/task.md` inside
the agent workspace.

Claude agents are pre-trusted in Claude Code's project state and launch with
`--dangerously-skip-permissions --permission-mode bypassPermissions` so they do
not stop for trust or per-tool permission prompts inside their isolated
workspace.

If the primary checkout has a trusted root `mise.toml` or `.mise.toml`, `spawn`
trusts the identical copy in the new workspace. That prevents mise from
rejecting `~/dotfiles.agents/<slug>/mise.toml` as an untrusted config.

### `list`

Human output is the default:

```sh
ai-agent list
agent-list --only=dirty
```

The UI consumes tab-delimited output:

```sh
ai-agent list --format=ui
ai-agent list --format=ui --only=live
```

Icons:

| Icon | Meaning                                        |
| ---- | ---------------------------------------------- |
| `✎`  | dirty working copy                             |
| `↑`  | commits exist above the bookmark; run `jj tug` |
| `●`  | live tmux window                               |
| `✓`  | merged cleanup candidate                       |
| `○`  | idle/no live window                            |

### `finish`

Finishes a clean, tugged agent branch:

```sh
ai-agent finish lint-fix
```

It runs:

1. dirty/untugged safety checks,
2. `jj git push --bookmark agent/<slug>`,
3. `gh pr create --head agent/<slug> --base main ...`,
4. `jj workspace forget agent-<slug>`,
5. `rm -rf <repo>.agents/<slug>`,
6. tmux window cleanup.

The PR body comes from `.claude-notes/task.md` when present.

### `cleanup`

With a slug, cleanup removes safe candidates:

```sh
ai-agent cleanup lint-fix
```

A candidate is safe when the workspace is clean, has no untugged commits, and
the bookmark is either merged into `trunk()` or marked deleted on the remote.

If cleanup refuses but you want to throw the workspace away, use `--force`:

```sh
ai-agent cleanup --force lint-fix
```

Without a slug, `ai-agent cleanup` scans every agent workspace. It
automatically removes safe candidates and prompts before removing protected
workspaces. It never silently removes unmerged or unpushed work.

### `preview`

`preview` is mainly for fzf:

```sh
ai-agent preview lint-fix
```

It shows recent `jj log` output for `agent/<slug>::@`, the last 40 lines of
the live tmux pane when present, and a diff stat when dirty.

## Tmux UI

After stowing `ai/` and reloading tmux, the snippet at
`~/.config/tmux/conf.d/40-agents.conf` adds:

- `Prefix + a`: open the agent modal.
- `Prefix + A`: start the spawn flow directly.

Inside the modal:

- `Enter`: switch to the selected agent window, or reopen a shell there.
- `Ctrl-a`: show all agents.
- `Ctrl-l`: show agents with live tmux windows.
- `Ctrl-z`: show dirty workspaces.
- `Alt-m`: show merged cleanup candidates.
- `Ctrl-n`: close the modal and open the spawn prompt popup.
- `Ctrl-x`: finish the selected agent after confirmation.
- `Alt-d`: cleanup the selected agent after confirmation.
- `Ctrl-w`: kill only the tmux window.
- `Ctrl-/`: toggle preview.
- `Ctrl-d` / `Ctrl-u`: scroll preview.

The spawn flow asks for slug, agent, optional brief, and whether to launch via
`sb` in a small tmux popup.

## Fish shims

Fish autoloads these shims from `~/.config/fish/functions/`:

```sh
agent-spawn <slug> [args...]
agent-list [args...]
agent-finish <slug>
agent-cleanup [--force] [<slug>]
```

Fish completions are installed for `ai-agent` and the four shims. Slug
completion is backed by `ai-agent list --format=ui`.

Each shim execs the matching `ai-agent` subcommand.

## Sandbox caveat

Agents run without the nono sandbox by default.

`ai-agent spawn <slug> --sandbox` launches `sb <agent>`, but `sb` profiles must
allow writes to the primary repository's `.jj/` directory. In this repo that
means adding an allow-write entry equivalent to:

```sh
--allow-write $HOME/dotfiles/.jj
```

Do this in the relevant `sb` profile before relying on sandboxed agents. The
default no-sandbox path is self-contained inside the `ai/` stow and does not
edit `sb.fish` or other stows.

## Installed files

All files live under `ai/`:

- `.local/bin/ai-agent`
- `.config/tmux/conf.d/40-agents.conf`
- `.config/fish/functions/agent-{spawn,list,finish,cleanup}.fish`
- `.config/fish/functions/__fish_ai_agent_*.fish`
- `.config/fish/completions/ai-agent.fish`
- `.config/fish/completions/agent-{spawn,list,finish,cleanup}.fish`
- `.claude/commands/spawn-agent.md`
- `.local/share/ai-agent/docs/multi-agent.md`
