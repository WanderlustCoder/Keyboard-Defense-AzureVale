#!/usr/bin/env node

import { promises as fs } from "node:fs";
import path from "node:path";
import process from "node:process";

const DEFAULT_TIMELINE_PATH = "artifacts/summaries/gold-timeline.ci.json";
const DEFAULT_BASELINE_PATH = "docs/codex_pack/fixtures/gold/gold-percentiles.baseline.json";
const DEFAULT_OUT_JSON = "artifacts/summaries/gold-baseline-guard.json";
const VALID_MODES = new Set(["fail", "warn", "info"]);

function printHelp() {
  console.log(`Gold Baseline Guard

Usage:
  node scripts/ci/goldBaselineGuard.mjs [options]

Options:
  --timeline <path>   Gold timeline summary JSON (default: ${DEFAULT_TIMELINE_PATH})
  --baseline <path>   Percentile baseline JSON (default: ${DEFAULT_BASELINE_PATH})
  --out-json <path>   Output report path (default: ${DEFAULT_OUT_JSON})
  --mode <fail|warn|info>  Failure behaviour when missing baselines are detected (default: fail)
  --help              Show this message
`);
}

function slugify(value) {
  if (typeof value !== "string" || value.length === 0) return "";
  return value
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

function normalizePath(value) {
  if (typeof value !== "string") return "";
  return value.replace(/\\/g, "/");
}

function deriveScenarioId(source) {
  const normalized = normalizePath(source);
  const base = normalized.split("/").pop() ?? normalized;
  const trimmed = base.replace(/\.[^.]+$/, "");
  return slugify(trimmed) || "unknown";
}

function parseArgs(argv) {
  const options = {
    timelinePath: process.env.GOLD_TIMELINE_SUMMARY ?? DEFAULT_TIMELINE_PATH,
    baselinePath: process.env.GOLD_TIMELINE_BASELINE ?? DEFAULT_BASELINE_PATH,
    outJson: DEFAULT_OUT_JSON,
    mode: (process.env.GOLD_BASELINE_GUARD_MODE ?? "fail").toLowerCase(),
    help: false
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--timeline":
        options.timelinePath = argv[++i] ?? options.timelinePath;
        break;
      case "--baseline":
        options.baselinePath = argv[++i] ?? options.baselinePath;
        break;
      case "--out-json":
        options.outJson = argv[++i] ?? options.outJson;
        break;
      case "--mode":
        options.mode = (argv[++i] ?? options.mode).toLowerCase();
        break;
      case "--help":
        options.help = true;
        break;
      default:
        if (token.startsWith("-")) {
          throw new Error(`Unknown option '${token}'. Use --help for usage.`);
        }
    }
  }

  if (!VALID_MODES.has(options.mode)) {
    throw new Error(
      `Invalid mode '${options.mode}'. Use one of: ${Array.from(VALID_MODES).join(", ")}`
    );
  }

  return options;
}

async function readJson(filePath) {
  const absolute = path.resolve(filePath);
  const raw = await fs.readFile(absolute, "utf8");
  return JSON.parse(raw);
}

function normalizeBaseline(baselineData) {
  if (!baselineData || typeof baselineData !== "object") return new Map();
  const map = new Map();
  for (const [key] of Object.entries(baselineData)) {
    if (key === "_meta") continue;
    const id = deriveScenarioId(key);
    map.set(id, true);
  }
  return map;
}

function collectTimelineScenarios(timelineData) {
  const ids = new Set();
  if (Array.isArray(timelineData?.scenarios)) {
    for (const scenario of timelineData.scenarios) {
      const id = slugify(scenario.id ?? scenario.scenario ?? "");
      if (id) ids.add(id);
    }
  }
  if (ids.size === 0 && Array.isArray(timelineData?.latestEvents)) {
    for (const event of timelineData.latestEvents) {
      const id = slugify(event.scenario ?? event.mode ?? "") || deriveScenarioId(event.file ?? "");
      if (id) ids.add(id);
    }
  }
  return ids;
}

async function writeJson(outPath, payload) {
  const absolute = path.resolve(outPath);
  await fs.mkdir(path.dirname(absolute), { recursive: true });
  await fs.writeFile(absolute, `${JSON.stringify(payload, null, 2)}\n`);
}

async function appendStepSummary(markdown) {
  const summaryFile = process.env.GITHUB_STEP_SUMMARY;
  if (!summaryFile) return;
  await fs.appendFile(summaryFile, `${markdown}\n`);
}

export async function runBaselineGuard(options) {
  const [timelineData, baselineData] = await Promise.all([
    readJson(options.timelinePath),
    readJson(options.baselinePath)
  ]);

  const baselineMap = normalizeBaseline(baselineData);
  const scenarios = collectTimelineScenarios(timelineData);
  const missing = Array.from(scenarios).filter((id) => !baselineMap.has(id));

  const report = {
    generatedAt: new Date().toISOString(),
    mode: options.mode,
    inputs: {
      timeline: options.timelinePath,
      baseline: options.baselinePath
    },
    totals: {
      scenarios: scenarios.size,
      baselineEntries: baselineMap.size,
      missing: missing.length
    },
    missing
  };

  await writeJson(options.outJson, report);
  await appendStepSummary(
    [
      "## Gold Baseline Guard",
      `Scenarios: ${report.totals.scenarios}, Baseline entries: ${report.totals.baselineEntries}`,
      missing.length > 0
        ? `Missing: ${missing.join(", ")}`
        : "Missing: none",
      `Report: \`${options.outJson}\``
    ].join("\n")
  );

  if (missing.length > 0 && options.mode === "fail") {
    throw new Error(
      `${missing.length} scenario(s) missing timeline baseline coverage. See ${options.outJson}`
    );
  }
  return report;
}

async function main() {
  let options;
  try {
    options = parseArgs(process.argv.slice(2));
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
    return;
  }

  if (options.help) {
    printHelp();
    return;
  }

  try {
    await runBaselineGuard(options);
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(options.mode === "warn" ? 0 : 1);
  }
}

if (
  import.meta.url === `file://${process.argv[1]}` ||
  process.argv[1]?.endsWith("goldBaselineGuard.mjs")
) {
  await main();
}
