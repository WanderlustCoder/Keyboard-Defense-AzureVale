import { promises as fs } from "node:fs";
import path from "node:path";
import process from "node:process";

const DEFAULT_SUMMARY_PATH = "artifacts/summaries/gold-summary-report.ci.json";
const DEFAULT_TIMELINE_PATH = "artifacts/summaries/gold-timeline.ci.json";
const DEFAULT_PASSIVE_PATH = "artifacts/summaries/passive-gold.ci.json";
const DEFAULT_GUARD_PATH = "artifacts/summaries/gold-percentile-guard.ci.json";
const DEFAULT_ALERTS_PATH = "artifacts/summaries/gold-percentiles.ci.json";
const DEFAULT_OUT_JSON = "artifacts/summaries/gold-analytics-board.ci.json";
const DEFAULT_OUT_MARKDOWN = "artifacts/summaries/gold-analytics-board.ci.md";
const VALID_MODES = new Set(["fail", "warn", "info"]);
const MAX_EVENTS_PER_SCENARIO = 3;
const MAX_UNLOCKS_PER_SCENARIO = 3;
const MAX_SPARKLINE_POINTS = 8;

function printHelp() {
  console.log(`Gold Analytics Board

Usage:
  node scripts/ci/goldAnalyticsBoard.mjs [options]

Options:
  --summary <path>            Gold summary report JSON (default: ${DEFAULT_SUMMARY_PATH})
  --timeline <path>           Gold timeline summary JSON (default: ${DEFAULT_TIMELINE_PATH})
  --passive <path>            Passive gold summary JSON (default: ${DEFAULT_PASSIVE_PATH})
  --percentile-guard <path>   Percentile guard JSON (default: ${DEFAULT_GUARD_PATH})
  --percentile-alerts <path>  Percentile alerts JSON (default: ${DEFAULT_ALERTS_PATH})
  --out-json <path>           Board JSON output path (default: ${DEFAULT_OUT_JSON})
  --markdown <path>           Board Markdown output path (default: ${DEFAULT_OUT_MARKDOWN})
  --mode <fail|warn|info>     Failure behaviour when warnings are present (default: fail)
  --help                      Show this message
`);
}

function parseArgs(argv) {
  const options = {
    summaryPath: process.env.GOLD_SUMMARY_REPORT_PATH ?? DEFAULT_SUMMARY_PATH,
    timelinePath: process.env.GOLD_TIMELINE_SUMMARY ?? DEFAULT_TIMELINE_PATH,
    passivePath: process.env.PASSIVE_GOLD_SUMMARY ?? DEFAULT_PASSIVE_PATH,
    guardPath: process.env.GOLD_GUARD_SUMMARY ?? DEFAULT_GUARD_PATH,
    alertsPath: process.env.GOLD_PERCENTILE_ALERTS ?? DEFAULT_ALERTS_PATH,
    outJson: process.env.GOLD_ANALYTICS_JSON ?? DEFAULT_OUT_JSON,
    markdown: process.env.GOLD_ANALYTICS_MARKDOWN ?? DEFAULT_OUT_MARKDOWN,
    mode: (process.env.GOLD_ANALYTICS_MODE ?? "fail").toLowerCase(),
    help: false
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--summary":
        options.summaryPath = argv[++i] ?? options.summaryPath;
        break;
      case "--timeline":
        options.timelinePath = argv[++i] ?? options.timelinePath;
        break;
      case "--passive":
        options.passivePath = argv[++i] ?? options.passivePath;
        break;
      case "--percentile-guard":
        options.guardPath = argv[++i] ?? options.guardPath;
        break;
      case "--percentile-alerts":
        options.alertsPath = argv[++i] ?? options.alertsPath;
        break;
      case "--out-json":
        options.outJson = argv[++i] ?? options.outJson;
        break;
      case "--markdown":
        options.markdown = argv[++i] ?? options.markdown;
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
    throw new Error(`Invalid mode '${options.mode}'. Use one of: ${Array.from(VALID_MODES).join(", ")}`);
  }

  return options;
}

function normalizePath(value) {
  if (typeof value !== "string") return "";
  return value.replace(/\\/g, "/");
}

function slugify(value) {
  if (typeof value !== "string" || value.length === 0) return "";
  return value
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

function deriveScenarioId(source) {
  const normalized = normalizePath(source);
  const base = normalized.split("/").pop() ?? normalized;
  const trimmed = base.replace(/\.[^.]+$/, "");
  return slugify(trimmed) || "unknown";
}

function ensureScenario(map, id) {
  if (!map.has(id)) {
    map.set(id, {
      id,
      summary: null,
      timelineEvents: [],
      timelineSparkline: [],
      passiveUnlocks: [],
      alerts: []
    });
  }
  return map.get(id);
}

function pickLatest(list, count) {
  if (!Array.isArray(list)) return [];
  return list.slice(0, count);
}

function buildTimelineSparkline(events) {
  if (!Array.isArray(events)) return [];
  return events.slice(0, MAX_SPARKLINE_POINTS).map((event) => ({
    delta: Number.isFinite(event?.delta) ? event.delta : null,
    timestamp: Number.isFinite(event?.timestamp) ? event.timestamp : null,
    gold: Number.isFinite(event?.gold) ? event.gold : null
  }));
}

function formatSparkline(points) {
  if (!Array.isArray(points) || points.length === 0) return "-";
  return points
    .map((point) => {
      const deltaPart =
        typeof point.delta === "number" && Number.isFinite(point.delta)
          ? formatDelta(point.delta)
          : "?";
      const timePart =
        typeof point.timestamp === "number" && Number.isFinite(point.timestamp)
          ? point.timestamp
          : "?";
      return `${deltaPart}@${timePart}`;
    })
    .join(", ");
}

async function loadJsonOptional(filePath, label, warnings) {
  if (!filePath) return null;
  const absolute = path.resolve(filePath);
  try {
    const raw = await fs.readFile(absolute, "utf8");
    return JSON.parse(raw);
  } catch (error) {
    warnings.push(`[${label}] ${error instanceof Error ? error.message : String(error)} (${filePath})`);
    return null;
  }
}

function formatDelta(value) {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    return value ?? "";
  }
  const sign = value > 0 ? "+" : "";
  return `${sign}${value}`;
}

function formatStarfieldNote(starfield) {
  if (!starfield || typeof starfield !== "object") {
    return "-";
  }
  const parts = [];
  if (typeof starfield.depth === "number") {
    parts.push(`depth ${starfield.depth}`);
  }
  if (typeof starfield.drift === "number") {
    parts.push(`drift ${starfield.drift}`);
  }
  if (typeof starfield.wavePercent === "number") {
    parts.push(`${starfield.wavePercent}% wave`);
  }
  if (typeof starfield.castlePercent === "number") {
    parts.push(`${starfield.castlePercent}% castle`);
  }
  if (starfield.tint) {
    parts.push(starfield.tint);
  }
  return parts.length > 0 ? parts.join(" / ") : "-";
}

function buildScenarioSummaryRow(scenario) {
  const summary = scenario.summary ?? {};
  const event = scenario.timelineEvents[0] ?? null;
  const passive = scenario.passiveUnlocks[0] ?? null;
  const alertCount = scenario.alerts.filter((alert) => alert.status && alert.status !== "pass").length;
  const alertBadge =
    scenario.alerts.length === 0
      ? "-"
      : alertCount > 0
        ? `WARN ${alertCount}/${scenario.alerts.length}`
        : `PASS ${scenario.alerts.length}`;
  const goldNote = event ? `${formatDelta(event.delta)} @ ${event.timestamp ?? "?"}s` : "-";
  const passiveNote = passive
    ? `${passive.id ?? "passive"} L${passive.level ?? "?"} (+${passive.delta ?? "?"}) @ ${passive.time ?? "?"}s`
    : "-";
  return {
    scenario: scenario.id,
    netDelta: summary.netDelta ?? "",
    medianGain: summary.medianGain ?? "",
    medianSpend: summary.medianSpend ?? "",
    starfield: formatStarfieldNote(summary.starfield),
    lastGold: goldNote,
    lastPassive: passiveNote,
    alerts: alertBadge
  };
}

export function buildGoldAnalyticsBoard({
  summaryData,
  timelineData,
  passiveData,
  guardData,
  alertsData,
  paths,
  now,
  initialWarnings
}) {
  const warnings = Array.isArray(initialWarnings) ? [...initialWarnings] : [];
  const scenarioMap = new Map();
  const board = {
    generatedAt: (now ?? new Date()).toISOString(),
    inputs: {
      summary: paths?.summary ?? null,
      timeline: paths?.timeline ?? null,
      passive: paths?.passive ?? null,
      guard: paths?.guard ?? null,
      alerts: paths?.alerts ?? null
    },
    outputs: {
      json: paths?.outJson ?? null,
      markdown: paths?.markdown ?? null
    },
    summary: null,
    timeline: null,
    passive: null,
    guard: null,
    percentileAlerts: null,
    scenarios: [],
    warnings,
    status: "pass"
  };

  if (summaryData) {
    if (Array.isArray(summaryData.warnings)) {
      for (const warning of summaryData.warnings) {
        warnings.push(`[summary] ${warning}`);
      }
    }
    board.summary = {
      generatedAt: summaryData.generatedAt ?? null,
      totals: summaryData.totals ?? null,
      metrics: summaryData.metrics ?? null,
      summaryPath: board.inputs.summary
    };
    if (Array.isArray(summaryData.summaries)) {
      for (const row of summaryData.summaries) {
        const scenarioId =
          slugify(row.scenario ?? row.mode ?? "") || deriveScenarioId(row.file ?? "");
        const bucket = ensureScenario(scenarioMap, scenarioId);
        bucket.summary = {
          file: normalizePath(row.file ?? ""),
          netDelta: row.netDelta ?? null,
          medianGain: row.medianGain ?? null,
          p90Gain: row.p90Gain ?? null,
          medianSpend: row.medianSpend ?? null,
          p90Spend: row.p90Spend ?? null,
          eventCount: row.eventCount ?? null,
          starfield: {
            depth: typeof row.starfieldDepth === "number" ? row.starfieldDepth : null,
            drift: typeof row.starfieldDrift === "number" ? row.starfieldDrift : null,
            wavePercent:
              typeof row.starfieldWaveProgress === "number" ? row.starfieldWaveProgress : null,
            castlePercent:
              typeof row.starfieldCastleRatio === "number" ? row.starfieldCastleRatio : null,
            tint: row.starfieldTint ?? null
          }
        };
      }
    }
  }

  if (timelineData) {
    if (Array.isArray(timelineData.warnings)) {
      for (const warning of timelineData.warnings) {
        warnings.push(`[timeline] ${warning}`);
      }
    }
    board.timeline = {
      generatedAt: timelineData.generatedAt ?? null,
      totals: timelineData.totals ?? null,
      metrics: timelineData.metrics ?? null,
      thresholds: timelineData.thresholds ?? null,
      summaryPath: board.inputs.timeline
    };
    const events =
      Array.isArray(timelineData.latestEvents) && timelineData.latestEvents.length > 0
        ? timelineData.latestEvents
        : Array.isArray(timelineData.metrics?.latestEvents)
          ? timelineData.metrics.latestEvents
          : [];
    for (const event of events) {
      const scenarioId =
        slugify(event.scenario ?? event.mode ?? "") || deriveScenarioId(event.file ?? "");
      if (!scenarioId) continue;
      const bucket = ensureScenario(scenarioMap, scenarioId);
      bucket.timelineEvents.push({
        delta: event.delta ?? null,
        gold: event.gold ?? null,
        timestamp: event.timestamp ?? null,
        file: normalizePath(event.file ?? ""),
        mode: event.mode ?? null,
        passiveId: event.passiveId ?? null,
        passiveLevel: event.passiveLevel ?? null
      });
    }
  }

  if (passiveData) {
    if (Array.isArray(passiveData.warnings)) {
      for (const warning of passiveData.warnings) {
        warnings.push(`[passive] ${warning}`);
      }
    }
    board.passive = {
      generatedAt: passiveData.generatedAt ?? null,
      totals: passiveData.totals ?? null,
      metrics: passiveData.metrics ?? null,
      thresholds: passiveData.thresholds ?? null,
      summaryPath: board.inputs.passive
    };
    const unlocks = passiveData.unlocks?.latest ?? [];
    for (const entry of unlocks) {
      const scenarioId =
        slugify(entry.scenario ?? entry.mode ?? "") || deriveScenarioId(entry.file ?? "");
      if (!scenarioId) continue;
      const bucket = ensureScenario(scenarioMap, scenarioId);
      bucket.passiveUnlocks.push({
        id: entry.id ?? "",
        level: entry.level ?? null,
        delta: entry.delta ?? null,
        time: entry.time ?? null,
        goldDelta: entry.goldDelta ?? null,
        goldLag: entry.goldLag ?? null,
        file: normalizePath(entry.file ?? "")
      });
    }
  }

  if (guardData) {
    board.guard = {
      generatedAt: guardData.generatedAt ?? null,
      totals: guardData.totals ?? null,
      percentiles: guardData.percentiles ?? null,
      files: guardData.files ?? [],
      summaryPath: board.inputs.guard
    };
    const failures = guardData.totals?.failures ?? (guardData.files ?? []).filter((entry) => !entry.ok)
      .length;
    board.guard.failures = failures ?? 0;
    if ((board.guard.failures ?? 0) > 0) {
      warnings.push(`Gold percentile guard reported ${board.guard.failures} failure(s).`);
    }
  }

  const alertsSource =
    alertsData?.rows?.length || alertsData?.totals
      ? alertsData
      : summaryData?.percentileAlerts ?? null;
  if (alertsSource) {
    const rows = Array.isArray(alertsSource.rows) ? alertsSource.rows : [];
    const normalizedRows = rows.map((row) => ({
      ...row,
      file: normalizePath(row.file ?? "")
    }));
    const failures = normalizedRows.filter(
      (row) => typeof row.status === "string" && row.status.toLowerCase() !== "pass"
    ).length;
    board.percentileAlerts = {
      rows: normalizedRows,
      failures,
      summaryPath: board.inputs.alerts ?? board.inputs.summary
    };
    if (failures > 0) {
      warnings.push(`Percentile alerts reported ${failures} failing metric(s).`);
    }
    for (const row of normalizedRows) {
      const scenarioId = slugify(row.scenario ?? "") || deriveScenarioId(row.file ?? "");
      if (!scenarioId) continue;
      const bucket = ensureScenario(scenarioMap, scenarioId);
      bucket.alerts.push(row);
    }
  }

  const scenarios = Array.from(scenarioMap.values()).map((scenario) => {
    const sparkline = buildTimelineSparkline(scenario.timelineEvents);
    scenario.timelineEvents = pickLatest(scenario.timelineEvents, MAX_EVENTS_PER_SCENARIO);
    scenario.passiveUnlocks = pickLatest(scenario.passiveUnlocks, MAX_UNLOCKS_PER_SCENARIO);
    scenario.timelineSparkline = sparkline;
    return scenario;
  });
  scenarios.sort((a, b) => a.id.localeCompare(b.id));
  board.scenarios = scenarios;
  board.totals = {
    scenarios: scenarios.length
  };
  board.status = warnings.length > 0 ? "warn" : "pass";
  return board;
}

export function formatGoldAnalyticsMarkdown(board) {
  const lines = [];
  lines.push("## Gold Analytics Board");
  lines.push(`Generated: ${board.generatedAt ?? "n/a"}`);
  lines.push(`Status: ${board.status === "pass" ? "PASS" : "WARN"}`);
  lines.push("");

  lines.push("### Inputs");
  lines.push("| Source | Path |");
  lines.push("| --- | --- |");
  for (const [label, value] of Object.entries(board.inputs ?? {})) {
    lines.push(`| ${label} | ${value ?? "_missing_"} |`);
  }
  lines.push("");

  if (board.summary) {
    lines.push(
      `- Summary net delta: **${board.summary.metrics?.netDelta ?? "n/a"}**, Avg median gain: ${
        board.summary.metrics?.avgMedianGain ?? "n/a"
      }, Avg median spend: ${board.summary.metrics?.avgMedianSpend ?? "n/a"}`
    );
    if (board.summary.metrics?.starfield) {
      const starfield = board.summary.metrics.starfield;
      lines.push(
        `- Starfield avg depth: ${starfield.depthAvg ?? "n/a"}, drift: ${starfield.driftAvg ?? "n/a"}, wave: ${starfield.waveProgressAvg ?? "n/a"}%, castle: ${starfield.castleRatioAvg ?? "n/a"}%, last tint: ${starfield.lastTint ?? "n/a"}`
      );
    }
  }
  if (board.timeline) {
    lines.push(
      `- Timeline net delta: **${board.timeline.metrics?.netDelta ?? "n/a"}**, Max spend streak: ${
        board.timeline.metrics?.maxSpendStreak ?? "n/a"
      } (limit ${board.timeline.thresholds?.maxSpendStreak ?? "?"})`
    );
  }
  if (board.passive) {
    lines.push(
      `- Passive unlocks: **${board.passive.totals?.unlocks ?? 0}**, Max gap: ${
        board.passive.metrics?.maxGapSeconds ?? "n/a"
      }s`
    );
  }
  if (board.guard) {
    const failures = board.guard.failures ?? 0;
    lines.push(
      `- Percentile guard: ${failures > 0 ? `WARN ${failures} failure(s)` : "PASS"} (${board.guard.totals?.checked ?? 0} files)`
    );
  }
  if (board.percentileAlerts) {
    lines.push(
      `- Percentile alerts: ${
        board.percentileAlerts.failures > 0
          ? `WARN ${board.percentileAlerts.failures} failing row(s)`
          : "PASS All metrics within thresholds"
      }`
    );
  }
  lines.push("");

  if (board.scenarios.length > 0) {
    lines.push("### Scenario Snapshot");
    lines.push(
      "| Scenario | Net delta | Median Gain | Median Spend | Starfield | Last Gold delta | Last Passive | Sparkline (Δ@t) | Alerts |"
    );
    lines.push("| --- | --- | --- | --- | --- | --- | --- | --- | --- |");
    for (const scenario of board.scenarios) {
      const row = buildScenarioSummaryRow(scenario);
      lines.push(
        `| ${row.scenario} | ${row.netDelta ?? ""} | ${row.medianGain ?? ""} | ${row.medianSpend ?? ""} | ${row.starfield} | ${row.lastGold} | ${row.lastPassive} | ${formatSparkline(scenario.timelineSparkline)} | ${row.alerts} |`
      );
    }
    lines.push("");
  } else {
    lines.push("_No scenarios detected._");
    lines.push("");
  }

  lines.push("### Warnings");
  if (board.warnings.length === 0) {
    lines.push("_None_");
  } else {
    for (const warning of board.warnings) {
      lines.push(`- ${warning}`);
    }
  }
  lines.push("");
  if (board.outputs?.json) {
    lines.push(`JSON: \`${board.outputs.json}\``);
  }
  if (board.outputs?.markdown) {
    lines.push(`Markdown: \`${board.outputs.markdown}\``);
  }
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

async function writeFileEnsuringDir(targetPath, contents) {
  const absolute = path.resolve(targetPath);
  await fs.mkdir(path.dirname(absolute), { recursive: true });
  await fs.writeFile(absolute, contents);
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

  const loadWarnings = [];
  const summaryData = await loadJsonOptional(options.summaryPath, "summary", loadWarnings);
  const timelineData = await loadJsonOptional(options.timelinePath, "timeline", loadWarnings);
  const passiveData = await loadJsonOptional(options.passivePath, "passive", loadWarnings);
  const guardData = await loadJsonOptional(options.guardPath, "percentile-guard", loadWarnings);
  const alertsData = await loadJsonOptional(options.alertsPath, "percentile-alerts", loadWarnings);

  const board = buildGoldAnalyticsBoard({
    summaryData,
    timelineData,
    passiveData,
    guardData,
    alertsData,
    paths: {
      summary: options.summaryPath,
      timeline: options.timelinePath,
      passive: options.passivePath,
      guard: options.guardPath,
      alerts: options.alertsPath,
      outJson: options.outJson,
      markdown: options.markdown
    },
    initialWarnings: loadWarnings
  });

  await writeFileEnsuringDir(options.outJson, `${JSON.stringify(board, null, 2)}\n`);
  const markdown = formatGoldAnalyticsMarkdown(board);
  await writeFileEnsuringDir(options.markdown, `${markdown}\n`);
  await appendStepSummary(markdown);

  if (board.warnings.length > 0 && options.mode === "fail") {
    throw new Error(
      `${board.warnings.length} gold analytics warning(s) detected. See ${options.outJson}.`
    );
  }
}

if (
  import.meta.url === `file://${process.argv[1]}` ||
  process.argv[1]?.endsWith("goldAnalyticsBoard.mjs")
) {
  try {
    await main();
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
  }
}


