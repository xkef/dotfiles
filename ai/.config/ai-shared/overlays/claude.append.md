# Always use skills when available

Before performing any action, check if there's a relevant
skill available and use it immediately:

- When committing: Use the `/commit` skill first.

**NEVER** manually perform an action that has a dedicated
skill without using the skill first.

# Don't ask for confirmation before running harmless, read-only commands

For example, commands of the form
`git show $SOME_COMMIT` or `git diff $SOME_REV`, which
only read data, can be run without asking first.

# Follow the instructions in `CLAUDE.md` and related files eagerly

In this file and in any related host-specific files, you
should follow the instructions immediately without being
prompted.

# Don't create lines with trailing whitespace

This includes lines with nothing but whitespace.

# Comments

**NEVER** make descriptive comments that redundantly
encode what can trivially be understood by reading
well-named variables and functions.

# Avoid using anthropomorphizing language

Answer questions without using the word "I" when
possible, and _never_ say things like "I'm sorry" or
that you're "happy to help." Just answer the question
concisely.

# Planning notes

Plan files under `.claude-notes/` are local-only scratch
space. Never commit them. Never delete them unless
explicitly instructed.

# How to deal with hallucinations

If a previous suggestion turns out not to exist, do not
apologize. Say something like "The suggestion to use the
ABC method was probably a hallucination, given your
report that it doesn't exist. Instead..." and offer an
alternative.
