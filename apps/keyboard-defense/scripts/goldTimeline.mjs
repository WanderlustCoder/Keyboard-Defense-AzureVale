#!/usr/bin/env node

import { promises as fs } from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

const DEFAULT_OUTPUT = null;

function printHelp() {
  console.log(`Keyboard Defense gold timeline export

Usage:
  node scripts/goldTimeline.mjs [options] <file-or-directory> [...]

Options:
  --csv           Emit CSV instead of JSON
  --out <path>    Write output to the provided file (stdout otherwise)
  --help          Show this help message

Description:
  Scans analytics snapshots or smoke artifacts for gold event arrays and emits a timeline
  summarising delta, resulting total, timestamps, and time-since values. Useful for correlating
  passive unlocks with economy swings in dashboards.`);
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
        options.help = true;
        break;
      default:
        if (token.startsWith("-")) {
          throw new Error(`Unknown option: ${token}`);
        }
        options.targets.push(token);
        break;
    }
  }

  if (!options.help && options.targets.length === 0) {
    throw new Error("Provide at least one file or directory to scan.");
  }

  return options;
}

async function resolveTargets(targets) {
  const files = [];
  for (const target of targets) {
    const absolute = path.resolve(target);
    let stat;
    try {
      stat = await fs.stat(absolute);
    } catch {
      continue;
    }
    if (stat.isDirectory()) {
      const entries = await fs.readdir(absolute);
      for (const entry of entries) {
        if (!entry.toLowerCase().endsWith(".json")) continue;
        files.push(path.join(absolute, entry));
      }
    } else {
      files.push(absolute);
    }
  }
  return files;
}

function safeJsonParse(content, filePath) {
  try {
    return JSON.parse(content);
  } catch (error) {
    throw new Error(`Failed to parse JSON from ${filePath}: ${error.message}`);
  }
}

function normalizeEvents(snapshot) {
  if (!snapshot || typeof snapshot !== "object") {
    return [];
  }
  const analytics = snapshot.analytics ?? snapshot.state?.analytics ?? null;
  if (Array.isArray(analytics?.goldEvents) && analytics.goldEvents.length > 0) {
    return analytics.goldEvents;
  }
  if (Array.isArray(snapshot.recentGoldEvents) && snapshot.recentGoldEvents.length > 0) {
    return snapshot.recentGoldEvents;
  }
  if (
    Array.isArray(snapshot.state?.recentGoldEvents) &&
    snapshot.state.recentGoldEvents.length > 0
  ) {
    return snapshot.state.recentGoldEvents;
  }
  return [];
}

function resolveReferenceTime(snapshot) {
  if (typeof snapshot?.time === "number" && Number.isFinite(snapshot.time)) {
    return snapshot.time;
  }
  if (typeof snapshot?.state?.time === "number" && Number.isFinite(snapshot.state.time)) {
    return snapshot.state.time;
  }
  const analyticsTime = snapshot?.analytics?.time ?? snapshot?.state?.analytics?.time;
  if (typeof analyticsTime === "number" && Number.isFinite(analyticsTime)) {
    return analyticsTime;
  }
  return null;
}

export function buildGoldTimelineEntries(snapshot, filePath) {
  const events = normalizeEvents(snapshot);
  if (events.length === 0) {
    return [];
  }
  const referenceTime = resolveReferenceTime(snapshot);
  const capturedAt = snapshot.capturedAt ?? null;
  const status = snapshot.status ?? snapshot.state?.status ?? null;
  const mode = snapshot.mode ?? snapshot.analytics?.mode ?? null;

  return events.map((event, index) => {
    const timestamp =
      typeof event.timestamp === "number" && Number.isFinite(event.timestamp)
        ? event.timestamp
        : null;
    const gold = typeof event.gold === "number" && Number.isFinite(event.gold) ? event.gold : null;
    const delta =
      typeof event.delta === "number" && Number.isFinite(event.delta) ? event.delta : null;
    const timeSince =
      referenceTime !== null && timestamp !== null ? Math.max(0, referenceTime - timestamp) : null;
    return {
      file: filePath,
      capturedAt,
      status,
      mode,
      eventIndex: index,
      gold,
      delta,
      timestamp,
      timeSince
    };
  });
}

function toCsv(rows) {
  const headers = [
    "file",
    "capturedAt",
    "status",
    "mode",
    "eventIndex",
    "gold",
    "delta",
    "timestamp",
    "timeSince"
  ];
  const escape = (value) => {
    if (value === null || value === undefined) return "";
    const str = String(value);
    if (str.includes(",") || str.includes("\n") || str.includes('"')) {
      return `"${str.replace(/"/g, '""')}"`;
    }
    return str;
  };
  const lines = [headers.join(",")];
  for (const row of rows) {
    lines.push(headers.map((header) => escape(row[header])).join(","));
  }
  return `${lines.join("\n")}\n`;
}

function toJson(rows) {
  return `${JSON.stringify(rows, null, 2)}\n`;
}

export async function runGoldTimeline(options) {
  const files = await resolveTargets(options.targets);
  const rows = [];
  for (const file of files) {
    let content;
    try {
      content = await fs.readFile(file, "utf8");
    } catch (error) {
      console.warn(`goldTimeline: skipped ${file} (${error.message})`);
      continue;
    }
    let payload;
    try {
      payload = safeJsonParse(content, file);
    } catch (error) {
      console.warn(error.message);
      continue;
    }
    const entries = buildGoldTimelineEntries(payload, file);
    rows.push(...entries);
  }

  const serialized = options.csv ? toCsv(rows) : toJson(rows);
  if (options.out) {
    const outPath = path.resolve(options.out);
    await fs.mkdir(path.dirname(outPath), { recursive: true });
    await fs.writeFile(outPath, serialized, "utf8");
    console.log(`goldTimeline: wrote ${rows.length} entries to ${outPath}`);
  } else {
    process.stdout.write(serialized);
  }
  return 0;
}

async function main() {
  let parsed;
  try {
    parsed = parseArgs(process.argv.slice(2));
  } catch (error) {
    console.error(error.message);
    process.exit(1);
    return;
  }

  if (parsed.help) {
    printHelp();
    process.exit(0);
    return;
  }

  try {
    const exitCode = await runGoldTimeline(parsed);
    process.exit(exitCode);
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
  }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  await main();
}
