# Proposal

## Why

Several agents often work in one repository at once: two panes on the same
checkout, or one per jj workspace. Nothing tells them, or the user, that two of
them are editing the same file, and the user's own unsaved edits collide with
agent writes. Coordination tools such as mcp_agent_mail make agents reserve
files explicitly, which needs every agent to adopt a protocol.

## What Changes

- Implicit claims: a file an agent edited during its running turn counts as
  claimed by that agent, derived from the event log.
- Explicit claims: `agent-trail claim` and `agent-trail release` for agents or
  users who want to reserve paths or globs up front.
- Claim markers on buffers and a `claims` picker source.
- Conflict warnings when two agents touch one file in overlapping turns, when
  the user edits a claimed file, and when an agent writes a file with unsaved
  user changes.
- A workspace map: agents grouped by jj workspace in the cockpit, with actions
  to add a workspace for a new agent and to review a workspace against trunk.

## Capabilities

### New Capabilities

- `coordination`: claims, conflict detection, and the workspace map.

### Modified Capabilities

- `event-log`: the writer gains `claim` and `release`.
- `cockpit`: agent rows show workspace and claims, and the section offers
  workspace actions.

## Impact

- `lua/tether/coord.lua`, cockpit Agents section, `agent-trail`.
- Uses `jj workspace list`, `jj workspace add`, and `jj workspace root`.
