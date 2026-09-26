# Spec Delta

## Purpose

Deliver review comments, selections, and task text from Neovim into the prompt
of the agent that works on the current repository.

## ADDED Requirements

### Requirement: Target resolution

The plugin SHALL read `agent-state list` and select agents whose cwd lies inside
the current root. With one match it SHALL use it, with several it SHALL ask the
user, and with none it SHALL fall back to the clipboard.

#### Scenario: One agent

- **WHEN** one listed agent has its cwd inside the root
- **THEN** text goes to that agent's pane without a prompt

#### Scenario: No agent

- **WHEN** no listed agent matches
- **THEN** the text lands in the clipboard register (`+`, or the unnamed
  register without a clipboard provider) and the user is told so

### Requirement: Delivery

The plugin SHALL deliver text with `wezterm cli send-text --pane-id <id>` as a
bracketed paste, and SHALL follow it with a carriage return only when
`send.submit` is true.

#### Scenario: Paste without submit

- **WHEN** the user sends text with default options
- **THEN** exactly one `send-text` call carries the text and none carries a
  carriage return

### Requirement: Context-aware send

`:Tether send` SHALL send pending review comments when any exist, the selection
as `@path#Lx-y` followed by the selected text in visual mode, and otherwise the
current file as `@path`. Comments SHALL be formatted as one message with a line
per comment, `path:line: text`, and SHALL be cleared after delivery.

#### Scenario: Batched comments

- **WHEN** two comments are pending and the user runs `:Tether send`
- **THEN** one message lists both as `path:line: text` and no comments remain
  pending

#### Scenario: Visual selection

- **WHEN** lines 3 to 5 of `src/a.lua` are selected and the user sends
- **THEN** the message starts with `@src/a.lua#L3-5`
