# Tasks

## 1. Event log

- [x] 1.1 `agent-trail` writer with record format, subcommands, rotation, and
      checkpoints (`bin/agent-trail`)
- [x] 1.2 Claude Code hook mode (`agent-trail hook claude`) and hook
      registration
- [x] 1.3 pi extension (`extras/pi/agent-trail.ts`) emitting `turn`, `edit`,
      `read`, `stop`
- [x] 1.4 `tether.events`: parse, tail with offset, rotation reset, replay,
      subscribers
- [x] 1.5 Tests: record format, value with a tab, log path, Claude hook input,
      prompt starts a turn, oversized log, appended event, rotation while
      running, turns survive a restart

## 2. VCS and turns

- [x] 2.1 `tether.vcs`: root detection, jj and Git backends, async runner,
      checkpoint, resolve, diff, file show, restore
- [x] 2.2 `tether.diff`: unified diff parser into files and hunks with hashes
- [x] 2.3 `tether.turns`: turn model from events, scopes, manual checkpoint,
      undo
- [x] 2.4 Tests: jj checkpoint, Git checkpoint, running and finished turns,
      other repositories ignored, diff of a finished jj turn, review since
      checkpoint, undo restores touched files only

## 3. Review

- [x] 3.1 Review buffer rendering, summary lines, folds, diff highlighting
- [x] 3.2 Hunk navigation, accept with persistence, reject with stale check
- [x] 3.3 Comments with virtual lines and `:Tether comment`
- [x] 3.4 Side-by-side diff (built-in diff tab), quickfix export, key help
- [x] 3.5 Tests: latest turn by default, empty scope, skip reviewed hunks,
      accepted hunk stays accepted, reject restores old lines, reject after
      further edits, comment anchored to the new line number, built-in diff tab,
      hunks to quickfix, key help

## 4. Follow

- [x] 4.1 Reload on edit, follow window, changed-line detection, flash
- [x] 4.2 Deferral during insert and command-line mode, `show` events, stop
      notification, status component
- [x] 4.3 Tests: buffer reloads, unsaved changes are kept, jump to the changed
      line, line from the event, deferred during insert, agent points at code,
      turn finished, idle editor

## 5. Pick and send

- [x] 5.1 Picker adapter (snacks.nvim, `vim.ui.select`) and source registry
- [x] 5.2 Sources `changed`, `trail`, `turns`, `hunks`
- [x] 5.3 Send: target resolution, WezTerm delivery, context-aware payloads
- [x] 5.4 Tests: registered source, trail order, turn opens its review, without
      snacks, one agent, no agent, paste without submit, batched comments,
      visual selection

## 6. Cockpit

- [x] 6.1 Sidebar with section providers, collapse, refresh timer, key help
- [x] 6.2 Agents, Turn, and Trail sections with actions
- [x] 6.3 Tests: toggle, empty sections hidden, agent row, changed file row,
      open from the trail

## 7. Integration

- [x] 7.1 `setup()`, `:Tether` command with completion, `<leader>a` keys,
      highlight groups, `:checkhealth tether`
- [x] 7.2 `doc/tether.txt` and README
- [x] 7.3 Host dotfiles: `agentic` config, `anvim`, LazyVim spec, Dotter links,
      AGENTS.md convention for `agent-trail show`
