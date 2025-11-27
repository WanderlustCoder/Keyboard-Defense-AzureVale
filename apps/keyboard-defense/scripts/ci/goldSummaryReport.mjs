#!/usr/bin/env node

import { promises as fs } from "node:fs";
import path from "node:path";
import process from "node:process";

const DEFAULT_TARGETS = [
  "artifacts/smoke/gold-summary.ci.json",
  "artifacts/e2e/gold-summary.ci.json"
];
const DEFAULT_SUMMARY_PATH = "artifacts/summaries/gold-summary-report.ci.json";
const DEFAULT_ALERTS_PATH = "artifacts/summaries/gold-percentiles.ci.json";
const DEFAULT_MODE = (process.env.GOLD_SUMMARY_REPORT_MODE ?? "fail").toLowerCase();
const DEFAULT_MIN_NET_DELTA = Number(process.env.GOLD_SUMMARY_MIN_NET_DELTA ?? -250);
const DEFAULT_MAX_P90_SPEND_MAG = Number(process.env.GOLD_SUMMARY_MAX_P90_SPEND_MAG ?? 250);
const DEFAULT_BASELINE_PATH =
  process.env.GOLD_PERCENTILE_BASELINE ??
  "docs/codex_pack/fixtures/gold/gold-percentiles.baseline.json";
const DEFAULT_THRESHOLD_PATH =
  process.env.GOLD_PERCENTILE_THRESHOLDS ?? "scripts/ci/gold-percentile-thresholds.json";
const VALID_MODES = new Set(["fail", "warn"]);

function printHelp() {
  console.log(`Gold Summary Dashboard

Usage:
  node scripts/ci/goldSummaryReport.mjs [options] [target ...]

Options:
  --summary <path>                Output JSON summary path (default: ${DEFAULT_SUMMARY_PATH})
  --mode <fail|warn>              Failure behaviour when thresholds trip (default: fail)
  --min-net-delta <gold>          Minimum acceptable cumulative net delta (default: ${DEFAULT_MIN_NET_DELTA})
  --max-spend-magnitude <gold>    Maximum allowed |p90Spend| magnitude (default: ${DEFAULT_MAX_P90_SPEND_MAG})
  --percentile-alerts <path>      Output JSON path for percentile drift rows (default: ${DEFAULT_ALERTS_PATH})
  --baseline <path>               Baseline JSON describing expected percentile values per artifact
                                  (default: ${DEFAULT_BASELINE_PATH})
  --thresholds <path>             Threshold JSON describing allowed delta bands
                                  (default: ${DEFAULT_THRESHOLD_PATH})
  --help                          Show this help message

Arguments:
  target                          gold-summary JSON file or directory (defaults: ${DEFAULT_TARGETS.join(", ")}).
`);
}

function parseNumber(value, fallback) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function formatOptionalNumber(value, suffix = "") {
  if (typeof value === "number" && Number.isFinite(value)) {
    return `${value}${suffix}`;
  }
  return "n/a";
}

function parseArgs(argv) {
  const options = {
    summaryPath: process.env.GOLD_SUMMARY_REPORT_PATH ?? DEFAULT_SUMMARY_PATH,
    alertsPath: process.env.GOLD_PERCENTILE_ALERTS ?? DEFAULT_ALERTS_PATH,
    mode: DEFAULT_MODE,
    minNetDelta: DEFAULT_MIN_NET_DELTA,
    maxSpendMagnitude: DEFAULT_MAX_P90_SPEND_MAG,
    baselinePath: DEFAULT_BASELINE_PATH,
    thresholdPath: DEFAULT_THRESHOLD_PATH,
    targets: [],
    help: false
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--summary":
        options.summaryPath = argv[++i] ?? options.summaryPath;
        break;
      case "--mode":
        options.mode = (argv[++i] ?? options.mode).toLowerCase();
        break;
      case "--min-net-delta":
        options.minNetDelta = parseNumber(argv[++i], options.minNetDelta);
        break;
      case "--max-spend-magnitude":
        options.maxSpendMagnitude = parseNumber(argv[++i], options.maxSpendMagnitude);
        break;
      case "--percentile-alerts":
        options.alertsPath = argv[++i] ?? options.alertsPath;
        break;
      case "--baseline":
        options.baselinePath = argv[++i] ?? options.baselinePath;
        break;
      case "--thresholds":
        options.thresholdPath = argv[++i] ?? options.thresholdPath;
        break;
      case "--help":
        options.help = true;
        break;
      default:
        if (token.startsWith("-")) {
          throw new Error(`Unknown option '${token}'. Use --help for usage.`);
        }
        options.targets.push(token);
    }
  }

  if (!VALID_MODES.has(options.mode)) {
    throw new Error(
      `Invalid mode '${options.mode}'. Use one of: ${Array.from(VALID_MODES).join(", ")}`
    );
  }

  if (options.targets.length === 0) {
    options.targets = [...DEFAULT_TARGETS];
  }

  return options;
}

async function collectSummaryFiles(targets) {
  const files = new Set();
  for (const target of targets) {
    const resolved = path.resolve(target);
    let stat;
    try {
      stat = await fs.stat(resolved);
    } catch {
      continue;
    }
    if (stat.isDirectory()) {
      const entries = await fs.readdir(resolved);
      for (const entry of entries) {
        if (!entry.toLowerCase().endsWith(".json")) continue;
        files.add(path.join(resolved, entry));
      }
    } else if (resolved.toLowerCase().endsWith(".json")) {
      files.add(resolved);
    }
  }
  return Array.from(files);
}

async function readSummaryRows(file) {
  const content = await fs.readFile(file, "utf8");
  const payload = JSON.parse(content);
  if (Array.isArray(payload?.rows)) {
    return payload.rows.map((row) => ({ ...row, source: file }));
  }
  if (Array.isArray(payload)) {
    return payload.map((row) => ({ ...row, source: file }));
  }
  throw new Error(`${file}: unsupported gold summary format (expected JSON rows).`);
}

function toNumber(value) {
  const num = Number(value);
  return Number.isFinite(num) ? num : null;
}

function normalizeRow(row) {
  const file = row.file ?? row.source ?? "unknown";
  const medianGain = toNumber(row.medianGain ?? row.gainP50);
  const p90Gain = toNumber(row.p90Gain ?? row.gainP90);
  const medianSpend = toNumber(row.medianSpend ?? row.spendP50);
  const p90Spend = toNumber(row.p90Spend ?? row.spendP90);
  const starfieldDepth = toNumber(row.starfieldDepth);
  const starfieldDrift = toNumber(row.starfieldDrift);
  const starfieldWaveProgress = toNumber(row.starfieldWaveProgress);
  const starfieldCastleRatio = toNumber(row.starfieldCastleRatio);
  const starfieldTint =
    typeof row.starfieldTint === "string" && row.starfieldTint.length > 0
      ? row.starfieldTint
      : null;
  return {
    file,
    eventCount: Number(row.eventCount ?? 0),
    netDelta: toNumber(row.netDelta),
    medianGain,
    p90Gain,
    medianSpend,
    p90Spend,
    starfieldDepth,
    starfieldDrift,
    starfieldWaveProgress,
    starfieldCastleRatio,
    starfieldTint
  };
}

function average(values) {
  const filtered = values.filter((value) => typeof value === "number" && Number.isFinite(value));
  if (filtered.length === 0) return null;
  const sum = filtered.reduce((acc, value) => acc + value, 0);
  return Number((sum / filtered.length).toFixed(3));
}

function buildSummary(rows, options, fileCount) {
  const netDelta = rows
    .map((row) => row.netDelta ?? 0)
    .reduce((sum, value) => sum + value, 0);
  const avgMedianGain = average(rows.map((row) => row.medianGain));
  const avgMedianSpend = average(rows.map((row) => row.medianSpend));
  const spendMagnitudes = rows
    .map((row) => (typeof row.p90Spend === "number" ? Math.abs(row.p90Spend) : null))
    .filter((value) => value !== null);
  const maxSpendMagnitude = spendMagnitudes.length
    ? Number(Math.max(...spendMagnitudes).toFixed(3))
    : 0;
  const starfieldDepthAvg = average(rows.map((row) => row.starfieldDepth));
  const starfieldDriftAvg = average(rows.map((row) => row.starfieldDrift));
  const starfieldWaveAvg = average(rows.map((row) => row.starfieldWaveProgress));
  const starfieldCastleAvg = average(rows.map((row) => row.starfieldCastleRatio));
  let latestTint = null;
  for (const row of rows) {
    if (row.starfieldTint) {
      latestTint = row.starfieldTint;
    }
  }
  const warnings = [];
  if (netDelta < options.minNetDelta) {
    warnings.push(
      `Net gold delta ${netDelta} below configured floor (${options.minNetDelta}).`
    );
  }
  if (maxSpendMagnitude > options.maxSpendMagnitude) {
    warnings.push(
      `p90 spend magnitude ${maxSpendMagnitude} exceeds limit (${options.maxSpendMagnitude}).`
    );
  }
  return {
    generatedAt: new Date().toISOString(),
    mode: options.mode,
    summaryPath: options.summaryPath,
    thresholds: {
      minNetDelta: options.minNetDelta,
      maxP90SpendMagnitude: options.maxSpendMagnitude
    },
    totals: {
      files: fileCount,
      summaries: rows.length
    },
    metrics: {
      netDelta,
      avgMedianGain,
      avgMedianSpend,
      maxP90SpendMagnitude: maxSpendMagnitude,
      starfield: {
        depthAvg: starfieldDepthAvg,
        driftAvg: starfieldDriftAvg,
        waveProgressAvg: starfieldWaveAvg,
        castleRatioAvg: starfieldCastleAvg,
        lastTint: latestTint
      }
    },
    summaries: rows,
    warnings,
    percentileAlerts: {
      rows: [],
      failures: 0
    }
  };
}

async function loadOptionalJson(filePath) {
  if (!filePath) return null;
  const resolved = path.resolve(filePath);
  try {
    const content = await fs.readFile(resolved, "utf8");
    return JSON.parse(content);
  } catch (error) {
    console.warn(`goldSummaryReport: unable to read ${resolved} (${error?.message ?? error})`);
    return null;
  }
}

function getBaselineForFile(file, baselineData) {
  if (!baselineData || typeof baselineData !== "object") return null;
  return baselineData[file] ?? baselineData[file.replace(/\\/g, "/")] ?? baselineData.default ?? null;
}

function getThresholdForMetric(file, metric, thresholds) {
  if (!thresholds || typeof thresholds !== "object") return null;
  const normalizedFile = file.replace(/\\/g, "/");
  return (
    thresholds[normalizedFile]?.[metric] ??
    thresholds[file]?.[metric] ??
    thresholds.defaults?.[metric] ??
    null
  );
}

function evaluatePercentileDrift(rows, baselineData, thresholds) {
  if (!baselineData) {
    return { rows: [], failures: 0, warnings: [] };
  }
  const metrics = ["medianGain", "p90Gain", "medianSpend", "p90Spend"];
  const checks = [];
  const warnings = [];
  for (const row of rows) {
    const baseline = getBaselineForFile(row.file, baselineData);
    if (!baseline) continue;
    for (const metric of metrics) {
      const actual = row[metric];
      const baselineValue = baseline[metric];
      if (typeof actual !== "number" || typeof baselineValue !== "number") {
        continue;
      }
      const threshold = getThresholdForMetric(row.file, metric, thresholds);
      if (!threshold) {
        continue;
      }
      const diff = actual - baselineValue;
      const absDiff = Math.abs(diff);
      const absLimit =
        typeof threshold.abs === "number" && Number.isFinite(threshold.abs)
          ? threshold.abs
          : Infinity;
      const pctDiff =
        baselineValue !== 0 ? Math.abs(diff / baselineValue) : Number.isFinite(absDiff) ? Infinity : null;
      const pctLimit =
        typeof threshold.pct === "number" && Number.isFinite(threshold.pct)
          ? threshold.pct
          : null;
      const passes =
        absDiff <= absLimit ||
        (pctLimit === null || pctDiff === null ? true : pctDiff <= pctLimit);
      if (!passes) {
        warnings.push(
          `${row.file} ${metric} drifted (actual ${actual}, baseline ${baselineValue}, diff ${diff.toFixed(
            3
          )})`
        );
      }
      checks.push({
        file: row.file,
        metric,
        actual,
        baseline: baselineValue,
        diff: Number(diff.toFixed(3)),
        absDiff: Number(absDiff.toFixed(3)),
        pctDiff: pctDiff === null ? null : Number(pctDiff.toFixed(3)),
        absLimit: Number.isFinite(absLimit) ? absLimit : null,
        pctLimit: pctLimit,
        status: passes ? "pass" : "fail"
      });
    }
  }
  const failures = checks.filter((check) => check.status === "fail").length;
  return { rows: checks, failures, warnings };
}

function buildMarkdown(summary) {
  const lines = [];
  lines.push("## Gold Summary Report");
  lines.push(`Generated: ${summary.generatedAt ?? "n/a"}`);
  lines.push(
    `Files: **${summary.totals.files}**, Summaries: **${summary.totals.summaries}**, Net �: **${summary.metrics.netDelta}**`
  );
  lines.push(
    `Avg median gain: ${summary.metrics.avgMedianGain ?? "n/a"} � Avg median spend: ${summary.metrics.avgMedianSpend ?? "n/a"}`
  );
  lines.push(
    `Max |p90 spend|: ${summary.metrics.maxP90SpendMagnitude} (limit ${summary.thresholds.maxP90SpendMagnitude})`
  );
  if (summary.metrics?.starfield) {
    const starfield = summary.metrics.starfield;
    lines.push(
      `Starfield avg depth: ${formatOptionalNumber(starfield.depthAvg)}, drift: ${formatOptionalNumber(
        starfield.driftAvg
      )}, wave: ${formatOptionalNumber(starfield.waveProgressAvg, "%")}, castle: ${formatOptionalNumber(
        starfield.castleRatioAvg,
        "%"
      )}, last tint: ${starfield.lastTint ?? "n/a"}`
    );
  }
  lines.push("");
  if (summary.summaries.length > 0) {
    const headers = [
      "File",
      "Net �",
      "Median Gain",
      "Median Spend",
      "P90 Gain",
      "P90 Spend",
      "Starfield Depth",
      "Starfield Drift",
      "Starfield Wave %",
      "Starfield Castle %",
      "Starfield Tint",
      "Events"
    ];
    lines.push(`| ${headers.join(" | ")} |`);
    lines.push(`| ${headers.map(() => "---").join(" | ")} |`);
    for (const row of summary.summaries) {
      const wave =
        typeof row.starfieldWaveProgress === "number" ? `${row.starfieldWaveProgress}%` : "";
      const castle =
        typeof row.starfieldCastleRatio === "number" ? `${row.starfieldCastleRatio}%` : "";
      const values = [
        row.file ?? "-",
        row.netDelta ?? "",
        row.medianGain ?? "",
        row.medianSpend ?? "",
        row.p90Gain ?? "",
        row.p90Spend ?? "",
        row.starfieldDepth ?? "",
        row.starfieldDrift ?? "",
        wave,
        castle,
        row.starfieldTint ?? "",
        row.eventCount ?? ""
      ];
      lines.push(`| ${values.map((value) => (value ?? value === 0 ? value : "")).join(" | ")} |`);
    }
    lines.push("");
  } else {
    lines.push("_No gold summary rows detected._");
    lines.push("");
  }
  if (summary.warnings.length > 0) {
    lines.push("**Warnings**");
    for (const warning of summary.warnings) {
      lines.push(`- ${warning}`);
    }
    lines.push("");
  }
  if (summary.percentileAlerts?.rows?.length) {
    lines.push("### Percentile Drift");
    lines.push("| File | Metric | Actual | Baseline | � | |�| | Status |");
    lines.push("| --- | --- | --- | --- | --- | --- | --- |");
    for (const alert of summary.percentileAlerts.rows) {
      lines.push(
        `| ${alert.file} | ${alert.metric} | ${alert.actual ?? ""} | ${alert.baseline ?? ""} | ${
          alert.diff ?? ""
        } | ${alert.absDiff ?? ""} | ${alert.status === "pass" ? "? Pass" : "? Fail"} |`
      );
    }
    lines.push("");
  }
  lines.push(`Summary JSON: \`${summary.summaryPath}\``);
  return lines.join("\n");
}
async function appendStepSummary(markdown) {
  const target = process.env.GITHUB_STEP_SUMMARY;
  if (target) {
    await fs.appendFile(target, `${markdown}\n`);
  } else {
    console.log(markdown);
  }
}

async function writeSummary(summaryPath, payload) {
  const absolute = path.resolve(summaryPath);
  await fs.mkdir(path.dirname(absolute), { recursive: true });
  await fs.writeFile(absolute, JSON.stringify(payload, null, 2));
}

function buildPercentileAlertOutput(summary, options) {
  const alerts = summary.percentileAlerts ?? { rows: [], failures: 0, warnings: [] };
  const rows = Array.isArray(alerts.rows) ? alerts.rows : [];
  return {
    generatedAt: summary.generatedAt,
    summaryPath: options.summaryPath,
    baselinePath: options.baselinePath,
    thresholdPath: options.thresholdPath,
    totals: {
      rows: rows.length,
      failures: alerts.failures ?? 0
    },
    rows,
    warnings: Array.isArray(alerts.warnings) ? alerts.warnings : []
  };
}

async function runReport(options) {
  const files = await collectSummaryFiles(options.targets);
  if (files.length === 0) {
    throw new Error("No gold summary JSON files found. Provide at least one file or directory.");
  }
  const rows = [];
  for (const file of files) {
    try {
      const entries = await readSummaryRows(file);
      rows.push(...entries.map(normalizeRow));
    } catch (error) {
      console.warn(error instanceof Error ? error.message : String(error));
    }
  }
  if (rows.length === 0) {
    throw new Error("No gold summary rows found in provided files.");
  }
  const baselineData = await loadOptionalJson(options.baselinePath);
  const thresholdData = await loadOptionalJson(options.thresholdPath);
  const summary = buildSummary(rows, options, files.length);
  const percentileAlerts = evaluatePercentileDrift(rows, baselineData, thresholdData);
  summary.percentileAlerts = percentileAlerts;
  summary.warnings.push(...percentileAlerts.warnings);
  await writeSummary(options.summaryPath, summary);
  if (options.alertsPath) {
    const alertsOutput = buildPercentileAlertOutput(summary, options);
    await writeSummary(options.alertsPath, alertsOutput);
  }
  await appendStepSummary(buildMarkdown(summary));
  if (summary.warnings.length > 0 && options.mode === "fail") {
    throw new Error(
      `${summary.warnings.length} gold summary warning(s) detected. See ${options.summaryPath}.`
    );
  }
  return summary;
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
    await runReport(options);
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(options.mode === "warn" ? 0 : 1);
  }
}

if (
  import.meta.url === `file://${process.argv[1]}` ||
  process.argv[1]?.endsWith("goldSummaryReport.mjs")
) {
  await main();
}

