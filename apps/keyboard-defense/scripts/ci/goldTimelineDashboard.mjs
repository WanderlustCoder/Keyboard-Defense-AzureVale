#!/usr/bin/env node

import { promises as fs } from "node:fs";
import path from "node:path";
import process from "node:process";

import { buildGoldTimelineEntries } from "../goldTimeline.mjs";

const DEFAULT_TARGETS = ["artifacts/smoke", "artifacts/e2e"];
const DEFAULT_SUMMARY_PATH = "artifacts/summaries/gold-timeline.ci.json";
const DEFAULT_MODE = (process.env.GOLD_TIMELINE_MODE ?? "fail").toLowerCase();
const DEFAULT_PASSIVE_WINDOW = Number(process.env.GOLD_TIMELINE_PASSIVE_WINDOW ?? 5);
const DEFAULT_MAX_SPEND_STREAK = Number(process.env.GOLD_TIMELINE_MAX_SPEND_STREAK ?? 200);
const DEFAULT_MIN_NET_DELTA = Number(process.env.GOLD_TIMELINE_MIN_NET_DELTA ?? -250);
const VALID_MODES = new Set(["fail", "warn"]);

function printHelp() {
  console.log(`Gold Timeline Dashboard

Usage:
  node scripts/ci/goldTimelineDashboard.mjs [options] [target ...]

Options:
  --summary <path>          Output JSON summary path (default: ${DEFAULT_SUMMARY_PATH})
  --mode <fail|warn>        Failure behavior when thresholds trip (default: fail)
  --passive-window <sec>    Passive merge window passed to goldTimeline helper (default: ${DEFAULT_PASSIVE_WINDOW})
  --max-spend-streak <gold> Maximum allowed cumulative spend streak before warning (default: ${DEFAULT_MAX_SPEND_STREAK})
  --min-net-delta <gold>    Minimum acceptable net gold delta (default: ${DEFAULT_MIN_NET_DELTA})
  --help                    Show this message

Arguments:
  target                    Snapshot/timeline JSON file or directory (defaults: ${DEFAULT_TARGETS.join(", ")}).
`);
}

function parseNumber(value, fallback) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
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

function deriveScenarioId(entry) {
  const mode = entry.mode ?? entry.scenario ?? "";
  if (mode) return slugify(mode);
  const normalized = normalizePath(entry.file ?? "");
  const base = normalized.split("/").pop() ?? normalized;
  const trimmed = base.replace(/\.[^.]+$/, "");
  return slugify(trimmed) || "unknown";
}

function parseArgs(argv) {
  const options = {
    summaryPath: process.env.GOLD_TIMELINE_SUMMARY ?? DEFAULT_SUMMARY_PATH,
    mode: DEFAULT_MODE,
    passiveWindow: DEFAULT_PASSIVE_WINDOW,
    maxSpendStreak: DEFAULT_MAX_SPEND_STREAK,
    minNetDelta: DEFAULT_MIN_NET_DELTA,
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
      case "--passive-window":
        options.passiveWindow = parseNumber(argv[++i], options.passiveWindow);
        break;
      case "--max-spend-streak":
        options.maxSpendStreak = parseNumber(argv[++i], options.maxSpendStreak);
        break;
      case "--min-net-delta":
        options.minNetDelta = parseNumber(argv[++i], options.minNetDelta);
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
    throw new Error(`Invalid mode '${options.mode}'. Use one of: ${Array.from(VALID_MODES).join(", ")}`);
  }
  if (options.targets.length === 0) {
    options.targets = [...DEFAULT_TARGETS];
  }
  return options;
}

async function collectFiles(targets) {
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

async function readJson(file) {
  try {
    const content = await fs.readFile(file, "utf8");
    return JSON.parse(content);
  } catch (error) {
    console.warn(`goldTimelineDashboard: skipped ${file} (${error?.message ?? error})`);
    return null;
  }
}

function isTimelineEntryArray(payload) {
  return (
    Array.isArray(payload) &&
    payload.length > 0 &&
    Object.prototype.hasOwnProperty.call(payload[0], "delta") &&
    Object.prototype.hasOwnProperty.call(payload[0], "timestamp")
  );
}

function normalizeTimelineEntries(data, filePath, passiveWindow) {
  if (!data) return [];
  if (isTimelineEntryArray(data)) {
    return data.map((entry) => ({
      ...entry,
      file: entry.file ?? filePath
    }));
  }
  if (Array.isArray(data.entries)) {
    return data.entries.map((entry) => ({
      ...entry,
      file: entry.file ?? filePath
    }));
  }
  // Assume snapshot; build timeline entries from analytics payload
  return buildGoldTimelineEntries(data, filePath, { mergePassives: true, passiveWindow });
}

function median(values) {
  if (values.length === 0) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  if (sorted.length % 2 === 0) {
    return (sorted[mid - 1] + sorted[mid]) / 2;
  }
  return sorted[mid];
}

function computeMetrics(entries) {
  const sorted = [...entries].sort(
    (a, b) => (Number(a.timestamp) || 0) - (Number(b.timestamp) || 0)
  );
  let cumulative = 0;
  let currentSpend = 0;
  let maxSpendStreak = 0;
  const gains = [];
  const spends = [];
  const deltas = [];
  for (const entry of sorted) {
    const delta = Number(entry.delta) || 0;
    deltas.push(delta);
    if (delta > 0) gains.push(delta);
    if (delta < 0) spends.push(delta);
    cumulative += delta;
    if (delta < 0) {
      currentSpend += Math.abs(delta);
      if (currentSpend > maxSpendStreak) {
        maxSpendStreak = currentSpend;
      }
    } else {
      currentSpend = 0;
    }
  }
  const avgDelta = deltas.length
    ? Number((deltas.reduce((sum, value) => sum + value, 0) / deltas.length).toFixed(3))
    : 0;
  return {
    netDelta: Number(cumulative.toFixed(3)),
    avgDelta,
    medianGain: median(gains),
    medianSpend: median(spends),
    maxSpendStreak: Number(maxSpendStreak.toFixed(3)),
    latestEvents: sorted.slice(-5).reverse()
  };
}

function buildMarkdown(summary) {
  const lines = [];
  lines.push("## Gold Timeline Dashboard");
  lines.push(
    `Files: **${summary.totals.files}**, Events: **${summary.totals.events}**, Net Δ: **${summary.metrics.netDelta}**`
  );
  lines.push(
    `Median gain: ${summary.metrics.medianGain} · Median spend: ${summary.metrics.medianSpend} · Avg Δ: ${summary.metrics.avgDelta}`
  );
  lines.push(
    `Max spend streak: ${summary.metrics.maxSpendStreak} (limit ${summary.thresholds.maxSpendStreak}) · Min net Δ limit: ${summary.thresholds.minNetDelta}`
  );
  lines.push(`Scenarios: ${summary.scenarios?.length ?? 0}`);
  lines.push("");
  if (summary.latestEvents.length > 0) {
    lines.push("| Gold Δ | Total | Timestamp | Mode | Source |");
    lines.push("| --- | --- | --- | --- | --- |");
    for (const event of summary.latestEvents) {
      lines.push(
        `| ${event.delta ?? ""} | ${event.gold ?? ""} | ${event.timestamp ?? ""} | ${
          event.mode ?? ""
        } | ${event.file} |`
      );
    }
    lines.push("");
  } else {
    lines.push("_No gold events detected._");
    lines.push("");
  }
  if (summary.warnings.length > 0) {
    lines.push("**Warnings**");
    for (const warning of summary.warnings) {
      lines.push(`- ${warning}`);
    }
    lines.push("");
  }
  lines.push(`Summary JSON: \`${summary.summaryPath}\``);
  return lines.join("\n");
}

async function appendStepSummary(markdown) {
  const summaryFile = process.env.GITHUB_STEP_SUMMARY;
  if (summaryFile) {
    await fs.appendFile(summaryFile, `${markdown}\n`);
  } else {
    console.log(markdown);
  }
}

async function writeSummary(summaryPath, payload) {
  const absolute = path.resolve(summaryPath);
  await fs.mkdir(path.dirname(absolute), { recursive: true });
  await fs.writeFile(absolute, JSON.stringify(payload, null, 2));
}

export async function runDashboard(options) {
  const files = await collectFiles(options.targets);
  if (files.length === 0) {
    throw new Error("No timeline or snapshot JSON files found. Provide at least one target.");
  }

  const entries = [];
  for (const file of files) {
    const payload = await readJson(file);
    const rows = normalizeTimelineEntries(payload, file, options.passiveWindow);
    if (rows.length > 0) {
      for (const row of rows) {
        entries.push({
          ...row,
          file: path.relative(process.cwd(), row.file ?? file) || path.basename(row.file ?? file)
        });
      }
    }
  }

  const warnings = [];
  if (entries.length === 0) {
    warnings.push("No gold events found in provided inputs.");
  }

  const scenarioMap = new Map();
  for (const entry of entries) {
    const scenarioId = deriveScenarioId(entry);
    if (!scenarioMap.has(scenarioId)) {
      scenarioMap.set(scenarioId, []);
    }
    scenarioMap.get(scenarioId).push(entry);
  }

  const metrics = computeMetrics(entries);
  if (metrics.maxSpendStreak > options.maxSpendStreak) {
    warnings.push(
      `Max spend streak ${metrics.maxSpendStreak} exceeds limit of ${options.maxSpendStreak}.`
    );
  }
  if (metrics.netDelta < options.minNetDelta) {
    warnings.push(
      `Net delta ${metrics.netDelta} below expected floor of ${options.minNetDelta}.`
    );
  }

  const scenarios = Array.from(scenarioMap.entries()).map(([id, scenarioEntries]) => {
    const scenarioMetrics = computeMetrics(scenarioEntries);
    return {
      id,
      totals: {
        events: scenarioEntries.length
      },
      metrics: scenarioMetrics,
      latestEvents: scenarioMetrics.latestEvents.map((event) => ({
        delta: event.delta ?? null,
        gold: event.gold ?? null,
        timestamp: event.timestamp ?? null,
        mode: event.mode ?? "",
        file: event.file ?? ""
      }))
    };
  });
  scenarios.sort((a, b) => a.id.localeCompare(b.id));

  const summary = {
    generatedAt: new Date().toISOString(),
    mode: options.mode,
    summaryPath: options.summaryPath,
    thresholds: {
      maxSpendStreak: options.maxSpendStreak,
      minNetDelta: options.minNetDelta
    },
    totals: {
      files: files.length,
      events: entries.length
    },
    metrics,
    latestEvents: metrics.latestEvents.map((event) => ({
      delta: event.delta ?? null,
      gold: event.gold ?? null,
      timestamp: event.timestamp ?? null,
      mode: event.mode ?? "",
      file: event.file
    })),
    scenarios,
    warnings
  };

  await writeSummary(options.summaryPath, summary);
  await appendStepSummary(buildMarkdown(summary));
  if (warnings.length > 0 && options.mode === "fail") {
    throw new Error(
      `${warnings.length} warning(s) triggered; see ${options.summaryPath} for details.`
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
    await runDashboard(options);
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(options.mode === "warn" ? 0 : 1);
  }
}

if (
  import.meta.url === `file://${process.argv[1]}` ||
  process.argv[1]?.endsWith("goldTimelineDashboard.mjs")
) {
  await main();
}
