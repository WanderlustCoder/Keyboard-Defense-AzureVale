#!/usr/bin/env node

import { promises as fs } from "node:fs";
import path from "node:path";
import process from "node:process";

import { buildTimelineEntries } from "../passiveTimeline.mjs";

const DEFAULT_TARGETS = ["artifacts/smoke", "artifacts/castle-breach.ci.json"];
const DEFAULT_SUMMARY_PATH = "artifacts/summaries/passive-gold.ci.json";
const DEFAULT_MODE = (process.env.PASSIVE_GUARD_MODE ?? "fail").toLowerCase();
const DEFAULT_MAX_GAP_SECONDS = Number(process.env.PASSIVE_MAX_GAP_SECONDS ?? 600);
const DEFAULT_MAX_GOLD_LAG_SECONDS = Number(process.env.PASSIVE_MAX_GOLD_LAG_SECONDS ?? 10);
const DEFAULT_GOLD_WINDOW = Number(process.env.PASSIVE_GOLD_WINDOW ?? 5);
const VALID_MODES = new Set(["fail", "warn"]);

function printHelp() {
  console.log(`Passive Unlock & Gold Dashboard

Usage:
  node scripts/ci/passiveGoldDashboard.mjs [options] [target ...]

Options:
  --summary <path>          Output JSON summary path (default: ${DEFAULT_SUMMARY_PATH})
  --mode <fail|warn>        Failure behaviour when thresholds trip (default: fail)
  --max-gap <seconds>       Maximum allowed gap between passive unlocks (default: ${DEFAULT_MAX_GAP_SECONDS})
  --max-gold-lag <seconds>  Maximum allowed lag between unlock and nearest gold event (default: ${DEFAULT_MAX_GOLD_LAG_SECONDS})
  --gold-window <seconds>   Gold merge window passed to passiveTimeline (default: ${DEFAULT_GOLD_WINDOW})
  --help                    Show this help message

Arguments:
  target                    Snapshot file or directory containing JSON analytics artifacts.
                            Defaults to ${DEFAULT_TARGETS.join(", ")} when omitted.
`);
}

function parseNumber(value, fallback) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function parseArgs(argv) {
  const options = {
    summaryPath: process.env.PASSIVE_GUARD_SUMMARY ?? DEFAULT_SUMMARY_PATH,
    mode: DEFAULT_MODE,
    maxGapSeconds: DEFAULT_MAX_GAP_SECONDS,
    maxGoldLagSeconds: DEFAULT_MAX_GOLD_LAG_SECONDS,
    goldWindow: DEFAULT_GOLD_WINDOW,
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
      case "--max-gap":
        options.maxGapSeconds = parseNumber(argv[++i], options.maxGapSeconds);
        break;
      case "--max-gold-lag":
        options.maxGoldLagSeconds = parseNumber(argv[++i], options.maxGoldLagSeconds);
        break;
      case "--gold-window":
        options.goldWindow = parseNumber(argv[++i], options.goldWindow);
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

async function collectSnapshotFiles(targets) {
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

async function readSnapshot(file) {
  try {
    const content = await fs.readFile(file, "utf8");
    return JSON.parse(content);
  } catch (error) {
    console.warn(`passiveGoldDashboard: skipped ${file} (${error?.message ?? error})`);
    return null;
  }
}

function extractRecentGoldEvents(snapshot) {
  if (Array.isArray(snapshot?.recentGoldEvents) && snapshot.recentGoldEvents.length > 0) {
    return snapshot.recentGoldEvents;
  }
  if (
    Array.isArray(snapshot?.state?.recentGoldEvents) &&
    snapshot.state.recentGoldEvents.length > 0
  ) {
    return snapshot.state.recentGoldEvents;
  }
  if (
    Array.isArray(snapshot?.analytics?.goldEvents) &&
    snapshot.analytics.goldEvents.length > 0
  ) {
    return snapshot.analytics.goldEvents.slice(-3);
  }
  return [];
}

function toNumber(value) {
  const num = Number(value);
  return Number.isFinite(num) ? num : null;
}

function summarizeUnlocks(entries) {
  const numericEntries = entries
    .map((entry) => ({
      ...entry,
      time: toNumber(entry.time),
      goldLag: toNumber(entry.goldLag)
    }))
    .filter((entry) => entry.time !== null);
  const sorted = numericEntries.sort((a, b) => a.time - b.time);
  const gaps = [];
  for (let i = 1; i < sorted.length; i += 1) {
    const gap = sorted[i].time - sorted[i - 1].time;
    if (Number.isFinite(gap)) {
      gaps.push(gap);
    }
  }
  const maxGap = gaps.length ? Math.max(...gaps) : 0;
  const avgGap =
    gaps.length > 0 ? Number((gaps.reduce((sum, gap) => sum + gap, 0) / gaps.length).toFixed(3)) : 0;
  const maxGoldLag = numericEntries
    .map((entry) => entry.goldLag ?? null)
    .filter((lag) => lag !== null)
    .reduce((max, lag) => Math.max(max, lag), 0);
  const latest = sorted.slice(-3).reverse();
  return {
    latest,
    maxGapSeconds: maxGap,
    avgGapSeconds: avgGap,
    maxGoldLagSeconds: Number(maxGoldLag?.toFixed?.(3) ?? maxGoldLag ?? 0)
  };
}

function summarizeGoldEvents(events, limit = 3) {
  const deduped = events
    .map((event) => ({
      delta: event.delta ?? null,
      gold: event.gold ?? null,
      timestamp: toNumber(event.timestamp),
      source: event.source
    }))
    .filter((event) => event.timestamp !== null);
  deduped.sort((a, b) => b.timestamp - a.timestamp);
  return deduped.slice(0, limit);
}

function buildMarkdown(summary) {
  const lines = [];
  lines.push("## Passive Unlocks & Gold Events");
  lines.push(
    `Files processed: **${summary.totals.files}**, Unlocks: **${summary.totals.unlocks}**, Gold events: **${summary.totals.goldEvents}**`
  );
  lines.push(
    `Max gap: ${summary.metrics.maxGapSeconds.toFixed(3)}s (limit ${summary.thresholds.maxGapSeconds}s) · Max gold lag: ${summary.metrics.maxGoldLagSeconds.toFixed(3)}s (limit ${summary.thresholds.maxGoldLagSeconds}s)`
  );
  lines.push("");
  if (summary.unlocks.latest.length > 0) {
    lines.push("| Passive | Level | Δ | Time (s) | Gold Δ | Gold Lag (s) | Source |");
    lines.push("| --- | --- | --- | --- | --- | --- | --- |");
    for (const entry of summary.unlocks.latest) {
      lines.push(
        `| ${entry.id} | ${entry.level} | ${entry.delta ?? ""} | ${entry.time?.toFixed?.(3) ?? ""} | ${
          entry.goldDelta ?? ""
        } | ${entry.goldLag ?? ""} | ${entry.file} |`
      );
    }
    lines.push("");
  } else {
    lines.push("_No passive unlocks detected._");
    lines.push("");
  }
  if (summary.gold.latest.length > 0) {
    lines.push("| Gold Δ | Total | Timestamp | Source |");
    lines.push("| --- | --- | --- | --- |");
    for (const event of summary.gold.latest) {
      lines.push(
        `| ${event.delta ?? ""} | ${event.gold ?? ""} | ${event.timestamp?.toFixed?.(3) ?? ""} | ${
          event.source
        } |`
      );
    }
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

async function runDashboard(options) {
  const files = await collectSnapshotFiles(options.targets);
  if (files.length === 0) {
    throw new Error("No snapshot JSON files found. Provide at least one file or directory.");
  }

  const unlockEntries = [];
  const goldEvents = [];
  for (const file of files) {
    const snapshot = await readSnapshot(file);
    if (!snapshot) continue;
    const entries = buildTimelineEntries(snapshot, file, {
      mergeGold: true,
      goldWindow: options.goldWindow
    });
    if (entries.length > 0) {
      unlockEntries.push(...entries);
    }
    const recentEvents = extractRecentGoldEvents(snapshot);
    for (const event of recentEvents) {
      goldEvents.push({
        ...event,
        source: path.relative(process.cwd(), file) || path.basename(file)
      });
    }
  }

  const warnings = [];
  if (unlockEntries.length === 0) {
    warnings.push("No passive unlocks found in provided snapshots.");
  }

  const unlockSummary = summarizeUnlocks(unlockEntries);
  const goldSummary = summarizeGoldEvents(goldEvents);

  if (unlockSummary.maxGapSeconds > options.maxGapSeconds) {
    warnings.push(
      `Passive unlock gap ${unlockSummary.maxGapSeconds.toFixed(
        3
      )}s exceeds limit of ${options.maxGapSeconds}s.`
    );
  }
  if (unlockSummary.maxGoldLagSeconds > options.maxGoldLagSeconds) {
    warnings.push(
      `Gold/passive lag ${unlockSummary.maxGoldLagSeconds.toFixed(
        3
      )}s exceeds limit of ${options.maxGoldLagSeconds}s.`
    );
  }

  const summary = {
    generatedAt: new Date().toISOString(),
    mode: options.mode,
    summaryPath: options.summaryPath,
    thresholds: {
      maxGapSeconds: options.maxGapSeconds,
      maxGoldLagSeconds: options.maxGoldLagSeconds
    },
    totals: {
      files: files.length,
      unlocks: unlockEntries.length,
      goldEvents: goldEvents.length
    },
    unlocks: {
      latest: unlockSummary.latest.map((entry) => ({
        id: entry.id,
        level: entry.level,
        delta: entry.delta,
        time: entry.time,
        goldDelta: entry.goldDelta ?? null,
        goldLag: entry.goldLag,
        file: path.relative(process.cwd(), entry.file) || path.basename(entry.file)
      }))
    },
    metrics: {
      maxGapSeconds: unlockSummary.maxGapSeconds,
      avgGapSeconds: unlockSummary.avgGapSeconds,
      maxGoldLagSeconds: unlockSummary.maxGoldLagSeconds
    },
    gold: {
      latest: goldSummary
    },
    warnings
  };

  await writeSummary(options.summaryPath, summary);
  await appendStepSummary(buildMarkdown(summary));
  if (warnings.length > 0 && options.mode === "fail") {
    throw new Error(
      `${warnings.length} passive unlock warning(s) detected. See ${options.summaryPath} for details.`
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
  process.argv[1]?.endsWith("passiveGoldDashboard.mjs")
) {
  await main();
}
