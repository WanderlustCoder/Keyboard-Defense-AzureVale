#!/usr/bin/env node
/**
 * Lightweight helper to download GitHub Actions artifacts for a given run.
 *
 * Requires the GitHub CLI (`gh`) to be installed and authenticated.
 *
 * Examples:
 *   node scripts/ci/downloadArtifacts.mjs --run-id 123456789
 *   node scripts/ci/downloadArtifacts.mjs --run-id 123456789 --out temp/nightly --name ci-matrix-summary --name codex-dashboard-nightly
 */

import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import process from "node:process";

function parseArgs(argv) {
  const opts = {
    runId: null,
    outDir: path.resolve("artifacts", "nightly-download"),
    names: ["ci-matrix-summary", "codex-dashboard-nightly"],
    workflows: [],
    help: false
  };
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--run-id":
      case "--run":
        opts.runId = argv[++i] ?? null;
        break;
      case "--out":
      case "--dir":
        opts.outDir = path.resolve(argv[++i] ?? opts.outDir);
        break;
      case "--name":
      case "--artifact":
        opts.names.push(argv[++i]);
        break;
      case "--workflow":
      case "--wf":
        opts.workflows.push(argv[++i]);
        break;
      case "--help":
      case "-h":
        opts.help = true;
        break;
      default:
        if (token?.startsWith("-")) {
          throw new Error(`Unknown option: ${token}`);
        }
    }
  }
  return opts;
}

function printHelp() {
  console.log(`Usage: node scripts/ci/downloadArtifacts.mjs --run-id <id> [--out dir] [--name artifact]...

Options:
  --run-id, --run   GitHub Actions run id (required)
  --workflow, --wf  Workflow filename to pull the latest run id (optional; ignored when --run-id is set)
  --out, --dir      Target directory (default artifacts/nightly-download)
  --name, --artifact Artifact name to download (repeatable; defaults: ci-matrix-summary, codex-dashboard-nightly)
  --help, -h        Show this help
`);
}

function ensureGhAvailable() {
  const res = spawnSync("gh", ["--version"], { stdio: "ignore", shell: process.platform === "win32" });
  if (res.status !== 0) {
    throw new Error("GitHub CLI (gh) is required. Install it and ensure it is on PATH.");
  }
}

function downloadArtifact(runId, name, outDir) {
  const targetDir = path.join(outDir, name);
  fs.mkdirSync(targetDir, { recursive: true });
  const res = spawnSync(
    "gh",
    ["run", "download", runId, "--name", name, "--dir", targetDir],
    { stdio: "inherit", shell: process.platform === "win32" }
  );
  if (res.status !== 0) {
    throw new Error(`Failed to download artifact "${name}" for run ${runId}`);
  }
  return targetDir;
}

function resolveLatestRunId(workflow) {
  const res = spawnSync(
    "gh",
    ["run", "list", "--workflow", workflow, "--limit", "1", "--json", "databaseId", "-q", ".[0].databaseId"],
    { shell: process.platform === "win32", encoding: "utf8" }
  );
  if (res.status !== 0) {
    throw new Error(`Failed to resolve latest run id for workflow "${workflow}". Ensure the workflow name is correct and gh is authenticated.`);
  }
  const runId = String(res.stdout ?? "").trim();
  if (!runId) {
    throw new Error(`No runs found for workflow "${workflow}".`);
  }
  return runId;
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

  if (opts.help || !opts.runId) {
    printHelp();
    process.exit(opts.runId ? 0 : 1);
    return;
  }

  ensureGhAvailable();

  let runId = opts.runId;
  if (!runId && opts.workflows.length > 0) {
    runId = resolveLatestRunId(opts.workflows[0]);
  }
  if (!runId) {
    console.error("Missing --run-id (or --workflow to resolve latest run).");
    process.exit(1);
    return;
  }

  const uniqueNames = Array.from(new Set(opts.names.filter(Boolean)));
  if (uniqueNames.length === 0) {
    console.error("No artifact names provided. Use --name to specify at least one.");
    process.exit(1);
    return;
  }

  const summary = [];
  for (const name of uniqueNames) {
    try {
      const dir = downloadArtifact(runId, name, opts.outDir);
      summary.push({ name, dir });
    } catch (error) {
      console.error(error instanceof Error ? error.message : String(error));
      process.exit(1);
      return;
    }
  }
  console.log("Downloaded artifacts:");
  for (const item of summary) {
    console.log(`- ${item.name}: ${item.dir}`);
  }
  console.log(`Run id: ${runId}`);
}

await main();
