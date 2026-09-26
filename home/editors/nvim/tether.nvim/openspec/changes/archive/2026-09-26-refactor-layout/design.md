# Design

## Context

Flat modules with cross-requires: `coord` required `cockpit`, `review`, `pick`,
`send`, and `events`; `sdd` required `cockpit`, `review`, and `pick`; UI modules
required the facade.

## Goals / Non-Goals

**Goals:**

- Dependencies point one way: features to the API, UI to core, core to nothing
  above it.
- The dependency rules are checked by a test, not by review.

**Non-Goals:**

- Changing behavior or the user-facing commands.

## Decisions

### Tiers

| Tier | May require |
| --- | --- |
| `tether.core.*` | core, `tether.config` |
| `tether.ui.*` | core, ui, `tether.config` |
| `tether.features.X.*` | `tether.api`, `tether.features.X.*` |
| `tether`, `tether.api` | anything but feature internals |

No module outside a feature may require its `internal/` modules.

### Registry and bus

`core/registry` holds picker sources, cockpit sections, review header providers,
agent row fields and actions, and subcommands. The UI renders from it; features
add to it through `api.register`. Built-in sources and sections register in
`setup()` after a reset, like any other contribution.

`core/bus` carries `stop` and `conflict` notifications and mirrors them as the
`TetherTurnStop` and `TetherConflict` User autocmds.

### VCS backends

`core/vcs/init.lua` detects the repository, caches the current one per working
directory, and dispatches each call by `repo.kind` to `core/vcs/jj.lua` or
`core/vcs/git.lua`, which share `common.lua`.

## Risks / Trade-offs

- `tether.api` forwards whitelisted functions; a new core function stays
  internal until the API lists it, which is the point.
