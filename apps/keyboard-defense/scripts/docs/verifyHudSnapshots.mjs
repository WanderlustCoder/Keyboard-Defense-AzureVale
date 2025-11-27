#!/usr/bin/env node

import { promises as fs } from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const appRoot = path.resolve(scriptDir, "..", "..");
const repoRoot = path.resolve(appRoot, "..", "..");
const DEFAULT_INPUT_DIR = path.resolve(appRoot, "artifacts", "screenshots");

function parseArgs(argv) {
  const opts = {
    inputDir: DEFAULT_INPUT_DIR,
    meta: [],
    help: false
  };
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--input":
      case "--dir": {
        const value = argv[++i];
        if (!value) throw new Error(`Missing value after ${token}`);
        opts.inputDir = path.resolve(value);
        break;
      }
      case "--meta": {
        const value = argv[++i];
        if (!value) throw new Error("Missing value after --meta");
        opts.meta.push(path.resolve(value));
        break;
      }
      case "--help":
      case "-h":
        opts.help = true;
        break;
      default:
        if (token.startsWith("-")) {
          throw new Error(`Unknown option "${token}". Use --help for usage.`);
        }
    }
  }
  return opts;
}

async function listMetaFiles(inputDir, extras) {
  const files = new Set();
  async function addDir(dir) {
    try {
      const entries = await fs.readdir(dir, { withFileTypes: true });
      for (const entry of entries) {
        if (entry.isFile() && entry.name.endsWith(".meta.json")) {
          files.add(path.join(dir, entry.name));
        }
      }
    } catch {
      /* ignore */
    }
  }
  if (inputDir) {
    await addDir(inputDir);
  }
  for (const target of extras) {
    try {
      const stat = await fs.stat(target);
      if (stat.isDirectory()) {
        await addDir(target);
      } else if (stat.isFile() && target.endsWith(".meta.json")) {
        files.add(target);
      }
    } catch {
      /* ignore */
    }
  }
  return Array.from(files);
}

function formatRelative(p) {
  return path.relative(repoRoot, p).replace(/\\/g, "/");
}

function validateEntry(entry, filePath) {
  const errors = [];
  if (!entry || typeof entry !== "object") {
    errors.push("Metadata is not an object.");
    return { file: filePath, id: path.basename(filePath), errors };
  }
  const snapshot = entry.uiSnapshot;
  if (!snapshot || typeof snapshot !== "object") {
    errors.push("Missing uiSnapshot payload.");
    return { file: filePath, id: entry.id ?? path.basename(filePath), errors };
  }
  const diagnostics = snapshot.diagnostics;
  if (!diagnostics || typeof diagnostics !== "object") {
    errors.push("uiSnapshot.diagnostics missing.");
  } else {
    if (
      !diagnostics.collapsedSections ||
      typeof diagnostics.collapsedSections !== "object" ||
      Object.keys(diagnostics.collapsedSections).length === 0
    ) {
      errors.push("uiSnapshot.diagnostics.collapsedSections missing or empty.");
    }
    if (typeof diagnostics.lastUpdatedAt !== "string" || diagnostics.lastUpdatedAt.length === 0) {
      errors.push("uiSnapshot.diagnostics.lastUpdatedAt missing.");
    }
  }
  const preferences = snapshot.preferences;
  if (!preferences || typeof preferences !== "object") {
    errors.push("uiSnapshot.preferences missing.");
  } else {
    if (
      !preferences.diagnosticsSections ||
      typeof preferences.diagnosticsSections !== "object" ||
      Object.keys(preferences.diagnosticsSections).length === 0
    ) {
      errors.push("uiSnapshot.preferences.diagnosticsSections missing or empty.");
    }
    if (
      typeof preferences.diagnosticsSectionsUpdatedAt !== "string" ||
      preferences.diagnosticsSectionsUpdatedAt.length === 0
    ) {
      errors.push("uiSnapshot.preferences.diagnosticsSectionsUpdatedAt missing.");
    }
  }
  if (
    !Array.isArray(entry.badges) ||
    !entry.badges.some((badge) => badge.startsWith("diagnostics:"))
  ) {
    errors.push("Badges missing diagnostics entries.");
  }
  return { file: filePath, id: entry.id ?? path.basename(filePath), errors };
}

function summarizeResults(results) {
  const failures = results.filter((result) => result.errors.length > 0);
  return {
    total: results.length,
    failures
  };
}

async function loadMetadata(filePath) {
  const raw = await fs.readFile(filePath, "utf8");
  return JSON.parse(raw);
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

  if (opts.help) {
    console.log("Usage: node scripts/docs/verifyHudSnapshots.mjs [--input dir] [--meta path]");
    console.log("Ensures HUD screenshot metadata exposes diagnostics + preference fields.");
    return;
  }

  const metaFiles = await listMetaFiles(opts.inputDir, opts.meta);
  if (metaFiles.length === 0) {
    console.warn("No screenshot metadata files found.");
    return;
  }
  const results = [];
  for (const file of metaFiles) {
    try {
      const data = await loadMetadata(file);
      results.push(validateEntry(data, file));
    } catch (error) {
      results.push({
        file,
        id: path.basename(file),
        errors: [error instanceof Error ? error.message : String(error)]
      });
    }
  }
  const summary = summarizeResults(results);
  if (summary.failures.length > 0) {
    console.error("HUD snapshot verification failed:");
    for (const failure of summary.failures) {
      console.error(`- ${formatRelative(failure.file)} (${failure.id})`);
      for (const message of failure.errors) {
        console.error(`    • ${message}`);
      }
    }
    process.exit(1);
    return;
  }
  console.log(`Verified ${summary.total} HUD snapshot metadata file(s).`);
}

const isCliInvocation =
  fileURLToPath(import.meta.url) === path.resolve(process.argv[1] ?? "") ||
  process.argv[1]?.endsWith("verifyHudSnapshots.mjs");

if (isCliInvocation) {
  await main();
}

export { listMetaFiles, loadMetadata, validateEntry, summarizeResults };
