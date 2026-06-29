# Repository instructions

## Version control

This repository uses Jujutsu (`jj`) in colocated mode. The `.jj/` directory is
part of the repo state.

- Use `jj` for status, diff, history, commit, bookmark, rebase, squash, split,
  and restore operations in this repo.
- Do not use `git status`, `git diff`, `git add`, `git commit`, `git checkout`,
  `git reset`, or `git stash` unless the user explicitly asks for a Git command
  or the operation is Git-only object inspection.
- When committing, use the `commit` skill and the `jj` skill if available.
- For mutating jj commands, specify file paths when possible so unrelated user
  changes stay out of the operation.
- Never include `.claude-notes/` or ignored local runtime/config files in a
  commit unless the user explicitly asks.

## Parallel agent workspaces

This repo ships `ai-agent` for parallel feature workers. Use it when multiple
agents need to work on this checkout concurrently.

- Spawn with `ai-agent spawn <slug> --brief "<task>"`; slugs are kebab-case.
- Each spawned agent uses sibling workspace `<repo>.agents/<slug>`, jj workspace
  `agent-<slug>`, bookmark `agent/<slug>`, and a herdr workspace labelled
  `<slug>` (its working/blocked/idle state shows in the herdr sidebar).
- `ai-agent` requires a running herdr server to spawn; `ai-agent focus <slug>`
  jumps to that agent's herdr workspace.
- Inside an agent workspace, commit selected files with jj and run `jj tug` so
  `agent/<slug>` points at the completed work before `ai-agent finish <slug>`.
- `ai-agent finish <slug>` refuses dirty or untugged work, then pushes the
  bookmark, creates a PR, forgets the workspace, removes the directory, and
  closes the herdr workspace.
- `ai-agent cleanup <slug>` only removes safe merged/deleted workspaces;
  `ai-agent cleanup --force <slug>` intentionally discards that agent workspace.
- User docs live at `ai-spawn/.local/share/ai-agent/docs/multi-agent.md`.
