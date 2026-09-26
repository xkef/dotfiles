# Proposal

## Why

StrongDM's Attractor defines agent pipelines as Graphviz DOT files: stages for
LLM work, tools, conditions, parallel branches, and human gates. Several engines
implement the spec, but no editor supports writing these files or watching a
run, and human gates need a web page or a console.

## What Changes

- A parser for Attractor's DOT subset with line positions.
- Lint diagnostics for `.dot` files following the spec's built-in rules.
- Picker source `nodes` and an outline buffer of the pipeline flow.
- A run view that shows each node's status as virtual text, from a run directory
  on disk or from an engine's HTTP event stream.
- Answering human-gate questions from Neovim.
- Command `:Tether attractor lint|outline|run <dir-or-url>|answer`.

## Capabilities

### New Capabilities

- `attractor`: DOT parsing, lint, navigation, run view, and human gates.

### Modified Capabilities

None.

## Impact

- `lua/tether/attractor/` modules and a picker source.
- Optional external command: `curl` for the HTTP mode.
