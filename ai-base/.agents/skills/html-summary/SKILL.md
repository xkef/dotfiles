---
name: html-summary
description: Create polished single-file HTML summaries of agent sessions, agent output, implementation work, code changes, and codebase architecture. Use when the user asks for an HTML report, visual summary, session summary, code summary, architecture summary, diagrams, or a shareable explanation of what an agent did.
---

# HTML Summary

Create a self-contained HTML report that turns agent output or codebase findings
into a concise, visual explanation.

## Inputs

Accept any of these:

- Current conversation context
- A pi/Claude exported HTML, Markdown, text transcript, or session JSONL path
- A diff, PR, issue, commit range, or changed-file list
- A codebase or subsystem the user wants summarized

If no transcript/file is available, summarize the visible conversation and say
that the report is based on visible context only.

## Report structure

Include only sections that have useful content:

1. Title, scope, generated timestamp, source paths or session IDs
2. Executive summary: 3-7 bullets
3. What changed: grouped by feature/module/file
4. Decisions and rationale
5. Code summary: important files, APIs, data models, tests, commands run
6. Architecture view: components, dependencies, data/control flow
7. Risks, open questions, follow-ups
8. Appendix: notable excerpts, command output, or diff snippets

## Visuals

Use diagrams when they clarify the report. Prefer:

- Mermaid 11 for flowcharts, sequence diagrams, ERDs, state machines, gantt,
  mindmaps, and simple architecture diagrams
- D3.js v7 for interactive dependency graphs or large relationship maps
- Chart.js 4 for metrics, timelines, file counts, or test/build summaries
- Highlight.js for code snippets

Use CDN libraries only when needed. Keep the file readable offline except for
optional CDN-rendered diagrams. If external CDN use is unacceptable, ask before
inlining vendored libraries.

## HTML requirements

- Write a single `.html` file, normally in the project root or requested path
- Inline CSS and project-specific styling; use CSS variables for colors
- Provide dark/light theme support unless the user asks otherwise
- Make diagrams responsive and readable at laptop width
- Add a table of contents for reports longer than one screen
- Use semantic HTML, ARIA labels for controls, visible focus states, and AA
  color contrast
- Escape user/code content before embedding it in HTML
- Avoid smart quotes in HTML attributes and avoid duplicate IDs

## Workflow

1. Identify the source material and target filename.
2. Read provided transcripts, diffs, session JSONL, or relevant source files.
3. Extract facts: changed files, goals, decisions, validation, risks.
4. Choose 1-3 diagrams that reduce cognitive load.
5. Write the HTML report.
6. Re-read the generated file and fix invalid markup, broken anchors,
   overlapping diagram labels, and unescaped snippets.
7. Tell the user where the file was written and how to open it.
