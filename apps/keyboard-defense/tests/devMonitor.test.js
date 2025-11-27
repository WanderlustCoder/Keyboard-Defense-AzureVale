import { test, afterEach } from "vitest";
import assert from "node:assert/strict";
import os from "node:os";
import path from "node:path";
import fs from "node:fs/promises";

import { parseArgs, runMonitor } from "../scripts/devMonitor.mjs";

const originalFetch = globalThis.fetch;

afterEach(() => {
  globalThis.fetch = originalFetch;
});

test("parseArgs merges CLI overrides onto defaults", () => {
  const options = parseArgs([
    "--url",
    "http://localhost:4200",
    "--interval",
    "1500",
    "--timeout",
    "60000",
    "--request-timeout",
    "2500",
    "--artifact",
    "./tmp/monitor.json",
    "--state",
    "./tmp/state.json",
    "--wait-ready",
    "--verbose"
  ]);

  assert.equal(options.url, "http://localhost:4200");
  assert.equal(options.intervalMs, 1500);
  assert.equal(options.timeoutMs, 60000);
  assert.equal(options.requestTimeoutMs, 2500);
  assert.equal(options.artifactPath, path.resolve("tmp/monitor.json"));
  assert.equal(options.statePath, path.resolve("tmp/state.json"));
  assert.equal(options.waitReady, true);
  assert.equal(options.verbose, true);
});

test("runMonitor resolves when a probe succeeds in wait-ready mode", async () => {
  const tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), "dev-monitor-success-"));
  const artifactPath = path.join(tmpDir, "summary.json");

  let callCount = 0;
  globalThis.fetch = async () => {
    callCount += 1;
    if (callCount === 1) {
      throw new Error("connect ECONNREFUSED 127.0.0.1:4173");
    }
    return { ok: true, status: 200 };
  };

  const summary = await runMonitor({
    url: "http://127.0.0.1:4173",
    intervalMs: 5,
    timeoutMs: 200,
    requestTimeoutMs: 5,
    artifactPath,
    waitReady: true,
    verbose: false
  });

  try {
    assert.equal(summary.status, "ready");
    assert.equal(summary.successCount, 1);
    assert.equal(summary.failureCount, 1);
    assert.ok(summary.readyAt);
    const artifact = JSON.parse(await fs.readFile(artifactPath, "utf8"));
    assert.equal(artifact.status, "ready");
  } finally {
    await fs.rm(tmpDir, { recursive: true, force: true });
  }
});

test("runMonitor marks timeout when no probe succeeds", async () => {
  const tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), "dev-monitor-timeout-"));
  const artifactPath = path.join(tmpDir, "summary.json");

  globalThis.fetch = async () => {
    throw new Error("connect ECONNREFUSED");
  };

  const summary = await runMonitor({
    url: "http://127.0.0.1:4173",
    intervalMs: 5,
    timeoutMs: 50,
    requestTimeoutMs: 5,
    artifactPath,
    waitReady: true,
    verbose: false
  });

  try {
    assert.equal(summary.status, "timeout");
    assert.equal(summary.successCount, 0);
    assert.ok(summary.failureCount > 0);
    const artifact = JSON.parse(await fs.readFile(artifactPath, "utf8"));
    assert.equal(artifact.status, "timeout");
  } finally {
    await fs.rm(tmpDir, { recursive: true, force: true });
  }
});

test("runMonitor records server metadata + last latency", async () => {
  const tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), "dev-monitor-metadata-"));
  const artifactPath = path.join(tmpDir, "summary.json");
  const statePath = path.join(tmpDir, "state.json");
  const stateSnapshot = {
    host: "127.0.0.1",
    port: 9999,
    url: "http://127.0.0.1:9999",
    logPath: ".devserver/server.log",
    flags: ["no-build"]
  };
  await fs.writeFile(statePath, JSON.stringify(stateSnapshot), "utf8");

  globalThis.fetch = async () => ({ ok: true, status: 200 });

  const summary = await runMonitor({
    url: "http://127.0.0.1:9999",
    intervalMs: 5,
    timeoutMs: 50,
    requestTimeoutMs: 5,
    artifactPath,
    statePath,
    waitReady: true,
    verbose: false
  });

  try {
    assert.equal(summary.server?.host, "127.0.0.1");
    assert.deepEqual(summary.flags, ["no-build"]);
    assert.equal(summary.status, "ready");
    assert.ok(summary.lastLatencyMs === 0 || summary.lastLatencyMs > 0);
    const persisted = JSON.parse(await fs.readFile(artifactPath, "utf8"));
    assert.equal(persisted.server.flags[0], "no-build");
    assert.ok(typeof persisted.uptimeMs === "number");
  } finally {
    await fs.rm(tmpDir, { recursive: true, force: true });
  }
});
