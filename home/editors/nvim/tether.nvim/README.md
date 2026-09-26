# Tether

`tether.nvim` reviews, follows, and steers the command-line coding agents that
work next to Neovim.

Claude Code, pi, Codex, and other agents run in their own terminal panes. tether
shows in Neovim which turn changed which lines and where an agent edits right
now. It sends review comments back into the agent's prompt without copy and
paste.

- **Turns as the unit of review.** Every agent prompt starts a turn, and every
  turn start and end records a jj operation or Git commit. A review shows
  exactly what one turn changed, including edits the agent made through shell
  commands.
- **Review buffer.** One buffer lists all hunks of a turn. Accept or reject each
  hunk, comment on lines, and open a side-by-side diff.
- **Follow mode.** A window jumps to each edit as the agent makes it and
  highlights the changed lines. It waits while you type.
- **Send.** Batched review comments, selections, and file references go to the
  agent's pane through `wezterm cli`.
- **Cockpit.** One panel shows agents, the current turn, and recent edits.

It works with any agent that can run a command. It supports jj and Git, and it
runs with or without a Neovim distribution.

## Requirements

- Neovim 0.11 or later.
- `jj` or `git`.
- Optional: [snacks.nvim](https://github.com/folke/snacks.nvim) for pickers, and
  [WezTerm](https://wezterm.org) for sending text to agent panes.
- `agent-state list` from the host dotfiles lists live agents for the cockpit
  and for send. Without it, send copies to the clipboard.

## Install

With lazy.nvim:

```lua
{ "xkef/tether.nvim", event = "VeryLazy", cmd = "Tether", opts = {} }
```

With `vim.pack`:

```lua
vim.pack.add({ "https://github.com/xkef/tether.nvim" })
require("tether").setup({})
```

Put `bin/agent-trail` on `PATH`. Agents call it to report what they do.

### Connect the agents

Claude Code: add the hook to `~/.claude/settings.json` for the events
`PostToolUse` (matcher `Edit|Write|MultiEdit|NotebookEdit|Read`),
`UserPromptSubmit`, `Stop`, and `SessionEnd`:

```json
{ "type": "command", "command": "~/.local/bin/agent-trail hook claude" }
```

pi: link `extras/pi/agent-trail.ts` into `~/.pi/agent/extensions/`.

Any other agent or script:

```sh
agent-trail turn codex "summary of the prompt"
agent-trail edit codex src/parser.lua 42
agent-trail stop codex
```

Agents can point you at code with `agent-trail show <path> [line]`.

## Use

| Key          | Command              | Action                                      |
| ------------ | -------------------- | ------------------------------------------- |
| `<leader>aa` | `:Tether cockpit`    | Toggle the cockpit panel                    |
| `<leader>ar` | `:Tether review`     | Review the last turn                        |
| `<leader>af` | `:Tether follow`     | Toggle follow mode                          |
| `<leader>ap` | `:Tether pick`       | Pick from changed files, trail, turns       |
| `<leader>as` | `:Tether send`       | Send comments, selection, or file           |
| `<leader>au` | `:Tether undo`       | Restore the files of the last turn          |
|              | `:Tether checkpoint` | Mark a base for `:Tether review checkpoint` |
|              | `:Tether comment`    | Comment on the cursor line                  |
|              | `:Tether hunks`      | Unreviewed hunks to the quickfix list       |

`:Tether review` takes a scope: `turn` for the last turn by default, `change`
for the working-copy change, `checkpoint`, or `since` for everything after the
last turn started.

In the review buffer, `a` accepts a hunk, `x` undoes it in the working file, `A`
and `X` act for the whole file, `]h` and `[h` move between unreviewed hunks, `c`
adds a comment, and `<CR>` opens a side-by-side diff. `g?` lists all keys in the
review buffer and in the cockpit.

`require("tether").status()` returns a short string for statuslines.

## Configure

`setup()` takes these defaults:

```lua
{
  log_file = nil, -- $XDG_STATE_HOME/agents/trail.log
  agent_state = "agent-state",
  prefix = "<leader>a", -- false disables the keys
  follow = { enabled = false, flash_ms = 800, reads = false },
  review = { keep_days = 30 },
  send = { wezterm = "wezterm", submit = false },
  cockpit = { side = "right", width = 46, interval = 2000, trail = 8 },
  notify_stop = true,
}
```

## How it works

`agent-trail` appends one tab-separated line per event to
`$XDG_STATE_HOME/agents/trail.log`. The `turn` and `stop` events carry a
checkpoint: the current jj operation ID, or a Git commit from
`git stash create`. tether tails the file, rebuilds turns from it on start, and
diffs a turn between its two checkpoints. jj queries for the UI run with
`--ignore-working-copy`, so tether doesn't add operations to the log. Reviewed
hunks persist by content hash in `stdpath("state")/tether/reviewed.json`.

## Develop

The plugin grows spec-first with
[OpenSpec](https://github.com/Fission-AI/OpenSpec). `openspec/specs/` holds the
current behavior, and `openspec/changes/` holds the work in progress. See
`AGENTS.md` for the workflow.

Run the tests, one per spec scenario, with `tests/run.sh`. They need `nvim`,
`jj`, and `git`.
