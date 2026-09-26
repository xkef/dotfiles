# Design

## Context

The event log already records which agent edited which file in which turn, and
`agent-state list` tells which agent panes are alive. jj workspaces give each
agent its own working copy that shares history.

## Goals / Non-Goals

**Goals:**

- Coordination that works with agents that know nothing about it.
- Warnings, never blocks: the user decides.

**Non-Goals:**

- Enforcing claims in agents (a pre-tool hook could, later).
- Mailboxes between agents; send already covers user-to-agent messages.
- Git worktree management.

## Decisions

### Claims are derived

A claim is `{agent, session, path or glob, kind}`. Implicit claims come from
`edit` events of running turns and end with the turn's `stop`. Explicit claims
come from `claim` events (path field holds a path or glob) and end with a
matching `release`, a `release` without a path, the agent pane disappearing from
`agent-state list`, or a TTL of two hours. Nothing is stored; claims are
recomputed from the replayed log.

### Conflict checks

- Agent versus agent: an `edit` event on a path claimed by another agent or
  session.
- User versus agent: the first change to a buffer (`TextChanged`,
  `TextChangedI`) whose file is claimed by an agent with a running turn, once
  per buffer and turn.
- Agent versus unsaved user edits: an `edit` event for a modified buffer, which
  follow already refuses to reload.

Each conflict raises one `vim.notify` warning and fires a `User TetherConflict`
autocmd with the details.

### Buffer markers

A claimed file's buffers show virtual text at the end of line one naming the
agent, in `TetherClaim`. Markers refresh on events and `BufEnter`.

### Workspaces

`jj workspace list` names the workspaces, and `jj workspace root` run in an
agent's cwd maps the agent to one. "Add workspace" runs
`jj workspace add <path>` with a name the user enters, next to the repository
root, and copies the path to the `+` register. "Review workspace" opens the
review with the range from `trunk()` to that workspace's working-copy commit.

## Risks / Trade-offs

- Implicit claims only exist after the first edit, so two agents can still start
  on one file at once; the warning arrives with the second edit.
- The TTL can drop a claim that an idle agent still intends to hold.
