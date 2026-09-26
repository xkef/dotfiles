# Spec Delta

## MODIFIED Requirements

### Requirement: Agents section

The Agents section SHALL list one row per agent from `agent-state list` whose
cwd lies inside the root, with state, tool, task, workspace, the number of
claimed files, and the unreviewed hunk count of its latest turn. `<CR>` SHALL
focus the agent's pane, `r` SHALL open the review of its latest turn, `s` SHALL
send to it, `w` SHALL add a jj workspace for a new agent, and `W` SHALL review
the agent's workspace against trunk.

#### Scenario: Agent row

- **WHEN** `agent-state list` reports a busy claude agent in the root
- **THEN** the section shows a row with `claude` and `busy`

#### Scenario: Workspace on the row

- **WHEN** the agent works in workspace `feat`
- **THEN** its row shows `feat`
