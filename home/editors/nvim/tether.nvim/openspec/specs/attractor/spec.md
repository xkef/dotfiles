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

### Requirement: Run view

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

#### Scenario: Fabro stream updates nodes

- **WHEN** `:Tether attractor run fabro:<id>` streams petri items
  `visit.started` and `step.finished` for `plan`
- **THEN** the plan line shows success, and the cockpit Pipeline section lists
  the run

#### Scenario: Fabro server from settings

- **WHEN** `~/.fabro/settings.toml` sets `url` under `[cli.target]` and no URL
  is configured
- **THEN** the Fabro backend connects to that URL

### Requirement: Human gates

`:Tether attractor answer` SHALL fetch pending questions of the attached run,
present the first with its options, and send the choice in the backend's format.

#### Scenario: Spec answer

- **WHEN** a spec server's pending question offers `Approve` and `Fix` and the
  user picks `Approve`
- **THEN** the plugin posts an answer with value `Approve` to that question's
  answer endpoint

#### Scenario: Fabro answer

- **WHEN** a Fabro question offers option key `A` labeled `Approve` and the user
  picks it
- **THEN** the plugin posts `{"kind":"selected","option_key":"A"}` to
  `/api/v1/runs/<id>/questions/<qid>/answer`

#### Scenario: Fabro yes or no

- **WHEN** a Fabro question has type `yes_no` and the user picks Yes
- **THEN** the plugin posts `{"kind":"yes"}`

### Requirement: Fabro launch and review

`:Tether attractor launch` SHALL start the workflow of the current buffer with
`fabro run -d` and attach to the printed run id. `:Tether attractor review <id>`
SHALL open a read-only review of branch `fabro/run/<id>` against the branch
point.

#### Scenario: Launch attaches

- **WHEN** the user runs `:Tether attractor launch` in a `.fabro` buffer and
  `fabro` prints run id `01J00000000000000000000000`
- **THEN** that run is attached

#### Scenario: Review a Fabro run

- **WHEN** branch `fabro/run/01J00000000000000000000000` changed `a.txt` and the
  user runs `:Tether attractor review 01J00000000000000000000000`
- **THEN** the review shows the change to `a.txt` and reject refuses
