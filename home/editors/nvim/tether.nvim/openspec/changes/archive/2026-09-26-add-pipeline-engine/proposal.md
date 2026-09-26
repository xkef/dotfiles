# Proposal

## Why

Watching pipelines needed an external engine, and the best one, Fabro, is a
separate Rust server with its own API. Tether already has what a pipeline engine
needs: CLI agents that do the work, jj for isolation and checkpoints, an event
log, and a review buffer. Running Attractor pipelines itself removes the
dependency and makes every stage a reviewable agent turn.

## What Changes

- A pipeline engine that follows the Attractor spec: traversal, edge selection,
  conditions, retries, failure routing, and goal gates.
- Stages run CLI agents (`claude`, `codex`, `pi`, or any configured command),
  shell tools, and human gates answered through files.
- A run directory in the spec's layout with checkpoints, so runs resume and any
  spec-aware viewer can watch them.
- Isolated runs in their own jj workspace or Git worktree, with one commit per
  stage.
- `tether-run`, a headless runner, so runs outlive the editor.
- `:Tether attractor launch` and `:Tether attractor review <run-dir>` use the
  engine; `:Tether attractor answer` answers its gates.
- **BREAKING**: the Fabro backend, `fabro:` targets, and the `attractor.fabro`
  and `attractor.fabro_url` options go away.

## Capabilities

### New Capabilities

- `pipeline-engine`: executing Attractor pipelines and managing their runs.

### Modified Capabilities

- `attractor`: human gates of engine runs, launch and review through the engine,
  and removal of the Fabro backend.

## Impact

- `lua/tether/features/attractor/internal/engine/`, `bin/tether-run`.
- Removes `internal/backend/fabro.lua`.
- Uses `jj workspace add` or `git worktree add` for isolated runs.
