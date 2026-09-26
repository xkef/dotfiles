# sdd Specification

## Purpose

Support spec-driven development with OpenSpec from Neovim: parse, check, and
navigate specs and changes, run the task list as a board, and link agent turns
to the work they did.

## Requirements

### Requirement: Activation

The SDD features SHALL activate only when an `openspec/` directory exists in the
working directory or one of its parents, or at the repository root, and SHALL
show no cockpit section or picker source otherwise.

#### Scenario: Project without OpenSpec

- **WHEN** the repository has no `openspec/` directory
- **THEN** the cockpit shows no Tasks section and `:Tether pick` lists no SDD
  sources

### Requirement: Parsing

The plugin SHALL parse specs into purpose, requirements, and scenarios, and
changes into tasks with id, text, done flag, and line, and delta requirements
grouped by operation, all with line numbers.

#### Scenario: Requirement with scenarios

- **WHEN** a spec has one requirement with two `#### Scenario:` headings
- **THEN** the parser returns one requirement with two scenarios and their lines

#### Scenario: Task list

- **WHEN** `tasks.md` holds `- [x] 1.1 A` and `- [ ] 1.2 B`
- **THEN** the parser returns two tasks, the first done

### Requirement: Diagnostics

On write of a file under `openspec/`, the plugin SHALL report problems as
diagnostics, from `openspec validate --strict --json` when the executable is
available and from built-in checks otherwise: a requirement without a scenario,
a scenario heading with three hashes, and requirement text without SHALL or
MUST.

#### Scenario: Missing scenario

- **WHEN** the CLI is absent and a spec's requirement has no scenario
- **THEN** the buffer gets a diagnostic on the requirement heading

### Requirement: Navigation

The plugin SHALL provide picker sources `specs`, `requirements`, and `changes`
that open the selected item at its line.

#### Scenario: Jump to a requirement

- **WHEN** the user selects a requirement in the `requirements` source
- **THEN** its spec file opens at the requirement heading

### Requirement: Tasks section

The cockpit SHALL show a Tasks section listing active changes with done and
total task counts. `<Tab>` SHALL expand a change to its tasks, `x` SHALL toggle
a task's checkbox on disk, `<CR>` SHALL open the task line, and `s` SHALL send
the task text rendered through `sdd.send_template`.

#### Scenario: Progress

- **WHEN** change `add-x` has two of five tasks done
- **THEN** the section shows `add-x` with `2/5`

#### Scenario: Toggle a task

- **WHEN** the user presses `x` on an unchecked task
- **THEN** `tasks.md` shows the task as `- [x]`

### Requirement: Traceability

A turn whose diff touches files under `openspec/changes/<id>/` SHALL be linked
to change `<id>`, and tasks checked within the turn SHALL be attributed to the
turn's agent. The review header SHALL name the linked change and the tasks
checked in the turn.

#### Scenario: Task checked by an agent

- **WHEN** during claude's turn `tasks.md` of change `add-x` goes from
  `- [ ] 1.2 B` to `- [x] 1.2 B`
- **THEN** the review header of that turn names change `add-x` and task `1.2`,
  and the Tasks section shows task `1.2` done by claude
