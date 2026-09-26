# coordination Specification

## Purpose

Let the user and parallel agents see who works on which files, and warn about
collisions, without requiring agents to adopt a protocol.

## Requirements

### Requirement: Implicit claims

A file edited by an agent during its running turn SHALL count as claimed by that
agent until the turn ends.

#### Scenario: Claim during a turn

- **WHEN** claude has a running turn and edited `a.lua`
- **THEN** `a.lua` is claimed by claude

#### Scenario: Claim ends with the turn

- **WHEN** that turn receives its `stop` event
- **THEN** `a.lua` is no longer claimed

### Requirement: Explicit claims

A `claim` event SHALL claim its path or glob for the agent until a matching
`release`, a `release` without a path from that agent, the agent's pane
disappearing from `agent-state list`, or two hours pass.

#### Scenario: Glob claim

- **WHEN** pi emits `claim` for `src/parser/*`
- **THEN** `src/parser/lexer.lua` is claimed by pi

#### Scenario: Release

- **WHEN** pi then emits `release` without a path
- **THEN** no file is claimed by pi

### Requirement: Claim markers

Buffers of claimed files SHALL show the claiming agent as virtual text on their
first line, and the `claims` picker source SHALL list all claims.

#### Scenario: Marker on a claimed buffer

- **WHEN** `a.lua` is loaded and becomes claimed by claude
- **THEN** its first line carries virtual text naming claude

### Requirement: Agent conflict warning

An `edit` event for a file claimed by another agent or session SHALL produce one
warning naming both agents and fire the `User TetherConflict` autocmd.

#### Scenario: Two agents on one file

- **WHEN** claude claims `a.lua` through its running turn and pi emits an `edit`
  event for `a.lua`
- **THEN** the user gets a warning naming claude and pi

### Requirement: User conflict warning

The first change the user makes to a buffer whose file is claimed by an agent
with a running turn SHALL produce one warning per buffer and turn.

#### Scenario: Editing a claimed file

- **WHEN** the user changes text in `a.lua` while claude's running turn claims
  it
- **THEN** the user gets one warning, and further changes produce none

### Requirement: Unsaved edits warning

An `edit` event for a buffer with unsaved changes SHALL produce a warning that
the file changed on disk under the user's edits.

#### Scenario: Agent writes under unsaved edits

- **WHEN** `a.lua` has unsaved changes and an agent emits `edit` for it
- **THEN** the user gets a warning and the buffer keeps the user's text

### Requirement: Workspace map

The plugin SHALL map each agent to the jj workspace that contains its cwd.

#### Scenario: Agent in a second workspace

- **WHEN** an agent's cwd lies in workspace `feat`
- **THEN** the plugin reports workspace `feat` for that agent

### Requirement: Workspace review

`:Tether review workspace <name>` SHALL show the diff from `trunk()` to the
working copy of jj workspace `<name>`, and reject SHALL refuse in that review,
because the files live in the other workspace.

#### Scenario: Review a workspace against trunk

- **WHEN** workspace `feat` changed `a.lua` and the user runs
  `:Tether review workspace feat`
- **THEN** the review shows the change to `a.lua`

#### Scenario: Reject refuses in a workspace review

- **WHEN** the user presses `x` on a hunk of that review
- **THEN** no file changes and the user is told to reject in the other workspace
