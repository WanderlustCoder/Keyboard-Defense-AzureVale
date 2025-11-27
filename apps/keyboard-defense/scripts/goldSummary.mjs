#!/usr/bin/env node

import { promises as fs } from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

import { buildGoldTimelineEntries } from "./goldTimeline.mjs";

const DEFAULT_OUTPUT = null;
const DEFAULT_PERCENTILES = [50, 90];

function printHelp() {
  console.log(`Keyboard Defense gold summary export

Usage:
  node scripts/goldSummary.mjs [options] <timeline-or-snapshot> [...]

Options:
  --csv           Emit CSV instead of JSON
  --out <path>    Write output to the provided file (stdout otherwise)
  --percentiles <list>
                  Comma-separated percentile cutlines (0-100) to include in the output (defaults to 50,90)
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
    global: false,
    percentiles: [...DEFAULT_PERCENTILES]
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
      case "--percentiles": {
        const value = argv[++i];
        if (!value) throw new Error("Expected list after --percentiles");
        const parsed = value
          .split(",")
          .map((token) => Number.parseFloat(token.trim()))
          .filter((num) => !Number.isNaN(num));
        if (parsed.length === 0) {
          throw new Error("Provide at least one numeric percentile (0-100).");
        }
        if (parsed.some((num) => num < 0 || num > 100)) {
          throw new Error("Percentiles must fall between 0 and 100.");
        }
        const uniqueSorted = [...new Set(parsed)].sort((a, b) => a - b);
        options.percentiles = uniqueSorted;
        break;
      }
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

function computePercentiles(values, percentiles) {
  if (!values.length) {
    return new Map();
  }
  const sorted = [...values].sort((a, b) => a - b);
  const map = new Map();
  for (const pct of percentiles) {
    map.set(pct, computePercentile(sorted, pct));
  }
  return map;
}

function formatPercentileKey(prefix, value) {
  const normalized = String(value)
    .replace(/\./g, "_")
    .replace(/[^0-9_]/g, "");
  return `${prefix}P${normalized}`;
}

export function summarizeFileEntries(file, entries, percentiles = DEFAULT_PERCENTILES) {
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
      maxPassiveLag: null,
      medianGain: null,
      p90Gain: null,
      medianSpend: null,
      p90Spend: null,
      ...Object.fromEntries(
        percentiles.flatMap((pct) => [
          [formatPercentileKey("gain", pct), null],
          [formatPercentileKey("spend", pct), null]
        ])
      )
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
  const gainPercentiles = computePercentiles(gains, percentiles);
  const spendPercentiles = computePercentiles(spends, percentiles);
  const percentileFields = {};
  for (const pct of percentiles) {
    percentileFields[formatPercentileKey("gain", pct)] = gainPercentiles.get(pct) ?? null;
    percentileFields[formatPercentileKey("spend", pct)] = spendPercentiles.get(pct) ?? null;
  }

  const starfieldStats = summarizeStarfield(entries);
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
    ...percentileFields,
    medianGain: gainPercentiles.get(50) ?? null,
    p90Gain: gainPercentiles.get(90) ?? null,
    medianSpend: spendPercentiles.get(50) ?? null,
    p90Spend: spendPercentiles.get(90) ?? null,
    maxPassiveLag,
    starfieldDepth: starfieldStats.depth,
    starfieldDrift: starfieldStats.drift,
    starfieldTint: starfieldStats.tint,
    starfieldWaveProgress: starfieldStats.waveProgress,
    starfieldCastleRatio: starfieldStats.castleRatio
  };
}

function average(values) {
  if (!Array.isArray(values) || values.length === 0) {
    return null;
  }
  const sum = values.reduce((acc, value) => acc + value, 0);
  return Number((sum / values.length).toFixed(3));
}

function summarizeStarfield(entries) {
  const depthValues = [];
  const driftValues = [];
  const waveValues = [];
  const castleValues = [];
  let latestTint = null;
  for (const entry of entries) {
    const state = entry.starfield;
    if (!state || typeof state !== "object") {
      continue;
    }
    if (typeof state.tint === "string" && state.tint.length > 0) {
      latestTint = state.tint;
    }
    if (typeof state.depth === "number" && Number.isFinite(state.depth)) {
      depthValues.push(state.depth);
    }
    if (
      typeof state.driftMultiplier === "number" &&
      Number.isFinite(state.driftMultiplier)
    ) {
      driftValues.push(state.driftMultiplier);
    }
    if (typeof state.waveProgress === "number" && Number.isFinite(state.waveProgress)) {
      waveValues.push(state.waveProgress);
    }
    if (
      typeof state.castleHealthRatio === "number" &&
      Number.isFinite(state.castleHealthRatio)
    ) {
      castleValues.push(state.castleHealthRatio);
    }
  }
  return {
    depth: average(depthValues),
    drift: average(driftValues),
    tint: latestTint,
    waveProgress: toPercent(average(waveValues)),
    castleRatio: toPercent(average(castleValues))
  };
}

function toPercent(value) {
  if (!Number.isFinite(value)) {
    return null;
  }
  return Number((value * 100).toFixed(3));
}

export function summarizeGoldEntries(entries, percentiles = DEFAULT_PERCENTILES) {
  const grouped = groupByFile(entries);
  const summaries = [];
  for (const [file, groupedEntries] of grouped.entries()) {
    summaries.push(summarizeFileEntries(file, groupedEntries, percentiles));
  }
  return summaries;
}

function toCsv(rows, percentiles, metadata) {
  const baseHeaders = [
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
    "uniquePassiveIds"
  ];
  const percentileHeaders = percentiles.flatMap((pct) => [
    formatPercentileKey("gain", pct),
    formatPercentileKey("spend", pct)
  ]);
  const tailHeaders = [
    "medianGain",
    "p90Gain",
    "medianSpend",
    "p90Spend",
    "maxPassiveLag",
    "starfieldDepth",
    "starfieldDrift",
    "starfieldTint",
    "starfieldWaveProgress",
    "starfieldCastleRatio"
  ];
  const headers = [...baseHeaders, ...percentileHeaders, ...tailHeaders];
  if (metadata && metadata.percentiles?.length) {
    headers.push("summaryPercentiles");
  }
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
    const serializedRow = {
      ...row
    };
    if (metadata?.percentiles?.length) {
      serializedRow.summaryPercentiles = metadata.percentiles.join("|");
    }
    lines.push(headers.map((header) => escape(serializedRow[header])).join(","));
  }
  return `${lines.join("\n")}\n`;
}

function toJson(rows, metadata) {
  if (metadata?.percentiles?.length) {
    return `${JSON.stringify({ percentiles: metadata.percentiles, rows }, null, 2)}\n`;
  }
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
  const percentiles = options.percentiles ?? DEFAULT_PERCENTILES;
  const summaries = summarizeGoldEntries(entries, percentiles);
  if (options.global) {
    summaries.push(summarizeFileEntries("ALL", entries, percentiles));
  }
  const metadata = { percentiles };
  const serialized = options.csv
    ? toCsv(summaries, percentiles, metadata)
    : toJson(summaries, metadata);
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
