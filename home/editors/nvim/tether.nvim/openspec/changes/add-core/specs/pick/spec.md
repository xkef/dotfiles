# Spec Delta

## Purpose

Offer one picker entry point over everything the plugin knows, with sources that
other capabilities can extend.

## ADDED Requirements

### Requirement: Entry point

`:Tether pick` without an argument SHALL let the user choose a source, and
`:Tether pick <source>` SHALL open that source directly. Modules SHALL be able
to register further sources.

#### Scenario: Registered source

- **WHEN** a module registers a source named `demo`
- **THEN** `:Tether pick demo` opens it and `:Tether pick` lists it

### Requirement: Built-in sources

The plugin SHALL provide the sources `changed` (files of the latest turn with a
diff preview), `trail` (recent edits and reads, newest first), `turns` (turns of
the root, opening their review), and `hunks` (unreviewed hunks, opening the file
at the hunk).

#### Scenario: Trail order

- **WHEN** an agent edited `a.lua` and then `b.lua`
- **THEN** the `trail` source lists `b.lua` before `a.lua`

#### Scenario: Turn opens its review

- **WHEN** the user selects a turn in the `turns` source
- **THEN** the review buffer opens for that turn

### Requirement: Picker backends

The plugin SHALL use snacks.nvim when it is loadable and `vim.ui.select`
otherwise, with the same items and actions.

#### Scenario: Without snacks

- **WHEN** snacks.nvim is not installed and the user opens a source
- **THEN** `vim.ui.select` receives the source's items
