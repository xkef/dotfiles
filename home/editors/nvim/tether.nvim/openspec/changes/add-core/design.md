# Design

## Context

Agents run in WezTerm panes, outside Neovim. The host dotfiles already have
`agent-state`, which stores one record per agent pane (agent, state, tool, cwd,
task) and lists them. Claude Code runs hooks, and pi loads TypeScript
extensions. Both can call a shell command on every tool call and at turn
boundaries. The nono sandbox and the Claude Code sandbox allow writes to
`$XDG_STATE_HOME/agents`.

## Goals / Non-Goals

**Goals:**

- Work with any agent that can run a command, with no agent-side protocol beyond
  appending a line.
- Make the agent turn the unit of review, on jj and on Git.
- Keep the UI to three surfaces: cockpit, review buffer, picker.
- Degrade without snacks.nvim, codediff.nvim, or WezTerm.

**Non-Goals:**

- Running agents inside Neovim (ACP clients cover that).
- Blocking the agent until the user approves an edit (claudecode.nvim covers
  that for Claude).
- One jj change per turn (`jj new` per turn). The op-range model covers review
  without rewriting history. A later change can add it.

## Decisions

### Event log over sockets

Agents append to `$XDG_STATE_HOME/agents/trail.log`. One record per line, ten
tab-separated fields, `-` for empty:

```text
epoch  kind  agent  session  pane  cwd  path  line  ref  text
```

`kind` is one of `turn`, `stop`, `edit`, `read`, `show`. `ref` is a VCS
checkpoint, `jj:<operation id>` or `git:<commit>`. `text` holds the turn
summary. Appends of short lines are atomic on local file systems, so writers
need no lock. `agent-trail` rotates the file to `trail.log.1` above 256 KiB.

A socket would need discovery, fail while Neovim is closed, and serve one
editor. A file serves any number of editors and survives restarts, and the
sandboxes already allow writing it.

Neovim watches the directory with `vim.uv.new_fs_event` (a file watch breaks on
rotation), reads from a stored byte offset, and resets the offset when the file
shrinks. On start it replays the file to rebuild turns and the trail, without
follow side effects.

### Turns as checkpoint ranges

`agent-trail turn` and `agent-trail stop` record a checkpoint in `ref`:

- jj: `jj op log -n1 --no-graph -T id`. The command snapshots the working copy
  first, so edits made through shell commands count too.
- Git: `git stash create`, or `HEAD` when the tree is clean.

The plugin resolves a jj operation to the workspace's working-copy commit with
`jj --ignore-working-copy --at-op <op> log -r @ -T commit_id`, run in the
agent's cwd so multi-workspace setups resolve the right `@`. A turn diff is
`jj --ignore-working-copy diff --git --from <start> --to <end>`. A running turn
has no end, so the plugin takes one snapshot (`jj log -r @`) when the user opens
its review. Background refreshes never snapshot, which keeps the operation log
free of editor noise.

Undo of a turn restores only the files the turn touched:
`jj restore --from <start> -- <paths>` or `git checkout <start> -- <paths>` plus
removal of added files. `jj op restore` would also discard other agents' work.

### Review state

Reviewed hunks are stored by content hash (SHA-256 of the path and the hunk's
`-` and `+` lines) in `stdpath("state")/tether/reviewed.json`, grouped by
repository root and pruned after 30 days. A hash survives line shifts and
re-renders. Rejecting a hunk writes the old lines back into the working file
when the hunk's new lines still match there, and refuses otherwise.

Comments live in memory until sent or cleared.

### Derived state

Turns, the trail, and agent rows are derived from the event log and
`agent-state list` on every refresh. Only reviewed hashes are stored. The
cockpit polls `agent-state list` every two seconds while it is open.

### Send

Text goes to the pane through `wezterm cli send-text --pane-id <id>`, which uses
bracketed paste, so newlines do not submit the prompt. With `send.submit = true`
a carriage return follows as `--no-paste`. Without WezTerm, or without a
matching agent, text goes to the `+` register.

### Optional integrations

The picker uses snacks.nvim when it loads and `vim.ui.select` otherwise. The
side-by-side diff uses codediff.nvim when available and a `diffthis` tab
otherwise.

## Risks / Trade-offs

- An agent that writes files without the hooks produces no `edit` events. Turn
  diffs still cover its changes, because checkpoints snapshot the tree.
- Git checkpoints from `git stash create` skip untracked files, so a Git turn
  diff misses new files that stay untracked.
- Rejecting a hunk after further edits to the same lines fails by design; the
  user refreshes the review first.
