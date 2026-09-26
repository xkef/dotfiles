# Spec Delta

## Purpose

Support StrongDM Attractor pipelines in Neovim: parse and lint their DOT files,
navigate stages, watch runs live, and answer human gates.

## ADDED Requirements

### Requirement: Parsing

The plugin SHALL parse Attractor's DOT subset, including comments, graph
attributes, node and edge defaults scoped by subgraphs, and chained edges, and
SHALL record each node's definition line and handler type.

#### Scenario: Chained edges

- **WHEN** a graph contains `start -> plan -> exit [label="next"]`
- **THEN** the parser returns two edges, both labeled `next`

#### Scenario: Handler from shape

- **WHEN** a node has `shape=hexagon`
- **THEN** its handler type is `wait.human`

#### Scenario: Subgraph defaults

- **WHEN** a subgraph sets `node [timeout="900s"]` and defines `plan`
- **THEN** `plan` has the timeout `900s` and nodes outside the subgraph do not

### Requirement: Lint

On read and write of a `.dot` file that contains a `digraph`, the plugin SHALL
report the spec's built-in lint rules as diagnostics on the relevant node or
edge line, with errors for structural rules and warnings for the rest.

#### Scenario: Missing exit

- **WHEN** a graph has a start node and no `Msquare` or `exit` node
- **THEN** the buffer gets an error diagnostic for `terminal_node`

#### Scenario: Unreachable node

- **WHEN** a node has no path from the start node
- **THEN** that node's line gets an error for `reachability`

#### Scenario: Valid example

- **WHEN** the buffer holds the spec's branching example
- **THEN** the buffer has no error diagnostics

### Requirement: Navigation

The plugin SHALL provide a `nodes` picker source that jumps to a node's
definition and shows its prompt, and an outline buffer listing nodes in
breadth-first order from the start node with their handler types.

#### Scenario: Outline order

- **WHEN** the graph is `start -> plan -> implement -> exit`
- **THEN** the outline lists start, plan, implement, exit in that order

### Requirement: Run view from a directory

`:Tether attractor run <dir>` SHALL read the run directory's checkpoint and node
status files, show each node's status as virtual text on its definition line,
and update when files in the directory change. `<CR>` on a node line SHALL open
its `prompt.md` and `response.md` when present.

#### Scenario: Completed and failed nodes

- **WHEN** `plan/status.json` has status `SUCCESS` and `implement/status.json`
  has status `FAIL`
- **THEN** the plan line shows success and the implement line shows failure

### Requirement: Run view from an event stream

`:Tether attractor run <url> <id>` SHALL stream the engine's SSE events with
`curl` and update node status from stage events.

#### Scenario: Stage started

- **WHEN** the stream delivers a `StageStarted` event for `plan`
- **THEN** the plan line shows it as running

### Requirement: Human gates

`:Tether attractor answer` SHALL fetch pending questions from the engine,
present the first with its options, and post the chosen answer.

#### Scenario: Multiple choice answer

- **WHEN** a pending question offers `Approve` and `Fix` and the user picks
  `Approve`
- **THEN** the plugin posts an answer with value `Approve` to that question's
  answer endpoint
