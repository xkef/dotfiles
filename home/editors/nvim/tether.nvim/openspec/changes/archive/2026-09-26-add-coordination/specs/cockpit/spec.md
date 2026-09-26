# Spec Delta

## MODIFIED Requirements

### Requirement: Agents section

The Agents section SHALL list one row per agent from `agent-state list` whose
cwd lies inside the root or in another workspace of the same jj repository, with
state, tool, task, workspace, the number of claimed files, and the unreviewed
hunk count of its latest turn. `<CR>` SHALL focus the agent's pane, `r` SHALL
open the review of its latest turn (for an agent in another workspace, that
workspace against trunk), `s` SHALL send to it, `w` SHALL add a jj workspace for
a new agent, and `W` SHALL review the agent's workspace against trunk.

#### Scenario: Agent row

- **WHEN** `agent-state list` reports a busy claude agent in the root
- **THEN** the section shows a row with `claude` and `busy`

#### Scenario: Workspace on the row

- **WHEN** an agent works in workspace `feat` of the same repository
- **THEN** the section lists it and its row shows `feat`
