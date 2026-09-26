# Spec Delta

## Purpose

Carry agent activity from any CLI agent to any number of Neovim instances
through an append-only, tab-separated log file.

## ADDED Requirements

### Requirement: Record format

Every event SHALL be one line of ten tab-separated fields: epoch, kind, agent,
session, pane, cwd, path, line, ref, text. Empty fields SHALL be written as `-`,
and tabs or line breaks inside a value SHALL be replaced by spaces.

#### Scenario: Edit event with a line

- **WHEN** `agent-trail edit claude src/a.lua 12` runs in `/repo` with
  `WEZTERM_PANE=7`
- **THEN** the log gains one line whose kind is `edit`, agent `claude`, pane
  `7`, cwd `/repo`, path `/repo/src/a.lua`, and line `12`

#### Scenario: Value with a tab

- **WHEN** `agent-trail turn pi` runs with the summary `fix\tparser`
- **THEN** the text field reads `fix parser`

### Requirement: Writer command

`agent-trail` SHALL accept the subcommands `turn <agent> [summary]`,
`stop <agent>`, `edit <agent> <path> [line]`, `read <agent> <path> [line]`,
`show <path> [line]`, `hook claude`, and `path`. It SHALL resolve relative paths
against the working directory, SHALL write the log under
`$XDG_STATE_HOME/agents/trail.log` (default `~/.local/state`), and SHALL exit 0
on any runtime failure so it never blocks an agent.

#### Scenario: Log path

- **WHEN** `agent-trail path` runs with `XDG_STATE_HOME=/s`
- **THEN** it prints `/s/agents/trail.log`

#### Scenario: Claude hook input

- **WHEN** `agent-trail hook claude` reads a PostToolUse payload for the `Edit`
  tool with `tool_input.file_path` set
- **THEN** it appends an `edit` event for that path with agent `claude` and
  session set to the payload's `session_id`

#### Scenario: Claude prompt starts a turn

- **WHEN** `agent-trail hook claude` reads a UserPromptSubmit payload
- **THEN** it appends a `turn` event whose text is the first 60 characters of
  the prompt

### Requirement: Rotation

The writer SHALL move the log to `trail.log.1` before appending when the log
exceeds 256 KiB.

#### Scenario: Oversized log

- **WHEN** the log holds 300 KiB and an event is written
- **THEN** `trail.log.1` holds the old content and `trail.log` holds only the
  new event

### Requirement: Tailing

The plugin SHALL watch the log directory, parse lines appended after its stored
offset, and dispatch each event to subscribers. It SHALL reset the offset to
zero when the file becomes smaller than the offset. It SHALL ignore malformed
lines.

#### Scenario: Appended event reaches subscribers

- **WHEN** a line is appended to the log while the plugin runs
- **THEN** subscribers receive a parsed event with numeric epoch and line

#### Scenario: Rotation while running

- **WHEN** the log is rotated and a new event is appended
- **THEN** subscribers receive the new event exactly once

### Requirement: Replay on start

On setup the plugin SHALL read the existing log and deliver its events with a
`replay` flag, so state is rebuilt without follow side effects.

#### Scenario: Turns survive a restart

- **WHEN** the log holds a `turn` and a `stop` event for the current repository
  and Neovim starts
- **THEN** the plugin lists that turn as finished
