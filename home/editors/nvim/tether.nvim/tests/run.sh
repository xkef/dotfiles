#!/bin/sh
# Runs the headless test suite. Arguments filter tests by name substring.
# Needs nvim, jj, and git on PATH, or NVIM pointing at a binary.
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/tether-test.XXXXXX")
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/state" "$work/config" "$work/data"
cat >"$work/jj.toml" <<'TOML'
user.name = "Test"
user.email = "test@example.com"
ui.paginate = "never"
TOML
export XDG_STATE_HOME="$work/state" XDG_CONFIG_HOME="$work/config" XDG_DATA_HOME="$work/data"
export JJ_CONFIG="$work/jj.toml" TETHER_TEST_TMP="$work"
export GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.com
export GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@example.com
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
unset WEZTERM_PANE AGENT_TRAIL_SESSION
exec "${NVIM:-nvim}" --headless --clean --cmd "set rtp^=$root" -l "$root/tests/run.lua" "$@"
