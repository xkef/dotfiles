# attractor Specification

## Purpose

Support StrongDM Attractor pipelines and the Fabro engine in Neovim: parse and
lint pipeline files, navigate stages, watch runs live, answer human gates, and
review what a run committed.

## Requirements

### Requirement: Parsing

The plugin SHALL parse Attractor's DOT subset in `.dot`, `.gv`, and `.fabro`
files, including comments, graph attributes, node and edge defaults scoped by
subgraphs, and chained edges, and SHALL record each node's definition line and
handler type.

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

On read and write of a pipeline file, the plugin SHALL report the spec's lint
rules as diagnostics on the relevant line, errors for structural rules and
warnings for the rest, and SHALL add the findings of `fabro validate` when that
command exists.

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
definition and an outline buffer listing nodes in breadth-first order from the
start node with their handler types.

#### Scenario: Outline order

- **WHEN** the graph is `start -> plan -> implement -> exit`
- **THEN** the outline lists start, plan, implement, exit in that order

### Requirement: Run status

While a run is attached, the plugin SHALL show each node's status as virtual
text on its definition line in the pipeline buffer, and a Pipeline section in
the cockpit with the run, its node statuses, and pending questions.

#### Scenario: Completed and failed nodes

- **WHEN** a spec run directory has `plan/status.json` with status `SUCCESS` and
  `implement/status.json` with status `FAIL`, and the user runs
  `:Tether attractor run <dir>`
- **THEN** the plan line shows success and the implement line shows failure

#### Scenario: Stage started from a spec server

- **WHEN** a spec server's event stream delivers `StageStarted` for `plan`
- **THEN** the plan line shows it as running

#### Scenario: Pending question marks the gate

- **WHEN** a run directory holds an unanswered question for stage `review`
- **THEN** the review line shows that it waits for the user

### Requirement: Gate answers

`:Tether attractor answer` SHALL fetch pending questions of the attached run,
present the first with its options, and send the choice in the backend's format:
a POST for a spec server, an answer file for a run directory.

#### Scenario: Spec answer

- **WHEN** a spec server's pending question offers `Approve` and `Fix` and the
  user picks `Approve`
- **THEN** the plugin posts an answer with value `Approve` to that question's
  answer endpoint

#### Scenario: Answer an engine gate from Neovim

- **WHEN** an attached engine run waits at a gate and the user picks
  `[A] Approve`
- **THEN** the plugin writes the answer file and the run continues along that
  edge

### Requirement: Launch and review engine runs

`:Tether attractor launch` SHALL start the current pipeline with `tether-run` in
the background and attach its run directory, with `--workspace` passed through.
`:Tether attractor review [run-dir]` SHALL open a read-only review of everything
the run changed, the attached run by default.

#### Scenario: Launch attaches the run

- **WHEN** the user runs `:Tether attractor launch` in a pipeline buffer
- **THEN** a run directory is attached and its nodes reach success

#### Scenario: Review a workspace run

- **WHEN** a `--workspace` run changed `a.txt` and the user runs
  `:Tether attractor review <run-dir>`
- **THEN** the review shows the change to `a.txt` and reject refuses
