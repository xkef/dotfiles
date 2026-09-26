# Tasks

## 1. Writer

- [x] 1.1 `agent-trail claim` and `agent-trail release`
- [x] 1.2 Tests: claim a glob

## 2. Claims and conflicts

- [x] 2.1 `tether.coord`: implicit and explicit claims from events, TTL, pane
      liveness
- [x] 2.2 Buffer markers, `claims` picker source
- [x] 2.3 Conflict checks and `User TetherConflict`
- [x] 2.4 Tests: claim during a turn, claim expires, claim ends when the pane
      closes, claim ends with the turn, glob claim, release, marker on a claimed
      buffer, two agents on one file, editing a claimed file, agent writes under
      unsaved edits

## 3. Workspaces

- [x] 3.1 Workspace map and cockpit row fields
- [x] 3.2 Add-workspace and review-workspace actions
- [x] 3.3 Read-only `:Tether review workspace <name>`
- [x] 3.4 Tests: agent in a second workspace, agent row, workspace on the row,
      review a workspace against trunk, reject refuses in a workspace review
