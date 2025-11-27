#!/usr/bin/env node

import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";

const DEFAULT_URL = process.env.DEV_MONITOR_URL ?? "http://127.0.0.1:4173";
const DEFAULT_INTERVAL = sanitizeNumber(process.env.DEV_MONITOR_INTERVAL, 2_000);
const DEFAULT_TIMEOUT = sanitizeNumber(process.env.DEV_MONITOR_TIMEOUT, 120_000);
const DEFAULT_REQUEST_TIMEOUT = sanitizeNumber(
  process.env.DEV_MONITOR_REQUEST_TIMEOUT,
  5_000
);
const DEFAULT_ARTIFACT =
  process.env.DEV_MONITOR_ARTIFACT ?? path.resolve("artifacts", "monitor", "dev-monitor.json");
const DEFAULT_STATE_PATH =
  process.env.DEV_MONITOR_STATE ?? path.resolve(".devserver", "state.json");
const HISTORY_LIMIT = 300;

function sanitizeNumber(value, fallback) {
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

export function parseArgs(argv = []) {
  const options = {
    url: DEFAULT_URL,
    intervalMs: DEFAULT_INTERVAL,
    timeoutMs: DEFAULT_TIMEOUT,
    requestTimeoutMs: DEFAULT_REQUEST_TIMEOUT,
    artifactPath: DEFAULT_ARTIFACT,
    statePath: DEFAULT_STATE_PATH,
    waitReady: false,
    verbose: false,
    help: false
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--url": {
        const value = argv[++i];
        if (!value) throw new Error("Expected value after --url");
        options.url = value;
        break;
      }
      case "--interval": {
        const value = sanitizeNumber(argv[++i], NaN);
        if (!Number.isFinite(value)) throw new Error("Expected number after --interval");
        options.intervalMs = value;
        break;
      }
      case "--timeout": {
        const value = sanitizeNumber(argv[++i], NaN);
        if (!Number.isFinite(value)) throw new Error("Expected number after --timeout");
        options.timeoutMs = value;
        break;
      }
      case "--request-timeout": {
        const value = sanitizeNumber(argv[++i], NaN);
        if (!Number.isFinite(value)) {
          throw new Error("Expected number after --request-timeout");
        }
        options.requestTimeoutMs = value;
        break;
      }
      case "--artifact": {
        const value = argv[++i];
        if (!value) throw new Error("Expected path after --artifact");
        options.artifactPath = path.resolve(value);
        break;
      }
      case "--state": {
        const value = argv[++i];
        if (!value) throw new Error("Expected path after --state");
        options.statePath = path.resolve(value);
        break;
      }
      case "--no-artifact":
        options.artifactPath = null;
        break;
      case "--wait-ready":
        options.waitReady = true;
        break;
      case "--verbose":
        options.verbose = true;
        break;
      case "--help":
      case "-h":
        options.help = true;
        break;
      default:
        if (token.startsWith("-")) {
          throw new Error(`Unknown option: ${token}`);
        }
    }
  }

  return options;
}

async function readStateSnapshot(statePath) {
  if (!statePath) return null;
  try {
    const raw = await fs.readFile(statePath, "utf8");
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function probe(url, requestTimeoutMs) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), requestTimeoutMs);
  const started = Date.now();
  try {
    const response = await fetch(url, { method: "HEAD", signal: controller.signal });
    return {
      ok: response.ok,
      status: response.status,
      latencyMs: Date.now() - started,
      error: response.ok ? null : `HTTP ${response.status}`
    };
  } catch (error) {
    return {
      ok: false,
      status: null,
      latencyMs: null,
      error: error instanceof Error ? error.message : String(error)
    };
  } finally {
    clearTimeout(timeout);
  }
}

async function writeArtifact(summary, artifactPath) {
  if (!artifactPath) return;
  await fs.mkdir(path.dirname(artifactPath), { recursive: true });
  await fs.writeFile(artifactPath, JSON.stringify(summary, null, 2), "utf8");
}

function pushHistory(history, entry) {
  history.push(entry);
  while (history.length > HISTORY_LIMIT) {
    history.shift();
  }
}

export async function runMonitor(options) {
  const stateSnapshot = await readStateSnapshot(options.statePath);
  const summary = {
    url: options.url,
    intervalMs: options.intervalMs,
    timeoutMs: options.timeoutMs,
    requestTimeoutMs: options.requestTimeoutMs,
    artifactPath: options.artifactPath,
    statePath: options.statePath,
    startedAt: new Date().toISOString(),
    status: "pending",
    readyAt: null,
    failureCount: 0,
    successCount: 0,
    lastError: null,
    lastLatencyMs: null,
    lastSuccessAt: null,
    lastFailureAt: null,
    completedAt: null,
    history: [],
    uptimeMs: 0,
    server: stateSnapshot
      ? {
          host: stateSnapshot.host ?? null,
          port: stateSnapshot.port ?? null,
          url: stateSnapshot.url ?? null,
          logPath: stateSnapshot.logPath ?? null,
          startedAt: stateSnapshot.startedAt ?? null,
          flags: Array.isArray(stateSnapshot.flags) ? stateSnapshot.flags : []
        }
      : null,
    flags: Array.isArray(stateSnapshot?.flags) ? stateSnapshot.flags : []
  };

  const deadline = Date.now() + options.timeoutMs;

  while (Date.now() < deadline) {
    const reading = await probe(options.url, options.requestTimeoutMs);
    const entry = {
      timestamp: new Date().toISOString(),
      ok: reading.ok,
      status: reading.status,
      latencyMs: reading.latencyMs,
      error: reading.error
    };
    pushHistory(summary.history, entry);

    summary.lastLatencyMs = entry.latencyMs ?? summary.lastLatencyMs;
    if (reading.ok) {
      summary.successCount += 1;
      summary.lastSuccessAt = entry.timestamp;
      if (options.verbose) {
        console.log(
          `[dev-monitor] OK ${reading.status} (${reading.latencyMs ?? 0} ms) at ${entry.timestamp}`
        );
      }
      if (options.waitReady) {
        summary.status = "ready";
        summary.readyAt = entry.timestamp;
        break;
      }
    } else {
      summary.failureCount += 1;
      summary.lastError = reading.error;
      summary.lastFailureAt = entry.timestamp;
      if (options.verbose) {
        console.warn(
          `[dev-monitor] ERROR ${reading.error ?? "unknown"} at ${entry.timestamp}`
        );
      }
    }
    await sleep(options.intervalMs);
  }

  if (summary.status === "pending") {
    if (summary.successCount === 0) {
      summary.status = "timeout";
    } else if (options.waitReady) {
      summary.status = "timeout";
    } else {
      summary.status = "complete";
    }
  }

  summary.completedAt = new Date().toISOString();
  summary.uptimeMs = Math.max(
    0,
    Date.parse(summary.completedAt) - Date.parse(summary.startedAt)
  );
  await writeArtifact(summary, options.artifactPath);
  return summary;
}

function printHelp() {
  console.log(`Keyboard Defense dev monitor

Usage:
  node scripts/devMonitor.mjs [options]

Options:
  --url <url>              Target URL to poll (default ${DEFAULT_URL})
  --interval <ms>          Delay between probes in milliseconds (default ${DEFAULT_INTERVAL})
  --timeout <ms>           Total time to monitor before exiting (default ${DEFAULT_TIMEOUT})
  --request-timeout <ms>   Per-request timeout in milliseconds (default ${DEFAULT_REQUEST_TIMEOUT})
  --artifact <path>        Where to write the JSON summary (default ${DEFAULT_ARTIFACT})
  --no-artifact            Skip writing the artifact to disk
  --wait-ready             Exit immediately once a successful probe occurs (non-zero status on timeout)
  --verbose                Log each probe result
  --help, -h               Display this help text
`);
}

async function main() {
  let options;
  try {
    options = parseArgs(process.argv.slice(2));
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
    return;
  }
  if (options.help) {
    printHelp();
    return;
  }

  try {
    const summary = await runMonitor(options);
    console.log(
      `Monitor finished with status "${summary.status}" (success=${summary.successCount}, failures=${summary.failureCount}).`
    );
    if (summary.artifactPath ?? options.artifactPath) {
      console.log(`Summary written to ${options.artifactPath ?? DEFAULT_ARTIFACT}`);
    }
    if (summary.status === "timeout" && (options.waitReady || summary.successCount === 0)) {
      process.exitCode = 1;
    }
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
  }
}

if (
  import.meta.url === `file://${process.argv[1]}` ||
  process.argv[1]?.endsWith("devMonitor.mjs")
) {
  await main();
}
