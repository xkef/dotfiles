# Proposal

## Why

StrongDM's Attractor defines agent pipelines as Graphviz DOT files: stages for
LLM work, tools, conditions, parallel branches, and human gates. Fabro is the
most complete engine: it runs `.fabro` workflows, serves an HTTP API with a live
event stream, asks human gates over that API, and commits each stage to a
`fabro/run/<id>` branch. No editor supports writing these files, watching a run,
or answering a gate; Fabro's own answer is a web page or a terminal prompt.

## What Changes

- A parser for Attractor's DOT subset and Fabro's extensions, with line
  positions, for `.dot`, `.gv`, and `.fabro` files.
- Lint diagnostics from the spec's rules, plus `fabro validate` when installed.
- Picker source `nodes` and an outline buffer of the pipeline flow.
- Live runs through backends behind one interface: the generic spec (run
  directory or HTTP server) and Fabro (HTTP API and event stream).
- Node status as virtual text on node lines and a Pipeline section in the
  cockpit.
- Answering human gates from Neovim.
- Launching a Fabro workflow from its buffer, and reviewing a Fabro run's branch
  in the review buffer.
- Commands:
  `:Tether attractor lint|outline|nodes|run|launch|answer|stop|review`.

## Capabilities

### New Capabilities

- `attractor`: DOT parsing, lint, navigation, run backends, human gates, and
  Fabro integration.

### Modified Capabilities

None.

## Impact

- `lua/tether/features/attractor/` with `internal/` modules; built only on
  `tether.api`.
- A `range` review scope in core for read-only reviews between two revisions.
- Optional external commands: `curl`, `fabro`.
