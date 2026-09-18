---
name: quiz-diff
description: Quiz the user on a diff, branch, or PR to check that they understood it before sending it for review. Use when the user asks for a quiz or a test of their understanding of a change.
---

# Quiz diff

A five-question quiz on a code change, answered in the terminal. The rule
this enforces: don't send code for review until you can pass a quiz
about it.

## Steps

1. Pick the change to quiz on. Default to the current change, `jj diff`,
   or the branch against `main`. Accept an explicit revision, commit
   range, or PR number. Read the full diff and enough surrounding code
   to write substantive questions.
2. Write five multiple-choice questions of medium difficulty. Answering
   must require understanding the change. Avoid gotchas and trivia.
   Wrong options must look plausible. Cover different aspects: why the
   change exists, how the mechanism works, behavior at edges, and what
   breaks without a piece of it.
3. Ask one question at a time with AskUserQuestion. Don't reveal the
   correct option in the labels. After each answer, say whether it
   matched and explain in one or two sentences.
4. Report the score. 4/5 or better: ready to send. Below that: name the
   areas the misses point at, suggest what to reread, and offer to run
   `/explain-diff` on the change.

Don't produce a document. The whole interaction stays in the terminal.
