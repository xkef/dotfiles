---
name: microworld
description: Build a throwaway interactive micro-world — a visualization, step-through debugger, or simulation of a system's actual internals — so the user can build intuition by exploring it. Use when the user wants to "get a feel for" code, visualize internal state or execution step by step, or walk through a script/migration before trusting it.
---

# Microworld

Build a small disposable UI whose only purpose is understanding: the
user inhabits it, pokes at it, and comes away with intuition for how
the real system behaves. The point is not software to ship — it is
the change in the user's head.

Not the `prototype` skill: that explores possible *designs*; this
explains *existing behavior* by visualizing the real code's internals.

## Pick a mode

**Trace-and-scrub** — for understanding an algorithm, interpreter,
state machine, or any code whose internal state evolves over steps:

1. Instrument the real code to dump a step-by-step trace of the
   relevant internal state as JSON (one snapshot per step). Run it on
   a small representative input.
2. Generate a self-contained HTML viewer: a timeline scrubber over the
   steps, rendering the state at each step visually (stacks, bindings,
   queues, coordinates — whatever the domain is). Show the current
   step's state, and where helpful, what changed since the previous
   step. A per-step notes field the user can type into is often worth
   including.

**Do-it-yourself walkthrough** — for a script, migration, or other
one-shot process the user doesn't yet trust:

1. Break the process into ordered steps: the exact command each step
   runs and its observable effect.
2. Generate a self-contained HTML page with a Next button that steps
   through them, showing before/after state at each step (file trees,
   output, the growing result). The user gets the benefit of doing the
   process by hand at the cost of clicking a button.

## Constraints

- Everything is ephemeral. Write viewers and traces to
  `/tmp/YYYY-MM-DD-microworld-<slug>.html` (and sibling data files),
  never into the repo.
- Instrumentation added to real code is temporary: keep it minimal,
  and revert it once the trace is captured, unless the user asks to
  keep it.
- Self-contained HTML only — inline CSS/JS, trace data embedded in the
  file, no external requests.
- Tune the input, not the viewer: a small, carefully chosen example
  input teaches more than an exhaustive one.
