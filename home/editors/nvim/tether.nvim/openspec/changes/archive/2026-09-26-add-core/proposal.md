# Proposal

## Why

CLI agents edit the repository from another terminal pane, and Neovim learns
nothing about it. Reviewing an agent's work means reading `jj diff` output,
finding the files by hand, and typing feedback into the agent's prompt.
Editor-integrated tools (Cursor, Zed, VS Code) solve this for their own chat
panels only, and existing Neovim plugins target one agent or Git only.

## What Changes

- An agent-agnostic event log: agents append TSV records through `agent-trail`,
  and the plugin tails the file.
- Turns as the unit of review: each `turn` and `stop` event carries a VCS
  checkpoint, so the plugin diffs exactly what one agent turn changed.
- A review buffer with per-hunk accept and reject, comments, and quickfix
  export.
- Follow mode that moves a window to where the agent edits.
- One picker entry point over changed files, the trail, turns, and hunks.
- Send: review comments, selections, and text go to the agent's pane.
- A cockpit sidebar that summarizes agents, the current turn, and the trail.
- Commands: `:Tether cockpit|review|follow|pick|send|undo|checkpoint`.
- Keys: `<leader>aa` cockpit, `<leader>ar` review, `<leader>af` follow,
  `<leader>ap` pick, `<leader>as` send, `<leader>au` undo turn.

## Capabilities

### New Capabilities

- `event-log`: record format, the `agent-trail` writer, and tailing in Neovim.
- `turns`: turn boundaries, VCS checkpoints, turn diffs, and undo.
- `review`: review buffer, hunk accept and reject, comments, quickfix.
- `follow`: buffer reload on agent edits, follow window, `show` events.
- `pick`: picker entry point and sources.
- `send`: delivery of text to an agent pane with target resolution.
- `cockpit`: sidebar with agents, turn, and trail sections.

### Modified Capabilities

None.

## Impact

- New plugin tree: `plugin/tether.lua`, `lua/tether/`, `doc/tether.txt`,
  `tests/`.
- Host dotfiles: `agent-trail`, a Claude Code hook, a pi extension, and a
  LazyVim spec plus a standalone `agentic` config.
- External commands: `jj`, `git`, `wezterm` (optional).
