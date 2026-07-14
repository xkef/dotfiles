---
name: quiz-diff
description: Quiz the user on a diff, branch, or PR to check they actually understood it before sending it for review. Use when the user says "quiz me", asks to test their understanding of a change, or wants a pre-review comprehension gate.
---

# Quiz Diff

A comprehension gate: five questions about a code change, answered
interactively in the terminal. The rule this supports — don't send
code for review until you can pass a quiz about it.

## Steps

1. Determine the change to quiz on. Default: the current change
   (`jj diff`, or the branch against `main`); accept an explicit
   revision, commit range, or PR number. Read the full diff and enough
   surrounding code to write substantive questions.
2. Write five multiple-choice questions, medium difficulty — hard
   enough that answering requires understanding the substance of the
   change, but no gotchas or trivia. Wrong options must be plausible.
   Cover different aspects: why the change exists, how the mechanism
   works, behavior at edges, what would break without a given piece.
3. Ask one question at a time with AskUserQuestion. Do not reveal
   which option is correct in the labels. After each answer, say
   whether it was correct and give a one-or-two-sentence explanation.
4. Report the score. 4/5 or better: ready to send. Below that: name
   the specific areas the misses point at, suggest what to re-read,
   and offer to run `/explain-diff` on the change.

Do not produce a document; the whole interaction lives in the
terminal.
