#!/usr/bin/env node

import { promises as fs } from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

const DEFAULT_OUTPUT = null;

function printHelp() {
  console.log(`Keyboard Defense passive unlock timeline

Usage:
  node scripts/passiveTimeline.mjs [options] <file-or-directory> [...]

Options:
  --csv             Emit CSV instead of JSON
  --out <path>      Write output to the provided file (stdout otherwise)
  --help            Show this help message

Description:
  Parses analytics snapshots (JSON files produced by the exporter or automation scripts)
  and emits a chronological list of castle passive unlocks. Use --csv when feeding data
  into spreadsheets or dashboards.`);
}

export function parseArgs(argv = []) {
  const options = {
    csv: false,
    out: DEFAULT_OUTPUT,
    help: false,
    targets: []
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--csv":
        options.csv = true;
        break;
      case "--out": {
        const value = argv[++i];
        if (!value) {
          throw new Error("Expected path after --out");
        }
        options.out = value;
        break;
      }
      case "--help":
      case "-h":
        options.help = true;
        break;
      default:
        if (token.startsWith("-")) {
          throw new Error(`Unknown argument "${token}". Use --help for usage.`);
        }
        options.targets.push(token);
        break;
    }
  }

  return options;
}

async function collectTargets(paths) {
  const files = [];
  for (const input of paths) {
    const resolved = path.resolve(input);
    let stat;
    try {
      stat = await fs.stat(resolved);
    } catch (error) {
      console.warn(`passiveTimeline: unable to read ${input}: ${error?.message ?? error}`);
      continue;
    }
    if (stat.isDirectory()) {
      const entries = await fs.readdir(resolved);
      for (const entry of entries) {
        if (entry.toLowerCase().endsWith(".json")) {
          files.push(path.join(resolved, entry));
        }
      }
    } else if (stat.isFile()) {
      files.push(resolved);
    }
  }
  return files;
}

async function loadSnapshot(file) {
  try {
    const raw = await fs.readFile(file, "utf8");
    return JSON.parse(raw);
  } catch (error) {
    console.warn(`passiveTimeline: failed to parse ${file}: ${error?.message ?? error}`);
    return null;
  }
}

export function buildTimelineEntries(snapshot, sourcePath) {
  const unlocks = snapshot?.analytics?.castlePassiveUnlocks;
  if (!Array.isArray(unlocks) || unlocks.length === 0) {
    return [];
  }
  const capturedAt = snapshot?.capturedAt ?? "";
  const runMode = snapshot?.mode ?? snapshot?.analytics?.mode ?? "";
  const waveIndex = snapshot?.wave?.index ?? "";
  const status = snapshot?.status ?? "";
  return unlocks.map((unlock, index) => ({
    file: sourcePath,
    capturedAt,
    status,
    mode: runMode,
    waveIndex,
    unlockIndex: index,
    id: unlock.id ?? "",
    level: unlock.level ?? "",
    time: unlock.time ?? "",
    total: unlock.total ?? "",
    delta: unlock.delta ?? ""
  }));
}

function formatCsv(rows) {
  const headers = [
    "file",
    "capturedAt",
    "status",
    "mode",
    "waveIndex",
    "unlockIndex",
    "id",
    "level",
    "time",
    "total",
    "delta"
  ];
  const escape = (value) => {
    if (value === null || value === undefined) return "";
    const string = String(value);
    if (/[",\n]/.test(string)) {
      return `"${string.replace(/"/g, '""')}"`;
    }
    return string;
  };
  const lines = [headers.join(",")];
  for (const row of rows) {
    lines.push(headers.map((key) => escape(row[key] ?? "")).join(","));
  }
  return lines.join("\n");
}

function formatJson(rows) {
  return JSON.stringify(
    {
      unlockCount: rows.length,
      entries: rows
    },
    null,
    2
  );
}

export async function runPassiveTimeline(options) {
  if (options.help) {
    printHelp();
    return 0;
  }
  if (options.targets.length === 0) {
    console.error("passiveTimeline: no input files provided. See --help for usage.");
    return 1;
  }
  const files = await collectTargets(options.targets);
  if (files.length === 0) {
    console.error("passiveTimeline: no JSON snapshots found in provided paths.");
    return 1;
  }
  const rows = [];
  for (const file of files) {
    const snapshot = await loadSnapshot(file);
    if (!snapshot) continue;
    rows.push(...buildTimelineEntries(snapshot, file));
  }
  if (rows.length === 0) {
    console.error("passiveTimeline: no castle passive unlocks found in provided snapshots.");
    return 1;
  }

  const payload = options.csv ? formatCsv(rows) : formatJson(rows);

  if (options.out) {
    const target = path.resolve(options.out);
    await fs.mkdir(path.dirname(target), { recursive: true });
    await fs.writeFile(target, payload, "utf8");
    console.log(`passiveTimeline: wrote ${rows.length} entries to ${target}`);
  } else {
    console.log(payload);
  }
  return 0;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const exitCode = await runPassiveTimeline(args);
  process.exit(exitCode);
}

const isCliInvocation =
  typeof process.argv[1] === "string" &&
  fileURLToPath(import.meta.url) === path.resolve(process.argv[1]);

if (isCliInvocation) {
  await main();
}
