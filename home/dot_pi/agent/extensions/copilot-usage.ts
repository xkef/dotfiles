import { execFile } from "node:child_process";
import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";
import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";

const STATUS_KEY = "copilot-usage";
const API_TIMEOUT_MS = 5_000;
const execFileAsync = promisify(execFile);

type Usage = {
  used: number;
  total: number;
};

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

function numberField(value: unknown): number | undefined {
  return typeof value === "number" && Number.isFinite(value) ? value : undefined;
}

function parseUsage(value: unknown): Usage | undefined {
  if (!isRecord(value)) {
    return undefined;
  }

  const snapshots = value.quota_snapshots;
  if (!isRecord(snapshots)) {
    return undefined;
  }

  const quota = snapshots.premium_interactions;
  if (!isRecord(quota)) {
    return undefined;
  }

  const total = numberField(quota.entitlement);
  if (total === undefined || total <= 0) {
    return undefined;
  }

  const remaining = numberField(quota.quota_remaining) ?? numberField(quota.remaining);
  const used = numberField(quota.credits_used) ?? (remaining === undefined ? undefined : total - remaining);
  if (used === undefined) {
    return undefined;
  }

  return {
    used: Math.max(0, Math.round(used)),
    total: Math.round(total),
  };
}

async function readOAuthToken(): Promise<string | undefined> {
  const agentDir = process.env.PI_CODING_AGENT_DIR ?? join(homedir(), ".pi", "agent");
  const value: unknown = JSON.parse(await readFile(join(agentDir, "auth.json"), "utf8"));
  if (!isRecord(value)) {
    return undefined;
  }

  const credential = value["github-copilot"];
  if (!isRecord(credential) || credential.type !== "oauth") {
    return undefined;
  }

  return typeof credential.refresh === "string" ? credential.refresh : undefined;
}

function isOffline(): boolean {
  return ["1", "true", "yes"].includes((process.env.PI_OFFLINE ?? "").toLowerCase());
}

function showUsage(ctx: ExtensionContext, usage: Usage): void {
  const format = new Intl.NumberFormat("en-US");
  const text = `Copilot ${format.format(usage.used)} / ${format.format(usage.total)} AI credits`;
  const percent = (usage.used / usage.total) * 100;
  const color = percent > 90 ? "error" : percent > 70 ? "warning" : "dim";

  ctx.ui.setStatus(STATUS_KEY, ctx.ui.theme.fg(color, text));
}

export default function (pi: ExtensionAPI) {
  let active = false;
  let controller: AbortController | undefined;
  let pendingContext: ExtensionContext | undefined;
  let request: Promise<void> | undefined;

  async function update(ctx: ExtensionContext, signal: AbortSignal): Promise<void> {
    const token = await readOAuthToken();
    if (!token) {
      if (active) {
        ctx.ui.setStatus(STATUS_KEY, undefined);
      }
      return;
    }

    // Use Pi's Copilot account instead of whichever GitHub account gh has active.
    const result = await execFileAsync("gh", ["api", "copilot_internal/user"], {
      encoding: "utf8",
      env: { ...process.env, GH_TOKEN: token },
      maxBuffer: 1024 * 1024,
      signal,
      timeout: API_TIMEOUT_MS,
    });
    const usage = parseUsage(JSON.parse(result.stdout));
    if (!active) {
      return;
    }

    if (usage) {
      showUsage(ctx, usage);
    } else {
      ctx.ui.setStatus(STATUS_KEY, undefined);
    }
  }

  function refresh(ctx: ExtensionContext): void {
    if (isOffline()) {
      return;
    }
    if (request) {
      pendingContext = ctx;
      return;
    }

    controller = new AbortController();
    const currentController = controller;
    request = update(ctx, currentController.signal)
      .catch(() => {})
      .finally(() => {
        request = undefined;
        if (controller === currentController) {
          controller = undefined;
        }

        const nextContext = pendingContext;
        pendingContext = undefined;
        if (active && nextContext) {
          refresh(nextContext);
        }
      });
  }

  pi.on("session_start", async (_event, ctx) => {
    active = true;
    if (ctx.hasUI) {
      refresh(ctx);
    }
  });

  pi.on("agent_settled", async (_event, ctx) => {
    if (ctx.hasUI) {
      refresh(ctx);
    }
  });

  pi.on("session_shutdown", async () => {
    active = false;
    pendingContext = undefined;
    controller?.abort();
  });
}
