// Feeds pi activity into the tether.nvim event log through `agent-trail`:
// a turn per prompt, an edit or read per file tool, and a stop when pi
// settles. `agent-trail` owns the format and records the VCS checkpoints.
//
// Install: link this file into ~/.pi/agent/extensions/ and put
// bin/agent-trail on PATH, or set AGENT_TRAIL to its path.

import { execFile } from "node:child_process";
import { isAbsolute, join, resolve } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const AGENT = "pi";
const AGENT_TRAIL = process.env.AGENT_TRAIL ?? join(process.env.HOME ?? "", ".local", "bin", "agent-trail");
// One id per pi process, so turns of parallel pi instances stay apart.
const SESSION = `pi-${process.pid}`;

// Each write waits for the one before it, so a stop never lands before the
// edits of its turn.
let queue: Promise<void> = Promise.resolve();

function trail(cwd: string, args: string[]): void {
  queue = queue.then(
    () =>
      new Promise<void>((done) => {
        // An event is never worth interrupting the agent over, so errors
        // resolve too.
        execFile(AGENT_TRAIL, args, { cwd, env: { ...process.env, AGENT_TRAIL_SESSION: SESSION } }, () => done());
      }),
  );
}

function pathOf(input: unknown, cwd: string): string | undefined {
  const path = (input as { path?: unknown } | undefined)?.path;
  if (typeof path !== "string" || path === "") {
    return undefined;
  }
  return isAbsolute(path) ? path : resolve(cwd, path);
}

export default function (pi: ExtensionAPI) {
  pi.on("before_agent_start", async (event, ctx) => {
    trail(ctx.cwd, ["turn", AGENT, event.prompt.slice(0, 200)]);
  });

  pi.on("tool_result", async (event, ctx) => {
    if (event.isError) {
      return;
    }
    const path = pathOf(event.input, ctx.cwd);
    if (!path) {
      return;
    }
    if (event.toolName === "edit" || event.toolName === "write") {
      const details = event.details as { firstChangedLine?: number } | undefined;
      const line = details?.firstChangedLine;
      trail(ctx.cwd, ["edit", AGENT, path, ...(line ? [String(line)] : [])]);
    } else if (event.toolName === "read") {
      const offset = (event.input as { offset?: unknown }).offset;
      trail(ctx.cwd, ["read", AGENT, path, ...(typeof offset === "number" ? [String(offset)] : [])]);
    }
  });

  pi.on("agent_settled", async (_event, ctx) => {
    trail(ctx.cwd, ["stop", AGENT]);
  });

  pi.on("session_shutdown", async () => {
    await queue;
  });
}
