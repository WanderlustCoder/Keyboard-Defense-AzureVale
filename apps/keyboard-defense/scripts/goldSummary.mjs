#!/usr/bin/env node

import { promises as fs } from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

import { buildGoldTimelineEntries } from "./goldTimeline.mjs";

const DEFAULT_OUTPUT = null;

function printHelp() {
  console.log(`Keyboard Defense gold summary export

Usage:
  node scripts/goldSummary.mjs [options] <timeline-or-snapshot> [...]

Options:
  --csv           Emit CSV instead of JSON
  --out <path>    Write output to the provided file (stdout otherwise)
  --help          Show this message

Description:
  Consumes either gold timeline files (produced by goldTimeline.mjs) or analytics snapshots/smoke
  artifacts and emits per-file summary stats (max gains/spends, totals, passive correlations, etc).`);
}

export function parseArgs(argv = []) {
  const options = {
    csv: false,
    out: DEFAULT_OUTPUT,
    help: false,
    targets: [],
    global: false
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
      case "--global":
        options.global = true;
        break;
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

function isTimelineEntries(data) {
  if (!Array.isArray(data)) return false;
  return data.every((entry) => entry && typeof entry === "object" && "eventIndex" in entry);
}

function groupByFile(entries) {
  const map = new Map();
  for (const entry of entries) {
    const file = entry.file ?? "unknown";
    if (!map.has(file)) {
      map.set(file, []);
    }
    map.get(file).push(entry);
  }
  return map;
}

function computePercentile(sortedValues, percentile) {
  if (sortedValues.length === 0) return null;
  if (sortedValues.length === 1) return sortedValues[0];
  const clamped = Math.min(Math.max(percentile, 0), 100);
  const position = (clamped / 100) * (sortedValues.length - 1);
  const lowerIndex = Math.floor(position);
  const upperIndex = Math.ceil(position);
  if (lowerIndex === upperIndex) {
    return sortedValues[lowerIndex];
  }
  const lowerValue = sortedValues[lowerIndex];
  const upperValue = sortedValues[upperIndex];
  const weight = position - lowerIndex;
  return lowerValue + (upperValue - lowerValue) * weight;
}

function computePercentilePair(values) {
  if (!values.length) {
    return { median: null, p90: null };
  }
  const sorted = [...values].sort((a, b) => a - b);
  return {
    median: computePercentile(sorted, 50),
    p90: computePercentile(sorted, 90)
  };
}

export function summarizeFileEntries(file, entries) {
  if (entries.length === 0) {
    return {
      file,
      eventCount: 0,
      netDelta: 0,
      maxGain: null,
      maxSpend: null,
      totalPositive: 0,
      totalNegative: 0,
      firstTimestamp: null,
      lastTimestamp: null,
      passiveLinkedCount: 0,
      uniquePassiveIds: [],
      medianGain: null,
      p90Gain: null,
      medianSpend: null,
      p90Spend: null,
      maxPassiveLag: null
    };
  }
  let netDelta = 0;
  let totalPositive = 0;
  let totalNegative = 0;
  let maxGain = null;
  let maxSpend = null;
  let firstTimestamp = null;
  let lastTimestamp = null;
  let passiveLinkedCount = 0;
  let maxPassiveLag = null;
  const passiveIds = new Set();
  const gains = [];
  const spends = [];

  for (const entry of entries) {
    const delta = Number.isFinite(entry.delta) ? entry.delta : 0;
    netDelta += delta;
    if (delta > 0) {
      totalPositive += delta;
      gains.push(delta);
      if (maxGain === null || delta > maxGain) {
        maxGain = delta;
      }
    } else if (delta < 0) {
      totalNegative += Math.abs(delta);
      spends.push(delta);
      if (maxSpend === null || delta < maxSpend) {
        maxSpend = delta;
      }
    }
    const timestamp =
      typeof entry.timestamp === "number" && Number.isFinite(entry.timestamp)
        ? entry.timestamp
        : null;
    if (timestamp !== null) {
      if (firstTimestamp === null || timestamp < firstTimestamp) {
        firstTimestamp = timestamp;
      }
      if (lastTimestamp === null || timestamp > lastTimestamp) {
        lastTimestamp = timestamp;
      }
    }
    if (entry.passiveId) {
      passiveLinkedCount += 1;
      passiveIds.add(entry.passiveId);
      if (typeof entry.passiveLag === "number" && Number.isFinite(entry.passiveLag)) {
        const lagAbs = Math.abs(entry.passiveLag);
        if (maxPassiveLag === null || lagAbs > maxPassiveLag) {
          maxPassiveLag = lagAbs;
        }
      }
    }
  }
  const gainPercentiles = computePercentilePair(gains);
  const spendPercentiles = computePercentilePair(spends);

  return {
    file,
    eventCount: entries.length,
    netDelta,
    maxGain,
    maxSpend,
    totalPositive,
    totalNegative,
    firstTimestamp,
    lastTimestamp,
    passiveLinkedCount,
    uniquePassiveIds: [...passiveIds],
    medianGain: gainPercentiles.median,
    p90Gain: gainPercentiles.p90,
    medianSpend: spendPercentiles.median,
    p90Spend: spendPercentiles.p90,
    maxPassiveLag
  };
}

export function summarizeGoldEntries(entries) {
  const grouped = groupByFile(entries);
  const summaries = [];
  for (const [file, groupedEntries] of grouped.entries()) {
    summaries.push(summarizeFileEntries(file, groupedEntries));
  }
  return summaries;
}

function toCsv(rows) {
  const headers = [
    "file",
    "eventCount",
    "netDelta",
    "maxGain",
    "maxSpend",
    "totalPositive",
    "totalNegative",
    "firstTimestamp",
    "lastTimestamp",
    "passiveLinkedCount",
    "uniquePassiveIds",
    "medianGain",
    "p90Gain",
    "medianSpend",
    "p90Spend",
    "maxPassiveLag"
  ];
  const escape = (value) => {
    if (value === null || value === undefined) return "";
    const str = String(Array.isArray(value) ? value.join("|") : value);
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

async function loadEntriesFromFile(file) {
  const content = await fs.readFile(file, "utf8");
  const payload = safeJsonParse(content, file);
  if (isTimelineEntries(payload)) {
    return payload.map((entry) => ({ ...entry, file: entry.file ?? file }));
  }
  return buildGoldTimelineEntries(payload, file, { mergePassives: true });
}

export async function runGoldSummary(options) {
  const files = await resolveTargets(options.targets);
  const entries = [];
  for (const file of files) {
    try {
      const fileEntries = await loadEntriesFromFile(file);
      entries.push(...fileEntries);
    } catch (error) {
      console.warn(error.message);
    }
  }
  const summaries = summarizeGoldEntries(entries);
  if (options.global) {
    summaries.push(summarizeFileEntries("ALL", entries));
  }
  const serialized = options.csv ? toCsv(summaries) : toJson(summaries);
  if (options.out) {
    const outPath = path.resolve(options.out);
    await fs.mkdir(path.dirname(outPath), { recursive: true });
    await fs.writeFile(outPath, serialized, "utf8");
    console.log(`goldSummary: wrote ${summaries.length} rows to ${outPath}`);
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
    const exitCode = await runGoldSummary(parsed);
    process.exit(exitCode);
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
  }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  await main();
}
