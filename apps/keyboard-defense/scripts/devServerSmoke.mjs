#!/usr/bin/env node

import { spawn } from "node:child_process";
import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";

const NPM_CMD = process.platform === "win32" ? "npm.cmd" : "npm";
const DEVSERVER_DIR = path.resolve(".devserver");
const STATE_PATH = path.join(DEVSERVER_DIR, "state.json");
const LOG_PATH = path.join(DEVSERVER_DIR, "server.log");
const POLL_INTERVAL_MS = 500;
const DEFAULT_TIMEOUT_MS = sanitizeNumber(process.env.DEVSERVER_SMOKE_TIMEOUT, 60_000);
const SUMMARY_PATH = path.resolve(
  process.env.DEVSERVER_SMOKE_SUMMARY ?? path.join("artifacts", "smoke", "devserver-smoke-summary.json")
);

function sanitizeNumber(value, fallback) {
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

function parseArgs(argv) {
  const opts = {
    timeoutMs: DEFAULT_TIMEOUT_MS,
    skipBuild: process.env.DEVSERVER_SMOKE_FULL_BUILD === "1" ? false : true,
    ci: false,
    help: false,
    emitJson: false
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--timeout": {
        const raw = argv[++i];
        if (!raw) throw new Error("Missing value for --timeout");
        opts.timeoutMs = sanitizeNumber(raw, opts.timeoutMs);
        break;
      }
      case "--full-build":
      case "--no-skip-build":
        opts.skipBuild = false;
        break;
      case "--skip-build":
        opts.skipBuild = true;
        break;
      case "--ci":
        opts.ci = true;
        break;
      case "--json":
        opts.emitJson = true;
        break;
      case "--help":
      case "-h":
        opts.help = true;
        break;
      default:
        if (token.startsWith("-")) {
          throw new Error(`Unknown argument "${token}". Use --help to list supported options.`);
        }
        break;
    }
  }

  return opts;
}

function printHelp() {
  console.log(`Keyboard Defense dev server smoke test

Usage:
  node scripts/devServerSmoke.mjs [--timeout 60000] [--skip-build|--full-build] [--ci]

Options:
  --timeout <ms>    Max time to wait for ready state & fetch checks (default ${DEFAULT_TIMEOUT_MS})
  --skip-build      Skip the build step when running npm run start (default)
  --full-build      Force npm run start to rebuild before serving
  --ci              Reserved for CI integrations (accepted for parity, no behavior change)
  --json            Print the final summary JSON to stdout in addition to writing the artifact
  --help            Show this message`);
}

function runNpmScript(script, args = [], options = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(NPM_CMD, ["run", script, ...args], {
      stdio: options.stdio ?? "inherit",
      env: options.env ?? process.env,
      shell: false
    });
    child.on("error", reject);
    child.on("exit", (code) => {
      if (code === 0) resolve();
      else reject(new Error(`npm run ${script} exited with code ${code}`));
    });
  });
}

async function readState() {
  try {
    const raw = await fs.readFile(STATE_PATH, "utf8");
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

async function waitForReadyState(timeoutMs) {
  const start = Date.now();
  let lastSeen = null;
  while (Date.now() - start < timeoutMs) {
    const state = await readState();
    if (state && state.ready && typeof state.url === "string") {
      return state;
    }
    lastSeen = state;
    await new Promise((resolve) => setTimeout(resolve, POLL_INTERVAL_MS));
  }
  const lastSummary = lastSeen
    ? `last state: ready=${Boolean(lastSeen.ready)} url=${lastSeen.url ?? "unknown"}`
    : "no state file";
  throw new Error(
    `Dev server state did not become ready within ${timeoutMs}ms (${lastSummary}). Check ${LOG_PATH} for details.`
  );
}

async function verifyHttpGet(url, timeoutMs) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetch(url, { method: "GET", signal: controller.signal });
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    throw new Error(`HTTP GET ${url} failed: ${message}`);
  } finally {
    clearTimeout(timer);
  }
}

async function ensureStopped(reason) {
  try {
    await runNpmScript("serve:stop");
    console.log(`[devserver:smoke] (${reason}) ensured dev server is stopped.`);
    return true;
  } catch (error) {
    console.warn(
      `[devserver:smoke] (${reason}) failed to stop dev server: ${
        error instanceof Error ? error.message : String(error)
      }`
    );
    return false;
  }
}

async function readLogTailLines(limit = 40) {
  try {
    const raw = await fs.readFile(LOG_PATH, "utf8");
    const trimmed = raw.trimEnd();
    if (!trimmed) {
      return [];
    }
    const lines = trimmed.split(/\r?\n/);
    return lines.slice(-limit);
  } catch (error) {
    console.warn(
      `[devserver:smoke] Unable to read log tail: ${error instanceof Error ? error.message : String(error)}`
    );
    return null;
  }
}

async function emitLogTail(summary, limit = 40) {
  const tail = await readLogTailLines(limit);
  if (!tail || tail.length === 0) {
    return;
  }
  if (summary) {
    summary.logTail = tail;
  }
  console.error(`[devserver:smoke] Last ${tail.length} lines from ${LOG_PATH}:`);
  for (const line of tail) {
    console.error(`  ${line}`);
  }
}

async function writeSummary(summary, { emitJson = false } = {}) {
  if (!summary) return;
  try {
    await fs.mkdir(path.dirname(SUMMARY_PATH), { recursive: true });
    await fs.writeFile(SUMMARY_PATH, JSON.stringify(summary, null, 2), "utf8");
    console.log(`[devserver:smoke] Summary written to ${SUMMARY_PATH}`);
    if (emitJson) {
      console.log("[devserver:smoke] Summary (stdout):");
      console.log(JSON.stringify(summary, null, 2));
    }
  } catch (error) {
    console.warn(
      `[devserver:smoke] Failed to write summary: ${
        error instanceof Error ? error.message : String(error)
      }`
    );
  }
}

async function smoke(opts) {
  const summary = {
    status: "pending",
    startedAt: new Date().toISOString(),
    finishedAt: null,
    options: { timeoutMs: opts.timeoutMs, skipBuild: opts.skipBuild },
    statePath: STATE_PATH,
    logPath: LOG_PATH,
    summaryPath: SUMMARY_PATH,
    preflight: null,
    startCommand: null,
    server: null,
    serveCheck: null,
    httpCheck: null,
    cleanup: null,
    error: null,
    logTail: null
  };
  try {
    console.log(
      `[devserver:smoke] Starting (timeout=${opts.timeoutMs}ms, skipBuild=${opts.skipBuild})`
    );
    summary.preflight = {
      attemptedAt: new Date().toISOString(),
      success: await ensureStopped("preflight")
    };
    const env = { ...process.env };
    if (opts.skipBuild) {
      env.DEVSERVER_SKIP_BUILD = "1";
    } else {
      delete env.DEVSERVER_SKIP_BUILD;
    }
    summary.startCommand = { startedAt: new Date().toISOString(), skipBuild: opts.skipBuild };
    await runNpmScript("start", [], { env });
    summary.startCommand.completedAt = new Date().toISOString();
    const state = await waitForReadyState(opts.timeoutMs);
    summary.server = {
      url: state.url ?? null,
      pid: state.pid ?? null,
      host: state.host ?? null,
      port: state.port ?? null,
      startedAt: state.startedAt ?? null,
      readyAt: state.readyAt ?? new Date().toISOString()
    };
    console.log(
      `[devserver:smoke] Ready at ${state.url} (pid ${state.pid ?? "unknown"}) after start command.`
    );
    await runNpmScript("serve:check");
    summary.serveCheck = { completedAt: new Date().toISOString() };
    console.log("[devserver:smoke] serve:check succeeded.");
    await verifyHttpGet(state.url, opts.timeoutMs);
    summary.httpCheck = { url: state.url, completedAt: new Date().toISOString() };
    console.log(`[devserver:smoke] HTTP GET ${state.url} succeeded.`);
    const cleanupSuccess = await ensureStopped("cleanup");
    summary.cleanup = {
      attemptedAt: new Date().toISOString(),
      success: cleanupSuccess
    };
    console.log("[devserver:smoke] Smoke test complete.");
    summary.status = "success";
    summary.finishedAt = new Date().toISOString();
    return summary;
  } catch (error) {
    summary.status = "failed";
    summary.error = error instanceof Error ? error.message : String(error);
    summary.finishedAt = new Date().toISOString();
    error.summary = summary;
    throw error;
  }
}

async function main() {
  let opts;
  try {
    opts = parseArgs(process.argv.slice(2));
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
    return;
  }

  if (opts.help) {
    printHelp();
    return;
  }

  let summary = null;
  try {
    summary = await smoke(opts);
  } catch (error) {
    console.error(
      `[devserver:smoke] ${error instanceof Error ? error.message : String(error)}`
    );
    console.error(`[devserver:smoke] Check ${LOG_PATH} for details.`);
    summary =
      error.summary ??
      {
        status: "failed",
        startedAt: new Date().toISOString(),
        finishedAt: new Date().toISOString(),
        options: { timeoutMs: opts.timeoutMs, skipBuild: opts.skipBuild },
        error: error instanceof Error ? error.message : String(error),
        statePath: STATE_PATH,
        logPath: LOG_PATH,
        summaryPath: SUMMARY_PATH
      };
    await emitLogTail(summary);
    process.exitCode = 1;
    await ensureStopped("cleanup-after-error");
    await writeSummary(summary, { emitJson: opts.emitJson });
    return;
  }

  await writeSummary(summary, { emitJson: opts.emitJson });
}

await main();
