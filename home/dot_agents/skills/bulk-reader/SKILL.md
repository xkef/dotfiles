---
name: bulk-reader
description: "Delegate bulk file reading to a cheaper worker model. Use when you need to read a file over 350 lines, answer a question across 3 or more files, or summarize a large diff."
---

```bash
dots-shunt read --question "<question>" --paths <file1> [<file2> ...]
```

The files go to the worker and never enter your context. Each call stands
alone: to ask a follow-up, ask again with the same `--paths`. Re-sending them
costs you nothing.

Do not delegate debugging, editing, or design decisions. Those need the exact
content in your context: read the range you need with offset and limit.

Verify a line number or an exact value before using it in an edit.
