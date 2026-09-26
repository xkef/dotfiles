# Tasks

## 1. Event log

- [ ] 1.1 `agent-trail` writer with record format, subcommands, rotation, and
      checkpoints (host dotfiles `home/bin/agent-trail`)
- [ ] 1.2 Claude Code hook mode (`agent-trail hook claude`) and hook
      registration
- [ ] 1.3 pi extension emitting `turn`, `edit`, `read`, `stop`
- [ ] 1.4 `tether.events`: parse, tail with offset, rotation reset, replay,
      subscribers
- [ ] 1.5 Tests: record format, value with a tab, log path, Claude hook input,
      prompt starts a turn, oversized log, appended event, rotation while
      running, turns survive a restart

## 2. VCS and turns

- [ ] 2.1 `tether.vcs`: root detection, jj and Git backends, async runner,
      checkpoint, resolve, diff, file show, restore
- [ ] 2.2 `tether.diff`: unified diff parser into files and hunks with hashes
- [ ] 2.3 `tether.turns`: turn model from events, scopes, manual checkpoint,
      undo
- [ ] 2.4 Tests: jj checkpoint, Git checkpoint, running and finished turns,
      other repositories ignored, diff of a finished jj turn, review since
      checkpoint, undo restores touched files only

## 3. Review

- [ ] 3.1 Review buffer rendering, summary lines, folds, diff highlighting
- [ ] 3.2 Hunk navigation, accept with persistence, reject with stale check
- [ ] 3.3 Comments with virtual lines and `:Tether comment`
- [ ] 3.4 Side-by-side diff (codediff.nvim or built-in tab), quickfix export,
      key help
- [ ] 3.5 Tests: latest turn by default, empty scope, skip reviewed hunks,
      accepted hunk stays accepted, reject restores old lines, reject after
      further edits, comment anchored to the new line number, built-in diff tab,
      hunks to quickfix, key help

## 4. Follow

- [ ] 4.1 Reload on edit, follow window, changed-line detection, flash
- [ ] 4.2 Deferral during insert and command-line mode, `show` events, stop
      notification, status component
- [ ] 4.3 Tests: buffer reloads, unsaved changes are kept, jump to the changed
      line, line from the event, deferred during insert, agent points at code,
      turn finished, idle editor

## 5. Pick and send

- [ ] 5.1 Picker adapter (snacks.nvim, `vim.ui.select`) and source registry
- [ ] 5.2 Sources `changed`, `trail`, `turns`, `hunks`
- [ ] 5.3 Send: target resolution, WezTerm delivery, context-aware payloads
- [ ] 5.4 Tests: registered source, trail order, turn opens its review, without
      snacks, one agent, no agent, paste without submit, batched comments,
      visual selection

## 6. Cockpit

- [ ] 6.1 Sidebar with section providers, collapse, refresh timer, key help
- [ ] 6.2 Agents, Turn, and Trail sections with actions
- [ ] 6.3 Tests: toggle, empty sections hidden, agent row, changed file row,
      open from the trail

## 7. Integration

- [ ] 7.1 `setup()`, `:Tether` command with completion, `<leader>a` keys,
      highlight groups, `:checkhealth tether`
- [ ] 7.2 `doc/tether.txt` and README
- [ ] 7.3 Host dotfiles: `agentic` config, `anvim`, LazyVim spec, Dotter links,
      AGENTS.md convention for `agent-trail show`
