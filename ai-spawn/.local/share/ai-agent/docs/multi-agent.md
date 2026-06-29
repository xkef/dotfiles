# Multi-agent jj workspaces

`ai-agent` runs parallel AI coding agents against one repository without
sharing a working copy. Each agent gets a sibling `jj workspace` and its own
[herdr](https://herdr.dev) workspace. Agents do not coordinate live; they
converge through commits, pushed bookmarks, and PRs.

herdr is the UI: its sidebar rolls each agent up to a working / blocked / idle
state, so you can see which agent needs you without cycling through windows.
`ai-agent` drives herdr over its socket API, so a herdr server must be running
to spawn (start one with `herdr`).

## Naming scheme

| Thing           | Pattern                | Example                      |
| --------------- | ---------------------- | ---------------------------- |
| Task slug       | kebab-case             | `lint-fix`                   |
| Workspace dir   | `<repo>.agents/<slug>` | `~/dotfiles.agents/lint-fix` |
| jj workspace ID | `agent-<slug>`         | `agent-lint-fix`             |
| jj bookmark     | `agent/<slug>`         | `agent/lint-fix`             |
| herdr workspace | label `<slug>`         | `lint-fix`                   |

The herdr workspace label is the source of truth for liveness; `ai-agent`
finds an agent's workspace by looking the slug up in `herdr workspace list`.

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
ai-agent spawn [<slug>] [--agent claude|pi] [--brief "task"] [--from <rev>] [--sandbox]
ai-agent list [--only=all|live|dirty|merged]
ai-agent finish <slug>
ai-agent cleanup [--force] [<slug>]
ai-agent focus <slug>
ai-agent preview <slug>
```

Run `ai-agent spawn` with no slug in a terminal to be prompted for slug, agent,
and brief.

### `spawn`

Creates the sibling workspace, bookmark, and herdr workspace, then launches the
agent in the herdr workspace's pane:

```sh
ai-agent spawn lint-fix --brief "tighten fish_indent on shell/"
ai-agent spawn old-base --from 'main@origin' --brief "test from a fixed base"
```

Collision checks happen before side effects:

- `agent/<slug>` must not already exist locally or remotely.
- `<repo>.agents/<slug>` must not already exist.
- no herdr workspace may already be labelled `<slug>`.

If `--brief` is present, the task is written to `.claude-notes/task.md` inside
the agent workspace.

Claude agents are pre-trusted in Claude Code's project state and launch with
`--dangerously-skip-permissions --permission-mode bypassPermissions` so they do
not stop for trust or per-tool permission prompts inside their isolated
workspace. herdr's `claude`/`pi` integration detects the running agent and
reports its state to the sidebar.

If the primary checkout has a trusted root `mise.toml` or `.mise.toml`, `spawn`
trusts the identical copy in the new workspace. That prevents mise from
rejecting `~/dotfiles.agents/<slug>/mise.toml` as an untrusted config.

### `list`

```sh
ai-agent list
ai-agent list --only=dirty
```

Each agent reports its workspace, bookmark, current change, and four flags:
`live` (a herdr workspace exists for the slug), `dirty`, `untugged-commits`,
and `merged-to-trunk`. Use `--only=all|live|dirty|merged` to filter.

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
6. `herdr workspace close` for the slug.

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

### `focus`

```sh
ai-agent focus lint-fix
```

Focuses the agent's herdr workspace (the equivalent of clicking it in the
sidebar).

### `preview`

```sh
ai-agent preview lint-fix
```

Shows recent `jj log` output for `agent/<slug>::@`, the last 40 lines of the
agent's herdr pane when live, and a diff stat when dirty.

## herdr UI

herdr's sidebar is the always-on agent UI — there is no separate modal. It
shows every workspace and its agent state (working / blocked / idle), and
`ai-agent focus <slug>` jumps to one. herdr uses the same `Ctrl-b` prefix as
tmux.

For quick spawning from inside tmux, the snippet at
`~/.config/tmux/conf.d/<agents>.conf` binds `Prefix + A` to a popup running
`ai-agent spawn`.

## Fish shims

Fish autoloads these shims from `~/.config/fish/functions/`:

```sh
agent-spawn <slug> [args...]
agent-list [args...]
agent-finish <slug>
agent-cleanup [--force] [<slug>]
```

Fish completions are installed for `ai-agent` and the four shims. Slug
completion is backed by the agent workspace directories.

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
default no-sandbox path is self-contained inside the `ai-spawn` stow and does
not edit `sb.fish` or other stows.

## Installed files

All files live under `ai-spawn/`:

- `.local/bin/ai-agent`
- `.config/tmux/conf.d/<agents>.conf`
- `.config/fish/functions/agent-{spawn,list,finish,cleanup}.fish`
- `.config/fish/functions/__fish_ai_agent_*.fish`
- `.config/fish/completions/ai-agent.fish`
- `.config/fish/completions/agent-{spawn,list,finish,cleanup}.fish`
- `.claude/commands/spawn-agent.md`
- `.local/share/ai-agent/docs/multi-agent.md`

herdr itself is in `Brewfile` (`brew "herdr"`); on Arch install it via the
herdr install script (see `pkgs.arch`).
