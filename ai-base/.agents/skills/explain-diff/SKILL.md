---
name: explain-diff
description: Use when the user asks for a rich explanation of a code change, diff, branch, or PR — a literate, teachable explainer document, not a review or report. Triggers on "explain this diff/change/PR", "help me understand this change", "make an explainer".
---

# Explain Diff

Adapted from Geoffrey Litt's explain-diff skill
(<https://gist.github.com/geoffreylitt/a29df1b5f9865506e8952488eac3d524>).

Make a rich, interactive explanation of the specified code change.
Broadly explore the surrounding code first — the explainer teaches the
system, not just the diff.

## Sections

- **Background**: Explain the existing system relevant to this change.
  We don't know how much the reader already knows, so include a deep
  background for beginners (note that it can be skipped if the reader
  is already familiar), then a narrower background directly relevant
  to the change.
- **Intuition**: Explain the core intuition for the change. Focus on
  the essence, not the full details. Use concrete examples with toy
  data. Use figures and diagrams liberally.
- **Code**: A literate walkthrough of the changes — grouped and
  ordered for understanding, with prose before each group, not a pile
  of files in alphabetical order.
- **Quiz**: Five multiple-choice questions testing knowledge of this
  change. Medium difficulty — hard enough that you must understand the
  substance to answer, but no gotchas. Interactive: clicking an answer
  says whether it was correct and gives feedback.

## Format

- One single self-contained HTML file with inline CSS and JavaScript.
  One long page with section headers and a table of contents; no tabs
  for the top-level structure. Basic responsive styling.
- Save it outside the repo with a date-prefixed filename so files stay
  time-sorted: `/tmp/YYYY-MM-DD-explanation-<slug>.html`.
- Write with the clarity and flow of Martin Kleppmann — engaging,
  classic style, smooth transitions between sections.
- Diagrams: pick a small number of diagram families and reuse them
  across the explanation. Useful families: a simplified version of the
  UI the user sees (for UI changes); a system diagram showing data
  flow between components, with example data. Never ASCII diagrams —
  always simple HTML/CSS designs, HTML lists for lists.
- Code blocks: use `<pre>` tags. Any custom styled div **must** have
  `white-space: pre-wrap`, or the browser collapses newlines. Before
  saving, scan each code block in the HTML source and confirm its CSS
  includes `white-space: pre` or `pre-wrap`.
- Use callouts for key concepts, definitions, and important edge cases.

## Publish

If the Artifact tool is available, publish the HTML file as a private
artifact (load the `artifact-design` skill first if the harness
requires it) and report both the local path and the URL. The file is
already self-contained, so no CSP changes are needed. If the Artifact
tool is unavailable, just report the local path.
