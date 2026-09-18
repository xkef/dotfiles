---
name: microworld
description: Build a throwaway interactive microworld, a visualization, step-through debugger, or simulation of a system's internals, so the user can explore how it behaves. Use when the user wants to get a feel for code, to see internal state or execution step by step, or to walk through a script or migration before trusting it, or asks for a microworld.
---

# Microworld

Build a small disposable UI for understanding only. The user pokes at it
and leaves with an intuition for how the real system behaves. That
intuition, not the UI, counts as the result.

This differs from the `prototype` skill. That one explores possible
designs. This one explains existing behavior by visualizing the real
code's internals.

## Pick a mode

**Trace and scrub**, for an algorithm, interpreter, state machine, or any
code whose internal state evolves over steps:

1. Instrument the real code to dump a trace of the relevant internal
   state as JSON, one snapshot per step. Run it on a small representative
   input.
2. Generate a self-contained HTML viewer: a timeline scrubber over the
   steps that renders the state at each step. Stacks, bindings, queues,
   coordinates, whatever fits the domain. Show the current step's state
   and, where helpful, what changed since the previous step. A per-step
   notes field the user can type into often pays off.

**Do-it-yourself walkthrough**, for a script, migration, or other
one-shot process the user doesn't yet trust:

1. Break the process into ordered steps: the exact command each step
   runs and its observable effect.
2. Generate a self-contained HTML page with a Next button that steps
   through them and shows before and after state at each step: file
   trees, output, the growing result. The user gets the benefit of doing
   the process by hand at the cost of clicking a button.

## Constraints

- Everything stays ephemeral. Write viewers and traces to
  `/tmp/YYYY-MM-DD-microworld-<slug>.html` and sibling data files, never
  into the repo.
- Keep instrumentation of real code minimal and remove it after
  capturing the trace, unless the user asks to keep it.
- Self-contained HTML only: inline CSS and JS, trace data embedded in the
  file, and zero external requests.
- Tune the input, not the viewer. A small, chosen example input explains
  more than an exhaustive one.
