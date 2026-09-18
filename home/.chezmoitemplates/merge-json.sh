#!/usr/bin/env bash
# Merges committed keys over a JSON settings file the agent writes at
# runtime. Managing the file outright would wipe that state on every apply.
# Committed keys win, and the rest stays. The template argument holds the
# committed JSON.
set -euo pipefail

managed=$(
  cat <<'MANAGED_JSON'
{{ . }}
MANAGED_JSON
)

local_settings=$(cat)
[ -n "$local_settings" ] || local_settings='{}'

printf '%s' "$local_settings" | jq --argjson managed "$managed" '. * $managed'
