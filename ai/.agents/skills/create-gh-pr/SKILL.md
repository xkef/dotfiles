---
name: create-gh-pr
description: Create a GitHub pull request with a well-formed title and body, following the same best practices as commits (Conventional Commits title, motivation in body, issue references). Use when the user wants to open, create, or draft a GitHub PR, or asks to "make a PR" / "send a pull request".
---

# Create a GitHub pull request

Use `gh` for all GitHub operations. Never use `curl`
against the GitHub API.

## Process

1. **Identify the branch and base.**
   - Current branch: `git branch --show-current` (or
     `jj log` in a Jujutsu repo).
   - Default base: query with
     `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`.
   - Confirm with the user if the base is not obvious.

2. **Inspect the diff that will land on the base.**
   - `git log <base>..HEAD --oneline` to see commits.
   - `git diff <base>...HEAD` for the full change.
   - In Jujutsu, use `jj log` and `jj diff` against the
     appropriate revset.

3. **Prefer a single commit.** The user squash-merges,
   so the PR usually represents one logical change.
   - If there are multiple WIP/fixup commits, suggest
     squashing them locally before opening the PR
     (or rely on the squash merge to collapse them —
     but the PR title/body still needs to read as the
     final single commit message).
   - If the branch legitimately contains multiple
     independent commits that should stay separate,
     ask the user whether to split into multiple PRs.

4. **Find related issues to reference.**
   - Search the diff and commit messages for issue
     numbers (`#123`, `GH-123`, `org/repo#123`).
   - Search the issue tracker for plausible matches:
     `gh issue list --search "<keywords>" --state open`.
     Pull keywords from the change (file names,
     symbols, user-facing strings).
   - Present candidates to the user and confirm which
     should be `Closes` (fully resolves) vs `Ref`
     (related/partial). When unsure, ask.

5. **Draft the PR title.**
   - Same rules as a commit subject: Conventional
     Commits type, optional scope, imperative verb,
     ≤72 characters.
   - Example: `feat(login): add support for magic links`.

6. **Draft the PR body.** Write Markdown. **Do not
   hard-wrap the body** — GitHub renders Markdown, and
   manual wrapping breaks list items, links, and
   blockquotes. Let the renderer handle line length.
   Suggested structure:

   ```md
   ## Summary

   One or two sentences on what changes.

   ## Motivation

   Why this change, what problem it solves, why this
   approach was chosen.

   ## Alternatives considered

   (Optional) Other approaches and why they were
   rejected.

   ## Notes

   (Optional) Testing performed, follow-ups, caveats.

   Closes #123
   Ref #456
   ```

   - Omit empty sections.
   - Put `Closes`/`Ref` trailers at the very bottom,
     one per line.
   - **Do not** include a prompt log or a
     `Co-Authored-By:` trailer in PR bodies.

7. **Create the PR.**
   - Write the body to a tempfile to preserve
     formatting (avoid shell quoting issues):
     ```sh
     gh pr create \
       --base "<base>" \
       --title "<title>" \
       --body-file /tmp/pr-body.md
     ```
   - Add `--draft` if the user asked for a draft.
   - Add `--web` only if the user explicitly wants to
     open the browser.

8. **Confirm.** Print the resulting PR URL.

## Wrapping rules summary

| Field    | Wrap?                                     |
| -------- | ----------------------------------------- |
| Title    | Yes — ≤72 chars, single line              |
| Body     | **No** — write Markdown, no hard wrapping |
| Trailers | One per line at the end of the body       |

## Issue reference keywords

- `Closes #N` / `Fixes #N` / `Resolves #N` — GitHub
  auto-closes the issue on merge.
- `Ref #N` / `Refs #N` / `Related to #N` — links
  without auto-closing.

Use `Closes` only when merging the PR fully resolves
the issue. Otherwise use `Ref`.

## Best practices (inherited from commits)

- Title starts with a Conventional Commits type
  (`feat`, `fix`, `chore`, `refactor`, `docs`, `test`,
  `perf`, `style`) followed by an imperative verb.
- Body explains _why_, not just _what_ — the diff
  already shows what.
- Note alternatives considered.
- Link to relevant prior commits, PRs, or docs.
- Do **not** include prompt logs or
  `Co-Authored-By:` trailers in PR bodies (these
  belong in commit messages only, if anywhere).

See also: the `commit` skill for commit message
conventions, and the `jj` skill when working in a
Jujutsu repo.
