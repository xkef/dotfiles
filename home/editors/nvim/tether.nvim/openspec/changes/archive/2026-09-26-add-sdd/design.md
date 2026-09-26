# Design

## Context

OpenSpec 1.x stores capability specs in `openspec/specs/<path>/spec.md` and
changes in `openspec/changes/<id>/` with `proposal.md`, `design.md`, `tasks.md`,
and delta specs under `specs/`. Archived changes move to `changes/archive/`.
Requirements are `### Requirement:` headings with `#### Scenario:` children;
tasks are `- [ ] 1.1 text` lines under `## N.` groups.

## Goals / Non-Goals

**Goals:**

- Useful without the OpenSpec CLI and without any agent integration.
- Zero cost in projects without `openspec/`.

**Non-Goals:**

- Generating specs or proposals; agents and the `/opsx:` commands do that.
- Archiving changes from the editor.

## Decisions

### Own parser

A line-based parser returns, per spec, the purpose and requirements with their
scenarios and line numbers; per change, the proposal sections, the tasks with
id, text, done flag, and line, and the delta requirements grouped by operation.
Parsing runs on demand and caches by file modification time.

### Diagnostics

On `BufWritePost` for files under `openspec/`, the plugin runs
`openspec validate <item> --strict --json` in the tree's parent directory when
the executable exists and maps its issues to `vim.diagnostic`. Otherwise it
checks that each requirement has a scenario, that scenarios use four hashes, and
that requirement text contains SHALL or MUST.

### Task board

The Tasks section lists active changes (not archived) with done and total counts
and, when expanded, their tasks. `x` rewrites the checkbox on disk and in a
loaded buffer. `s` sends the task through the send capability using the
`sdd.send_template` string with `{change}`, `{id}`, and `{text}` placeholders.

### Traceability

When a turn's diff touches files under `openspec/changes/<id>/`, the turn is
linked to change `<id>`. Tasks whose checkbox went from unchecked to checked
within the turn diff are attributed to that turn and agent. The review header
and the Tasks section show both.

## Risks / Trade-offs

- The parser follows OpenSpec 1.x conventions; format changes upstream need
  parser updates. The CLI path stays authoritative when installed.
