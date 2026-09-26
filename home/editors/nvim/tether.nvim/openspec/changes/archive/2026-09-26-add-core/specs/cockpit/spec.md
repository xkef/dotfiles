# Spec Delta

## Purpose

Summarize agents, the current turn, and recent activity in one sidebar that also
serves as the launch point for review, send, and navigation.

## ADDED Requirements

### Requirement: Sidebar

`:Tether cockpit` SHALL toggle a sidebar on the configured side that renders
sections from registered providers, hides empty sections, and refreshes on
events and on a timer while visible. `<Tab>` SHALL collapse or expand the
section under the cursor, and `g?` SHALL list the keys.

#### Scenario: Toggle

- **WHEN** the user runs `:Tether cockpit` twice
- **THEN** the sidebar opens and then closes

#### Scenario: Empty sections hidden

- **WHEN** no agent is listed
- **THEN** the sidebar shows no Agents header

### Requirement: Agents section

The Agents section SHALL list one row per agent from `agent-state list` whose
cwd lies inside the root, with state, tool, task, and the unreviewed hunk count
of its latest turn. `<CR>` SHALL focus the agent's pane, `r` SHALL open the
review of its latest turn, and `s` SHALL send to it.

#### Scenario: Agent row

- **WHEN** `agent-state list` reports a busy claude agent in the root
- **THEN** the section shows a row with `claude` and `busy`

### Requirement: Turn section

The Turn section SHALL list the files of the latest turn with added and removed
line counts, and `<CR>` SHALL open the review at that file.

#### Scenario: Changed file row

- **WHEN** the latest turn added three lines to `a.lua`
- **THEN** the section shows `a.lua` with `+3`

### Requirement: Trail section

The Trail section SHALL list the most recent edit and read events in the root,
newest first, and `<CR>` SHALL open the file at the event's line.

#### Scenario: Open from the trail

- **WHEN** the user presses `<CR>` on a trail row for `b.lua` line 9
- **THEN** the previous window shows `b.lua` at line 9
