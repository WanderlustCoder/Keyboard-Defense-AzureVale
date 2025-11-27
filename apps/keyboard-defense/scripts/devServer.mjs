#!/usr/bin/env node

import { spawn } from "node:child_process";
import { createRequire } from "node:module";
import { watch } from "node:fs";
import fsSync from "node:fs";
import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";

const require = createRequire(import.meta.url);

const DEVSERVER_DIR = path.resolve(".devserver");
const STATE_PATH = path.join(DEVSERVER_DIR, "state.json");
const LOG_PATH = path.join(DEVSERVER_DIR, "server.log");
const RESOLUTION_ERROR_PATH = path.join(DEVSERVER_DIR, "resolution-error.json");
const PUBLIC_DIR = path.resolve("public");
const BUILD_CMD = process.platform === "win32" ? "npm.cmd" : "npm";
const DEFAULT_PORT = sanitizePort(process.env.PORT);
const DEFAULT_HOST = process.env.HOST?.trim() || "127.0.0.1";
const READY_TIMEOUT_MS = sanitizeNumber(process.env.DEVSERVER_READY_TIMEOUT, 30_000);
const READY_INTERVAL_MS = 500;
const REQUEST_TIMEOUT_MS = 5_000;
const MONITOR_INTERVAL_MS = 5_000;

const START_FLAG_TOKENS = new Set(["--no-build", "--force-restart"]);

export function parseStartOptions(args = []) {
  const options = {
    noBuild: false,
    forceRestart: false
  };

  for (const token of args) {
    if (!token) continue;
    switch (token) {
      case "--no-build":
        options.noBuild = true;
        break;
      case "--force-restart":
        options.forceRestart = true;
        break;
      default:
        if (token.startsWith("-")) {
          throw new Error(`Unknown start flag "${token}". Supported flags: ${[
            ...START_FLAG_TOKENS
          ].join(", ")}`);
        }
    }
  }

  return options;
}

function shouldSkipBuild(options = {}) {
  if (options.noBuild) return true;
  if (process.env.DEVSERVER_NO_BUILD === "1") return true;
  if (process.env.DEVSERVER_SKIP_BUILD === "1") return true;
  return false;
}

function getDeps(overrides = {}) {
  return {
    readState,
    writeState,
    clearState,
    runBuild,
    launchHttpServer,
    waitForReady,
    terminateProcess,
    isProcessRunning,
    ...overrides
  };
}

function resolveHttpServerBin() {
  const candidates = [
    "http-server/bin/http-server.js",
    "http-server/bin/http-server"
  ];
  const attempted = [];
  for (const candidate of candidates) {
    try {
      return require.resolve(candidate);
    } catch {
      attempted.push(candidate);
    }
  }
  const guidanceLines = [
    "Unable to locate the http-server binary required by `npm run start`.",
    `Tried resolving: ${attempted.join(", ") || "http-server"}.`,
    "",
    "Fixes:",
    "  • From apps/keyboard-defense/: run `npm install --save-dev http-server`.",
    "  • Or install globally: `npm install -g http-server` (then re-run `npm run start -- --no-build`).",
    "  • Or run `npx http-server --version` once so Node caches the shim.",
    "",
    "Docs:",
    "  • apps/keyboard-defense/docs/DEVELOPMENT.md#dev-server-automation",
    "  • docs/CODEX_PORTAL.md",
    "",
    "After installing, retry with `npm run start -- --no-build` for a faster loop."
  ].join("\n");

  persistResolutionError({
    attempted,
    cwd: process.cwd(),
    pathEnv: process.env.PATH ?? "",
    suggestions: [
      "npm install --save-dev http-server",
      "npm install -g http-server",
      "npx http-server --version",
      "See apps/keyboard-defense/docs/DEVELOPMENT.md#dev-server-automation"
    ],
    timestamp: new Date().toISOString()
  });

  const message = `${guidanceLines}\nResolution diagnostics written to ${RESOLUTION_ERROR_PATH}`;
  console.error(message);
  throw new Error(message);
}

let HTTP_SERVER_BIN = null;

function getHttpServerBin() {
  if (!HTTP_SERVER_BIN) {
    HTTP_SERVER_BIN = resolveHttpServerBin();
  }
  return HTTP_SERVER_BIN;
}

function persistResolutionError(payload) {
  try {
    fsSync.mkdirSync(DEVSERVER_DIR, { recursive: true });
    fsSync.writeFileSync(RESOLUTION_ERROR_PATH, JSON.stringify(payload, null, 2), "utf8");
  } catch {
    // best effort
  }
}

function sanitizePort(value) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed <= 0 || parsed >= 65535) {
    return 4173;
  }
  return parsed;
}

function sanitizeNumber(value, fallback) {
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

async function ensureDevServerDir() {
  await fs.mkdir(DEVSERVER_DIR, { recursive: true });
}

async function ensureLogFile() {
  await ensureDevServerDir();
  await fs.appendFile(LOG_PATH, "", "utf8");
}

async function readState() {
  try {
    const raw = await fs.readFile(STATE_PATH, "utf8");
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

async function writeState(state) {
  await ensureDevServerDir();
  await fs.writeFile(STATE_PATH, JSON.stringify(state, null, 2), "utf8");
}

async function clearState() {
  await fs.rm(STATE_PATH, { force: true });
}

function isProcessRunning(pid) {
  if (!pid) {
    return false;
  }
  try {
    process.kill(pid, 0);
    return true;
  } catch (error) {
    return error && error.code === "EPERM";
  }
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function run(command, args, options = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      stdio: options.stdio ?? "inherit",
      shell: options.shell ?? (process.platform === "win32"),
      ...options
    });
    child.on("error", reject);
    child.on("exit", (code) => {
      if (code === 0) resolve();
      else reject(new Error(`${command} ${args.join(" ")} exited with code ${code}`));
    });
  });
}

async function runBuild() {
  if (process.env.DEVSERVER_SKIP_BUILD === "1" || process.env.DEVSERVER_NO_BUILD === "1") {
    return;
  }
  console.log("Building project (npm run build)...");
  await run(BUILD_CMD, ["run", "build"]);
}

function resolveHostInfo(hostOverride) {
  const listenHost = hostOverride?.trim() || DEFAULT_HOST;
  const urlHost = listenHost === "0.0.0.0" ? "127.0.0.1" : listenHost;
  return { listenHost, urlHost };
}

async function launchHttpServer(host, port) {
  await ensureLogFile();
  const logHandle = await fs.open(LOG_PATH, "a");
  const args = [
    PUBLIC_DIR,
    "-a",
    host,
    "-p",
    String(port),
    "-c",
    "-1",
    "--log-ip",
    "--cors"
  ];
    const child = spawn(process.execPath, [getHttpServerBin(), ...args], {
    detached: true,
    stdio: ["ignore", logHandle.fd, logHandle.fd]
  });
  await logHandle.close();
  child.unref();
  return child;
}

async function terminateProcess(pid) {
  if (!pid) {
    return;
  }
  try {
    process.kill(pid, "SIGTERM");
  } catch (error) {
    if (error && error.code === "ESRCH") {
      return;
    }
    if (error && error.code !== "EPERM") {
      throw error;
    }
  }
  const stopStart = Date.now();
  while (isProcessRunning(pid) && Date.now() - stopStart < 4_000) {
    await sleep(200);
  }
  if (isProcessRunning(pid)) {
    try {
      process.kill(pid, "SIGKILL");
    } catch {
      // Best-effort on platforms without SIGKILL.
    }
  }
}

async function pingServer(url, requestTimeoutMs = REQUEST_TIMEOUT_MS) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), requestTimeoutMs);
  const started = Date.now();
  try {
    const response = await fetch(url, { method: "HEAD", signal: controller.signal });
    return {
      ok: response.ok,
      status: response.status,
      latency: Date.now() - started,
      error: response.ok ? null : `HTTP ${response.status}`
    };
  } catch (error) {
    return {
      ok: false,
      status: null,
      latency: null,
      error: error instanceof Error ? error.message : String(error)
    };
  } finally {
    clearTimeout(timeout);
  }
}

async function waitForReady(url) {
  const startTime = Date.now();
  let lastError = "no response";
  while (Date.now() - startTime < READY_TIMEOUT_MS) {
    const result = await pingServer(url);
    if (result.ok) {
      return result;
    }
    lastError = result.error ?? `HTTP ${result.status ?? "unknown"}`;
    await sleep(READY_INTERVAL_MS);
  }
  throw new Error(
    `Dev server failed to respond within ${READY_TIMEOUT_MS}ms (${lastError}). Check ${LOG_PATH} for details.`
  );
}

export async function startServer(options = {}, overrides = {}) {
  const deps = getDeps(overrides);
  const skipBuild = shouldSkipBuild(options);
  const flags = [];
  if (skipBuild) flags.push("no-build");
  if (options.forceRestart) flags.push("force-restart");

  const existing = await deps.readState();
  if (existing && deps.isProcessRunning(existing.pid)) {
    if (options.forceRestart) {
      console.log(
        `Force restarting dev server on ${existing.url} (pid ${existing.pid}).`
      );
      await stopServer({ quiet: true }, deps);
    } else {
      console.log(`Dev server already running on ${existing.url} (pid ${existing.pid}).`);
      console.log(
        "Use `npm run serve:status` or `npm run serve:stop` if you need to inspect it."
      );
      return;
    }
  } else if (existing) {
    await deps.clearState();
  }

  if (!skipBuild) {
    await deps.runBuild();
  } else {
    console.log("Skipping build step (--no-build).");
  }

  const port = options.port ? sanitizePort(options.port) : DEFAULT_PORT;
  const { listenHost, urlHost } = resolveHostInfo(options.host);
  console.log(`Starting http-server on ${listenHost}:${port} (serving ${PUBLIC_DIR}).`);
  const child = await deps.launchHttpServer(listenHost, port);
  if (!child.pid) {
    throw new Error("Failed to spawn http-server process.");
  }

  const state = {
    pid: child.pid,
    host: listenHost,
    urlHost,
    port,
    url: `http://${urlHost}:${port}`,
    logPath: LOG_PATH,
    startedAt: new Date().toISOString(),
    ready: false,
    flags
  };
  await deps.writeState(state);

  try {
    await deps.waitForReady(state.url);
    state.ready = true;
    state.readyAt = new Date().toISOString();
    await deps.writeState(state);
      console.log(`DEV_SERVER_READY url=${state.url} pid=${state.pid} log=${state.logPath}`);
    } catch (error) {
      await deps.terminateProcess(child.pid);
      await deps.clearState();
      throw error;
    }
  return state;
}

export async function stopServer(options = {}, overrides = {}) {
  const deps = getDeps(overrides);
  const quiet = options.quiet ?? false;
  const state = await deps.readState();
  if (!state) {
    if (!quiet) {
      console.log("Dev server is not running (no state file).");
    }
    return;
  }
  if (!deps.isProcessRunning(state.pid)) {
    if (!quiet) {
      console.log("Dev server process already stopped. Cleaning up state.");
    }
    await deps.clearState();
    return;
  }
  if (!quiet) {
    console.log(`Stopping dev server (pid ${state.pid})...`);
  }
  await deps.terminateProcess(state.pid);
  await deps.clearState();
  if (!quiet) {
    console.log("Dev server stopped.");
  }
}

async function requireRunningState() {
  const state = await readState();
  if (!state) {
    throw new Error("Dev server is not running. Launch it with `npm run start`.");
  }
  if (!isProcessRunning(state.pid)) {
    await clearState();
    throw new Error("Dev server state exists but process exited. Run `npm run start` again.");
  }
  return state;
}

async function printStatus() {
  const state = await readState();
  if (!state) {
    console.log("Dev server is not running.");
    return;
  }
  const alive = isProcessRunning(state.pid);
  if (!alive) {
    console.log("Dev server state exists but process has exited. Cleaning up.");
    await clearState();
    return;
  }
  const ping = await pingServer(state.url);
  console.log(`Dev server running at ${state.url}`);
  console.log(`  pid: ${state.pid}`);
  console.log(`  ready: ${ping.ok ? "yes" : "no"}`);
  console.log(`  log: ${state.logPath}`);
}

async function checkServer() {
  let state;
  try {
    state = await requireRunningState();
  } catch (error) {
    console.error(error.message);
    process.exit(1);
    return;
  }
  const ping = await pingServer(state.url);
  if (ping.ok) {
    console.log(`Dev server ready at ${state.url} (HTTP ${ping.status}, ${ping.latency} ms).`);
  } else {
    console.error(`Dev server not reachable (${ping.error ?? "unknown error"}).`);
    process.exit(1);
  }
}

async function tailLogs(logPath) {
  await ensureLogFile();
  const handle = await fs.open(logPath, "r");
  let position = 0;

  async function pump(force = false) {
    const stats = await handle.stat();
    if (!force && stats.size === position) {
      return;
    }
    if (stats.size < position) {
      position = 0;
    }
    const length = stats.size - position;
    if (length <= 0) {
      return;
    }
    const buffer = Buffer.alloc(length);
    await handle.read(buffer, 0, length, position);
    position = stats.size;
    process.stdout.write(buffer.toString("utf8"));
  }

  await pump(true);

  const watcher = watch(logPath, (event) => {
    if (event === "change") {
      pump().catch((error) => console.warn("Log tail error:", error.message));
    }
  });

  const stop = async () => {
    watcher.close();
    await handle.close();
  };

  return stop;
}

async function logsCommand() {
  console.log(`Tailing ${LOG_PATH}. Press Ctrl+C to stop.`);
  const cleanup = await tailLogs(LOG_PATH);
  let done = false;
  const handleSignal = async () => {
    if (done) return;
    done = true;
    await cleanup();
    process.exit(0);
  };
  process.on("SIGINT", handleSignal);
  process.on("SIGTERM", handleSignal);
  await new Promise(() => {});
}

async function monitorCommand() {
  let state;
  try {
    state = await requireRunningState();
  } catch (error) {
    console.error(error.message);
    process.exit(1);
    return;
  }
  console.log(
    `Monitoring dev server at ${state.url} (pid ${state.pid}). Press Ctrl+C to stop monitoring.`
  );
  const cleanupLogs = await tailLogs(state.logPath ?? LOG_PATH);
  let stopping = false;

  const stopAll = async () => {
    if (stopping) return;
    stopping = true;
    clearInterval(intervalId);
    await cleanupLogs();
    process.exit(0);
  };

  const intervalId = setInterval(async () => {
    const ping = await pingServer(state.url);
    const timestamp = new Date().toISOString();
    if (ping.ok) {
      console.log(`[monitor ${timestamp}] OK ${ping.status} (${ping.latency ?? 0} ms)`);
    } else {
      console.warn(
        `[monitor ${timestamp}] ERROR ${ping.error ?? `HTTP ${ping.status ?? "unknown"}`}`
      );
    }
    if (!isProcessRunning(state.pid)) {
      console.warn("[monitor] Detected server exit. Stopping monitor.");
      stopAll();
    }
  }, MONITOR_INTERVAL_MS);

  process.on("SIGINT", stopAll);
  process.on("SIGTERM", stopAll);
}

function printHelp() {
  console.log(`Keyboard Defense dev server

Usage:
  node scripts/devServer.mjs <command>

Commands:
  start     Build the project and launch http-server (detached). Writes readiness state + logs.
  stop      Terminate the running dev server and clear state.
  status    Show whether the dev server is running and reachable.
  check     Fast readiness probe (exit code 0 only when reachable).
  logs      Tail .devserver/server.log until interrupted.
  monitor   Tail logs while issuing periodic HTTP probes.
  help      Show this message.

Flags (apply to the "start" command):
  --no-build        Skip \`npm run build\` (also respects DEVSERVER_NO_BUILD=1).
  --force-restart   Stop an existing server before starting a new one.
`);
}

async function main() {
  const [, , ...rawArgs] = process.argv;
  const command = rawArgs[0];
  const commandArgs = rawArgs.slice(1);

  switch (command) {
    case "start":
      await startServer(parseStartOptions(commandArgs));
      break;
    case "stop":
      await stopServer();
      break;
    case "status":
      await printStatus();
      break;
    case "check":
      await checkServer();
      break;
    case "logs":
      await logsCommand();
      break;
    case "monitor":
      await monitorCommand();
      break;
    case "help":
    case undefined:
      printHelp();
      break;
    default:
      console.error(`Unknown command "${command}". Use "help" to list supported commands.`);
      process.exit(1);
  }
}

if (
  import.meta.url === `file://${process.argv[1]}` ||
  process.argv[1]?.endsWith("devServer.mjs")
) {
  try {
    await main();
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
  }
}
