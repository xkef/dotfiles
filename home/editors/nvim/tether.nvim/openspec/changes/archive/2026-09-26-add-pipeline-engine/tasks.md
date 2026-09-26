# Tasks

## 1. Engine

- [x] 1.1 Condition language and edge selection
- [x] 1.2 Run loop with retries, failure routing, goal gates, visit limit
- [x] 1.3 Handlers: start, exit, conditional, codergen, tool, wait.human,
      parallel and fan-in in sequence
- [x] 1.4 Agent templates and prompt assembly with the status-file contract
- [x] 1.5 Run directory, events, checkpoints, resume
- [x] 1.6 Isolation: jj workspace or Git worktree, commit per stage
- [x] 1.7 Stage turn and stop events through `agent-trail`
- [x] 1.8 `tether-run` CLI: start, resume, answer, status
- [x] 1.9 Tests: linear run completes, preferred label picks the edge, condition
      routes on outcome, failure retries then takes the retry target, goal gate
      blocks exit, agent receives the prompt, tool exit code sets the outcome,
      answer file resumes the run, resume skips completed nodes, commit per
      stage in a workspace, stage turns appear in tether

## 2. Neovim

- [x] 2.1 Directory backend: pending questions, waiting status, answer files
- [x] 2.2 Launch and review commands on the engine
- [x] 2.3 Remove the Fabro backend, options, and docs
- [x] 2.4 Tests: pending question marks the gate, answer an engine gate from
      Neovim, launch attaches the run, review a workspace run
- [x] 2.5 README and vimdoc
