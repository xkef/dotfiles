// Maps pi events to agent states for the `mux-agents` picker and the
// WezTerm status line. `agent-state` owns the storage and the format.
//
// pi inherits WEZTERM_PANE from the pane it started in, and `agent-state`
// finds the pane through it. Without a pane the extension does nothing.
//
// pi documents agent_settled and ui_prompt_start/end for status integrations
// like this one. agent_settled marks the point where pi stops on its own, and
// the ui_prompt pair brackets a prompt that blocks on the user.

import { execFile, execFileSync } from "node:child_process";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const AGENT = "pi";
const NO_TOOL = "-";
const AGENT_STATE = join(process.env.HOME ?? "", ".local", "bin", "agent-state");

type State = "idle" | "busy" | "waiting";

// Each write waits for the one before it. Concurrent processes could land
// out of order and leave a finished run reading busy.
let queue: Promise<void> = Promise.resolve();

function publish(state: State, tool: string, cwd: string): void {
  queue = queue.then(
    () =>
      new Promise<void>((resolve) => {
        // A status entry is never worth interrupting the agent over, so
        // errors resolve too.
        execFile(AGENT_STATE, ["set", AGENT, state, tool, cwd], () => resolve());
      }),
  );
}

export default function (pi: ExtensionAPI) {
  if (!process.env.WEZTERM_PANE) {
    return;
  }

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

  // A prompt can close while a run still goes on, so ask pi which it is
  // instead of assuming the agent went idle.
  pi.on("ui_prompt_end", async (_event, ctx) => {
    publish(ctx.isIdle() ? "idle" : "busy", NO_TOOL, ctx.cwd);
  });

  // Synchronous, so the entry is gone before pi exits. The launcher clears
  // it again after pi returns.
  pi.on("session_shutdown", async () => {
    await queue;
    try {
      execFileSync(AGENT_STATE, ["clear"]);
    } catch {
      // A stale entry drops out of the picker once its pane closes.
    }
  });
}
