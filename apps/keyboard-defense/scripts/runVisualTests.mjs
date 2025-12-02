#!/usr/bin/env node

/**
 * Convenience runner for Playwright visual tests that will:
 * 1) Start the dev server (skipping the build) if it is not already running.
 * 2) Run either `npm run test:visual` or `npm run test:visual:update`.
 * 3) Stop the dev server automatically unless --keep-alive is passed.
 *
 * Pass-through arguments after the known flags are forwarded to Playwright.
 */

import { spawn } from "node:child_process";
import process from "node:process";

import { startServer, stopServer } from "./devServer.mjs";

const ARG_MAP = new Map([
  ["--update", "updateSnapshots"],
  ["--keep-alive", "keepAlive"],
  ["--host", "host"],
  ["--port", "port"]
]);

const NPM_BIN = process.platform === "win32" ? "npm.cmd" : "npm";
const KNOWN_FLAGS = new Set(["--update", "--keep-alive"]);

async function runCommand(cmd, args) {
  return await new Promise((resolve, reject) => {
    const child = spawn(cmd, args, { stdio: "inherit" });
    child.on("error", reject);
    child.on("exit", (code, signal) => {
      if (signal) {
        resolve({ code: 1, signal });
      } else {
        resolve({ code: code ?? 0, signal: null });
      }
    });
  });
}

async function main() {
  const rawArgs = process.argv.slice(2);
  const options = {
    updateSnapshots: rawArgs.includes("--update"),
    keepAlive: rawArgs.includes("--keep-alive"),
    host: undefined,
    port: undefined
  };

  for (let i = 0; i < rawArgs.length; i += 1) {
    const token = rawArgs[i];
    const key = ARG_MAP.get(token);
    if (!key || key === "updateSnapshots" || key === "keepAlive") continue;
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

  const passThrough = [];
  for (let i = 0; i < rawArgs.length; i += 1) {
    const token = rawArgs[i];
    if (KNOWN_FLAGS.has(token)) {
      // skip flag and its value if applicable
      if (token === "--host" || token === "--port") {
        i += 1;
      }
      continue;
    }
    passThrough.push(token);
  }

  let startedState = null;
  let exitCode = 0;

  try {
    // Skip the build step for speed; rely on existing public assets.
    startedState = await startServer({
      noBuild: true,
      host: options.host,
      port: options.port
    });

    const script = options.updateSnapshots ? "test:visual:update" : "test:visual";
    const args = ["run", script];
    if (passThrough.length) {
      args.push("--", ...passThrough);
    }

    const result = await runCommand(NPM_BIN, args);
    exitCode = result.code ?? 1;
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    exitCode = 1;
  } finally {
    const serverWasStartedByScript = Boolean(startedState);
    if (serverWasStartedByScript && !options.keepAlive) {
      await stopServer({ quiet: true });
    } else if (serverWasStartedByScript && options.keepAlive) {
      console.log(
        `Dev server left running at ${startedState?.url ?? "http://localhost:4173"} (pid ${
          startedState?.pid ?? "unknown"
        }).`
      );
    }
  }

  if (exitCode !== 0) {
    process.exitCode = exitCode;
  }
}

await main();
