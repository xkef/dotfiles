# Spec Delta

## MODIFIED Requirements

### Requirement: Writer command

`agent-trail` SHALL accept the subcommands `turn <agent> [summary]`,
`stop <agent>`, `edit <agent> <path> [line]`, `read <agent> <path> [line]`,
`show <path> [line]`, `claim <agent> <path-or-glob>`,
`release <agent> [path-or-glob]`, `hook claude`, and `path`. It SHALL resolve
relative paths against the working directory, SHALL write the log under
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

#### Scenario: Claim a glob

- **WHEN** `agent-trail claim pi 'src/*'` runs in `/repo`
- **THEN** the log gains a `claim` event with path `/repo/src/*`
