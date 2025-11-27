#!/usr/bin/env node

import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";

import { startServer, stopServer } from "./devServer.mjs";

const DEFAULT_ARTIFACT = path.resolve("artifacts", "monitor", "start-smoke.json");
const DEFAULT_LOG = path.resolve("artifacts", "monitor", "start-smoke.log");
const DEFAULT_STATE_PATH = path.resolve(".devserver", "state.json");
const DEFAULT_DEVSERVER_LOG = path.resolve(".devserver", "server.log");

function sanitizePositive(value, fallback) {
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export function parseArgs(argv = []) {
  const options = {
    attempts: 1,
    retryDelayMs: 5_000,
    artifact: DEFAULT_ARTIFACT,
    log: DEFAULT_LOG,
    devServerLog: DEFAULT_DEVSERVER_LOG,
    statePath: DEFAULT_STATE_PATH,
    host: null,
    port: null,
    timeoutMs: null,
    help: false
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--attempts":
        options.attempts = sanitizePositive(argv[++i], options.attempts);
        break;
      case "--retry-delay-ms":
        options.retryDelayMs = sanitizePositive(argv[++i], options.retryDelayMs);
        break;
      case "--artifact":
        options.artifact = path.resolve(argv[++i] ?? options.artifact);
        break;
      case "--log":
        options.log = path.resolve(argv[++i] ?? options.log);
        break;
      case "--devserver-log":
        options.devServerLog = path.resolve(argv[++i] ?? options.devServerLog);
        break;
      case "--state":
        options.statePath = path.resolve(argv[++i] ?? options.statePath);
        break;
      case "--host":
        options.host = argv[++i] ?? null;
        break;
      case "--port": {
        const value = argv[++i];
        if (!value) throw new Error("Expected value after --port");
        const parsed = Number(value);
        if (!Number.isFinite(parsed)) {
          throw new Error("Port must be a number");
        }
        options.port = parsed;
        break;
      }
      case "--timeout-ms":
        options.timeoutMs = sanitizePositive(argv[++i], null);
        break;
      case "--help":
      case "-h":
        options.help = true;
        break;
      case "--ci":
        // Ignored but accepted for convenience.
        break;
      default:
        if (token?.startsWith("-")) {
          throw new Error(`Unknown flag "${token}". Use --help for usage.`);
        }
    }
  }

  return options;
}

async function readStateSnapshot(statePath) {
  try {
    const raw = await fs.readFile(statePath, "utf8");
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

async function ensureDir(filePath) {
  await fs.mkdir(path.dirname(filePath), { recursive: true });
}

async function copyLog(source, destination) {
  try {
    const content = await fs.readFile(source, "utf8");
    await ensureDir(destination);
    await fs.writeFile(destination, content, "utf8");
    return destination;
  } catch {
    return null;
  }
}

async function writeJson(filePath, data) {
  await ensureDir(filePath);
  await fs.writeFile(filePath, JSON.stringify(data, null, 2), "utf8");
}

export async function runStartSmoke(options = {}, overrides = {}) {
  const attempts = Math.max(1, options.attempts ?? 1);
  const retryDelayMs = Math.max(0, options.retryDelayMs ?? 5_000);
  const artifactPath = options.artifact ?? DEFAULT_ARTIFACT;
  const logPath = options.log ?? DEFAULT_LOG;
  const devServerLog = options.devServerLog ?? DEFAULT_DEVSERVER_LOG;
  const statePath = options.statePath ?? DEFAULT_STATE_PATH;

  const summary = {
    status: "pending",
    startedAt: new Date().toISOString(),
    attempts: [],
    artifactPath,
    logPath
  };

  const start = overrides.startServer ?? startServer;
  const stop = overrides.stopServer ?? stopServer;
  const restoreEnv = {};

  const applyEnv = () => {
    restoreEnv.PORT = process.env.PORT;
    restoreEnv.HOST = process.env.HOST;
    restoreEnv.DEVSERVER_READY_TIMEOUT = process.env.DEVSERVER_READY_TIMEOUT;
    if (options.port) {
      process.env.PORT = String(options.port);
    }
    if (options.host) {
      process.env.HOST = options.host;
    }
    if (options.timeoutMs) {
      process.env.DEVSERVER_READY_TIMEOUT = String(options.timeoutMs);
    }
  };

  const revertEnv = () => {
    if ("PORT" in restoreEnv) {
      process.env.PORT = restoreEnv.PORT;
    }
    if ("HOST" in restoreEnv) {
      process.env.HOST = restoreEnv.HOST;
    }
    if ("DEVSERVER_READY_TIMEOUT" in restoreEnv) {
      process.env.DEVSERVER_READY_TIMEOUT = restoreEnv.DEVSERVER_READY_TIMEOUT;
    }
  };

  let lastError = null;

  for (let attemptIndex = 1; attemptIndex <= attempts; attemptIndex += 1) {
    const attempt = {
      attempt: attemptIndex,
      startedAt: new Date().toISOString(),
      status: "pending"
    };
    summary.attempts.push(attempt);

    try {
      applyEnv();
      await start({
        noBuild: options.noBuild ?? true,
        forceRestart: true,
        port: options.port,
        host: options.host
      });
      attempt.status = "pass";
      attempt.completedAt = new Date().toISOString();
      const stateSnapshot = await readStateSnapshot(statePath);
      summary.state = stateSnapshot;
      summary.status = "pass";
      summary.readyAt = attempt.completedAt;
      break;
    } catch (error) {
      attempt.status = "fail";
      attempt.error = error instanceof Error ? error.message : String(error);
      lastError = attempt.error;
      if (attemptIndex < attempts) {
        await sleep(retryDelayMs);
      }
    } finally {
      revertEnv();
    }
  }

  try {
    await stop({ quiet: true });
  } catch (error) {
    summary.stopError = error instanceof Error ? error.message : String(error);
  }

  summary.completedAt = new Date().toISOString();
  summary.logPath = (await copyLog(devServerLog, logPath)) ?? logPath;

  if (summary.status !== "pass") {
    summary.status = "fail";
    summary.error = lastError ?? "dev server start smoke failed";
  }

  await writeJson(artifactPath, summary);

  if (summary.status !== "pass") {
    const error = new Error(summary.error);
    error.summary = summary;
    throw error;
  }

  return summary;
}

function printHelp() {
  console.log(`Dev server start smoke

Usage:
  node scripts/serveStartSmoke.mjs [--attempts 2] [--retry-delay-ms 3000] [--artifact <path>] [--log <path>]

Flags:
  --attempts <n>         How many attempts before failing (default 1)
  --retry-delay-ms <n>   Delay between attempts (default 5000)
  --timeout-ms <n>       Override readiness timeout (ms)
  --host <value>         Host to bind (defaults to HOST env or 127.0.0.1)
  --port <value>         Port to bind (defaults to PORT env or 4173)
  --artifact <path>      Where to write the JSON summary (default artifacts/monitor/start-smoke.json)
  --log <path>           Copy of .devserver/server.log (default artifacts/monitor/start-smoke.log)
  --devserver-log <path> Source log to copy (default .devserver/server.log)
  --state <path>         Dev server state file (default .devserver/state.json)
  --help                 Show this message
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
    await runStartSmoke(options);
    console.log("Dev server start smoke: PASS");
  } catch (error) {
    const summary = error?.summary;
    if (summary) {
      console.error(
        `Dev server start smoke failed after ${summary.attempts.length} attempt(s). See ${summary.artifactPath}`
      );
    }
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
  }
}

if (
  import.meta.url === `file://${process.argv[1]}` ||
  process.argv[1]?.endsWith("serveStartSmoke.mjs")
) {
  await main();
}
