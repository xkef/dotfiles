# Spec Delta

## ADDED Requirements

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

## REMOVED Requirements

### Requirement: Fabro launch and review

**Reason**: tether runs pipelines itself; the Fabro backend is gone.

**Migration**: use `:Tether attractor launch` and
`:Tether attractor review <run-dir>` with the built-in engine.

### Requirement: Run view

**Reason**: replaced by "Run status", which drops the Fabro scenarios.

**Migration**: attach engine runs by their run directory.

### Requirement: Human gates

**Reason**: replaced by "Gate answers", which answers engine gates through
answer files instead of the Fabro API.

**Migration**: `:Tether attractor answer` works the same for engine runs.
