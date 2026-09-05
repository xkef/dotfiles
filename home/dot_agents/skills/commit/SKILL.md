---
name: commit
description: Create a commit in a repository
---

# Create a commit in a repository

## Creating Git commits

The most common case will be creating a commit in a Git
repository. Usually, you will include all changes in the
working directory in the commit (that is, you should run
`command git diff` to see what the changes are, and/or
`command git diff --staged` to see what has already been
staged). Generally, if your user wants you to commit only
a subset of the changes in the working directory, he will
instruct you to do so.

## Creating Jujutsu commits

Less frequently, you will find yourself in a Jujutsu
repository (which you can determine via the presence of a
`.jj` directory in the repository root). Jujutsu does not
have a concept of a staging area like Git, and running any
`jj` command will cause a snapshot of the working directory
(including untracked files) to be made; you should therefore
interactively prompt your user to indicate which changed
files should be included in the change. In the most common
case, you can use `jj st` to see which files are in the
current snapshot, and `jj show` to see the diff, then
`jj split <file>...` to indicate which specific files to be
included in the commit (passing your commit message using
the `-m` option.

In general, because of the lack of staging area, you should
be careful with *any* `jj` command that creates or modifies
a change. For example, if you user asks you to squash some
changes into the last commit using `jj squash`, you should
prompt the user to indicate *which* files' changes they
want squashed (and invoke `jj squash <file>...`
accordingly).

For more information on Jujutsu, see the `jj` skill.

## Common instructions

1. Run the appropriate Git-specific or Jujutsu-specific
   commands to see what should be included in the commit.
2. Note that your user may have asked you to create or
   update "plan" files under `.claude-notes/`, a directory
   which is ignored via the global `~/.config/git/ignore`
   file: these plan files should never be included in a
   commit as they are intended to be local-only aids to
   development.
3. Draft a commit message using the format below. Never
   include prompt text or generated-by attribution.
4. **Always** present the proposed commit message to the
   user and wait for their explicit approval before
   creating the commit. They may want to edit it first; do
   not run the commit command until they confirm.

## Commit message format

- Subject: use `type: description` or
  `type(scope): description`. Aim for 50 characters, with
  a hard limit of 72 for the entire subject. Use lowercase,
  imperative mood, and no final period. The subject states
  what the commit does, such as `fix(zsh): restore history`.
- Scope: optional, such as `feat(tmux)` or `fix(zsh)`.
- Body: add only when the motivation is non-obvious.
  Separate it from the subject with a blank line and wrap
  at 72 characters. Explain why the change is needed.
  Keep it brief and avoid repeating what the diff shows.
- Footer: separate it from the body, or subject when there
  is no body, with a blank line. Use the fields below when
  applicable.

### Footer fields

- `Breaking-Change:`: describe the incompatible change
  and any required migration.
- `Co-Authored-By: Name <email>`: credit a known co-author.
  Use their actual name and email. Never invent attribution.
- `Refs:`: identify the issues or other work items this
  commit advances, such as a PR, task, or specification.
  Use known IDs, URLs, or paths from the task context, such
  as `Refs: #123` or `Refs: TEAM-456, docs/spec.md`.
  Omit this field when no related work item is known.
  Never invent a reference.

## Conventional Commits types

| Type     | When to use                               |
| -------- | ----------------------------------------- |
| feat     | New features                              |
| fix      | Bug fixes                                 |
| refactor | Code improvements with no behavior change |
| docs     | Documentation, including code comments    |
| test     | Add or change tests                       |
| perf     | Performance improvements                  |
| style    | Formatting and lint fixes                 |
| chore    | Maintenance, dependencies, and tooling    |

## Example

```text
fix(zsh): preserve history across sessions

Concurrent shells can overwrite each other's history, losing commands
needed in later sessions.

Refs: #123
```
