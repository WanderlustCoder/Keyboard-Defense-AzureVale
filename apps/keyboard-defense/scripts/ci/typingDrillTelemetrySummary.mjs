#!/usr/bin/env node

import { promises as fs } from "node:fs";
import path from "node:path";
import process from "node:process";

const DEFAULT_TELEMETRY = "artifacts/summaries";
const DEFAULT_OUT_JSON = "artifacts/summaries/typing-drill-telemetry.json";
const DEFAULT_OUT_MD = "artifacts/summaries/typing-drill-telemetry.md";
const DEFAULT_RECENT_LIMIT = 8;

function printHelp() {
  console.log(`Typing Drill Telemetry Summary

Usage:
  node scripts/ci/typingDrillTelemetrySummary.mjs [options] [telemetry ...]

Options:
  --telemetry <path>  Telemetry JSON file or directory (default: ${DEFAULT_TELEMETRY})
  --out-json <path>   Output JSON summary path (default: ${DEFAULT_OUT_JSON})
  --markdown <path>   Markdown output path (default: ${DEFAULT_OUT_MD})
  --recent <count>    Number of recent quickstarts to display (default: ${DEFAULT_RECENT_LIMIT})
  --help              Show this help message

Arguments:
  telemetry           Additional telemetry files or directories to include.`);
}

function parseArgs(argv) {
  const options = {
    telemetryPaths: [],
    outJson: DEFAULT_OUT_JSON,
    markdown: DEFAULT_OUT_MD,
    recent: DEFAULT_RECENT_LIMIT,
    help: false
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--telemetry":
        options.telemetryPaths.push(argv[++i] ?? "");
        break;
      case "--out-json":
        options.outJson = argv[++i] ?? options.outJson;
        break;
      case "--markdown":
        options.markdown = argv[++i] ?? options.markdown;
        break;
      case "--recent":
        options.recent = Number.parseInt(argv[++i] ?? options.recent, 10);
        break;
      case "--help":
        options.help = true;
        break;
      default:
        if (token.startsWith("-")) {
          throw new Error(`Unknown option '${token}'. Use --help for usage.`);
        }
        options.telemetryPaths.push(token);
        break;
    }
  }

  if (!Number.isFinite(options.recent) || options.recent <= 0) {
    options.recent = DEFAULT_RECENT_LIMIT;
  }

  if (options.telemetryPaths.length === 0) {
    options.telemetryPaths.push(DEFAULT_TELEMETRY);
  }

  return {
    ...options,
    telemetryPaths: options.telemetryPaths.map((entry) => path.resolve(entry)),
    outJson: options.outJson ? path.resolve(options.outJson) : null,
    markdown: options.markdown ? path.resolve(options.markdown) : null
  };
}

async function readJson(filePath) {
  const content = await fs.readFile(filePath, "utf8");
  return JSON.parse(content);
}

function normalizeEvent(raw) {
  if (!raw || typeof raw !== "object") return null;
  const eventName = raw.event ?? raw.name ?? raw.type;
  if (!eventName || typeof eventName !== "string") return null;
  const payload =
    raw.payload && typeof raw.payload === "object" ? { ...raw.payload } : {};
  const metadata =
    raw.metadata && typeof raw.metadata === "object" ? { ...raw.metadata } : undefined;
  const candidateTimestamp =
    Number.isFinite(payload.timestamp) && !Number.isNaN(payload.timestamp)
      ? payload.timestamp
      : Number.isFinite(raw.timestamp)
        ? raw.timestamp
        : typeof raw.timestamp === "string" && !Number.isNaN(Date.parse(raw.timestamp))
          ? Date.parse(raw.timestamp)
          : null;
  return {
    event: eventName,
    payload,
    metadata,
    timestamp: Number.isFinite(candidateTimestamp) ? candidateTimestamp : null
  };
}

function extractEventsFromDocument(document) {
  if (document === null || document === undefined) return [];
  if (Array.isArray(document)) {
    return document.flatMap((entry) => extractEventsFromDocument(entry));
  }
  if (typeof document !== "object") return [];
  if (document.event || document.name || document.type) {
    const normalized = normalizeEvent(document);
    return normalized ? [normalized] : [];
  }
  const events = [];
  if (document.telemetry && typeof document.telemetry === "object") {
    const queue = Array.isArray(document.telemetry.queue) ? document.telemetry.queue : [];
    for (const item of queue) {
      const normalized = normalizeEvent(item);
      if (normalized) events.push(normalized);
    }
  }
  if (Array.isArray(document.queue)) {
    for (const item of document.queue) {
      const normalized = normalizeEvent(item);
      if (normalized) events.push(normalized);
    }
  }
  return events;
}

async function collectTelemetryEvents(paths) {
  const events = [];
  const warnings = [];
  for (const target of paths) {
    let stats;
    try {
      stats = await fs.stat(target);
    } catch (error) {
      warnings.push(`Telemetry path not found: ${target} (${error?.message ?? error})`);
      continue;
    }
    if (stats.isDirectory()) {
      const files = await fs.readdir(target);
      for (const file of files) {
        if (!file.toLowerCase().endsWith(".json")) continue;
        const absolute = path.join(target, file);
        try {
          const doc = await readJson(absolute);
          events.push(...extractEventsFromDocument(doc));
        } catch (error) {
          warnings.push(`${absolute}: ${error?.message ?? error}`);
        }
      }
    } else {
      try {
        const doc = await readJson(target);
        events.push(...extractEventsFromDocument(doc));
      } catch (error) {
        warnings.push(`${target}: ${error?.message ?? error}`);
      }
    }
  }
  return { events, warnings };
}

function increment(map, key) {
  if (!key) return;
  const normalized = String(key);
  map[normalized] = (map[normalized] ?? 0) + 1;
}

function sortCounts(map) {
  return Object.entries(map)
    .sort((a, b) => b[1] - a[1])
    .map(([key, value]) => ({ key, value }));
}

function summarizeTelemetry(events, options = {}) {
  const { recentLimit = DEFAULT_RECENT_LIMIT, telemetryPaths = [] } = options;
  const warnings = [];
  if (!Array.isArray(events) || events.length === 0) {
    warnings.push("No telemetry entries found.");
  }
  const starts = events.filter((entry) => entry.event === "typing-drill.started");
  const completions = events.filter((entry) => entry.event === "typing-drill.completed");
  const quickstarts = events.filter((entry) => entry.event === "ui.typingDrill.menuQuickstart");

  const startsBySource = {};
  const startsByMode = {};
  for (const start of starts) {
    const source = start.payload?.source ?? "unknown";
    increment(startsBySource, source);
    const mode = start.payload?.mode ?? "unknown";
    increment(startsByMode, mode);
  }

  const quickstartByMode = {};
  const quickstartReasons = {};
  let recommended = 0;
  let fallback = 0;
  const recentQuickstarts = quickstarts
    .map((entry) => {
      const hadRecommendation = Boolean(entry.payload?.hadRecommendation);
      if (hadRecommendation) recommended += 1;
      else fallback += 1;
      const mode = entry.payload?.mode ?? "unknown";
      increment(quickstartByMode, mode);
      const reason = entry.payload?.reason ?? (hadRecommendation ? "recommended" : "fallback");
      increment(quickstartReasons, reason);
      return {
        mode,
        hadRecommendation,
        reason,
        timestamp: Number.isFinite(entry.timestamp) ? entry.timestamp : null
      };
    })
    .sort((a, b) => (b.timestamp ?? 0) - (a.timestamp ?? 0))
    .slice(0, recentLimit);

  const menuStarts = starts.filter((entry) => (entry.payload?.source ?? "unknown") === "menu");
  const menuQuickstartShare =
    menuStarts.length > 0 ? quickstarts.length / menuStarts.length : null;

  if (quickstarts.length === 0) {
    warnings.push("No menu quickstart telemetry found (ui.typingDrill.menuQuickstart).");
  }

  return {
    generatedAt: new Date().toISOString(),
    inputs: { telemetryPaths: [...telemetryPaths] },
    totals: {
      events: events.length,
      drillStarts: starts.length,
      completions: completions.length,
      quickstarts: quickstarts.length
    },
    starts: {
      bySource: startsBySource,
      byMode: startsByMode
    },
    menuQuickstart: {
      count: quickstarts.length,
      recommended,
      fallback,
      byMode: quickstartByMode,
      byReason: quickstartReasons,
      menuStartShare: menuQuickstartShare,
      recent: recentQuickstarts
    },
    warnings
  };
}

function formatCountMap(map) {
  const entries = sortCounts(map);
  if (entries.length === 0) return "-";
  return entries.map(({ key, value }) => `${key} ${value}`).join(", ");
}

function formatShare(share) {
  if (!Number.isFinite(share)) return "n/a";
  return `${Math.round(share * 1000) / 10}%`;
}

function formatTimestamp(ms) {
  if (!Number.isFinite(ms)) return "n/a";
  try {
    return new Date(ms).toISOString();
  } catch {
    return "n/a";
  }
}

function formatMarkdown(summary) {
  const lines = [];
  lines.push("## Typing Drill Quickstart Telemetry");
  lines.push(`Generated: ${summary.generatedAt ?? "unknown"}`);
  lines.push("");

  if (summary.totals.events === 0) {
    lines.push("_No telemetry entries found. Supply telemetry JSON exports or a directory of telemetry files._");
    return lines.join("\n");
  }

  const quickstarts = summary.menuQuickstart;
  const starts = summary.starts;
  const shareLabel = formatShare(quickstarts.menuStartShare);
  lines.push(
    `Menu quickstarts: ${quickstarts.count} (recommended ${quickstarts.recommended}, fallback ${quickstarts.fallback}); share of menu starts: ${shareLabel}.`
  );
  lines.push(
    `Drill starts: ${summary.totals.drillStarts} (sources: ${formatCountMap(starts.bySource)}; modes: ${formatCountMap(starts.byMode)}).`
  );
  lines.push(
    `Quickstart reasons: ${formatCountMap(quickstarts.byReason)}; modes: ${formatCountMap(quickstarts.byMode)}.`
  );
  lines.push("");

  if (quickstarts.recent.length > 0) {
    lines.push("| Timestamp | Mode | Recommendation | Reason |");
    lines.push("| --- | --- | --- | --- |");
    for (const entry of quickstarts.recent) {
      lines.push(
        `| ${formatTimestamp(entry.timestamp)} | ${entry.mode} | ${entry.hadRecommendation ? "recommended" : "fallback"} | ${entry.reason ?? "-"} |`
      );
    }
    lines.push("");
  }

  if (Array.isArray(summary.warnings) && summary.warnings.length > 0) {
    lines.push("Warnings:");
    for (const warning of summary.warnings) {
      lines.push(`- ${warning}`);
    }
  }

  return lines.join("\n");
}

async function writeFileEnsuringDir(targetPath, contents) {
  await fs.mkdir(path.dirname(targetPath), { recursive: true });
  await fs.writeFile(targetPath, contents, "utf8");
}

async function appendStepSummary(markdown) {
  const summaryPath = process.env.GITHUB_STEP_SUMMARY;
  if (!summaryPath) return;
  try {
    await fs.appendFile(summaryPath, `${markdown}\n`, "utf8");
  } catch (error) {
    console.warn(
      `Unable to append step summary (${error instanceof Error ? error.message : String(error)})`
    );
  }
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  if (options.help) {
    printHelp();
    return;
  }
  const { events, warnings } = await collectTelemetryEvents(options.telemetryPaths);
  const summary = summarizeTelemetry(events, {
    recentLimit: options.recent,
    telemetryPaths: options.telemetryPaths
  });
  summary.warnings.push(...warnings);
  summary.outputs = {
    json: options.outJson ? path.relative(process.cwd(), options.outJson) : null,
    markdown: options.markdown ? path.relative(process.cwd(), options.markdown) : null
  };

  if (options.outJson) {
    await writeFileEnsuringDir(options.outJson, `${JSON.stringify(summary, null, 2)}\n`);
  }
  const markdown = formatMarkdown(summary);
  if (options.markdown) {
    await writeFileEnsuringDir(options.markdown, `${markdown}\n`);
  }
  await appendStepSummary(markdown);

  if (summary.warnings.length > 0) {
    const label = summary.warnings.length === 1 ? "warning" : "warnings";
    console.warn(`${summary.warnings.length} ${label} detected. See summary output for details.`);
  }
}

if (
  import.meta.url === `file://${process.argv[1]}` ||
  process.argv[1]?.endsWith("typingDrillTelemetrySummary.mjs")
) {
  main().catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
  });
}

export {
  parseArgs,
  collectTelemetryEvents,
  summarizeTelemetry,
  formatMarkdown
};
