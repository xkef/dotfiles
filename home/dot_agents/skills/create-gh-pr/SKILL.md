---
name: create-gh-pr
description: Create a GitHub pull request with a well-formed title and body that follows the commit conventions, with a Conventional Commits title, motivation in the body, and issue references. Use when the user wants to open, create, or draft a GitHub PR.
---

# Create a GitHub pull request

Use `gh` for all GitHub operations. Never use `curl`
against the GitHub API.

## Process

1. **Identify the branch and base.**
   - Current branch: `git branch --show-current`, or
     `jj log` in a Jujutsu repo.
   - Default base:
     `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`.
   - Confirm the base with the user when in doubt.

2. **Inspect the diff against the base.**
   - `git log <base>..HEAD --oneline` for the commits.
   - `git diff <base>...HEAD` for the full change.
   - In Jujutsu, use `jj log` and `jj diff` against the
     matching revset.

3. **Prefer one commit.** The user squash-merges, so
   the PR represents one logical change.
   - For a run of work-in-progress or fixup commits,
     suggest squashing them locally before opening the
     PR. The squash merge collapses them either way,
     but the PR title and body still need to read as
     the final commit message.
   - If the branch holds independent commits that must
     stay separate, ask the user whether to split them
     into separate PRs.

4. **Find related issues to reference.**
   - Search the diff and commit messages for issue
     numbers: `#123`, `GH-123`, `org/repo#123`.
   - Search the issue tracker for plausible matches:
     `gh issue list --search "<keywords>" --state open`.
     Pull keywords from the change: file names,
     symbols, user-facing strings.
   - Present candidates to the user and confirm which
     get `Closes`, for a full fix, and which get `Ref`,
     for a related or partial one. When unsure, ask.

5. **Draft the PR title.**
   - Same rules as a commit subject: a Conventional
     Commits type, optional scope, imperative verb,
     at most 72 characters.
   - Example: `feat(login): add support for magic links`.

6. **Draft the PR body.** Write Markdown. **Don't
   hard-wrap the body.** GitHub renders Markdown, and
   a manual line break splits list items, links, and
   blockquotes. Let the renderer handle line length.
   Suggested structure:

   ```md
   ## Summary

   One or two sentences on what changes.

   ## Motivation

   Why this change, what problem it solves, why this
   approach won.

   ## Alternatives considered

   (Optional) Other approaches and why they lost.

   ## Notes

   (Optional) Testing performed, follow-ups, caveats.

   Closes #123
   Ref #456
   ```

   - Omit empty sections.
   - Put `Closes` and `Ref` trailers last, one per
     line.
   - **Don't** include a prompt log or a
     `Co-Authored-By:` trailer in PR bodies.

7. **Create the PR.**
   - Write the body to a temporary file to preserve
     formatting and avoid shell quoting:

     ```sh
     gh pr create \
       --base "<base>" \
       --title "<title>" \
       --body-file /tmp/pr-body.md
     ```

   - Add `--draft` if the user asked for a draft.
   - Add `--web` only if the user wants the browser.

8. **Confirm.** Print the resulting PR URL.

## Wrapping rules summary

| Field    | Wrap?                                |
| -------- | ------------------------------------ |
| Title    | Yes. At most 72 characters, one line |
| Body     | **No.** Markdown, renderer wraps it  |
| Trailers | One per line at the end of the body  |

## Issue reference keywords

- `Closes #N`, `Fixes #N`, `Resolves #N`: GitHub closes
  the issue on merge.
- `Ref #N`, `Refs #N`, `Related to #N`: links without
  closing.

Use `Closes` only when merging the PR resolves the
issue in full. Otherwise use `Ref`.

## Conventions shared with commits

- Title starts with a Conventional Commits type,
  `feat`, `fix`, `chore`, `refactor`, `docs`, `test`,
  `perf`, or `style`, followed by an imperative verb.
- Body explains why. The diff already shows what.
- Note alternatives considered.
- Link to relevant prior commits, PRs, or docs.
- **Don't** include prompt logs or `Co-Authored-By:`
  trailers in PR bodies.

See also the `commit` skill for commit message
conventions and the `jj` skill for a Jujutsu repo.
