---
name: jj
description: How to use `jj`, the Jujutsu version control system. Use when working in a repository with a `.jj` directory or when the user asks about jj operations.
---

# Jujutsu

Jujutsu, `jj`, is a Git-compatible version control system.
This setup runs it colocated, with a `.jj` directory next
to `.git`. A `.jj` directory marks a jj repository. Git
commands still work for reading objects: `git show`,
`git log`, `git grep`. Use `jj` to create commits.

## No staging area

Every `jj` command snapshots the working directory. `jj`
respects `.gitignore`. To stop tracking a file, add it to
`.gitignore` and run `jj file untrack <file>...`.

Any `jj` command that creates or edits a change takes
file arguments. Always pass them.

## Common commands

| Command     | Description                                          |
| ----------- | ---------------------------------------------------- |
| `jj st`     | Show summary of working copy changes                 |
| `jj diff`   | Show diff of working copy changes                    |
| `jj log`    | Show graph of commits, by default only unpushed ones |
| `jj evolog` | Show previous states, like `git reflog`              |
| `jj op log` | Show previous operations                             |

## Specifying revisions

| Revset   | Meaning                             |
| -------- | ----------------------------------- |
| `@`      | Current revision, the working copy  |
| `@-`     | Parent of current revision          |
| `a-`     | Parents of `a`                      |
| `a--`    | Grandparents of `a`                 |
| `a+`     | Children of `a`                     |
| `::a`    | Ancestors of `a`, including `a`     |
| `a::`    | Descendants of `a`, including `a`   |
| `a..b`   | Reachable from `b` but not from `a` |
| `a \| b` | Union of `a` and `b`                |
| `a & b`  | Intersection of `a` and `b`         |
| `~a`     | Not in `a`                          |

## Creating commits

Never run `jj commit` without file arguments unless
instructed to. Use `jj split <file>...` or
`jj commit <file>...` to select files.

| Command               | Description                                                      |
| --------------------- | ---------------------------------------------------------------- |
| `jj commit <file>...` | Create a commit containing specific changes                      |
| `jj split <file>...`  | Create a commit containing specific changes and update bookmarks |

For commit message formatting, see the `commit` skill.

## Interacting with Git remotes

| Command                         | Description               |
| ------------------------------- | ------------------------- |
| `jj git fetch`                  | Fetch from default remote |
| `jj git fetch --all-remotes`    | Fetch from all remotes    |
| `jj git push`                   | Push to default remote    |
| `jj git push --remote <remote>` | Push to that remote       |

## Custom aliases

| Alias        | Description                                                      |
| ------------ | ---------------------------------------------------------------- |
| `jj examine` | Detailed log with diff for a revision                            |
| `jj nt`      | New change on top of trunk                                       |
| `jj retrunk` | Rebase current change onto trunk                                 |
| `jj reheat`  | Rebase entire stack onto trunk                                   |
| `jj tug`     | Fast-forward closest bookmark to point at recent pushable change |
| `jj consume` | Squash another change into the current one                       |
| `jj eject`   | Move changes from current into another change                    |
| `jj credit`  | Annotate file, like `git blame`                                  |
| `jj cat`     | Show file contents at a revision                                 |

## Custom revset aliases

| Alias      | Description                                     |
| ---------- | ----------------------------------------------- |
| `stack()`  | Ancestors of reachable mutable changes from `@` |
| `stack(x)` | Ancestors of reachable mutable changes from `x` |
