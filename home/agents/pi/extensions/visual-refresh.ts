import { basename } from "node:path";
import type { Usage } from "@earendil-works/pi-ai";
import {
  VERSION,
  type ExtensionAPI,
  type ExtensionContext,
  type Theme,
  type ThemeColor,
} from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const METER_WIDTH = 8;
const MIN_GAP = 2;
const PULSE_INTERVAL_MS = 110;
const ANSI_CYAN = "\x1b[36m";
const ANSI_RESET = "\x1b[39m";
const PULSE_FRAMES = ["·", "•", "◆", "•"].map(
  (frame) => `${ANSI_CYAN}${frame}${ANSI_RESET}`,
);

type Totals = {
  input: number;
  output: number;
};

function formatTokens(count: number): string {
  if (count < 1_000) {
    return count.toString();
  }
  if (count < 10_000) {
    return `${(count / 1_000).toFixed(1)}k`;
  }
  if (count < 1_000_000) {
    return `${Math.round(count / 1_000)}k`;
  }

  return `${(count / 1_000_000).toFixed(1)}m`;
}

function addUsage(totals: Totals, usage: Usage): void {
  totals.input += usage.input;
  totals.output += usage.output;
}

function getTotals(ctx: ExtensionContext): Totals {
  const totals = { input: 0, output: 0 };

  for (const entry of ctx.sessionManager.getEntries()) {
    if (entry.type !== "message") {
      continue;
    }

    if (entry.message.role === "assistant") {
      addUsage(totals, entry.message.usage);
    } else if (entry.message.role === "toolResult" && entry.message.usage) {
      addUsage(totals, entry.message.usage);
    }
  }

  return totals;
}

function align(left: string, right: string, width: number): string {
  if (width <= 0) {
    return "";
  }

  const rightWidth = visibleWidth(right);
  if (rightWidth >= width) {
    return truncateToWidth(right, width, "");
  }

  const leftWidth = Math.max(0, width - rightWidth - MIN_GAP);
  const fittedLeft = truncateToWidth(left, leftWidth, "…");
  const padding = " ".repeat(
    Math.max(MIN_GAP, width - visibleWidth(fittedLeft) - rightWidth),
  );

  return truncateToWidth(fittedLeft + padding + right, width, "");
}

function frameLine(
  left: string,
  right: string,
  width: number,
  start: string,
  end: string,
  theme: Theme,
): string {
  if (width < visibleWidth(start) + visibleWidth(end)) {
    return theme.fg("borderAccent", "─".repeat(Math.max(0, width)));
  }

  const innerWidth = width - visibleWidth(start) - visibleWidth(end);
  const fittedLeft = truncateToWidth(left, Math.max(0, innerWidth - MIN_GAP), "");
  const rightWidth = Math.max(0, innerWidth - visibleWidth(fittedLeft) - MIN_GAP);
  const fittedRight = truncateToWidth(right, rightWidth, "");
  const fill = "─".repeat(
    Math.max(0, innerWidth - visibleWidth(fittedLeft) - visibleWidth(fittedRight)),
  );

  return (
    theme.fg("borderAccent", start) +
    fittedLeft +
    theme.fg("borderMuted", fill) +
    fittedRight +
    theme.fg("borderAccent", end)
  );
}

function keyHint(theme: Theme, key: string, label: string): string {
  return `${theme.fg("accent", key)} ${theme.fg("dim", label)}`;
}

function renderHeader(theme: Theme, project: string, width: number): string[] {
  const brand = ` ${theme.bold(theme.fg("accent", "π"))} ${theme.bold("PI")} `;
  const version = theme.fg("dim", ` v${VERSION} `);
  const projectName = theme.fg("muted", ` ${project} `);
  const hints = [
    theme.fg("accent", "/help"),
    keyHint(theme, "ctrl+l", "model"),
    keyHint(theme, "shift+tab", "think"),
    keyHint(theme, "ctrl+o", "tools"),
  ].join(theme.fg("borderMuted", " · "));

  return [
    frameLine(brand, version, width, "╭─", "─╮", theme),
    frameLine(projectName, ` ${hints} `, width, "╰─", "─╯", theme),
  ];
}

function formatCwd(cwd: string): string {
  const home = process.env.HOME;
  if (home && (cwd === home || cwd.startsWith(`${home}/`))) {
    return `~${cwd.slice(home.length)}`;
  }

  return cwd;
}

function thinkingColor(level: string): ThemeColor {
  switch (level) {
    case "minimal":
      return "thinkingMinimal";
    case "low":
      return "thinkingLow";
    case "medium":
      return "thinkingMedium";
    case "high":
      return "thinkingHigh";
    case "xhigh":
      return "thinkingXhigh";
    case "max":
      return "thinkingMax";
    default:
      return "thinkingOff";
  }
}

function contextMeter(ctx: ExtensionContext, theme: Theme): string {
  const usage = ctx.getContextUsage();
  if (!usage || usage.percent === null) {
    return theme.fg("dim", "ctx unknown");
  }

  const percent = Math.max(0, Math.min(100, Math.round(usage.percent)));
  const filled = Math.round((percent / 100) * METER_WIDTH);
  const color: ThemeColor = percent > 90 ? "error" : percent > 70 ? "warning" : "accent";
  const meter = theme.fg(color, "━".repeat(filled));
  const remainder = theme.fg("borderMuted", "─".repeat(METER_WIDTH - filled));

  return `${theme.fg("dim", "ctx")} ${meter}${remainder} ${theme.fg(color, `${percent}%`)}`;
}

function footerLines(
  ctx: ExtensionContext,
  theme: Theme,
  branch: string | null,
  statuses: ReadonlyMap<string, string>,
  width: number,
): string[] {
  const model = ctx.model?.id ?? "no model";
  const thinking = ctx.thinkingLevel ?? "off";
  const primaryLeft = [
    theme.bold(theme.fg("accent", "π")),
    theme.fg("text", model),
    theme.fg(thinkingColor(thinking), thinking),
  ].join(theme.fg("borderMuted", "  ·  "));

  const location = [formatCwd(ctx.cwd), branch].filter(Boolean).join("  @ ");
  const sessionName = ctx.sessionManager.getSessionName();
  const secondaryLeft = theme.fg(
    "muted",
    sessionName ? `${location}  ·  ${sessionName}` : location,
  );
  const totals = getTotals(ctx);
  const stats = theme.fg(
    "dim",
    `↑${formatTokens(totals.input)}  ↓${formatTokens(totals.output)}`,
  );
  const statusText = Array.from(statuses.values())
    .map((status) => status.replace(/[\r\n\t]+/g, " ").trim())
    .filter(Boolean)
    .join(theme.fg("borderMuted", "  ·  "));
  const secondaryRight = statusText ? `${stats}  ${statusText}` : stats;

  return [
    align(primaryLeft, contextMeter(ctx, theme), width),
    align(secondaryLeft, secondaryRight, width),
  ];
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    if (ctx.mode !== "tui") {
      return;
    }

    const project = basename(ctx.cwd);
    ctx.ui.setTitle(`π ${project}`);
    ctx.ui.setHiddenThinkingLabel("reasoning");
    ctx.ui.setWorkingIndicator({
      frames: PULSE_FRAMES,
      intervalMs: PULSE_INTERVAL_MS,
    });
    ctx.ui.setHeader((_tui, theme) => ({
      render: (width) => renderHeader(theme, project, width),
      invalidate() {},
    }));
    ctx.ui.setFooter((tui, theme, footerData) => ({
      dispose: footerData.onBranchChange(() => tui.requestRender()),
      render: (width) =>
        footerLines(
          ctx,
          theme,
          footerData.getGitBranch(),
          footerData.getExtensionStatuses(),
          width,
        ),
      invalidate() {},
    }));
  });
}
