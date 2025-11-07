#!/usr/bin/env node

import { spawn } from "node:child_process";
import process from "node:process";

function run(command, args) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      stdio: "inherit",
      shell: false
    });
    child.on("error", reject);
    child.on("exit", (code) => {
      if (code === 0) resolve();
      else reject(new Error(`${command} ${args.join(" ")} exited with code ${code}`));
    });
  });
}

async function main() {
  const monitorArgs = process.argv.slice(2);
  try {
    await run(process.execPath, ["./scripts/devServer.mjs", "start"]);
  } catch (error) {
    console.error(
      error instanceof Error ? `Failed to launch dev server: ${error.message}` : String(error)
    );
    process.exit(1);
    return;
  }

  try {
    await run(process.execPath, ["./scripts/devMonitor.mjs", "--wait-ready", ...monitorArgs]);
  } catch (error) {
    console.error(
      error instanceof Error ? `Dev monitor failed: ${error.message}` : String(error)
    );
    process.exit(1);
  }
}

if (
  import.meta.url === `file://${process.argv[1]}` ||
  process.argv[1]?.endsWith("startMonitored.mjs")
) {
  await main();
}
