# Design

## Context

The Attractor spec (github.com/strongdm/attractor, `attractor-spec.md`) defines
a DOT subset (section 2), node handlers selected by `shape` or `type` (2.8),
lint rules (7.2), the run directory layout (5.6: `checkpoint.json`,
`manifest.json`, `<node>/status.json`, `prompt.md`, `response.md`), an HTTP
server mode (9.5) with an SSE event stream, and typed events (9.6). The spec
leaves the HTTP wire format open.

## Goals / Non-Goals

**Goals:**

- Authoring support that needs no engine.
- Live run status from any conforming engine that writes the run directory.

**Non-Goals:**

- Executing pipelines.
- Rendering the graph as an image.

## Decisions

### Parser

A tokenizer strips `//` and `/* */` comments and yields identifiers, quoted
strings, `->`, brackets, braces, `=`, `,`, and `;` with line numbers. The parser
handles graph attributes (`graph [..]` and `key = value`), `node` and `edge`
defaults with subgraph scoping, node statements, and chained edges. Nodes record
their first definition line, attributes after defaults, and their handler type
from `type` or the shape table.

### Lint

Rules: `start_node`, `terminal_node`, `edge_target_exists`, `reachability`,
`start_no_incoming`, `exit_no_outgoing`, `retry_target_exists`,
`goal_gate_has_retry`, `prompt_on_llm_nodes`, `fidelity_valid`, and
`type_known`, with the spec's severities. Condition and stylesheet syntax rules
are out of scope for now.

### Run view

For a directory, the view reads `checkpoint.json` (`completed_nodes`,
`current_node`) and each `<node>/status.json` (`status`), watches the directory,
and draws `✓ SUCCESS`, `✗ FAIL`, `… running` and similar as virtual text on node
definition lines. For a URL, `curl -sN <url>/pipelines/<id>/events` streams SSE;
each `data:` line is parsed as JSON and read tolerantly: the event name from
`type`, `event`, or `kind`, the node from `node_id`, `stage`, or `name`.

### Human gates

`:Tether attractor answer` fetches `<url>/pipelines/<id>/questions`, shows the
first pending question with `vim.ui.select` for options or yes/no and
`vim.ui.input` for free text, and posts `{"value": ..., "text": ...}` to
`.../questions/<qid>/answer`.

## Risks / Trade-offs

- HTTP payload shapes vary between engines; tolerant field lookup covers the
  common names, and the file mode stays the reliable path.
