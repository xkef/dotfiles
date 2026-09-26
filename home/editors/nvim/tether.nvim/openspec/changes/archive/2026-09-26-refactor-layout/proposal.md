# Proposal

## Why

The first three changes grew nineteen flat modules. Features reached into core
internals: coordination appended to cockpit tables, SDD pushed review header
providers, and every module required the facade for the repository. Before the
plugin moves to its own repository and gains more features, the code needs tiers
that make those dependencies impossible.

## What Changes

- Three tiers: `tether.core` (state and services, no UI), `tether.ui` (review,
  cockpit, follow, pick, send), and `tether.features.<name>` with an `internal/`
  directory each.
- A registry in core for UI contributions and a bus for notifications, so the UI
  reads contributions instead of features writing into UI modules.
- The VCS layer splits into jj and Git backends behind one interface.
- Review state moves from the review buffer into `core/store`.
- A layering test fails on any dependency that crosses the tiers.
- No behavior changes; the existing tests stay as they are.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None.

## Impact

- Every module path under `lua/tether/` except `init.lua`, `config.lua`, and
  `health.lua`.
