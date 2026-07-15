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

## GitHub accounts

Multiple gh logins exist; the primary is whichever account is keyring-active
in gh (currently `xkef`, which owns this repo). git and jj pushes route
through `gh auth git-credential`, so the active account is used
automatically. To run a single command as another account without touching
global state, set `GH_TOKEN` inline — the credential helper follows it, so
this routes `gh`, `git`, and `jj git push` alike:

    GH_TOKEN=$(gh auth token --user <account>) <cmd...>

Repos owned by another account may pin it for the whole directory via
mise, e.g. in `mise.local.toml`:

    [env]
    GH_TOKEN = "{{ exec(command='gh auth token --user <account>') }}"

Do not `gh auth switch` — it misroutes concurrent sessions. A stray
`GITHUB_TOKEN` in the environment pins plain `gh` to that account;
`GH_TOKEN` overrides it, or prefix with `env -u GITHUB_TOKEN`.
