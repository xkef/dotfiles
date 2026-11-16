---
name: explain-code
description: Publish an Artifact that explains a feature, subsystem, codebase, or agent session with architecture diagrams, flowcharts, sequence diagrams, and short summaries. Use when the user asks to explain, visualize, or summarize code or a session as a page. For a diff or PR, use explain-diff.
---

# Explain code as an Artifact

Publish one Artifact page that a reader new to the code can follow from top to
bottom. It explains the **mechanism**: the parts and the paths that data and
control take between them, with the reasons behind the design.

## 1. Read

Read the code the user names, and follow it outward through its callers and
storage to its external boundaries. For a session, read its transcript, or else
the visible conversation. Done when you can list each component the page shows
and point to the file that defines it.

## 2. Plan the page

Pick the diagrams that answer the reader's questions, one question each:

- **Architecture:** which components exist and what calls what.
- **Flowchart:** how one request, job, or decision moves through the code.
- **Sequence:** which messages cross a boundary, and in what order.
- **State machine or data model:** for code organized around state or records.

Plan two to four diagrams. Each diagram names real modules, functions, and
files, never placeholders. Order the page as:

1. Summary: what it does and why it exists, in three to five bullets.
2. The diagrams, each with a short paragraph on what to notice.
3. Key code: the few files and functions that make up the core of the design,
   with short excerpts and `file:line` references.
4. Decisions and tradeoffs the code makes.
5. Open questions or risks, only when the reading found some.

## 3. Build and publish

Call the Artifact tool's quickstart with intent `other`, then load the
`artifact-design` and `artifact-diagramming` skills. Follow them for the page
and its inline SVG diagrams. Write the page under `.claude/tmp/` and publish it.
Done when the publish succeeds and every diagram renders legibly in light and
dark themes.

## 4. Report

Give the user the link and a two-line summary of what the page covers.
