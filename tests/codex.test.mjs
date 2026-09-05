import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";

const ROOT = resolve(import.meta.dirname, "..");
const CONFIG_TEMPLATE = join(ROOT, "home/dot_codex/modify_config.toml.tmpl");
const PICKER = join(ROOT, "home/dot_local/bin/executable_tmux-agents");
const TASK = join(ROOT, "home/dot_local/bin/executable_agent-task");
const CODEX_PANE = "%901";
const CLAUDE_PANE = "%902";

function command(file, args, options = {}) {
  return execFileSync(file, args, { encoding: "utf8", ...options });
}

const configScript = command("chezmoi", ["execute-template"], {
  cwd: ROOT,
  input: readFileSync(CONFIG_TEMPLATE, "utf8"),
});

function mergeConfig(input) {
  return command("bash", ["-c", configScript], { input });
}

function parseConfig(input) {
  return JSON.parse(command("taplo", ["get", "-o", "json"], { input }));
}

test("Codex defaults include the local status line and approval preferences", () => {
  const config = parseConfig(mergeConfig(""));
  assert.equal(config.service_tier, "default");
  assert.equal(config.approvals_reviewer, "auto_review");
  assert.equal(config.tui.status_line_use_colors, true);
  assert.deepEqual(config.tui.status_line, [
    "model-with-reasoning", "context-used", "weekly-limit", "context-window-size",
    "fast-mode", "git-branch", "five-hour-limit", "estimated-thread-cost",
  ]);
});

for (const statusLine of ['["model-name"]', '[\n  "model-name",\n]']) {
  test(`Codex replaces ${statusLine.includes("\n") ? "multiline" : "inline"} status lines`, () => {
    const output = mergeConfig(`model = "local-model"
service_tier = "fast"
[tui]
status_line = ${statusLine}
status_line_use_colors = false
notifications = false
[tui.model_availability_nux]
seen = 3
[projects."/tmp/project with spaces"]
trust_level = "trusted"
[profiles.custom]
service_tier = "fast"
`);
    const config = parseConfig(output);
    assert.equal(config.model, "local-model");
    assert.equal(config.service_tier, "default");
    assert.equal(config.tui.status_line_use_colors, true);
    assert.equal(config.tui.status_line.length, 8);
    assert.equal(config.tui.notifications, false);
    assert.equal(config.tui.model_availability_nux.seen, 3);
    assert.equal(config.projects["/tmp/project with spaces"].trust_level, "trusted");
    assert.equal(config.profiles.custom.service_tier, "fast");
    assert.equal(mergeConfig(output), output);
  });
}

test("Codex adds a missing TUI table after existing tables", () => {
  const output = mergeConfig('[projects."/tmp/project"]\ntrust_level = "trusted"\n');
  const config = parseConfig(output);
  assert.equal(config.projects["/tmp/project"].trust_level, "trusted");
  assert.equal(config.tui.status_line_use_colors, true);
  assert.equal(mergeConfig(output), output);
});

function pickerFixture(t) {
  const dir = mkdtempSync(join(tmpdir(), "codex-picker-"));
  t.after(() => rmSync(dir, { recursive: true, force: true }));
  const bin = join(dir, "bin");
  mkdirSync(bin);
  const env = { ...process.env, PATH: `${bin}:${process.env.PATH}`, XDG_STATE_HOME: dir };
  writeFileSync(join(bin, "tmux"), `#!/bin/sh
case "$1" in
  list-panes) printf '%s\\n' "$TEST_PANES" ;;
  *) printf '%s\\n' "$*" >> "$XDG_STATE_HOME/tmux-calls" ;;
esac
`, { mode: 0o755 });
  writeFileSync(join(bin, "fzf"), '#!/bin/sh\ntee "$XDG_STATE_HOME/rows" | head -n 1\n', {
    mode: 0o755,
  });
  writeFileSync(join(bin, "agent-task"), '#!/bin/sh\nprintf "%s\\n" "$TEST_SUMMARY"\n', {
    mode: 0o755,
  });
  env.TEST_PANES = `${CODEX_PANE}\twork:1\tcodex\t/tmp/project with spaces`;
  env.TEST_SUMMARY = "Track Codex settings and agent summaries";
  return { dir, bin, env };
}

test("the picker discovers Codex without a state file and displays its task", (t) => {
  const { dir, env } = pickerFixture(t);
  command("bash", [PICKER], { env });
  const rows = readFileSync(join(dir, "rows"), "utf8");
  assert.match(rows, /codex/);
  assert.match(rows, /running/);
  assert.ok(rows.includes(env.TEST_SUMMARY));
  assert.ok(rows.includes("/tmp/project with spaces"));
  const calls = readFileSync(join(dir, "tmux-calls"), "utf8");
  assert.match(calls, /switch-client -t work:1/);
  assert.ok(calls.includes(`select-pane -t ${CODEX_PANE}`));
  assert.notEqual(command("bash", [PICKER, "--count"], { env }).trim(), "");
});

test("Codex discovery overrides stale state while other agents retain their status", (t) => {
  const { dir, env } = pickerFixture(t);
  const state = join(dir, "agents");
  mkdirSync(state);
  const record = `claude\twaiting\t-\t${Math.floor(Date.now() / 1000)}\t/tmp/claude\n`;
  writeFileSync(join(state, CODEX_PANE), record);
  writeFileSync(join(state, CLAUDE_PANE), record);
  writeFileSync(join(state, "%903"), record);
  env.TEST_PANES += `\n${CLAUDE_PANE}\tother:2\tclaude\t/tmp/claude`;
  command("bash", [PICKER], { env });
  const rows = readFileSync(join(dir, "rows"), "utf8");
  assert.match(rows, /codex/);
  assert.match(rows, /claude/);
  assert.match(rows, /waiting/);
  assert.equal(rows.trim().split("\n").length, 2);
  for (const row of rows.trim().split("\n")) {
    assert.equal(row.split("\t").length, 3);
  }
});

test("an ordinary shell without an agent does not appear", (t) => {
  const { dir, env } = pickerFixture(t);
  env.TEST_PANES = `${CODEX_PANE}\twork:1\tfish\t/tmp/project`;
  assert.equal(command("bash", [PICKER, "--count"], { env }), "");
  command("bash", [PICKER], { env });
  assert.match(readFileSync(join(dir, "tmux-calls"), "utf8"), /No agents running/);
});

test("task summaries round-trip as one line and stay separate by pane", (t) => {
  const { bin, env } = pickerFixture(t);
  const id = join(bin, "id");
  writeFileSync(id, '#!/bin/sh\nprintf "%s\\n" "$TEST_UID"\n', { mode: 0o755 });
  env.TEST_UID = `test-${process.pid}`;
  env.TMUX_PANE = CODEX_PANE;
  const taskDir = `/tmp/tmux-agent-tasks-${env.TEST_UID}`;
  t.after(() => rmSync(taskDir, { recursive: true, force: true }));
  command("bash", [TASK, "Track Codex\tsettings\nand summaries"], { env });
  const summary = command("bash", [TASK, "--read", CODEX_PANE], { env });
  assert.equal(summary.trim(), "Track Codex settings and summaries");
  command("bash", [TASK, "Another task"], { env: { ...env, TMUX_PANE: CLAUDE_PANE } });
  assert.equal(command("bash", [TASK, "--read", CODEX_PANE], { env }), summary);
  command("bash", [TASK, "x".repeat(100)], { env });
  assert.ok(command("bash", [TASK, "--read", CODEX_PANE], { env }).trim().length <= 60);
});
