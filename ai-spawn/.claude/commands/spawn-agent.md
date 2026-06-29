---
description: Spawn a parallel jj-workspace coding agent
argument-hint: "<slug> [brief]"
allowed-tools: Bash(ai-agent:*)
---

Spawn a new parallel feature worker using `ai-agent spawn`.

1. Parse `$ARGUMENTS` as a kebab-case slug followed by an optional task brief.
2. If the brief is missing or vague, draft a concise `--brief` that states:
   - the task,
   - target files, and
   - expected outcome.
3. Use Bash to run:

   ```bash
   ai-agent spawn <slug> --agent claude --brief "<brief>"
   ```

Rules:

- The slug becomes the jj workspace `agent-<slug>` and bookmark
  `agent/<slug>`.
- Do not reuse a slug unless its old workspace, bookmark, and window have been
  cleaned up.
- The spawned agent starts on an empty descendant of `agent/<slug>`.
- The spawned agent should commit its work and run `jj tug` before
  `ai-agent finish <slug>`.
- Add `--agent codex`, `--agent opencode`, or `--agent pi` only when requested.
- Add `--sandbox` only when the user confirms their `sb` profile allows writes
  to the primary repo's `.jj/` directory.
