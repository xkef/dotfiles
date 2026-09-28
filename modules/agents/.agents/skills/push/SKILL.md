---
name: push
description: Push the main bookmark and watch CI until it passes. Use when the user asks to push.
---

# Push main and watch CI

Done means CI passes on the pushed commit, or you report the failing step and
its reproduction.

1. Run the tasks CI runs, and fix any failure before you push. `mise run lint`
   includes local-only checks, so name the tasks:

   ```sh
   mise run lint-sh ::: lint-fish ::: lint-fmt ::: lint-md ::: lint-prose ::: lint-actions
   mise run check
   ```

2. Move `main` to the newest commit with a description:
   `jj bookmark set main -r <rev>`. jj refuses to push a commit without a
   description, so ask the user for one if an ancestor lacks it.

3. Run `jj git push -b main` as a command of its own, with no `cd` prefix.

4. Find the run for the pushed commit and wait for it:

   ```sh
   gh run list --workflow ci.yml --commit <commit id> --json databaseId --jq '.[0].databaseId'
   gh run watch <run id> --exit-status
   ```

5. On failure, read `gh run view <run id> --log-failed`, reproduce it with the
   matching `mise run` task, and report the cause with a proposed fix.
