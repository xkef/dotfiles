---
name: code-writer
description: "Delegate boilerplate code generation to a cheaper worker model. Use for tests, config, docstrings, type stubs, or any generation where more than 80% is predictable from a reference file."
---

```bash
# Generate and write directly to the target file
dots-shunt write --spec "<what to generate>" --reference <file> --target <out>

# Print to stdout instead (omit --target)
dots-shunt write --spec "<what to generate>" --reference <file>
```

`--reference` is required: the worker matches its patterns, naming, and style.
Each call stands alone. To build on what was just generated, pass that file as
the `--reference` for the next call.

Review the output and make surgical edits for the part that needs your
judgment.
