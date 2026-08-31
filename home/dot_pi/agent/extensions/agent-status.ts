// Publishes this agent's state for the `tmux-agents` picker, in the same
// tab-separated format the claude-agent-status hook writes.
//
// pi inherits TMUX_PANE from the pane it was started in, so keying the state
// file by that pane id gives the picker a join back to tmux that holds across
// sessions. Without a pane there is nothing to join to, so the extension does
// nothing at all.
//
// pi documents agent_settled and ui_prompt_start/end for status integrations
// like this one: agent_settled is the point where pi will not continue on its
// own, and the ui_prompt pair brackets a prompt that blocks on the user.

import { mkdirSync, renameSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const AGENT = "pi";
const NO_TOOL = "-";

const pane = process.env.TMUX_PANE;
const stateDir = join(
  process.env.XDG_STATE_HOME ?? join(process.env.HOME ?? "", ".local", "state"),
  "agents",
);
const stateFile = pane ? join(stateDir, pane) : "";

type State = "idle" | "busy" | "waiting";

function publish(state: State, tool: string, cwd: string): void {
  try {
    // The cwd goes last so a path never shifts another field, and the write
    // goes through a temp file so the picker never reads a half-written line.
    const epoch = Math.floor(Date.now() / 1000);
    const tmp = `${stateFile}.${process.pid}`;
    writeFileSync(tmp, `${AGENT}\t${state}\t${tool}\t${epoch}\t${cwd}\n`);
    renameSync(tmp, stateFile);
  } catch {
    // A status file is never worth interrupting the agent over.
  }
}

export default function (pi: ExtensionAPI) {
  if (!pane) {
    return;
  }
  mkdirSync(stateDir, { recursive: true });

  pi.on("session_start", async (_event, ctx) => {
    publish("idle", NO_TOOL, ctx.cwd);
  });

  pi.on("agent_start", async (_event, ctx) => {
    publish("busy", NO_TOOL, ctx.cwd);
  });

  pi.on("tool_call", async (event, ctx) => {
    publish("busy", event.toolName, ctx.cwd);
  });

  pi.on("agent_settled", async (_event, ctx) => {
    publish("idle", NO_TOOL, ctx.cwd);
  });

  pi.on("ui_prompt_start", async (_event, ctx) => {
    publish("waiting", NO_TOOL, ctx.cwd);
  });

  // A prompt can close while a run is still going, so ask pi which it is
  // rather than assuming the agent went idle.
  pi.on("ui_prompt_end", async (_event, ctx) => {
    publish(ctx.isIdle() ? "idle" : "busy", NO_TOOL, ctx.cwd);
  });

  pi.on("session_shutdown", async () => {
    try {
      rmSync(stateFile, { force: true });
    } catch {
      // Nothing to do; a stale file drops out of the picker on its own.
    }
  });
}
