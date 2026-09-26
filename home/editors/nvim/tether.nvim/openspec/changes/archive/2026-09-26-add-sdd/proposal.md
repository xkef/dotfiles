# Proposal

## Why

Spec-driven development gives agents a written contract: requirements with
scenarios, and a task list per change. OpenSpec keeps these as Markdown in
`openspec/`. Working that way from Neovim today means reading raw files,
checking boxes by hand, and copying task text into the agent's prompt, with no
link between an agent turn and the task it worked on.

## What Changes

- Detection of an `openspec/` tree in the working directory, its parents, or the
  repository root; every feature below stays inactive without one.
- A parser for specs and changes that needs no OpenSpec CLI.
- Diagnostics on save, from `openspec validate` when installed and from built-in
  checks otherwise.
- Picker sources `specs`, `requirements`, and `changes`.
- A Tasks section in the cockpit with progress per change, checkbox toggling,
  and sending a task to an agent.
- Traceability: turns are linked to the change they worked on, and task
  check-offs are attributed to the turn that made them.

## Capabilities

### New Capabilities

- `sdd`: OpenSpec parsing, diagnostics, navigation, task board, and
  traceability.

### Modified Capabilities

None.

## Impact

- `lua/tether/sdd/` modules, a cockpit section provider, picker sources.
- Optional external command: `openspec`.
