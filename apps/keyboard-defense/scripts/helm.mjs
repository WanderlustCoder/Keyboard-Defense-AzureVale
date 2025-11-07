#!/usr/bin/env node

import { spawn } from "node:child_process";
import process from "node:process";

const TASKS = new Map([
  ["start", () => runCmd("npm", ["run", "start"])],
  ["build", () => runCmd("npm", ["run", "build"])],
  ["test", () => runCmd("npm", ["run", "test"])],
  [
    "smoke",
    () =>
      runCmd("npm", ["run", "analytics:gold:report", "smoke-artifacts/tutorial-smoke.json"], {
        cwd: process.cwd()
      })
  ],
  [
    "gold-check",
    (args) => runCmd("npm", ["run", "analytics:gold:check", ...args.slice(1)])
  ]
]);

function runCmd(command, args, options = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      stdio: "inherit",
      shell: process.platform === "win32",
      ...options
    });
    child.on("error", reject);
    child.on("exit", (code) => {
      if (code === 0) resolve();
      else reject(new Error(`${command} ${args.join(" ")} exited with code ${code}`));
    });
  });
}

function printHelp() {
  console.log(`Keyboard Defense Helm

Usage:
  node scripts/helm.mjs <task> [args...]

Tasks:
  start          Run the monitored dev server (alias for npm run start)
  build          Build the project (npm run build)
  test           Run the full test suite (npm run test)
  smoke          Run the tutorial smoke + gold report pipeline
  gold-check     Validate gold summary artifacts (forwards args to npm run analytics:gold:check)
`);
}

async function main() {
  const [, , task, ...rest] = process.argv;
  if (!task || task === "--help" || task === "-h") {
    printHelp();
    return;
  }
  const handler = TASKS.get(task);
  if (!handler) {
    console.error(`Unknown task "${task}". Use --help to list supported tasks.`);
    process.exit(1);
    return;
  }
  try {
    await handler([task, ...rest]);
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
  }
}

if (
  import.meta.url === `file://${process.argv[1]}` ||
  process.argv[1]?.endsWith("helm.mjs")
) {
  await main();
}

