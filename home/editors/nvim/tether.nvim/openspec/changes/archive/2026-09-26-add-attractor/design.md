# Design

## Context

- The Attractor spec (github.com/strongdm/attractor) defines the DOT subset
  (section 2), handler types by shape (2.8), lint rules (7.2), the run directory
  (5.6: `checkpoint.json`, `<node>/status.json`, `prompt.md`, `response.md`), an
  HTTP mode (9.5) and event names (9.6). It leaves wire formats open.
- Fabro (github.com/fabro-sh/fabro) documents its run directory as unstable. Its
  stable surfaces are the HTTP API, default `http://127.0.0.1:32276`, configured
  under `[cli.target]` in `~/.fabro/settings.toml`:
  - `GET /api/v1/runs/{id}/attach?after=<stream_seq>`: SSE of
    `RunStreamItem { run_id, stream_seq, kind, id, recorded_at, item }`. Petri
    items name the event at `item.record.body.event` (`visit.started`,
    `step.finished`, `run.finished`) and the node at
    `item.record.body.subject.node.name`.
  - `GET /api/v1/runs/{id}/questions`: a list of
    `{ id, text, stage, question_type, options, allow_freeform }`, each option
    `{ key, label }`.
  - `POST /api/v1/runs/{id}/questions/{qid}/answer` with `{ kind = "yes" }`,
    `{ kind = "no" }`, `{ kind = "selected", option_key }`, or
    `{ kind = "text", text }`.
  - `fabro run -d <workflow>` prints the run id; `fabro validate <file>` checks
    a workflow. Each run commits to branch `fabro/run/<id>`.

## Goals / Non-Goals

**Goals:**

- Authoring support that needs no engine.
- Live runs from any spec-conforming engine and from Fabro, through one view.

**Non-Goals:**

- Executing pipelines.
- Rendering the graph as an image.

## Decisions

### Module layout

`features/attractor/init.lua` wires commands, sources, the cockpit section, and
autocmds through `tether.api`. Everything else is internal:

| Module | Role |
| --- | --- |
| `internal/dot.lua` | tokenizer and parser, BFS order, handler types |
| `internal/lint.lua` | spec rules |
| `internal/outline.lua` | outline buffer |
| `internal/http.lua` | `curl` GET, POST, and SSE line parsing |
| `internal/backend/spec.lua` | run directory and spec HTTP mode |
| `internal/backend/fabro.lua` | Fabro API, stream resume, launch, validate |
| `internal/run.lua` | the active run: backend, node statuses, questions |
| `internal/view.lua` | virtual text on node lines |

### Backend interface

A backend implements `start(run, emit) -> stop`, `questions(run, cb)`,
`answer(run, question, choice, cb)`, and optionally `stage_files(run, node)`.
`emit` receives normalized updates `{ node, status }` with status one of
`running`, `success`, `fail`, `retry`, `partial`, `skipped`, `waiting`, plus
`{ done = message }`. Questions normalize to `{ id, text, kind = yes_no |
choice | text, options = [{ key, label }] }` and choices to `{ kind, key,
label, text }`. Each backend translates both ways, so the view and the commands
never see a wire format.

### Graph rules

Edge statements declare their endpoints as nodes, as in Graphviz, so
`edge_target_exists` never fires and is not implemented. `type_known` accepts
Fabro's handler names, and the shape table includes Fabro's `tab` (prompt) and
`insulator` (wait).

### Fabro stream

The stream resumes after a dropped connection with `after=<last stream_seq>`,
drops duplicate item ids, and stops reconnecting after `run.finished`. A
`visit.started` on a human-gate node marks it `waiting` and fetches its
questions.

### Fabro run review

`:Tether attractor review <run>` opens a read-only review of the range from the
run's base to branch `fabro/run/<id>`, through a new `range` scope in core.

## Risks / Trade-offs

- Spec HTTP payloads vary between engines; tolerant field lookup covers the
  common names, and the run directory stays the reliable spec path.
- Fabro's petri event names may change; the mapping lives in one function.
