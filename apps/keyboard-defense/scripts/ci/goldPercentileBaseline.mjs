#!/usr/bin/env node

import { mkdir, readFile, writeFile, stat, glob } from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const appRoot = path.resolve(__dirname, "..", "..");
const repoRoot = path.resolve(appRoot, "..", "..");

const DEFAULT_TARGETS = [
  path.join(appRoot, "artifacts", "summaries", "gold-summary-report.ci.json"),
  path.join(appRoot, "artifacts", "summaries", "gold-summary-report.smoke.json"),
  path.join(appRoot, "artifacts", "summaries", "gold-summary-report.e2e.json"),
  path.join(repoRoot, "docs", "codex_pack", "fixtures", "gold-summary.json")
];
const DEFAULT_BASELINE_OUT =
  process.env.GOLD_PERCENTILE_BASELINE ??
  path.join(repoRoot, "docs", "codex_pack", "fixtures", "gold", "gold-percentiles.baseline.json");
const DEFAULT_THRESHOLDS_OUT =
  process.env.GOLD_PERCENTILE_THRESHOLDS ??
  path.join(appRoot, "scripts", "ci", "gold-percentile-thresholds.json");
const DEFAULT_MARKDOWN_OUT = path.join(appRoot, "artifacts", "summaries", "gold-percentiles.md");

export const DEFAULT_METRICS = ["medianGain", "p90Gain", "medianSpend", "p90Spend"];
const DEFAULT_DELTA_ABS = Number(process.env.GOLD_BASELINE_DELTA_ABS ?? 20);
const DEFAULT_DELTA_PCT = Number(process.env.GOLD_BASELINE_DELTA_PCT ?? 0.3);

function printHelp() {
  console.log(`Gold Percentile Baseline Refresh

Usage:
  node scripts/ci/goldPercentileBaseline.mjs [options] [target ...]

Options:
  --baseline-out <path>       Baseline JSON output path (default: ${relToCwd(DEFAULT_BASELINE_OUT)})
  --thresholds-out <path>     Threshold JSON output path (default: ${relToCwd(DEFAULT_THRESHOLDS_OUT)})
  --markdown <path>           Optional Markdown summary output path (default: ${relToCwd(DEFAULT_MARKDOWN_OUT)})
  --metrics <list>            Comma-separated metric keys to aggregate (default: ${DEFAULT_METRICS.join(",")})
  --delta <spec>              Override abs/pct thresholds. Examples:
                                --delta abs=20
                                --delta pct=0.35
                                --delta medianGain:abs=15,pct=0.25
  --check                     Verify that existing baseline/threshold files match the computed output.
  --help                      Show this help message.

Targets:
  goldSummary JSON artifacts, directories, or glob patterns. When omitted the
  script scans the default CI outputs plus docs fixtures.`);
}

function relToCwd(targetPath) {
  return path.relative(process.cwd(), targetPath);
}

function normalizePath(value) {
  if (typeof value !== "string") return "";
  return value.replace(/\\/g, "/");
}

function toNumber(value) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function cleanRounded(value) {
  if (!Number.isFinite(value)) return null;
  const rounded = Number(value.toFixed(3));
  return Object.is(rounded, -0) ? 0 : rounded;
}

function sortObject(value) {
  if (Array.isArray(value)) {
    return value.map(sortObject);
  }
  if (!value || typeof value !== "object") {
    return value;
  }
  return Object.fromEntries(
    Object.keys(value)
      .sort()
      .map((key) => [key, sortObject(value[key])])
  );
}

async function globAll(pattern) {
  const matches = [];
  try {
    for await (const entry of glob(pattern)) {
      matches.push(entry);
    }
  } catch {
    return [];
  }
  return matches;
}

function parseDeltaToken(value, options) {
  if (!value) {
    throw new Error("Expected value after --delta");
  }
  const [scope, rest] = value.includes(":") ? value.split(":", 2) : [null, value];
  const assignments = (rest ?? "")
    .split(",")
    .map((token) => token.trim())
    .filter(Boolean);
  if (assignments.length === 0) {
    throw new Error(`Invalid --delta value '${value}'`);
  }
  const delta = {};
  for (const assignment of assignments) {
    const [key, raw] = assignment.split("=");
    if (!raw) {
      throw new Error(`Malformed delta assignment '${assignment}'`);
    }
    if (key === "abs") {
      delta.abs = toNumber(raw);
    } else if (key === "pct") {
      delta.pct = toNumber(raw);
    } else {
      throw new Error(`Unknown delta key '${key}'. Use abs= or pct=.`);
    }
  }
  if (scope === null) {
    options.deltaAbs = delta.abs ?? options.deltaAbs;
    options.deltaPct = delta.pct ?? options.deltaPct;
    return;
  }
  const metric = scope.trim();
  if (!metric) throw new Error(`Invalid metric name in delta spec '${value}'`);
  const previous = options.metricOverrides.get(metric) ?? {};
  options.metricOverrides.set(metric, {
    abs: delta.abs ?? previous.abs ?? options.deltaAbs,
    pct: delta.pct ?? previous.pct ?? options.deltaPct
  });
}

function parseMetrics(value) {
  if (!value) return [...DEFAULT_METRICS];
  return value
    .split(",")
    .map((token) => token.trim())
    .filter(Boolean);
}

function parseArgs(argv) {
  const options = {
    baselineOut: DEFAULT_BASELINE_OUT,
    thresholdsOut: DEFAULT_THRESHOLDS_OUT,
    markdownOut: DEFAULT_MARKDOWN_OUT,
    metrics: [...DEFAULT_METRICS],
    targets: [],
    deltaAbs: DEFAULT_DELTA_ABS,
    deltaPct: DEFAULT_DELTA_PCT,
    metricOverrides: new Map(),
    check: false,
    help: false
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--baseline-out":
        options.baselineOut = path.resolve(argv[++i] ?? "");
        break;
      case "--thresholds-out":
        options.thresholdsOut = path.resolve(argv[++i] ?? "");
        break;
      case "--markdown":
        options.markdownOut = path.resolve(argv[++i] ?? "");
        break;
      case "--metrics":
        options.metrics = parseMetrics(argv[++i]);
        break;
      case "--delta":
        parseDeltaToken(argv[++i], options);
        break;
      case "--check":
        options.check = true;
        break;
      case "--help":
        options.help = true;
        break;
      default:
        if (token.startsWith("-")) {
          throw new Error(`Unknown option '${token}'. Use --help for usage.`);
        }
        options.targets.push(token);
        break;
    }
  }

  if (!options.baselineOut) {
    options.baselineOut = DEFAULT_BASELINE_OUT;
  }
  if (options.thresholdsOut === "") {
    options.thresholdsOut = null;
  }
  if (options.markdownOut === "") {
    options.markdownOut = null;
  }

  return options;
}

async function resolveTargets(inputs) {
  const search = inputs.length > 0 ? inputs : DEFAULT_TARGETS;
  const files = new Set();

  async function addFile(candidate) {
    const normalized = normalizePath(candidate);
    if (!files.has(normalized)) {
      files.add(normalized);
    }
  }

  for (const entry of search) {
    const pattern = path.resolve(entry);
    let matches = await globAll(pattern);
    if (matches.length === 0) {
      matches = [pattern];
    }
    for (const match of matches) {
      let stats;
      try {
        stats = await stat(match);
      } catch {
        continue;
      }
      if (stats.isDirectory()) {
        const nestedPattern = path.join(match, "**/*.json");
        let nestedMatches = await globAll(nestedPattern);
        for (const nested of nestedMatches) {
          const lower = nested.toLowerCase();
          if (lower.endsWith(".json")) {
            await addFile(nested);
          }
        }
      } else if (match.toLowerCase().endsWith(".json")) {
        await addFile(match);
      }
    }
  }

  return Array.from(files).map((file) => path.resolve(file));
}

async function readJson(filePath) {
  const raw = await readFile(filePath, "utf8");
  return JSON.parse(raw);
}

function extractRows(data) {
  if (!data) return [];
  if (Array.isArray(data)) {
    return data;
  }
  if (Array.isArray(data.rows)) {
    return data.rows;
  }
  if (Array.isArray(data.summaries)) {
    return data.summaries;
  }
  return [];
}

function normalizeRow(row, metrics) {
  const file = row?.file ?? row?.path ?? row?.source ?? null;
  if (!file) return null;
  const normalized = { file: normalizePath(file) };
  let hasValue = false;
  for (const metric of metrics) {
    const value = row?.[metric];
    if (typeof value === "number" && Number.isFinite(value)) {
      normalized[metric] = value;
      hasValue = true;
    }
  }
  return hasValue ? normalized : null;
}

async function loadSummaryRows(files, metrics) {
  const rows = [];
  const warnings = [];
  for (const file of files) {
    let data;
    try {
      data = await readJson(file);
    } catch (error) {
      warnings.push(`Failed to read ${relToCwd(file)} (${error?.message ?? error})`);
      continue;
    }
    const extracted = extractRows(data);
    if (extracted.length === 0) {
      warnings.push(`No summary rows found in ${relToCwd(file)}`);
    }
    for (const row of extracted) {
      const normalized = normalizeRow(row, metrics);
      if (normalized) {
        rows.push(normalized);
      }
    }
  }
  return { rows, warnings };
}

export function buildBaselineMap(rows, metrics) {
  const scenarioMap = new Map();
  for (const row of rows) {
    const key = row.file ?? "unknown";
    if (!scenarioMap.has(key)) {
      scenarioMap.set(key, new Map());
    }
    const metricsMap = scenarioMap.get(key);
    for (const metric of metrics) {
      if (!metricsMap.has(metric)) {
        metricsMap.set(metric, []);
      }
      const value = row[metric];
      if (typeof value === "number" && Number.isFinite(value)) {
        metricsMap.get(metric).push(value);
      }
    }
  }
  const baselines = {};
  for (const [scenario, metricMap] of scenarioMap.entries()) {
    const entry = {};
    for (const metric of metrics) {
      const values = metricMap.get(metric) ?? [];
      if (values.length === 0) {
        entry[metric] = null;
      } else {
        const sum = values.reduce((total, value) => total + value, 0);
        entry[metric] = cleanRounded(sum / values.length);
      }
    }
    baselines[scenario] = entry;
  }
  return baselines;
}

export function buildBaselineDocument(baselines, metrics, generatedAt = new Date().toISOString()) {
  const scenarios = Object.keys(baselines).sort();
  const output = {};
  for (const scenario of scenarios) {
    output[scenario] = baselines[scenario];
  }
  output._meta = {
    generatedAt,
    metrics
  };
  return output;
}

export function buildThresholdDocument(
  metrics,
  options,
  previous = null,
  generatedAt = new Date().toISOString()
) {
  const defaults = {};
  for (const metric of metrics) {
    const override = options.metricOverrides.get(metric) ?? {};
    defaults[metric] = {
      abs: override.abs ?? options.deltaAbs,
      pct: override.pct ?? options.deltaPct
    };
  }
  const output = {
    defaults,
    _meta: {
      generatedAt,
      deltaAbs: options.deltaAbs,
      deltaPct: options.deltaPct
    }
  };
  if (previous) {
    for (const [key, value] of Object.entries(previous)) {
      if (key === "defaults" || key === "_meta") continue;
      output[key] = value;
    }
  }
  return output;
}

export function formatBaselineMarkdown(baselineDoc, thresholdsDoc) {
  const lines = [];
  const metrics = baselineDoc?._meta?.metrics ?? [];
  const scenarios = Object.keys(baselineDoc || {})
    .filter((key) => key !== "_meta")
    .sort();
  lines.push("## Gold Percentile Baselines");
  if (baselineDoc?._meta?.generatedAt) {
    lines.push(`Generated: ${baselineDoc._meta.generatedAt}`);
  }
  lines.push("");
  if (scenarios.length === 0 || metrics.length === 0) {
    lines.push("_No baseline rows detected._");
  } else {
    const header = ["Scenario", ...metrics];
    lines.push(`| ${header.join(" | ")} |`);
    lines.push(`| ${header.map(() => "---").join(" | ")} |`);
    for (const scenario of scenarios) {
      const row = baselineDoc[scenario] ?? {};
      const cells = metrics.map((metric) => row[metric] ?? "");
      lines.push(`| ${scenario} | ${cells.join(" | ")} |`);
    }
  }
  if (thresholdsDoc) {
    lines.push("");
    lines.push("### Threshold Defaults");
    lines.push("| Metric | Abs | Pct |");
    lines.push("| --- | --- | --- |");
    for (const metric of metrics) {
      const entry = thresholdsDoc.defaults?.[metric] ?? {};
      lines.push(`| ${metric} | ${entry.abs ?? ""} | ${entry.pct ?? ""} |`);
    }
  }
  return lines.join("\n");
}

async function writeJsonFile(targetPath, payload) {
  const absolute = path.resolve(targetPath);
  await mkdir(path.dirname(absolute), { recursive: true });
  const sorted = sortObject(payload);
  await writeFile(absolute, `${JSON.stringify(sorted, null, 2)}\n`);
}

async function readJsonIfExists(targetPath) {
  if (!targetPath) return null;
  try {
    return await readJson(targetPath);
  } catch {
    return null;
  }
}

function isSameJson(nextValue, existingValue) {
  return JSON.stringify(sortObject(nextValue)) === JSON.stringify(sortObject(existingValue));
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  if (options.help) {
    printHelp();
    return;
  }

  const targets = await resolveTargets(options.targets);
  if (targets.length === 0) {
    throw new Error("No gold summary files found. Provide at least one JSON artifact.");
  }

  const { rows, warnings } = await loadSummaryRows(targets, options.metrics);
  for (const warning of warnings) {
    console.warn(`⚠️ ${warning}`);
  }
  if (rows.length === 0) {
    throw new Error("No usable rows found in provided files.");
  }

  const baselines = buildBaselineMap(rows, options.metrics);
  const existingBaseline = await readJsonIfExists(options.baselineOut);
  if (existingBaseline) {
    for (const [scenario, values] of Object.entries(existingBaseline)) {
      if (scenario === "_meta") continue;
      if (!baselines[scenario]) {
        baselines[scenario] = values;
      }
    }
  }
  const baselineDoc = buildBaselineDocument(baselines, options.metrics);

  let thresholdDoc = null;
  let existingThresholds = null;
  if (options.thresholdsOut) {
    existingThresholds = await readJsonIfExists(options.thresholdsOut);
    thresholdDoc = buildThresholdDocument(options.metrics, options, existingThresholds);
  }

  if (options.check) {
    const baselineMatches = Boolean(existingBaseline) && isSameJson(baselineDoc, existingBaseline);
    const thresholdMatches =
      !options.thresholdsOut ||
      !thresholdDoc ||
      (existingThresholds && isSameJson(thresholdDoc, existingThresholds));
    if (!baselineMatches || (!thresholdMatches && options.thresholdsOut)) {
      throw new Error("Gold percentile baselines are out of date. Re-run the refresh command.");
    }
    console.log("Gold percentile baselines and thresholds are up to date.");
    return;
  }

  await writeJsonFile(options.baselineOut, baselineDoc);
  console.log(`Wrote baseline → ${relToCwd(options.baselineOut)}`);
  if (thresholdDoc && options.thresholdsOut) {
    await writeJsonFile(options.thresholdsOut, thresholdDoc);
    console.log(`Wrote thresholds → ${relToCwd(options.thresholdsOut)}`);
  }
  if (options.markdownOut) {
    const markdown = formatBaselineMarkdown(baselineDoc, thresholdDoc);
    await mkdir(path.dirname(options.markdownOut), { recursive: true });
    await writeFile(options.markdownOut, `${markdown}\n`);
    console.log(`Wrote Markdown summary → ${relToCwd(options.markdownOut)}`);
  }
}

if (
  import.meta.url === `file://${process.argv[1]}` ||
  process.argv[1]?.endsWith("goldPercentileBaseline.mjs")
) {
  main().catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
  });
}
