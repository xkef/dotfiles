# api Specification

## Purpose

Give features and user configuration a documented, stable surface for extending
tether and reading its state, separate from internal modules.

## Requirements

### Requirement: Registration

`require("tether.api").register` SHALL let callers add picker sources, cockpit
sections, review header lines, agent row fields and actions, and `:Tether`
subcommands, and the UI SHALL render them without the caller touching UI
modules.

#### Scenario: Register a picker source

- **WHEN** a caller registers a source named `demo`
- **THEN** `:Tether pick demo` opens it

#### Scenario: Register a cockpit section

- **WHEN** a caller registers a section `Notes` whose rows return one row
- **THEN** the cockpit shows a `Notes` header with that row

#### Scenario: Register a review header

- **WHEN** a caller registers a review header that returns `extra line`
- **THEN** the review buffer header contains `extra line`

#### Scenario: Register a command

- **WHEN** a caller registers command `hello`
- **THEN** `:Tether hello a b` calls it with the arguments `a` and `b`, and
  completion after `:Tether` offers `hello`

### Requirement: Notifications

`api.on(name, fn)` SHALL deliver `event` for every event-log record, `stop` for
every finished turn in the current repository as `{ turn, files }`, and
`conflict` for coordination warnings, and SHALL return a function that
unsubscribes.

#### Scenario: Subscribe to finished turns

- **WHEN** a caller subscribes to `stop` and an agent's turn ends
- **THEN** the callback receives the turn and its changed files

#### Scenario: Unsubscribe

- **WHEN** the caller calls the returned function and another turn ends
- **THEN** the callback does not run again

### Requirement: Read-only state

`require("tether").turns()` SHALL return copies of the current repository's
turns, newest first, so that modifying them leaves tether's state unchanged.

#### Scenario: Turn snapshots are copies

- **WHEN** a caller changes the summary of a turn returned by `turns()`
- **THEN** the next call returns the original summary

### Requirement: Layering

Feature modules SHALL require only `tether.api` and their own modules, core
modules SHALL NOT require UI or feature modules, UI modules SHALL NOT require
feature modules, and no module SHALL require another feature's internal modules.
Every public function SHALL appear in `doc/tether.txt`.

#### Scenario: Features stay behind the API

- **WHEN** the layering test scans the requires of every module
- **THEN** it finds no dependency that crosses the tiers

#### Scenario: Every public function is documented

- **WHEN** the test lists the functions of `tether` and `tether.api`
- **THEN** each name appears in `doc/tether.txt`
