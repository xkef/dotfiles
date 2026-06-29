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
