import assert from "node:assert/strict";
import { afterEach, mock, test } from "node:test";
import { promisify } from "node:util";

const CODEX_PROVIDER = "openai-codex";
const COPILOT_PROVIDER = "github-copilot";
const STATUS_KEY = "copilot-usage";
const tokenPayload = { "https://api.openai.com/auth": { chatgpt_account_id: "account-id" } };
const CODEX_TOKEN = `header.${Buffer.from(JSON.stringify(tokenPayload)).toString("base64url")}.signature`;
const HTTP_UNAUTHORIZED = 401;
const copilotQuota = {
  quota_snapshots: {
    premium_interactions: { entitlement: 1_500, credits_used: 250 },
  },
};
const codexQuota = {
  rate_limit: {
    primary_window: { used_percent: 20, limit_window_seconds: 18_000 },
    secondary_window: { used_percent: 40, limit_window_seconds: 604_800 },
  },
  credits: { has_credits: true, unlimited: false, balance: "1234.5" },
};

let readToken = async () => JSON.stringify({
  [COPILOT_PROVIDER]: { type: "oauth", refresh: "copilot-token" },
});
let runGh = async () => ({ stdout: JSON.stringify(copilotQuota) });
mock.module("node:fs/promises", { exports: { readFile: (...args) => readToken(...args) } });
mock.module("node:child_process", {
  exports: {
    execFile: Object.assign(() => {}, {
      [promisify.custom]: (...args) => runGh(...args),
    }),
  },
});
const { default: usageExtension } = await import("../home/dot_pi/agent/extensions/copilot-usage.ts");

const sessions = [];
const originalOffline = process.env.PI_OFFLINE;
afterEach(async () => {
  for (const session of sessions.splice(0)) {
    await session.emit("session_shutdown");
  }
  mock.restoreAll();
  if (originalOffline === undefined) {
    delete process.env.PI_OFFLINE;
  } else {
    process.env.PI_OFFLINE = originalOffline;
  }
  readToken = async () => JSON.stringify({
    [COPILOT_PROVIDER]: { type: "oauth", refresh: "copilot-token" },
  });
  runGh = async () => ({ stdout: JSON.stringify(copilotQuota) });
});

function createSession(provider = CODEX_PROVIDER) {
  delete process.env.PI_OFFLINE;
  const handlers = new Map();
  const statuses = new Map();
  const colors = [];
  const authCalls = [];
  const ctx = {
    hasUI: true,
    model: { provider, id: "gpt-test" },
    modelRegistry: {
      getProviderAuth: async (id) => {
        authCalls.push(id);
        return { auth: { apiKey: CODEX_TOKEN }, source: "OAuth" };
      },
    },
    ui: {
      theme: { fg: (color, text) => { colors.push(color); return text; } },
      setStatus: (key, text) => { statuses.set(key, text); },
    },
  };
  usageExtension({ on: (event, handler) => handlers.set(event, handler) });
  const session = {
    ctx, authCalls, colors,
    status: () => statuses.get(STATUS_KEY),
    emit: (event) => handlers.get(event)?.({ model: ctx.model }, ctx),
    select: async (provider) => {
      ctx.model = { provider, id: "gpt-test" };
      await session.emit("model_select");
    },
  };
  sessions.push(session);
  return session;
}

async function flush() {
  for (let i = 0; i < 5; i++) {
    await new Promise((resolve) => setImmediate(resolve));
  }
}

function mockQuota(payload = codexQuota) {
  return mock.method(globalThis, "fetch", async () => Response.json(payload));
}

test("Codex shows remaining allowance and credits instead of Copilot", async () => {
  const fetch = mockQuota();
  let ghCalls = 0;
  runGh = async () => { ghCalls++; return { stdout: JSON.stringify(copilotQuota) }; };
  const session = createSession();
  await session.emit("session_start");
  await flush();

  assert.equal(session.status(), "OpenAI 5h 80% / 7d 60% left · 1,234.5 credits");
  assert.equal(ghCalls, 0);
  assert.deepEqual(session.authCalls, [CODEX_PROVIDER]);
  const [url, options] = fetch.mock.calls[0].arguments;
  assert.equal(url, "https://chatgpt.com/backend-api/wham/usage");
  assert.equal(options.headers.Authorization, `Bearer ${CODEX_TOKEN}`);
  assert.equal(new Headers(options.headers).get("chatgpt-account-id"), "account-id");
  assert.ok(options.signal instanceof AbortSignal);
});

test("GPT models billed through Copilot keep Copilot credits", async () => {
  const fetch = mockQuota();
  const session = createSession(COPILOT_PROVIDER);
  await session.emit("session_start");
  await flush();

  assert.equal(session.status(), "Copilot 250 / 1,500 AI credits");
  assert.equal(fetch.mock.callCount(), 0);
});

test("model selection replaces the previous provider's status immediately", async () => {
  mockQuota();
  const session = createSession(COPILOT_PROVIDER);
  await session.emit("session_start");
  await flush();
  await session.select(CODEX_PROVIDER);
  assert.equal(session.status(), undefined);
  await flush();
  assert.match(session.status(), /^OpenAI /);
  await session.select(COPILOT_PROVIDER);
  assert.equal(session.status(), undefined);
  await flush();
  assert.match(session.status(), /^Copilot /);
});

test("a late response cannot restore credits from the old provider", async () => {
  let finish;
  runGh = () => new Promise((resolve) => { finish = resolve; });
  mockQuota();
  const session = createSession(COPILOT_PROVIDER);
  await session.emit("session_start");
  await flush();
  await session.select(CODEX_PROVIDER);
  finish({ stdout: JSON.stringify(copilotQuota) });
  await flush();

  assert.match(session.status(), /^OpenAI /);
});

test("a late Codex response cannot overwrite Copilot credits", async () => {
  let finish;
  mock.method(globalThis, "fetch", () => new Promise((resolve) => { finish = resolve; }));
  const session = createSession();
  await session.emit("session_start");
  await flush();
  await session.select(COPILOT_PROVIDER);
  finish(Response.json(codexQuota));
  await flush();
  assert.equal(session.status(), "Copilot 250 / 1,500 AI credits");
});

test("API-key OpenAI and unrelated providers do not show Copilot credits", async () => {
  const fetch = mockQuota();
  const session = createSession(COPILOT_PROVIDER);
  await session.emit("session_start");
  await flush();
  for (const provider of ["openai", "anthropic"]) {
    await session.select(provider);
    await flush();
    assert.equal(session.status(), undefined);
  }
  assert.equal(fetch.mock.callCount(), 0);
});

test("missing Codex auth and failed requests leave the status empty", async () => {
  const fetch = mock.method(globalThis, "fetch", async () => new Response(null, { status: HTTP_UNAUTHORIZED }));
  const session = createSession();
  session.ctx.modelRegistry.getProviderAuth = async () => undefined;
  await session.emit("session_start");
  await flush();
  assert.equal(session.status(), undefined);
  assert.equal(fetch.mock.callCount(), 0);

  session.ctx.modelRegistry.getProviderAuth = async () => ({ auth: { apiKey: CODEX_TOKEN } });
  await session.emit("agent_settled");
  await flush();
  assert.equal(session.status(), undefined);
});

test("malformed Codex tokens cannot send an unaffiliated usage request", async () => {
  const fetch = mockQuota();
  const session = createSession();
  for (const token of ["invalid", "header.e30.signature"]) {
    session.ctx.modelRegistry.getProviderAuth = async () => ({ auth: { apiKey: token } });
    await session.emit("session_start");
    await flush();
    assert.equal(session.status(), undefined);
  }
  assert.equal(fetch.mock.callCount(), 0);
});

test("Codex handles unlimited and zero credits without inventing a balance", async () => {
  const fetch = mockQuota({ credits: { unlimited: true, balance: null } });
  const session = createSession();
  await session.emit("session_start");
  await flush();
  assert.equal(session.status(), "OpenAI unlimited credits");

  fetch.mock.mockImplementation(async () => Response.json({ credits: { unlimited: false, balance: "0" } }));
  await session.emit("agent_settled");
  await flush();
  assert.equal(session.status(), "OpenAI 0 credits");

  fetch.mock.mockImplementation(async () => Response.json({ credits: { balance: "" } }));
  await session.emit("agent_settled");
  await flush();
  assert.equal(session.status(), undefined);
});

test("subscription-only usage is colored by the most exhausted window", async () => {
  mockQuota({
    rate_limit: {
      primary_window: { used_percent: 95, limit_window_seconds: 18_000 },
      secondary_window: { used_percent: 10, limit_window_seconds: 604_800 },
    },
    credits: null,
  });
  const session = createSession();
  await session.emit("session_start");
  await flush();
  assert.equal(session.status(), "OpenAI 5h 5% / 7d 90% left");
  assert.equal(session.colors.at(-1), "error");
});

test("window labels follow the API and missing windows are omitted", async () => {
  mockQuota({
    rate_limit: {
      primary_window: null,
      secondary_window: { used_percent: 1, limit_window_seconds: 604_800 },
    },
    credits: { balance: null },
  });
  const session = createSession();
  await session.emit("session_start");
  await flush();
  assert.equal(session.status(), "OpenAI 7d 99% left");
});

test("network errors and malformed responses clear stale usage", async () => {
  const fetch = mockQuota();
  const session = createSession();
  await session.emit("session_start");
  await flush();
  assert.match(session.status(), /^OpenAI /);

  for (const response of [
    async () => { throw new Error("offline"); },
    async () => new Response("not JSON"),
    async () => Response.json({ rate_limit: { primary_window: {} }, credits: { balance: "unknown" } }),
  ]) {
    fetch.mock.mockImplementation(response);
    await session.emit("agent_settled");
    await flush();
    assert.equal(session.status(), undefined);
  }
});

test("offline and non-UI sessions make no credit requests", async () => {
  const fetch = mockQuota();
  let ghCalls = 0;
  runGh = async () => { ghCalls++; return { stdout: JSON.stringify(copilotQuota) }; };
  const session = createSession();
  process.env.PI_OFFLINE = "1";
  await session.emit("session_start");
  await session.select(COPILOT_PROVIDER);
  await flush();
  delete process.env.PI_OFFLINE;
  session.ctx.hasUI = false;
  await session.select(CODEX_PROVIDER);
  await session.emit("agent_settled");
  await flush();
  assert.equal(fetch.mock.callCount(), 0);
  assert.equal(ghCalls, 0);
});

test("shutdown prevents in-flight results from publishing", async () => {
  let finish;
  mock.method(globalThis, "fetch", () => new Promise((resolve) => { finish = resolve; }));
  const session = createSession();
  await session.emit("session_start");
  await flush();
  await session.emit("session_shutdown");
  finish(Response.json(codexQuota));
  await flush();
  assert.equal(session.status(), undefined);
});
