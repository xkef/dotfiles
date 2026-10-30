---
name: improve-instructions
description: Find the corrections and blocked commands that recur across recent agent sessions and propose edits to the global agent instructions.
disable-model-invocation: true
---

# Improve the global instructions from past sessions

Find the **corrections** the user keeps repeating across every repository, and
turn each recurring one into an edit of the global instructions at
`~/dotfiles/modules/agents/.agents/AGENTS.md`. For the sandbox, permissions, and
docs of one repository, use the `improve-agent` skill instead.

## 1. Gather

Take the window the user names. Without one, take the last 30 days. Work in a
fresh `mktemp -d .claude/tmp/XXXXXX` directory:

```sh
agents trace --all --since <date> corrections > corrections.tsv
agents trace --all --since <date> denials > denials.tsv
```

Each `corrections` row holds session, environment, timestamp, the tail of the
agent's previous reply, and a prompt that reads like a correction. `denials`
adds the permission rules, the auto mode classifier, user rejections, and hook
blocks that stopped a tool call.

## 2. Analyze

Split `corrections.tsv` into chunks of about 150 rows and hand each chunk and
`denials.tsv` to its own subagent. Every subagent reads the global `AGENTS.md`
first, then reads every row of its chunk, and reports up to 12 **patterns**. A
pattern means one agent behavior the user corrected in two or more rows. Each
pattern carries:

- The behavior, in one line.
- The row count and one to three verbatim quotes with their project and date.
- The `AGENTS.md` heading that covers it, or the words `not covered`. A covered
  pattern that still recurs means weak wording or a harness instruction that
  overrides it.
- A proposed edit of a few lines, or the words `project-specific` when the edit
  belongs in one repository's `AGENTS.md`.

Drop task notifications, retries after API errors, and one-off feature requests.

## 3. Merge

Merge the patterns across chunks. Rank them by the number of rows and projects
that show them. Keep only patterns seen in at least two sessions. A pattern that
one quote supports stays out.

## 4. Report

Write `.claude-notes/instructions-review-<date>.md` with one section per pattern
in rank order. Each section holds the evidence and the current coverage, then
the proposed edit as a diff. List the project-specific patterns and the
permission-rule changes apart from the `AGENTS.md` edits. Show the user a
summary and apply nothing until they choose which edits to make. Apply the
chosen ones with the `writing-for-agents` skill.
