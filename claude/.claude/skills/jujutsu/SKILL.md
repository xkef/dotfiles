---
name: jujutsu
description: How to use `jj`, the Jujutsu version control system
---

# Jujutsu (`jj`)

Jujutsu is a Git-compatible VCS used in "colocated" form (a `.jj` directory alongside `.git`). The presence of `.jj` indicates a jj repository. You can still use Git commands to examine objects (`git show`, `git log`, `git grep`), but use `jj` for creating commits.

## Key concept: no staging area

Any `jj` command automatically snapshots the working directory. `jj` respects `.gitignore`. To stop tracking an unintentionally included file, modify `.gitignore` then run `jj file untrack <file>...`.

Be careful with any `jj` command that creates or modifies a change. Always specify files explicitly.

## Common commands

| Command     | Description                                               |
| ----------- | --------------------------------------------------------- |
| `jj st`     | Show summary of working copy changes                      |
| `jj diff`   | Show diff of working copy changes                         |
| `jj log`    | Show graph of commits (by default, only unpushed commits) |
| `jj evolog` | Show previous states (analogous to `git reflog`)          |
| `jj op log` | Show previous operations                                  |

## Specifying revisions

| Revset   | Meaning                             |
| -------- | ----------------------------------- |
| `@`      | Current revision (working copy)     |
| `@-`     | Parent of current revision          |
| `a-`     | Parent(s) of `a`                    |
| `a--`    | Grandparent(s) of `a`               |
| `a+`     | Child(ren) of `a`                   |
| `::a`    | Ancestors of `a` (including `a`)    |
| `a::`    | Descendants of `a` (including `a`)  |
| `a..b`   | Reachable from `b` but not from `a` |
| `a \| b` | Union of `a` and `b`                |
| `a & b`  | Intersection of `a` and `b`         |
| `~a`     | Not in `a`                          |

## Creating commits

Never run `jj commit` without file arguments unless instructed to; use `jj split <file>...` or `jj commit <file>...` to select specific files.

| Command               | Description                                                          |
| --------------------- | -------------------------------------------------------------------- |
| `jj commit <file>...` | Create a commit containing specific changes                          |
| `jj split <file>...`  | Create a commit containing specific changes (also updates bookmarks) |

For commit message formatting, see the `/commit` skill.

## Interacting with Git remotes

| Command                         | Description               |
| ------------------------------- | ------------------------- |
| `jj git fetch`                  | Fetch from default remote |
| `jj git fetch --all-remotes`    | Fetch from all remotes    |
| `jj git push`                   | Push to default remote    |
| `jj git push --remote <remote>` | Push to a named remote    |

## Custom aliases (from config)

| Alias        | Description                                                      |
| ------------ | ---------------------------------------------------------------- |
| `jj examine` | Detailed log with diff for a revision                            |
| `jj nt`      | New change on top of trunk                                       |
| `jj retrunk` | Rebase current change onto trunk                                 |
| `jj reheat`  | Rebase entire stack onto trunk                                   |
| `jj tug`     | Fast-forward closest bookmark to point at recent pushable change |
| `jj consume` | Squash another change into the current one                       |
| `jj eject`   | Move changes from current into another change                    |
| `jj credit`  | Annotate file (like `git blame`)                                 |
| `jj cat`     | Show file contents at a revision                                 |

## Custom revset aliases

| Alias      | Description                                     |
| ---------- | ----------------------------------------------- |
| `stack()`  | Ancestors of reachable mutable changes from `@` |
| `stack(x)` | Ancestors of reachable mutable changes from `x` |
