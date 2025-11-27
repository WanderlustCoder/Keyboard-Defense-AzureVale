#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const DEFAULT_PATHS = [
  path.resolve("artifacts", "summaries", "audio-intensity.ci.json"),
  path.resolve("artifacts", "summaries", "audio-intensity.json")
];

function parseArgs(argv) {
  const args = { file: null, help: false };
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (token === "--file") {
      const next = argv[i + 1];
      if (!next) {
        throw new Error("Missing value for --file.");
      }
      args.file = path.resolve(process.cwd(), next);
      i += 1;
    } else if (token === "--help" || token === "-h") {
      args.help = true;
    } else {
      throw new Error(`Unknown argument "${token}".`);
    }
  }
  return args;
}

function resolveSummaryPath(override) {
  if (override && fs.existsSync(override)) {
    return override;
  }
  for (const candidate of DEFAULT_PATHS) {
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }
  return null;
}

function readSummary(file) {
  if (!file) {
    throw new Error("Audio intensity summary not found.");
  }
  try {
    const raw = fs.readFileSync(file, "utf8");
    return JSON.parse(raw);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    throw new Error(`Unable to read ${file}: ${message}`);
  }
}

function formatNumber(value) {
  if (value === null || value === undefined || Number.isNaN(value)) {
    return "-";
  }
  return Intl.NumberFormat("en-US").format(value);
}

function formatMetric(value, suffix = "") {
  const base = formatNumber(value);
  if (base === "-") {
    return base;
  }
  return suffix ? `${base}${suffix}` : base;
}

function printSummary(run, file) {
  console.log("### Audio Intensity Summary");
  console.log();
  console.log(`Source: ${path.relative(process.cwd(), file)}`);
  console.log();
  const rows = [
    ["Scenario", run.scenario ?? "-"],
    ["Requested", formatMetric(run.requestedIntensity)],
    ["Recorded", formatMetric(run.recordedIntensity)],
    ["Average", formatMetric(run.averageIntensity)],
    ["Delta", formatMetric(run.intensityDelta)],
    ["Samples", formatNumber(run.historySamples)],
    ["Combo correlation", formatMetric(run.comboCorrelation)],
    ["Accuracy correlation", formatMetric(run.accuracyCorrelation)],
    ["Drift", formatMetric(run.driftPercent, "%")]
  ];
  console.log("| Metric | Value |");
  console.log("| --- | --- |");
  for (const [metric, value] of rows) {
    console.log(`| ${metric} | ${value} |`);
  }
}

function printHelp() {
  console.log(`Usage:\n  node scripts/ci/audioIntensitySummary.mjs [--file <summary.json>]\n\nPrints a Markdown table describing the most recent audio intensity summary run.`);
}

try {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    printHelp();
    process.exit(0);
  }
  const summaryPath = resolveSummaryPath(args.file);
  const summary = readSummary(summaryPath);
  const run = Array.isArray(summary?.runs) && summary.runs.length > 0 ? summary.runs[0] : null;
  if (!run) {
    throw new Error("Audio intensity summary does not include any runs.");
  }
  printSummary(run, summaryPath);
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
}
