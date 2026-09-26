# Proposal

## Why

Features and user configuration need a stable surface to build on: adding a
picker source, a cockpit section, a review header, or a subcommand, and reacting
to finished turns. Without one, extensions depend on internal modules that
change with every refactor.

## What Changes

- `require("tether.api")`: registration functions, notifications, and
  whitelisted read-only access to turns, agents, review state, VCS, diffs, and
  utilities.
- `require("tether")` gains `turns()`, which returns copies, `on()`, and
  `register`, both forwarding to the API.
- `:Tether` runs subcommands that extensions register.
- `doc/tether.txt` documents every public function, checked by a test.

## Capabilities

### New Capabilities

- `api`: the public facade and the extension API.

### Modified Capabilities

None.

## Impact

- `lua/tether/api.lua`, `lua/tether/types.lua`, `lua/tether/init.lua`,
  `doc/tether.txt`.
