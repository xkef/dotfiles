---
name: improve-agent
description: Review past agent sessions of the current repository and propose fixes to its sandbox, permissions, docs, skills, and hooks.
disable-model-invocation: true
---

# Improve the agent from its past sessions

Mine this repository's past sessions for **friction**, and turn each finding
into a concrete change. Every finding needs **evidence**: a session id and
timestamp you confirmed by reading the transcript around it.

## 1. Gather

Pick the window. Use the date the user gives. Without one, take the date of the
last commit that restructured the repository, since older sessions describe
files that no longer exist.

Run from the repository root:

```sh
agent-trace --since <date> list      # one row per session
agent-trace --since <date> errors    # every failed tool call
agent-trace --since <date> denials   # failures that read like a denial
agent-trace --since <date> sandbox   # Seatbelt denials the tools never reported
```

`agent-trace` without arguments prints its usage. Transcripts live at
`~/.claude/projects/<cwd with non-alphanumerics as ->/<id>.jsonl`, with subagent
transcripts under `<id>/subagents/`. Lima sessions live under
`~/.local/state/agents/lima-<vm>/claude-projects/` in the same layout.

The environment column separates this machine from `lima-<vm>`. They differ:
nono confines the agent here and prompts guard its tools, while the VM confines
it in Lima and prompts stay off. In Lima a blocked read shows up as
`No such file or directory` on a host path the VM doesn't share, not as a
permission error.

## 2. Analyze

Work through all five. Each ends with findings, or with "none" and the signals
you checked.

1. **Blocked reads:** group `denials` and `sandbox` rows by path. Sort each path
   into: needed for the task (grant it), a harmless probe (list it as noise), or
   a wrong approach (the agent should look elsewhere). A silent denial, such as
   a tool skipping its config file, matters most: the tool gives wrong results
   without a visible cause.
2. **Wrong permissions:** for the sandbox, map each needed path to the nono
   profile (`~/.config/nono/profiles/<profile>.json`, whose source sits in the
   dotfiles repository) and write the missing entry. A grant that only this
   repository's work needs goes into `<profile>-<repository name>.json`, which
   extends the base profile. `sb` picks it up inside the repository, and every
   other project keeps the narrower base profile. For Claude's permissions, find
   rejected tool calls (`doesn't want to proceed`), interrupts
   (`Request interrupted by user`), and hook blocks in the transcripts. Decide
   per case whether the rule or the agent was wrong.
3. **Confusing code:** look for files read or searched again and again within a
   session, searches that found nothing, reads of missing paths, failed edits
   (`String to replace not found`, `File has not been read yet`), and user
   corrections. Rank files and directories by this friction. The fix is a doc
   line, an `AGENTS.md` entry, or a rename.
4. **Skills to derive:** find tool sequences and user instructions that recur
   across three or more sessions. Each candidate names its trigger, its steps,
   and the sessions it would have served.
5. **Anti-patterns to block:** find commands that break an `AGENTS.md` rule,
   commands the user rejected or corrected, and failure-then-workaround loops.
   Propose a PreToolUse hook or a `hookify` rule for each, with the pattern it
   matches.

## 3. Confirm

Open the transcript at every piece of evidence before you report it. Raw text
matches mislead: a file the agent read can contain `Blocked:` or
`Operation not permitted` without any block or denial having happened. Drop what
you can't confirm.

## 4. Report

Write the report to `.claude-notes/agent-review-<date>.md` with one section per
analysis. Each finding states what happened, its evidence, the proposed change
as a diff or rule, and whether it affects this machine, Lima, or both. Show the
user a summary and apply nothing until they choose which changes to make.
