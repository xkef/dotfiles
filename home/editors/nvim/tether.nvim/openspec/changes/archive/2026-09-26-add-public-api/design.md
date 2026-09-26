# Design

## Context

After `refactor-layout`, features already reach the core through an `api` table;
this change defines it as a contract.

## Goals / Non-Goals

**Goals:**

- One place that lists everything an extension may call.
- Loading the API loads nothing else.

**Non-Goals:**

- Versioning the API; the plugin is pre-1.0.

## Decisions

- `tether.api` builds each group from an explicit list of function names that
  forward to the internal module on call. Adding a function to the API is a
  one-line, reviewable change.
- `require("tether").turns()` returns deep copies, so user code can't corrupt
  the turn model. `api.turns` returns the shared tables for features, which the
  documentation marks read-only.
- Notifications carry plain tables and mirror to User autocmds for users who
  prefer autocmds.

## Risks / Trade-offs

- Forwarding costs one extra call per API use, which is negligible next to the
  jj and Git processes behind most calls.
