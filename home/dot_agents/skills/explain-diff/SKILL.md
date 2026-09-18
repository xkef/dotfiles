---
name: explain-diff
description: Use when the user asks for a rich explanation of a code change, diff, branch, or PR, as a literate, teachable explainer document rather than a review or report. Triggers on requests to explain a diff, change, or PR, or to make an explainer.
---

# Explain diff

Adapted from Geoffrey Litt's explain-diff skill:
<https://gist.github.com/geoffreylitt/a29df1b5f9865506e8952488eac3d524>

Make a rich, interactive explanation of the code change. Explore
the surrounding code first. The explainer covers the system, not only
the diff.

## Sections

- **Background**: explain the existing system relevant to this change.
  The reader's prior knowledge varies, so start with a deep background
  for beginners, marked as optional, then a narrower background tied to
  the change.
- **Intuition**: explain the core idea of the change. Focus on the
  essence, not the full details. Use concrete examples with toy data.
  Use figures and diagrams liberally.
- **Code**: a literate walkthrough of the changes, grouped and ordered
  for understanding, with prose before each group. Never a list of files
  in alphabetical order.
- **Quiz**: five multiple-choice questions on this change, of medium
  difficulty. Answering must require understanding the substance.
  Avoid gotchas. Clicking an answer reports whether it matched and
  gives feedback.

## Format

- One self-contained HTML file with inline CSS and JavaScript. One long
  page with section headers and a table of contents. No tabs for the
  top-level structure. Basic responsive styling.
- Save it outside the repo with a date-prefixed filename so files stay
  time-sorted: `/tmp/YYYY-MM-DD-explanation-<slug>.html`.
- Write with the clarity and flow of Martin Kleppmann: engaging, classic
  style, with transitions between sections.
- Diagrams: pick a few diagram families and reuse them across the
  explanation. Useful families: a simplified version of the UI for UI
  changes, and a system diagram of data flow between components with
  example data. Never ASCII diagrams. Use plain HTML and CSS designs,
  and HTML lists for lists.
- Code blocks: use `<pre>` tags. Any custom styled div **must** have
  `white-space: pre-wrap`, or the browser collapses newlines. Before
  saving, scan each code block in the HTML source and confirm its CSS
  includes `white-space: pre` or `pre-wrap`.
- Use callouts for key concepts, definitions, and important edge cases.

## Publish

If the Artifact tool exists, publish the HTML file as a private artifact.
Load the `artifact-design` skill first if the harness requires it. Report
both the local path and the URL. The file already contains everything it
needs, so leave the CSP alone. Without the Artifact tool, report the
local path.
