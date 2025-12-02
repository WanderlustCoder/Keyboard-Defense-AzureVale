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
  const updateSnapshots = rawArgs.includes("--update");
  const keepAlive = rawArgs.includes("--keep-alive");
  const passThrough = rawArgs.filter((arg) => !KNOWN_FLAGS.has(arg));

  let startedState = null;
  let exitCode = 0;

  try {
    // Skip the build step for speed; rely on existing public assets.
    startedState = await startServer({ noBuild: true });

    const script = updateSnapshots ? "test:visual:update" : "test:visual";
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
    if (serverWasStartedByScript && !keepAlive) {
      await stopServer({ quiet: true });
    } else if (serverWasStartedByScript && keepAlive) {
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
