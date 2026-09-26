---
name: html-summary
description: Create single-file HTML summaries of agent sessions, agent output, code changes, and codebase architecture. Use when the user asks for an HTML report, a visual or session summary, a code or architecture summary, diagrams, or a shareable explanation of what an agent did.
---

# HTML summary

Create a self-contained HTML report that turns agent output or codebase findings
into a short, visual explanation.

## Inputs

Accept any of these:

- Current conversation context
- An exported pi or Claude HTML, Markdown, or text transcript, or a session
  JSONL path
- A diff, PR, issue, commit range, or changed-file list
- A codebase or subsystem the user names

Without a transcript or file, summarize the visible conversation. Say in the
report that it covers visible context only.

## Report structure

Include only sections with content:

1. Title, scope, generated timestamp, and source paths or session IDs
2. Executive summary: 3-7 bullets
3. What changed, grouped by feature, module, or file
4. Decisions and rationale
5. Code summary: important files, APIs, data models, tests, commands run
6. Architecture view: components, dependencies, data flow, control flow
7. Risks, open questions, follow-ups
8. Appendix: excerpts, command output, diff snippets

## Visuals

Use diagrams when they clarify the report. Prefer:

- Mermaid 11 for flowcharts, sequence diagrams, ERDs, state machines, gantt,
  mindmaps, and small architecture diagrams
- D3.js v7 for interactive dependency graphs or large relationship maps
- Chart.js 4 for metrics, timelines, file counts, or test and build summaries
- Highlight.js for code snippets

Load CDN libraries only when a diagram needs them. Keep the file readable
offline except for those diagrams. If the user rejects CDN use, ask before
inlining vendored libraries.

## HTML requirements

- Write one `.html` file, in the project root unless the user names a path
- Inline the CSS and use CSS variables for colors
- Support dark and light themes unless the user asks otherwise
- Make diagrams responsive and readable at laptop width
- Add a table of contents for reports longer than one screen
- Use semantic HTML, ARIA labels for controls, visible focus states, and AA
  color contrast
- Escape user and code content before embedding it in HTML
- Avoid smart quotes in HTML attributes and duplicate IDs

## Workflow

1. Identify the source material and target filename.
2. Read the transcripts, diffs, session JSONL, or source files.
3. Extract facts: changed files, goals, decisions, validation, risks.
4. Choose 1-3 diagrams that reduce cognitive load.
5. Write the HTML report.
6. Reread the generated file and fix malformed markup, broken anchors,
   overlapping diagram labels, and unescaped snippets.
7. Tell the user the path and how to open it.
