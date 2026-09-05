#!/usr/bin/env bash
# Tests for the shunt gate hook and the dots-shunt worker script.
#
# The hook tests feed PreToolUse JSON to claude-shunt-gate and assert the
# exit code: 0 lets the tool call through, 2 blocks it. The script tests run
# dots-shunt against a stub `claude` on PATH that records what it was asked,
# so they need no network and no account.
set -uo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd)
HOOK="$REPO/home/dot_claude/hooks/executable_claude-shunt-gate"
SHUNT="$REPO/home/dot_local/bin/executable_dots-shunt"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

PASSED=0
FAILED=0

fixture() {
  local path=$1 lines=$2
  seq 1 "$lines" | sed 's/^/line /' >"$path"
}

fixture "$TMP/small" 100
fixture "$TMP/boundary" 350
fixture "$TMP/large" 1200
: >"$TMP/empty"

assert() {
  local name=$1 expected=$2 actual=$3
  if [ "$expected" = "$actual" ]; then
    PASSED=$((PASSED + 1))
    return
  fi
  FAILED=$((FAILED + 1))
  printf 'FAIL  %s\n      expected: %s\n      actual:   %s\n' "$name" "$expected" "$actual"
}

# hook <name> <expected exit> <json> [ENV=VAL...]
hook() {
  local name=$1 expected=$2 json=$3
  shift 3
  local rc=0
  echo "$json" | env "$@" bash "$HOOK" >/dev/null 2>&1 || rc=$?
  assert "$name" "$expected" "$rc"
}

read_json() {
  jq -cn --arg p "$1" --arg o "${2:-}" --arg l "${3:-}" \
    '{tool_name: "Read", tool_input: ({file_path: $p} + (if $o != "" then {offset: ($o | tonumber)} else {} end) + (if $l != "" then {limit: ($l | tonumber)} else {} end))}'
}

bash_json() {
  jq -cn --arg c "$1" '{tool_name: "Bash", tool_input: {command: $c}}'
}

echo "hook: Read"
hook "small file passes" 0 "$(read_json "$TMP/small")"
hook "file at the threshold passes" 0 "$(read_json "$TMP/boundary")"
hook "large file is blocked" 2 "$(read_json "$TMP/large")"
hook "empty file passes" 0 "$(read_json "$TMP/empty")"
hook "missing file passes" 0 "$(read_json "$TMP/nope")"
hook "offset makes a targeted read" 0 "$(read_json "$TMP/large" 100)"
hook "limit makes a targeted read" 0 "$(read_json "$TMP/large" "" 50)"
hook "threshold follows DOTS_SHUNT_MIN_LINES" 0 "$(read_json "$TMP/large")" DOTS_SHUNT_MIN_LINES=2000
hook "a lower threshold blocks a small file" 2 "$(read_json "$TMP/small")" DOTS_SHUNT_MIN_LINES=50
hook "junk threshold falls back to the default" 2 "$(read_json "$TMP/large")" DOTS_SHUNT_MIN_LINES=abc

echo "hook: Bash"
hook "cat large is blocked" 2 "$(bash_json "cat $TMP/large")"
hook "cat -n large is blocked" 2 "$(bash_json "cat -n $TMP/large")"
hook "bat large is blocked" 2 "$(bash_json "bat $TMP/large")"
hook "quoted path is blocked" 2 "$(bash_json "cat \"$TMP/large\"")"
hook "second file in a cat is blocked" 2 "$(bash_json "cat $TMP/small $TMP/large")"
hook "cat small passes" 0 "$(bash_json "cat $TMP/small")"
hook "pipe is a targeted read" 0 "$(bash_json "cat $TMP/large | grep line")"
hook "redirect is a copy" 0 "$(bash_json "cat $TMP/large > $TMP/out")"
hook "head is bounded" 0 "$(bash_json "head -50 $TMP/large")"
hook "tail is bounded" 0 "$(bash_json "tail $TMP/large")"
hook "non-read command passes" 0 "$(bash_json "git status")"
hook "grep passes" 0 "$(bash_json "grep -n foo $TMP/large")"
hook "missing file passes" 0 "$(bash_json "cat $TMP/nope")"
hook "empty command passes" 0 "$(bash_json "")"

echo "hook: other tools"
hook "unrelated tool passes" 0 '{"tool_name":"Edit","tool_input":{"file_path":"x"}}'

# Stub claude: record the system prompt and stdin, answer with a canned reply.
mkdir -p "$TMP/bin"
cat >"$TMP/bin/claude" <<'STUB'
#!/usr/bin/env bash
out=${SHUNT_STUB_DIR:?}
: >"$out/args"
while [ $# -gt 0 ]; do
  case "$1" in
  --system-prompt) printf '%s' "$2" >"$out/system"; shift 2 ;;
  --model) printf '%s' "$2" >"$out/model"; shift 2 ;;
  *) printf '%s\n' "$1" >>"$out/args"; shift ;;
  esac
done
cat >"$out/stdin"
pwd >"$out/cwd"
printf '%s\n' "${SHUNT_STUB_REPLY:-- stub answer}"
STUB
chmod +x "$TMP/bin/claude"
export PATH="$TMP/bin:$PATH"
export SHUNT_STUB_DIR="$TMP/stub"
mkdir -p "$SHUNT_STUB_DIR"

run() {
  local rc=0
  bash "$SHUNT" "$@" >"$TMP/stdout" 2>"$TMP/stderr" || rc=$?
  echo "$rc"
}

echo "dots-shunt read"
assert "no subcommand is a usage error" 2 "$(run)"
assert "missing --question fails" 1 "$(run read --paths "$TMP/small")"
assert "missing --paths fails" 1 "$(run read --question q)"
assert "missing file fails before invoking" 1 "$(run read --question q --paths "$TMP/nope")"

rc=$(run read --question "what is it" --paths "$TMP/small" "$TMP/empty")
assert "read succeeds" 0 "$rc"
assert "read prints the worker answer" "- stub answer" "$(cat "$TMP/stdout")"
assert "read wraps each file in a tag" 2 "$(grep -c '^<file path=' "$SHUNT_STUB_DIR/stdin")"
assert "read sends the file content" "line 100" "$(sed -n '101p' "$SHUNT_STUB_DIR/stdin")"
assert "read ends with the question" "Question: what is it" "$(tail -1 "$SHUNT_STUB_DIR/stdin")"
assert "read uses the analyst prompt" "You are a precise code analyst" "$(cut -c1-30 "$SHUNT_STUB_DIR/system")"
assert "read reports tokens kept out of context" 1 "$(grep -c 'input tokens kept out of context' "$TMP/stderr")"
assert "worker defaults to haiku" haiku "$(cat "$SHUNT_STUB_DIR/model")"
assert "worker gets no tools" 1 "$(grep -cx -- '--tools' "$SHUNT_STUB_DIR/args")"
assert "worker loads no settings" 1 "$(grep -cx -- '--setting-sources' "$SHUNT_STUB_DIR/args")"
assert "worker runs outside the project" 0 "$(grep -c "^$REPO" "$SHUNT_STUB_DIR/cwd")"

DOTS_SHUNT_MODEL=sonnet run read --question q --paths "$TMP/small" >/dev/null
assert "DOTS_SHUNT_MODEL picks the worker" sonnet "$(cat "$SHUNT_STUB_DIR/model")"

echo "dots-shunt write"
assert "missing --spec fails" 1 "$(run write --reference "$TMP/small")"
assert "missing --reference fails" 1 "$(run write --spec s)"
assert "missing reference file fails" 1 "$(run write --spec s --reference "$TMP/nope")"

export SHUNT_STUB_REPLY=$'```ts\nexport const x = 1;\n```'
rc=$(run write --spec "make x" --reference "$TMP/small")
assert "write succeeds" 0 "$rc"
assert "write strips fences on stdout" "export const x = 1;" "$(cat "$TMP/stdout")"
assert "write starts with the spec" "Spec: make x" "$(head -1 "$SHUNT_STUB_DIR/stdin")"
assert "write includes the reference" "line 1" "$(sed -n '4p' "$SHUNT_STUB_DIR/stdin")"
assert "write uses the generator prompt" "You generate code files" "$(cut -c1-23 "$SHUNT_STUB_DIR/system")"

rc=$(run write --spec "make x" --reference "$TMP/small" --target "$TMP/gen.ts")
assert "write --target succeeds" 0 "$rc"
assert "write --target lands on disk" "export const x = 1;" "$(cat "$TMP/gen.ts")"
assert "write --target keeps stdout empty" "" "$(cat "$TMP/stdout")"
assert "write --target reports the line count" 1 "$(grep -c 'Wrote 1 lines' "$TMP/stderr")"

echo
echo "$PASSED passed, $FAILED failed"
[ "$FAILED" -eq 0 ]
