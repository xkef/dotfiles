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
be careful with _any_ `jj` command that creates or modifies
a change. For example, if you user asks you to squash some
changes into the last commit using `jj squash`, you should
prompt the user to indicate _which_ files' changes they
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
3. Draft a commit message with:

- A subject of 72 characters or less in Conventional
  Commits format (eg. "docs: add migration notes" or
  "fix: avoid double-render in list component"). In
  repositories that make use of scopes, you can include
  a scope in parentheses (eg.
  "chore(frontend): update copyright year" or
  "feat(login): add support for magic links").
- A body only when the change is non-obvious: a blank
  line, then a short description wrapped to 72 characters
  stating the motivation and anything surprising. Keep it
  concise — many commits need no body at all. Do not pad.

**Never** add a "Co-Authored-By" trailer, a "Generated
with Claude Code" line, or any other attribution. **Never**
include the text of prompts in the commit message.

4. **Always** present the proposed commit message to the
   user and wait for their explicit approval before
   creating the commit. They may want to edit it first; do
   not run the commit command until they confirm.

## Best practices

- Subjects MUST start with a Conventional Commits type
  (eg. "docs", "fix", "feat", "chore" etc; see the table
  below for a full list) followed by a statement beginning
  with a verb (eg. "add", "remove", "rename" etc). The
  subject describes _what_ the commit does.
- Prefer a clear subject on its own. Add a body only when
  the change is non-obvious, and keep it brief: explain the
  motivation, not the mechanics.
- Reference relevant prior commits, issues, or PRs when it
  genuinely aids understanding.

## Conventional Commits types

| Type     | When to use                                                                                        |
| -------- | -------------------------------------------------------------------------------------------------- |
| fix      | Bug fixes                                                                                          |
| feat     | New features                                                                                       |
| chore    | Content                                                                                            |
| refactor | Code improvements (eg. for better readability, easier maintenance etc) which don't change behavior |
| docs     | Documentation changes (including changes to code comments)                                         |
| test     | Changing or adding/removing tests                                                                  |
| perf     | Performance improvements                                                                           |
| style    | Formatting changes, automated lint fixes                                                           |

## Example

```text
refactor: remove unused `recurse` setting

We never exposed a user-accessible setting here; it is always `true` in
practice, except in the benchmarks where we offered an environment
override. Leaving it out simplifies the code, and saving the conditional
checks is marginally faster.
```
