#!/usr/bin/env node

import { promises as fs } from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

const DEFAULT_TARGETS = ["artifacts/smoke", "artifacts/e2e"];
const DEFAULT_JSON_PATH = "artifacts/summaries/gold-delta-aggregates.ci.json";
const DEFAULT_MD_PATH = "artifacts/summaries/gold-delta-aggregates.ci.md";
const DEFAULT_WARN_MAX_LOSS = Number(process.env.GOLD_DELTA_WARN_MAX_LOSS ?? -200);
const DEFAULT_FAIL_MIN_NET = Number(process.env.GOLD_DELTA_FAIL_MIN_NET ?? -300);
const DEFAULT_MODE = (process.env.GOLD_DELTA_MODE ?? "fail").toLowerCase();
const VALID_MODES = new Set(["fail", "warn"]);

function printHelp() {
  console.log(`Gold Delta Aggregator

Usage:
  node scripts/analytics/goldDeltaAggregator.mjs [options] [target ...]

Options:
  --output <path>        Output JSON path (default: ${DEFAULT_JSON_PATH})
  --markdown <path>      Output Markdown path (default: ${DEFAULT_MD_PATH})
  --mode <fail|warn>     Failure behaviour when thresholds trip (default: ${DEFAULT_MODE})
  --warn-max-loss <g>    Warn when any single delta drops below this value (default: ${DEFAULT_WARN_MAX_LOSS})
  --fail-min-net <g>     Fail/warn when net delta falls below this value (default: ${DEFAULT_FAIL_MIN_NET})
  --help                 Show this message

Targets default to: ${DEFAULT_TARGETS.join(", ")}.
`);
}

function parseArgs(argv) {
  const options = {
    output: process.env.GOLD_DELTA_OUTPUT ?? DEFAULT_JSON_PATH,
    markdown: process.env.GOLD_DELTA_MARKDOWN ?? DEFAULT_MD_PATH,
    warnMaxLoss: DEFAULT_WARN_MAX_LOSS,
    failMinNet: DEFAULT_FAIL_MIN_NET,
    mode: DEFAULT_MODE,
    targets: [],
    help: false
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--output":
        options.output = argv[++i] ?? options.output;
        break;
      case "--markdown":
        options.markdown = argv[++i] ?? options.markdown;
        break;
      case "--mode":
        options.mode = (argv[++i] ?? options.mode).toLowerCase();
        break;
      case "--warn-max-loss":
        options.warnMaxLoss = Number(argv[++i] ?? options.warnMaxLoss);
        break;
      case "--fail-min-net":
        options.failMinNet = Number(argv[++i] ?? options.failMinNet);
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
        if (entry.toLowerCase().endsWith(".json")) {
          files.add(path.join(resolved, entry));
        }
      }
    } else if (resolved.toLowerCase().endsWith(".json")) {
      files.add(resolved);
    }
  }
  return Array.from(files);
}

async function readSnapshot(file) {
  try {
    const raw = await fs.readFile(file, "utf8");
    return JSON.parse(raw);
  } catch (error) {
    console.warn(`goldDeltaAggregator: skipped ${file} (${error?.message ?? error})`);
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
  return path.basename(filePath, path.extname(filePath));
}

function buildWaveBoundaries(snapshot) {
  const waves = Array.isArray(snapshot?.analytics?.waveSummaries)
    ? snapshot.analytics.waveSummaries
    : Array.isArray(snapshot?.analytics?.waveHistory)
      ? snapshot.analytics.waveHistory
      : [];
  if (!waves.length) {
    return [{ index: 0, start: 0, end: Number(snapshot?.time) || Infinity }];
  }
  const boundaries = [];
  let cursor = 0;
  for (const wave of waves) {
    const duration = Number(wave.duration) || 0;
    const start = cursor;
    const end = cursor + duration;
    boundaries.push({ index: wave.index ?? boundaries.length, start, end });
    cursor = end;
  }
  boundaries[boundaries.length - 1].end = Math.max(
    boundaries[boundaries.length - 1].end,
    Number(snapshot?.time) || boundaries[boundaries.length - 1].end
  );
  return boundaries;
}

function assignEventsToWaves(events, boundaries) {
  const buckets = new Map();
  if (!Array.isArray(events) || events.length === 0) {
    return buckets;
  }
  const fallbackWave = boundaries[boundaries.length - 1];
  for (const event of events) {
    if (!event || typeof event !== "object") continue;
    const timestamp = Number(event.timestamp);
    const delta = Number(event.delta) || 0;
    const waveBoundary = Number.isFinite(timestamp)
      ? boundaries.find((boundary) => timestamp >= boundary.start && timestamp < boundary.end) ?? fallbackWave
      : fallbackWave;
    const key = waveBoundary.index;
    if (!buckets.has(key)) {
      buckets.set(key, {
        index: key,
        start: waveBoundary.start,
        end: waveBoundary.end,
        events: []
      });
    }
    buckets.get(key).events.push({ delta, timestamp });
  }
  return buckets;
}

function summariseWave(bucket) {
  let gain = 0;
  let spend = 0;
  let largestDelta = 0;
  for (const event of bucket.events) {
    const delta = event.delta;
    if (delta >= 0) gain += delta;
    else spend += delta;
    if (Math.abs(delta) > Math.abs(largestDelta)) {
      largestDelta = delta;
    }
  }
  return {
    waveIndex: bucket.index,
    start: bucket.start,
    end: bucket.end,
    events: bucket.events.length,
    gain: Number(gain.toFixed(3)),
    spend: Number(spend.toFixed(3)),
    net: Number((gain + spend).toFixed(3)),
    largestDelta: Number(largestDelta.toFixed(3))
  };
}

function median(values) {
  if (!values.length) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 === 0 ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid];
}

function summariseScenario(file, snapshot, options) {
  const scenario = inferScenario(file, snapshot);
  const events = Array.isArray(snapshot?.analytics?.goldEvents)
    ? snapshot.analytics.goldEvents
    : [];
  const boundaries = buildWaveBoundaries(snapshot);
  const buckets = assignEventsToWaves(events, boundaries);
  const waveSummaries = boundaries.map((boundary) => {
    const bucket = buckets.get(boundary.index) ?? {
      index: boundary.index,
      start: boundary.start,
      end: boundary.end,
      events: []
    };
    return summariseWave(bucket);
  });

  const deltas = events.map((event) => Number(event.delta) || 0);
  const netDelta = deltas.reduce((sum, delta) => sum + delta, 0);
  const largestGain = deltas.reduce((max, delta) => (delta > max ? delta : max), Number.NEGATIVE_INFINITY);
  const largestLoss = deltas.reduce((min, delta) => (delta < min ? delta : min), Number.POSITIVE_INFINITY);
  const stats = {
    netDelta: Number(netDelta.toFixed(3)),
    largestGain: Number.isFinite(largestGain) ? largestGain : null,
    largestLoss: Number.isFinite(largestLoss) ? largestLoss : null,
    medianDelta: deltas.length ? Number(median(deltas).toFixed(3)) : null,
    cumulative: deltas.reduce((arr, delta) => {
      const prev = arr.length ? arr[arr.length - 1] : 0;
      arr.push(Number((prev + delta).toFixed(3)));
      return arr;
    }, [])
  };

  const alerts = [];
  if (stats.largestLoss !== null && stats.largestLoss < options.warnMaxLoss) {
    alerts.push({ level: "warn", message: `Gold delta dropped to ${stats.largestLoss}g.` });
  }
  if (stats.netDelta < options.failMinNet) {
    alerts.push({ level: options.mode === "fail" ? "fail" : "warn", message: `Net gold delta ${stats.netDelta}g below threshold ${options.failMinNet}g.` });
  }

  const status = alerts.some((alert) => alert.level === "fail")
    ? "fail"
    : alerts.some((alert) => alert.level === "warn")
      ? "warn"
      : "ok";

  return {
    file,
    scenario,
    stats,
    waves: waveSummaries,
    alerts,
    status
  };
}

function buildMarkdown(summary) {
  const lines = [];
  lines.push("## Gold Delta Aggregates");
  lines.push("");
  if (!summary.entries.length) {
    lines.push("_No gold delta data found._");
    return lines.join("\n");
  }
  for (const entry of summary.entries) {
    lines.push(`### ${entry.scenario}`);
    lines.push(`Source: \`${entry.file}\``);
    lines.push("");
    lines.push(`Net Δ: ${entry.stats.netDelta}g • Largest gain: ${entry.stats.largestGain ?? "n/a"}g • Largest loss: ${entry.stats.largestLoss ?? "n/a"}g`);
    lines.push("");
    lines.push("| Wave | Gain | Spend | Net | Events | Largest Δ |");
    lines.push("| --- | --- | --- | --- | --- | --- |");
    for (const wave of entry.waves) {
      lines.push(
        `| ${wave.waveIndex + 1} | ${wave.gain.toFixed(1)} | ${wave.spend.toFixed(1)} | ${wave.net.toFixed(1)} | ${wave.events} | ${wave.largestDelta.toFixed(1)} |`
      );
    }
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

async function writeOutputs(jsonPath, markdownPath, summary, markdown) {
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
    console.warn("goldDeltaAggregator: no input snapshots found.");
  }

  const entries = [];
  for (const file of files) {
    const snapshot = await readSnapshot(file);
    if (!snapshot) continue;
    entries.push(summariseScenario(file, snapshot, options));
  }

  const status = entries.some((entry) => entry.status === "fail") && options.mode === "fail"
    ? "fail"
    : entries.some((entry) => entry.status !== "ok")
      ? "warn"
      : "ok";

  const summary = {
    generatedAt: new Date().toISOString(),
    mode: options.mode,
    status,
    config: {
      warnMaxLoss: options.warnMaxLoss,
      failMinNet: options.failMinNet
    },
    entries
  };
  const markdown = buildMarkdown(summary);
  await writeOutputs(options.output, options.markdown, summary, markdown);

  if (status === "fail" && options.mode === "fail") {
    console.error("goldDeltaAggregator: fail-level alerts detected.");
    return 1;
  }
  if (status === "warn" && options.mode === "fail") {
    console.warn("goldDeltaAggregator: warn-level alerts detected.");
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

export { summariseScenario as summarizeScenario, buildMarkdown };
