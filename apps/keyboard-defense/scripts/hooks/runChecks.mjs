#!/usr/bin/env node
import { spawn } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = process.env.REPO_ROOT ?? path.resolve(__dirname, "..", "..", "..", "..");
const APP_ROOT = path.join(REPO_ROOT, "apps", "keyboard-defense");
export const DEFAULT_COMMANDS = [
  "lint",
  "test",
  "codex:validate-pack",
  "codex:validate-links",
  "codex:status"
];
export const FAST_COMMANDS = ["lint", "format:check", "codex:validate-pack", "codex:validate-links"];

function makeCommandDescriptor(command) {
  return {
    id: command,
    cmd: "npm",
    args: ["run", command, "--prefix", APP_ROOT],
    cwd: REPO_ROOT
  };
}

export async function runCommandSequence(commands, options = {}) {
  const runner = options.runner ?? defaultRunner;
  const dryRun = Boolean(options.dryRun);
  const results = [];
  for (const descriptor of commands) {
    if (dryRun) {
      console.log(`[hooks] DRY RUN: ${descriptor.cmd} ${descriptor.args.join(" ")}`);
      results.push({ id: descriptor.id, status: "dry-run" });
      continue;
    }
    const code = await runner(descriptor);
    if (code !== 0) {
      results.push({ id: descriptor.id, status: "failed", code });
      throw new Error(`[hooks] ${descriptor.id} failed with code ${code}`);
    }
    results.push({ id: descriptor.id, status: "passed" });
  }
  return results;
}

export async function runChecks(options = {}) {
  const env = options.env ?? process.env;
  const fastMode =
    options.fast === true || env.HOOKS_FAST === "1" || (env.HOOKS_FAST ?? "").toLowerCase() === "true";
  if (env.SKIP_HOOKS === "1") {
    console.log("[hooks] SKIP_HOOKS=1 detected. Skipping pre-commit checks.");
    return { skipped: true, results: [] };
  }
  const sourceCommands = options.commands ?? (fastMode ? FAST_COMMANDS : DEFAULT_COMMANDS);
  if (fastMode) {
    console.log("[hooks] FAST mode enabled; running a reduced command set.");
  }
  const commands = sourceCommands.map(makeCommandDescriptor);
  const results = await runCommandSequence(commands, {
    runner: options.runner,
    dryRun: options.dryRun
  });
  return { skipped: false, results };
}

function defaultRunner(descriptor) {
  return new Promise((resolve, reject) => {
    const child = spawn(descriptor.cmd, descriptor.args, {
      cwd: descriptor.cwd,
      stdio: "inherit",
      shell: process.platform === "win32"
    });
    child.on("error", reject);
    child.on("exit", (code) => resolve(code ?? 1));
  });
}

async function main() {
  try {
    const dryRun = process.argv.includes("--dry-run");
    const fast = process.argv.includes("--fast");
    await runChecks({ dryRun, fast });
    console.log("[hooks] All pre-commit checks passed.");
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.error(message);
    process.exitCode = 1;
  }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  void main();
}
