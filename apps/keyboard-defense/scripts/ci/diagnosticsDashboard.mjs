#!/usr/bin/env node

import { promises as fs } from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

const DEFAULT_TARGETS = ["artifacts/smoke", "artifacts/e2e"];
const DEFAULT_JSON_PATH = "artifacts/summaries/diagnostics-dashboard.ci.json";
const DEFAULT_MARKDOWN_PATH = "artifacts/summaries/diagnostics-dashboard.ci.md";
const DEFAULT_MODE = (process.env.DIAGNOSTICS_DASHBOARD_MODE ?? "fail").toLowerCase();
const DEFAULT_WARN_MAX_NEGATIVE_DELTA = Number(
  process.env.DIAGNOSTICS_WARN_MAX_NEGATIVE_DELTA ?? -250
);
const DEFAULT_FAIL_PASSIVE_LAG = Number(process.env.DIAGNOSTICS_FAIL_PASSIVE_LAG ?? 300);
const DEFAULT_RECENT_EVENT_COUNT = Number(process.env.DIAGNOSTICS_RECENT_EVENTS ?? 5);
const VALID_MODES = new Set(["fail", "warn"]);

function printHelp() {
  console.log(`Diagnostics Dashboard

Usage:
  node scripts/ci/diagnosticsDashboard.mjs [options] [target ...]

Options:
  --summary <path>          Output JSON summary path (default: ${DEFAULT_JSON_PATH})
  --markdown <path>         Output Markdown path (default: ${DEFAULT_MARKDOWN_PATH})
  --mode <fail|warn>        Failure behavior when thresholds trip (default: ${DEFAULT_MODE})
  --warn-max-negative-delta <gold>
                            Trigger a warning when a single delta drops below this value (default: ${DEFAULT_WARN_MAX_NEGATIVE_DELTA})
  --fail-passive-lag <sec>  Trigger the configured mode when time since the last passive exceeds this many seconds (default: ${DEFAULT_FAIL_PASSIVE_LAG})
  --recent-events <count>   Number of gold events to list in the summary (default: ${DEFAULT_RECENT_EVENT_COUNT})
  --help                    Show this message

Targets default to: ${DEFAULT_TARGETS.join(", ")}.
`);
}

function parseArgs(argv) {
  const options = {
    summaryPath: process.env.DIAGNOSTICS_DASHBOARD_SUMMARY ?? DEFAULT_JSON_PATH,
    markdownPath: process.env.DIAGNOSTICS_DASHBOARD_MARKDOWN ?? DEFAULT_MARKDOWN_PATH,
    mode: DEFAULT_MODE,
    warnMaxNegativeDelta: DEFAULT_WARN_MAX_NEGATIVE_DELTA,
    failPassiveLag: DEFAULT_FAIL_PASSIVE_LAG,
    recentEventCount: DEFAULT_RECENT_EVENT_COUNT,
    targets: [],
    help: false
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--summary":
        options.summaryPath = argv[++i] ?? options.summaryPath;
        break;
      case "--markdown":
        options.markdownPath = argv[++i] ?? options.markdownPath;
        break;
      case "--mode":
        options.mode = (argv[++i] ?? options.mode).toLowerCase();
        break;
      case "--warn-max-negative-delta":
        options.warnMaxNegativeDelta = Number(argv[++i] ?? options.warnMaxNegativeDelta);
        break;
      case "--fail-passive-lag":
        options.failPassiveLag = Number(argv[++i] ?? options.failPassiveLag);
        break;
      case "--recent-events":
        options.recentEventCount = Math.max(1, Number(argv[++i] ?? options.recentEventCount));
        break;
      case "--help":
        options.help = true;
        break;
      default:
        if (token.startsWith("-")) {
          throw new Error(`Unknown option '${token}'. Use --help for available flags.`);
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
    console.warn(`diagnosticsDashboard: skipped ${file} (${error?.message ?? error})`);
    return null;
  }
}

function inferScenario(filePath, snapshot) {
  if (snapshot?.analytics?.mode === "practice") {
    return "tutorial-smoke";
  }
  const lower = filePath.toLowerCase();
  if (lower.includes("smoke")) return "tutorial-smoke";
  if (lower.includes("e2e")) return "e2e";
  const base = path.basename(filePath, path.extname(filePath));
  return base || "snapshot";
}

function formatPassiveEntry(entry) {
  if (!entry || typeof entry !== "object") {
    return "";
  }
  const labelMap = { regen: "Regen", armor: "Armor", gold: "Gold" };
  const label = labelMap[entry.id] ?? (entry.id ?? "Passive");
  const level = Number.isFinite(entry.level) ? `L${entry.level}` : "";
  const delta =
    typeof entry.delta === "number" && entry.delta !== 0 ? ` Δ${entry.delta.toFixed(2)}` : "";
  const time =
    typeof entry.time === "number" && Number.isFinite(entry.time)
      ? `${entry.time.toFixed(2)}s`
      : "N/A";
  return `${label}${level ? ` ${level}` : ""} (${time}${delta ? `, ${delta}` : ""})`;
}

function summarizeGold(events, recentEventCount) {
  if (!Array.isArray(events)) {
    return {
      totalEvents: 0,
      lastDelta: null,
      lastTimestamp: null,
      largestGain: null,
      largestLoss: null,
      netDelta: null,
      latestEvents: []
    };
  }
  const sorted = [...events]
    .filter((event) => typeof event === "object" && event !== null)
    .sort((a, b) => (Number(a.timestamp) || 0) - (Number(b.timestamp) || 0));
  let netDelta = 0;
  let largestGain = Number.NEGATIVE_INFINITY;
  let largestLoss = Number.POSITIVE_INFINITY;
  for (const event of sorted) {
    const delta = Number(event.delta) || 0;
    netDelta += delta;
    if (delta > largestGain) largestGain = delta;
    if (delta < largestLoss) largestLoss = delta;
  }
  const lastEvent = sorted.at(-1) ?? null;
  const latestEvents = sorted
    .slice(-recentEventCount)
    .reverse()
    .map((event) => ({
      delta: Number(event.delta) || 0,
      gold: Number(event.gold) || 0,
      timestamp: Number(event.timestamp) || 0
    }));
  return {
    totalEvents: sorted.length,
    lastDelta: lastEvent ? Number(lastEvent.delta) || 0 : null,
    lastTimestamp: lastEvent ? Number(lastEvent.timestamp) || null : null,
    largestGain: Number.isFinite(largestGain) ? largestGain : null,
    largestLoss: Number.isFinite(largestLoss) ? largestLoss : null,
    netDelta: Number.isFinite(netDelta) ? Number(netDelta.toFixed(3)) : null,
    latestEvents
  };
}

function summarizePassives(unlocks) {
  if (!Array.isArray(unlocks)) {
    return { totalUnlocks: 0, lastUnlock: null, timeline: [] };
  }
  const sorted = [...unlocks]
    .filter((entry) => entry && typeof entry === "object")
    .sort((a, b) => (Number(a.time) || 0) - (Number(b.time) || 0));
  const timeline = sorted.slice(-5).reverse().map((entry) => ({
    id: entry.id ?? null,
    level: Number(entry.level) || null,
    delta: typeof entry.delta === "number" ? entry.delta : null,
    total: typeof entry.total === "number" ? entry.total : null,
    time: typeof entry.time === "number" ? entry.time : null,
    label: formatPassiveEntry(entry)
  }));
  const lastUnlock = sorted.at(-1) ?? null;
  return {
    totalUnlocks: sorted.length,
    lastUnlock,
    timeline
  };
}

function buildAlerts(entry, options) {
  const alerts = [];
  const { gold, passives } = entry;
  if (
    typeof gold?.largestLoss === "number" &&
    gold.largestLoss < options.warnMaxNegativeDelta
  ) {
    alerts.push({
      level: "warn",
      message: `Gold delta dropped to ${gold.largestLoss}g (threshold ${options.warnMaxNegativeDelta}g).`
    });
  }
  if (
    options.failPassiveLag > 0 &&
    passives?.lastUnlock &&
    typeof passives.lastUnlock.time === "number" &&
    typeof entry.snapshotTime === "number"
  ) {
    const lag = entry.snapshotTime - passives.lastUnlock.time;
    if (lag > options.failPassiveLag) {
      alerts.push({
        level: options.mode === "fail" ? "fail" : "warn",
        message: `Last passive unlocked ${lag.toFixed(1)}s ago (threshold ${options.failPassiveLag}s).`
      });
    }
  }
  return alerts;
}

function statusFromAlerts(alerts) {
  if (alerts.some((alert) => alert.level === "fail")) {
    return "fail";
  }
  if (alerts.some((alert) => alert.level === "warn")) {
    return "warn";
  }
  return "ok";
}

function summarizeSnapshot(file, snapshot, options) {
  const scenario = inferScenario(file, snapshot);
  const gold = summarizeGold(snapshot?.analytics?.goldEvents, options.recentEventCount);
  const passives = summarizePassives(snapshot?.analytics?.castlePassiveUnlocks);
  const entry = {
    file,
    scenario,
    mode: snapshot?.analytics?.mode ?? snapshot?.mode ?? "",
    gold,
    passives,
    snapshotTime: typeof snapshot?.time === "number" ? snapshot.time : null
  };
  entry.alerts = buildAlerts(entry, options);
  entry.status = statusFromAlerts(entry.alerts);
  return entry;
}

function buildMarkdown(summary) {
  const lines = [];
  lines.push("## Diagnostics Dashboard");
  lines.push("");
  if (!summary.entries.length) {
    lines.push("_No diagnostics snapshots were processed._");
    return lines.join("\n");
  }

  for (const entry of summary.entries) {
    lines.push(`### ${entry.scenario}`);
    lines.push(`Source: \`${entry.file}\``);
    lines.push("");
    lines.push("**Gold Delta**");
    if (entry.gold.latestEvents.length === 0) {
      lines.push("- No gold events recorded.");
    } else {
      lines.push("| Δg | Gold | Time (s) |");
      lines.push("| --- | --- | --- |");
      for (const event of entry.gold.latestEvents) {
        lines.push(
          `| ${event.delta >= 0 ? `+${event.delta}` : event.delta} | ${event.gold} | ${event.timestamp?.toFixed?.(
            2
          ) ?? event.timestamp} |`
        );
      }
    }
    const largestLoss =
      typeof entry.gold.largestLoss === "number" ? `${entry.gold.largestLoss}g` : "n/a";
    lines.push(
      `Net Δ: ${entry.gold.netDelta ?? "n/a"}g • Largest loss: ${largestLoss} • Events tracked: ${entry.gold.totalEvents}`
    );
    lines.push("");
    lines.push("**Passive Unlock Timeline**");
    if (entry.passives.timeline.length === 0) {
      lines.push("- No passive unlocks recorded.");
    } else {
      lines.push("| Passive | Details |");
      lines.push("| --- | --- |");
      for (const passive of entry.passives.timeline) {
        lines.push(`| ${passive.id ?? "passive"} | ${passive.label} |`);
      }
    }
    lines.push(`Total unlocks: ${entry.passives.totalUnlocks}`);
    lines.push("");
    if (entry.alerts.length) {
      lines.push("**Alerts**");
      for (const alert of entry.alerts) {
        const emoji = alert.level === "fail" ? "❌" : "⚠️";
        lines.push(`- ${emoji} ${alert.message}`);
      }
      lines.push("");
    }
  }
  return lines.join("\n");
}

async function writeOutput(jsonPath, markdownPath, summary, markdown) {
  await fs.mkdir(path.dirname(path.resolve(jsonPath)), { recursive: true });
  await fs.writeFile(jsonPath, JSON.stringify(summary, null, 2), "utf8");
  await fs.mkdir(path.dirname(path.resolve(markdownPath)), { recursive: true });
  await fs.writeFile(markdownPath, markdown, "utf8");
}

async function main(argv) {
  const options = parseArgs(argv);
  if (options.help) {
    printHelp();
    return 0;
  }

  const files = await collectFiles(options.targets);
  if (files.length === 0) {
    console.warn("diagnosticsDashboard: no analytics snapshots found.");
  }

  const entries = [];
  for (const file of files) {
    const snapshot = await readJson(file);
    if (!snapshot) continue;
    entries.push(summarizeSnapshot(file, snapshot, options));
  }

  const status =
    entries.some((entry) => entry.status === "fail") && options.mode === "fail"
      ? "fail"
      : entries.some((entry) => entry.status !== "ok")
        ? "warn"
        : "ok";

  const summary = {
    generatedAt: new Date().toISOString(),
    mode: options.mode,
    config: {
      warnMaxNegativeDelta: options.warnMaxNegativeDelta,
      failPassiveLag: options.failPassiveLag,
      recentEventCount: options.recentEventCount
    },
    status,
    entries
  };
  const markdown = buildMarkdown(summary);
  await writeOutput(options.summaryPath, options.markdownPath, summary, markdown);

  if (status === "fail" && options.mode === "fail") {
    console.error("diagnosticsDashboard: fail-level alerts detected.");
    return 1;
  }
  if (status === "warn" && options.mode === "fail") {
    console.warn("diagnosticsDashboard: warn-level alerts detected.");
  }
  return 0;
}

const isCliInvocation =
  typeof process.argv[1] === "string" &&
  fileURLToPath(import.meta.url) === path.resolve(process.argv[1]);

if (isCliInvocation) {
  main(process.argv.slice(2))
    .then((code) => {
      if (typeof code === "number") {
        process.exit(code);
      }
    })
    .catch((error) => {
      console.error(error instanceof Error ? error.stack ?? error.message : error);
      process.exit(1);
    });
}

export { collectFiles, summarizeSnapshot, buildMarkdown };
