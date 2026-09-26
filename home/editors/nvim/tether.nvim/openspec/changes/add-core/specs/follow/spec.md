# Spec Delta

## Purpose

Keep buffers current while agents edit files, and optionally move a window to
each edit as it happens, for any agent that emits events.

## ADDED Requirements

### Requirement: Reload on edit

On an `edit` event for a file loaded in an unmodified buffer, the plugin SHALL
reload the buffer from disk. It SHALL NOT reload a buffer with unsaved changes.

#### Scenario: Buffer reloads

- **WHEN** an agent writes a loaded, unmodified file and emits an `edit` event
- **THEN** the buffer holds the new content

#### Scenario: Unsaved changes are kept

- **WHEN** the buffer has unsaved changes and an `edit` event arrives for it
- **THEN** the buffer keeps the user's changes

### Requirement: Follow mode

`:Tether follow` SHALL toggle follow mode and remember the current window as the
follow window. In follow mode each live `edit` event inside the root SHALL show
the file in the follow window at the first changed line and highlight the
changed lines briefly. The line SHALL come from the event when present, else
from comparing the previous and new content.

#### Scenario: Jump to the changed line

- **WHEN** follow mode is on and an agent changes line 20 of a file and emits an
  `edit` event without a line
- **THEN** the follow window shows that file with the cursor on line 20

#### Scenario: Line from the event

- **WHEN** follow mode is on and an `edit` event carries line 7
- **THEN** the cursor lands on line 7

### Requirement: No interruption while typing

When the follow window is the current window and the user is in insert or
command-line mode, the plugin SHALL defer the jump until the user returns to
normal mode and then apply only the latest one.

#### Scenario: Deferred during insert

- **WHEN** the user is in insert mode and two `edit` events arrive
- **THEN** the cursor stays until the user leaves insert mode, then moves to the
  location of the second event

### Requirement: Show events

A live `show` event inside the root SHALL reveal its location even when follow
mode is off.

#### Scenario: Agent points at code

- **WHEN** `agent-trail show src/a.lua 5` runs in the repository
- **THEN** Neovim shows `src/a.lua` with the cursor on line 5

### Requirement: Stop notification

A live `stop` event inside the root SHALL produce a notification that names the
agent and the number of changed files and unreviewed hunks of the turn.

#### Scenario: Turn finished

- **WHEN** a turn that changed two files ends
- **THEN** the notification names the agent and reports two files

### Requirement: Status component

`require("tether").status()` SHALL return a short string for statuslines that
shows follow mode, busy agents, and unreviewed hunks of the latest turn, and
SHALL return an empty string when nothing applies.

#### Scenario: Idle editor

- **WHEN** follow mode is off, no agent is busy, and nothing is unreviewed
- **THEN** `status()` returns an empty string
