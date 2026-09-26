# Design

## Context

The attractor feature already parses and lints pipelines, and watches a spec run
directory. It lacked an engine. Fabro showed which engine features matter in
practice: isolated runs, a commit per stage, resume, human gates, a live view,
and a review of what a run changed.

## Goals / Non-Goals

**Goals:**

- Run pipelines with nothing but Neovim, jj or Git, and the CLI agents already
  installed.
- Reuse the existing viewer: the engine writes the spec run directory.
- Make each stage a tether turn, so review, follow, and the cockpit work
  unchanged.

**Non-Goals:**

- An HTTP server, LLM API clients, model stylesheets, context fidelity modes,
  and manager loops (`stack.manager_loop` fails as unsupported).
- Concurrent parallel branches; v1 runs branches one after another.

## Decisions

### Headless runner

`bin/tether-run` starts `nvim --headless --clean -l` on `engine/cli.lua`. The
engine is plain Lua over `tether.api` and works synchronously: a stage waits for
its process, and a human gate polls for its answer file. Neovim launches the
runner detached and watches the run directory, so closing the editor leaves the
run going.

### Modules

| Module | Role |
| --- | --- |
| `engine/init.lua` | run loop, edge selection, retries, failure routing, goal gates |
| `engine/condition.lua` | spec section 10 condition language |
| `engine/handlers.lua` | start, exit, conditional, codergen, tool, wait.human, parallel |
| `engine/agents.lua` | command templates per agent and prompt assembly |
| `engine/store.lua` | run directory, events, checkpoints |
| `engine/isolate.lua` | jj workspace or Git worktree, commit per stage |
| `engine/cli.lua` | `tether-run` commands |

### Outcomes

A codergen stage runs the agent template with the stage prompt: the node prompt
with `$goal` expanded, the previous stage's response summary, and the stage
directory. The agent may write `<stage>/status.json` with `status`,
`preferred_label`, `suggested_next_ids`, and `context_updates`; the engine reads
it after the process ends. Without one, exit 0 means `success`, and anything
else is an error that retries within `max_retries` and then fails. A tool stage
runs `tool_command` in the shell and sets `tool.output`.

### Human gates through files

A gate writes `questions/<node>-<visit>.json` with its options, derived from the
outgoing edge labels and their accelerator keys, and waits for
`answers/<same>.json`. `tether-run answer`, `:Tether attractor answer`, or any
editor writes that file. The selection becomes the outcome's
`suggested_next_ids` and the context keys `human.gate.selected` and
`human.gate.label`.

### Isolation

With `--workspace`, the engine creates jj workspace `run-<id>` next to the
repository (or Git worktree on branch `tether/run/<id>`), runs every stage
there, and commits after each stage as `pipeline(<id>): <node> (<status>)`. The
manifest records the base commit, so a review of the run is the range from the
base to the workspace head. Without it, the run works in place, and the manifest
records start and end checkpoints for the review.

### Stages as turns

Before and after each stage, the engine emits `agent-trail turn` and `stop` with
agent `pipeline` and session `<run id>`. The event log then carries each stage
as a turn with its own checkpoints.

## Risks / Trade-offs

- Synchronous stages keep the engine simple but block one runner process per
  run; that suits pipelines of long-running agents.
- Agent CLIs differ in flags; templates are configuration, not code.
