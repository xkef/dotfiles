# Spec Delta

## Purpose

Group agent activity into turns bounded by VCS checkpoints, so one diff shows
exactly what one agent turn changed, on jj or Git.

## ADDED Requirements

### Requirement: Checkpoint at turn boundaries

`agent-trail turn` and `agent-trail stop` SHALL record a checkpoint in the `ref`
field: `jj:<operation id>` inside a jj workspace, `git:<commit>` inside a Git
work tree (from `git stash create`, or `HEAD` when clean), and `-` elsewhere.

#### Scenario: jj checkpoint

- **WHEN** `agent-trail turn claude` runs inside a jj workspace
- **THEN** the event's ref is `jj:` followed by the current operation id

#### Scenario: Git checkpoint

- **WHEN** `agent-trail stop claude` runs in a Git repository with a modified
  tracked file
- **THEN** the event's ref is `git:` followed by a commit that contains the
  modification

### Requirement: Turn model

The plugin SHALL build turns per agent and session from events whose cwd or path
lies inside the current repository root. A turn SHALL start at a `turn` event,
SHALL collect `edit` and `read` paths, and SHALL end at the next `stop` event of
the same agent and session.

#### Scenario: Running and finished turns

- **WHEN** the log holds `turn`, `edit`, `stop`, `turn`, `edit` for one agent
- **THEN** the plugin reports two turns, the first finished and the second
  running, each with its edited path

#### Scenario: Other repositories are ignored

- **WHEN** a `turn` event has a cwd outside the current root
- **THEN** the plugin does not list it

### Requirement: Turn diff

The plugin SHALL compute a turn's diff from the start checkpoint to the end
checkpoint, or to the current working copy for a running turn. UI refreshes
SHALL run jj with `--ignore-working-copy`, and only an explicit review of a
running turn SHALL snapshot.

#### Scenario: Diff of a finished jj turn

- **WHEN** a file changes between a turn's start and stop checkpoints and again
  after the stop
- **THEN** the turn diff shows only the change made between the checkpoints

### Requirement: Manual checkpoint

`:Tether checkpoint` SHALL record a checkpoint for the current repository that
review can use as a base.

#### Scenario: Review since checkpoint

- **WHEN** the user runs `:Tether checkpoint`, a file changes, and the user runs
  `:Tether review checkpoint`
- **THEN** the review shows that change only

### Requirement: Undo turn

`:Tether undo` SHALL restore the files touched by the selected turn to their
content at the turn's start after the user confirms, and SHALL leave other files
untouched.

#### Scenario: Undo restores touched files only

- **WHEN** a turn modified `a.txt` and the user modified `b.txt`, and the user
  confirms `:Tether undo`
- **THEN** `a.txt` has its pre-turn content and `b.txt` keeps the user's
  modification
