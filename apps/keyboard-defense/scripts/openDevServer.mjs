#!/usr/bin/env node

/**
 * Starts the dev server if needed and opens the app in the default browser.
 * - Reuses the running server when healthy.
 * - Skips the build step for speed (`--no-build`); rebuild manually when assets change.
 * - Pass `--force-restart` to kill and restart the managed server.
 * - Accepts `--host <host>` / `--port <port>` to override bind/URL.
 */

import { spawn } from "node:child_process";
import fs from "node:fs/promises";
import fsSync from "node:fs";
import path from "node:path";
import process from "node:process";

import { startServer, stopServer } from "./devServer.mjs";

const STATE_PATH = path.resolve(".devserver", "state.json");
const DEFAULT_URL = "http://127.0.0.1:4173";
const ARG_MAP = new Map([
  ["--host", "host"],
  ["--port", "port"],
  ["--force-restart", "forceRestart"]
]);

async function readState() {
  try {
    const raw = await fs.readFile(STATE_PATH, "utf8");
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

function isProcessRunning(pid) {
  if (!pid) return false;
  try {
    process.kill(pid, 0);
    return true;
  } catch (error) {
    return error && error.code === "EPERM";
  }
}

async function ping(url) {
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 2_000);
    const response = await fetch(url, { method: "HEAD", signal: controller.signal });
    clearTimeout(timeout);
    return response.ok;
  } catch {
    return false;
  }
}

function openInBrowser(url) {
  const platform = process.platform;
  const options = { stdio: "ignore", detached: true };
  try {
    if (platform === "win32") {
      // Use `start` to respect default browser on Windows.
      spawn("cmd", ["/c", "start", "", url], options);
    } else if (platform === "darwin") {
      spawn("open", [url], options);
    } else {
      spawn("xdg-open", [url], options);
    }
  } catch (error) {
    console.error("Failed to open browser automatically:", error?.message ?? error);
    console.error(`Open manually: ${url}`);
  }
}

async function ensureServer(options = {}) {
  const { forceRestart = false, host, port } = options;
  // 1) Reuse healthy existing server.
  const existing = await readState();
  const wantsPort = typeof port === "number" && Number.isFinite(port);
  const wantsHost = typeof host === "string" && host.trim().length > 0;
  const existingMatches =
    existing &&
    (!wantsPort || existing.port === port) &&
    (!wantsHost || existing.host === host || existing.url?.includes(host));

  if (existing && !forceRestart && isProcessRunning(existing.pid) && existing.url) {
    const healthy = await ping(existing.url);
    if (healthy && existingMatches) {
      return { url: existing.url, fromExisting: true };
    }
    // unhealthy or option mismatch; clear state so startServer can recover
    try {
      fsSync.rmSync(STATE_PATH, { force: true });
    } catch {
      // ignore
    }
  }

  // 2) Start a new server without rebuilding the bundle for speed.
  const state = await startServer({
    noBuild: true,
    forceRestart,
    host,
    port
  });
  const url = state?.url ?? existing?.url ?? DEFAULT_URL;
  return { url, fromExisting: Boolean(existing) && !forceRestart };
}

async function main() {
  const rawArgs = process.argv.slice(2);
  const options = {
    forceRestart: rawArgs.includes("--force-restart"),
    host: undefined,
    port: undefined
  };

  for (let i = 0; i < rawArgs.length; i += 1) {
    const token = rawArgs[i];
    const key = ARG_MAP.get(token);
    if (!key || key === "forceRestart") continue;
    const value = rawArgs[i + 1];
    if (!value || value.startsWith("--")) {
      throw new Error(`Flag ${token} requires a value`);
    }
    if (key === "port") {
      options.port = Number(value);
    } else if (key === "host") {
      options.host = value;
    }
    i += 1;
  }

  const { url, fromExisting } = await ensureServer(options);
  console.log(
    fromExisting
      ? `Dev server already running at ${url}. Opening browser...`
      : `Dev server started at ${url}. Opening browser...`
  );

  openInBrowser(url);

  if (options.forceRestart) {
    process.on("exit", async () => {
      await stopServer({ quiet: true });
    });
  }
}

await main();
