# Spec Delta

## Purpose

Execute StrongDM Attractor pipelines with CLI agents, shell tools, and human
gates, in isolated and resumable runs whose stages tether can review.

## ADDED Requirements

### Requirement: Traversal and edge selection

The engine SHALL start at the start node, execute each node, record its outcome
in the checkpoint, and select the next edge by the spec's order: matching
conditions, then the preferred label, then suggested next ids, then the highest
weight, then the lexically first target. It SHALL finish with success at the
exit node.

#### Scenario: Linear run completes

- **WHEN** `tether-run start` runs `start -> plan -> implement -> exit` with an
  agent that exits 0
- **THEN** the run finishes with success and the checkpoint lists plan and
  implement as completed with success

#### Scenario: Preferred label picks the edge

- **WHEN** a stage's agent writes `status.json` with preferred label `Fix` and
  the stage has edges labeled `Ship` and `Fix`
- **THEN** the run continues along the `Fix` edge

### Requirement: Conditions

Edge conditions SHALL follow the spec's language: clauses joined by `&&`,
operators `=` and `!=`, and the keys `outcome`, `preferred_label`, and
`context.<key>`.

#### Scenario: Condition routes on outcome

- **WHEN** a conditional node follows a failed tool stage and has edges with
  `condition="outcome=success"` and `condition="outcome!=success"`
- **THEN** the run takes the `outcome!=success` edge

### Requirement: Retries and failure routing

A stage whose process fails SHALL run again up to `max_retries` more times.
After that, the engine SHALL follow an `outcome=fail` edge, else the node's
`retry_target`, else `fallback_retry_target`, else end the run with failure.

#### Scenario: Failure retries then takes the retry target

- **WHEN** a stage with `max_retries=2` and `retry_target=recover` fails every
  time
- **THEN** its agent runs three times and the run continues at `recover`

### Requirement: Goal gates

At the exit node, the engine SHALL send the run to the retry target of any
visited goal-gate node whose outcome was not success, and SHALL fail the run
when no retry target exists.

#### Scenario: Goal gate blocks exit

- **WHEN** a goal-gate stage fails on its first visit, has `retry_target=fix`,
  and succeeds on its second visit
- **THEN** the run visits `fix`, runs the gate again, and finishes with success

### Requirement: Agent and tool stages

Codergen stages SHALL run the configured agent command with the stage prompt,
and SHALL take their outcome from `<stage>/status.json` when the agent wrote
one, else from the exit code. Tool stages SHALL run `tool_command` in the shell
and fail on a non-zero exit code.

#### Scenario: Agent receives the prompt

- **WHEN** a stage has `prompt="Plan $goal"` and the run's goal is `a parser`
- **THEN** the agent command receives a prompt containing `Plan a parser`

#### Scenario: Tool exit code sets the outcome

- **WHEN** a tool stage runs `tool_command="exit 3"`
- **THEN** the stage's status is fail

### Requirement: Human gates through files

A human gate SHALL write its question with the options derived from its outgoing
edges to `questions/<id>.json` and wait for `answers/<id>.json`, then continue
along the chosen option's edge.

#### Scenario: Answer file resumes the run

- **WHEN** a run waits at a gate with options `[A] Approve` and `[F] Fix` and
  `tether-run answer` selects `A`
- **THEN** the run continues along the `[A] Approve` edge

### Requirement: Run directory and resume

The engine SHALL write the spec's run directory: `manifest.json`,
`checkpoint.json` after every node, and `<node>/prompt.md`, `response.md`, and
`status.json`. `tether-run resume` SHALL continue a stopped run from its
checkpoint without running completed nodes again.

#### Scenario: Resume skips completed nodes

- **WHEN** a run stopped after `plan` and `tether-run resume` runs it
- **THEN** the plan agent does not run again and the run finishes

### Requirement: Isolated runs

With `--workspace`, the engine SHALL run in a new jj workspace, or a Git
worktree on branch `tether/run/<id>`, and SHALL commit after every stage.

#### Scenario: Commit per stage in a workspace

- **WHEN** a jj run with `--workspace` executes two stages that each change a
  file
- **THEN** the workspace history holds two `pipeline(<id>)` commits and the main
  working copy is unchanged

### Requirement: Stages as turns

The engine SHALL emit a `turn` event before and a `stop` event after every
stage, with agent `pipeline` and the run id as session.

#### Scenario: Stage turns appear in tether

- **WHEN** a run with two stages finishes in the current repository
- **THEN** `require("tether").turns()` lists two pipeline turns
