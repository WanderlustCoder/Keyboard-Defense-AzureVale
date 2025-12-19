#!/usr/bin/env node
/**
 * Codex CI summary emitter.
 * Reads existing artifacts (smoke, tutorial, gold, breach, screenshots, monitor)
 * and prints a Markdown table suitable for $GITHUB_STEP_SUMMARY.
 */
import fs from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const APP_ROOT = path.resolve(__dirname, "..", "..");
const WORKSPACE_ROOT = path.resolve(APP_ROOT, "..", "..");

const DEFAULTS = {
  devSmoke: [
    path.join("artifacts", "smoke", "devserver-smoke-summary.ci.json"),
    path.join("artifacts", "smoke", "devserver-smoke-summary.json")
  ],
  startSmoke: [
    path.join("artifacts", "monitor", "start-smoke-node20.json"),
    path.join("artifacts", "monitor", "start-smoke-node18.json"),
    path.join("artifacts", "monitor", "start-smoke.ci.json"),
    path.join("artifacts", "monitor", "start-smoke.json")
  ],
  smokeSummary: [
    path.join("artifacts", "smoke", "smoke-summary.ci.json"),
    path.join("artifacts", "smoke", "smoke-summary.json")
  ],
  tutorialPayload: [
    path.join("artifacts", "smoke", "smoke-payload.json"),
    path.join("smoke-artifacts", "tutorial-smoke.ci.json"),
    path.join("smoke-artifacts", "tutorial-smoke.json")
  ],
  gold: [
    path.join("artifacts", "e2e", "gold-summary.ci.json"),
    path.join("artifacts", "smoke", "gold-summary.ci.json"),
    path.join("artifacts", "summaries", "gold-summary-report.e2e.json"),
    path.join("artifacts", "e2e", "gold-summary.json"),
    path.join("artifacts", "smoke", "gold-summary.json"),
    path.join("artifacts", "summaries", "gold-summary-report.json")
  ],
  screenshots: [
    path.join("artifacts", "screenshots", "screenshots-summary.ci.json"),
    path.join("artifacts", "screenshots", "screenshots-summary.json")
  ],
  monitor: [
    path.join("artifacts", "monitor", "dev-monitor.ci.json"),
    path.join("artifacts", "monitor", "dev-monitor.json"),
    path.join("monitor-artifacts", "run.ci.json"),
    path.join("monitor-artifacts", "run.json")
  ],
  breach: [
    path.join("artifacts", "castle-breach.ci.json"),
    path.join("artifacts", "castle-breach.json")
  ],
  audioIntensity: [
    path.join("artifacts", "summaries", "audio-intensity.ci.json"),
    path.join("artifacts", "summaries", "audio-intensity.json")
  ],
  condensedAudit: [
    path.join("artifacts", "summaries", "condensed-audit.ci.json"),
    path.join("artifacts", "summaries", "condensed-audit.json")
  ],
  perf: [
    path.join("artifacts", "perf", "perf-smoke-summary.ci.json"),
    path.join("artifacts", "perf", "perf-smoke-summary.json")
  ]
};

const FLAG_MAP = {
  smoke: "smoke",
  tutorial: "tutorial",
  gold: "gold",
  monitor: "monitor",
  screenshots: "screenshots",
  breach: "breach",
  "start-smoke": "startSmoke",
  "audio-intensity": "audioIntensity",
  "condensed-audit": "condensedAudit",
  perf: "perf"
};

function parseArgs(argv) {
  const overrides = {};
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (token === "--help" || token === "-h") {
      return { help: true, overrides };
    }
    if (!token.startsWith("--")) {
      throw new Error(`Unknown argument "${token}". Use --help for usage.`);
    }
    const key = token.slice(2);
    const normalizedKey = FLAG_MAP[key];
    if (!normalizedKey) {
      throw new Error(`Unsupported flag "--${key}". Use --help for usage.`);
    }
    const next = argv[i + 1];
    if (!next) {
      throw new Error(`Missing value for "--${key}".`);
    }
    const absolute = path.resolve(process.cwd(), next);
    overrides[key] = absolute;
    overrides[normalizedKey] = absolute;
    i += 1;
  }
  return { help: false, overrides };
}

function printHelp() {
  console.log(`Usage:
  node scripts/ci/emit-summary.mjs [--smoke <file>] [--gold <file>] [--monitor <file>] [--screenshots <file>] [--breach <file>]

Flags override the default artifact search paths so you can dry-run with fixtures.
Example:
  node scripts/ci/emit-summary.mjs --smoke ../docs/codex_pack/fixtures/smoke-summary.json --gold ../docs/codex_pack/fixtures/gold-summary.json`);
}

function resolveFirst(paths) {
  for (const candidate of paths) {
    if (!candidate) continue;
    const absolute = path.isAbsolute(candidate) ? candidate : path.resolve(APP_ROOT, candidate);
    if (fs.existsSync(absolute)) {
      return absolute;
    }
  }
  return null;
}

function readJSON(file) {
  if (!file) return null;
  try {
    const raw = fs.readFileSync(file, "utf8");
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

function summarizeCondensedFailures(failures, maxEntries = 3) {
  if (!Array.isArray(failures) || failures.length === 0) {
    return "-";
  }
  const preview = failures.slice(0, maxEntries).map((failure) => {
    const panel = failure?.panelId ?? "panel?";
    const snapshot = failure?.snapshot ?? "snapshot?";
    const breakpoint = failure?.breakpoint ?? "";
    const location = breakpoint ? `${snapshot}@${breakpoint}` : snapshot;
    return `${panel} (${location})`;
  });
  if (failures.length > maxEntries) {
    preview.push(`+${failures.length - maxEntries} more`);
  }
  return preview.join(" / ");
}

function toDisplayPath(file) {
  if (!file) return null;
  const fromWorkspace = path.relative(WORKSPACE_ROOT, file);
  if (fromWorkspace && !fromWorkspace.startsWith("..")) {
    return fromWorkspace.replace(/\\/g, "/");
  }
  const fromCwd = path.relative(process.cwd(), file);
  if (fromCwd && !fromCwd.startsWith("..")) {
    return fromCwd.replace(/\\/g, "/");
  }
  return file.replace(/\\/g, "/");
}

function linkOrDash(label, file) {
  if (!file) return "-";
  const display = toDisplayPath(file);
  return `[\`${label}\`](${display})`;
}

function mdTable(rows) {
  const headers = ["Section", "Metric", "Value"];
  const parts = [
    `| ${headers.join(" | ")} |`,
    `| ${headers.map(() => "---").join(" | ")} |`,
    ...rows.map((r) => `| ${r.join(" | ")} |`)
  ];
  return parts.join("\n");
}

function formatNumber(value) {
  if (value === null || value === undefined || Number.isNaN(value)) return "-";
  return Intl.NumberFormat("en-US").format(value);
}

function formatMetric(value, suffix = "") {
  const base = formatNumber(value);
  if (base === "-") return base;
  return suffix ? `${base}${suffix}` : base;
}

function computeReadyMs(summary) {
  if (!summary) return null;
  if (Number.isFinite(summary.readyMs)) return summary.readyMs;
  if (Number.isFinite(summary.serverReadyMs)) return summary.serverReadyMs;
  const start = summary.startCommand?.startedAt ?? summary.startedAt;
  const readyAt = summary.server?.readyAt;
  if (start && readyAt) {
    const delta = Date.parse(readyAt) - Date.parse(start);
    return Number.isFinite(delta) && delta >= 0 ? delta : null;
  }
  return null;
}

function resolveArtifactPath(value) {
  if (!value || typeof value !== "string") return null;
  if (fs.existsSync(value)) return value;
  const resolvedFromApp = path.resolve(APP_ROOT, value);
  if (fs.existsSync(resolvedFromApp)) return resolvedFromApp;
  return null;
}

function extractShotCount(summary) {
  if (!summary) return null;
  if (Array.isArray(summary.screenshots)) return summary.screenshots.length;
  if (Array.isArray(summary.entries)) return summary.entries.length;
  if (Number.isFinite(summary.count)) return summary.count;
  return null;
}

function extractStarfieldScene(summary) {
  if (!summary) return null;
  if (typeof summary.starfieldScene === "string" && summary.starfieldScene.length > 0) {
    return summary.starfieldScene;
  }
  const viaParameters = summary.parameters?.starfieldScene;
  if (typeof viaParameters === "string" && viaParameters.length > 0) {
    return viaParameters;
  }
  return null;
}

function extractPercentiles(summary) {
  if (!summary) return "-";
  if (Array.isArray(summary.percentiles)) return summary.percentiles.join(", ");
  if (Array.isArray(summary.summaryPercentiles)) return summary.summaryPercentiles.join(", ");
  if (Array.isArray(summary.goldSummaryPercentiles)) {
    return summary.goldSummaryPercentiles.join(", ");
  }
  if (typeof summary.percentiles === "string") return summary.percentiles;
  if (typeof summary.summaryPercentiles === "string") return summary.summaryPercentiles;
  if (typeof summary.goldSummaryPercentiles === "string") return summary.goldSummaryPercentiles;
  return "-";
}

function main() {
  let parsed;
  try {
    parsed = parseArgs(process.argv.slice(2));
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
    return;
  }

  if (parsed.help) {
    printHelp();
    return;
  }

  const resolvedFiles = {
    devSmoke: resolveFirst([
      parsed.overrides.smoke,
      ...DEFAULTS.devSmoke
    ]),
    smokeSummary: resolveFirst([
      parsed.overrides.smoke,
      parsed.overrides.tutorial,
      ...DEFAULTS.smokeSummary
    ]),
    tutorialPayload: resolveFirst([
      parsed.overrides.tutorial,
      ...DEFAULTS.tutorialPayload
    ]),
    gold: resolveFirst([
      parsed.overrides.gold,
      ...DEFAULTS.gold
    ]),
    screenshots: resolveFirst([
      parsed.overrides.screenshots,
      ...DEFAULTS.screenshots
    ]),
    monitor: resolveFirst([
      parsed.overrides.monitor,
      ...DEFAULTS.monitor
    ]),
    startSmoke: resolveFirst([
      parsed.overrides.startSmoke,
      ...DEFAULTS.startSmoke
    ]),
    breach: resolveFirst([
      parsed.overrides.breach,
      ...DEFAULTS.breach
    ]),
    audioIntensity: resolveFirst([
      parsed.overrides.audioIntensity,
      ...DEFAULTS.audioIntensity
    ]),
    condensedAudit: resolveFirst([
      parsed.overrides.condensedAudit,
      ...DEFAULTS.condensedAudit
    ]),
    perf: resolveFirst([
      parsed.overrides.perf,
      ...DEFAULTS.perf
    ])
  };

  const devSmoke = readJSON(resolvedFiles.devSmoke) || null;
  const smokeSummary = readJSON(resolvedFiles.smokeSummary) || null;
  const tutorialArtifact =
    resolveArtifactPath(smokeSummary?.artifact) ?? resolvedFiles.tutorialPayload;
  const tutorialPayload = readJSON(tutorialArtifact) || null;
  const goldSummary = readJSON(resolvedFiles.gold) || null;
  const screenshots = readJSON(resolvedFiles.screenshots) || null;
  const monitor = readJSON(resolvedFiles.monitor) || null;
  const startSmoke = readJSON(resolvedFiles.startSmoke) || null;
  const breach = readJSON(resolvedFiles.breach) || null;
  const audioSummary = readJSON(resolvedFiles.audioIntensity) || null;
  const condensedSummary = readJSON(resolvedFiles.condensedAudit) || null;
  const perfSummary = readJSON(resolvedFiles.perf) || null;

  const rows = [];

  const readyMs = computeReadyMs(devSmoke ?? smokeSummary);
  rows.push(["Dev server smoke", "readyMs", readyMs !== null ? formatNumber(readyMs) : "-"]);
  rows.push([
    "Dev server smoke",
    "status",
    devSmoke?.status ?? smokeSummary?.status ?? "-"
  ]);
  rows.push([
    "Dev server smoke",
    "url",
    devSmoke?.server?.url ?? monitor?.url ?? "-"
  ]);
  rows.push([
    "Dev server smoke",
    "artifact",
    linkOrDash("dev-smoke", resolvedFiles.devSmoke)
  ]);

  rows.push([
    "Tutorial smoke",
    "status",
    tutorialPayload?.status ?? smokeSummary?.status ?? "-"
  ]);
  rows.push([
    "Tutorial smoke",
    "mode",
    tutorialPayload?.mode ?? smokeSummary?.mode ?? "-"
  ]);
  rows.push([
    "Tutorial smoke",
    "artifact",
    linkOrDash("tutorial", tutorialArtifact)
  ]);

  const defeatPayloadAnalytics = tutorialPayload?.analytics ?? null;
  const defeatBurstStats = defeatPayloadAnalytics?.defeatBurst ?? null;
  const tutorialDuration =
    typeof tutorialPayload?.state?.time === "number"
      ? tutorialPayload.state.time
      : typeof tutorialPayload?.time === "number"
        ? tutorialPayload.time
        : null;
  const defeatPerMinute =
    defeatBurstStats &&
    typeof tutorialDuration === "number" &&
    tutorialDuration > 0 &&
    Number.isFinite(tutorialDuration)
      ? defeatBurstStats.total / (tutorialDuration / 60)
      : null;
  const defeatSpritePct =
    defeatBurstStats && defeatBurstStats.total > 0
      ? (defeatBurstStats.sprite / defeatBurstStats.total) * 100
      : null;
  rows.push([
    "Defeat bursts",
    "count",
    defeatBurstStats
      ? `${defeatBurstStats.total} (sprite ${formatNumber(defeatSpritePct ?? 0, 1)}%)`
      : "-"
  ]);
  rows.push([
    "Defeat bursts",
    "perMinute",
    defeatPerMinute !== null && Number.isFinite(defeatPerMinute)
      ? formatNumber(defeatPerMinute, 2)
      : "-"
  ]);
  const lastBurstAge =
    defeatBurstStats && typeof tutorialDuration === "number" && defeatBurstStats.lastTimestamp !== null
      ? tutorialDuration - defeatBurstStats.lastTimestamp
      : null;
  rows.push([
    "Defeat bursts",
    "last",
    defeatBurstStats
      ? `${defeatBurstStats.lastEnemyType ?? "-"} @ ${
          typeof defeatBurstStats.lastLane === "number" ? `lane ${defeatBurstStats.lastLane + 1}` : "lane ?"
        } (${defeatBurstStats.lastMode ?? "procedural"}${
          lastBurstAge !== null && Number.isFinite(lastBurstAge) ? `, ${formatNumber(lastBurstAge, 1)}s ago` : ""
        })`
      : "-"
  ]);

  const audioRun =
    Array.isArray(audioSummary?.runs) && audioSummary.runs.length > 0
      ? audioSummary.runs[0]
      : null;
  if (audioRun) {
    rows.push([
      "Audio intensity",
      "requested",
      formatMetric(audioRun.requestedIntensity)
    ]);
    rows.push([
      "Audio intensity",
      "recorded",
      formatMetric(audioRun.recordedIntensity)
    ]);
    rows.push([
      "Audio intensity",
      "average",
      formatMetric(audioRun.averageIntensity)
    ]);
    rows.push(["Audio intensity", "delta", formatMetric(audioRun.intensityDelta)]);
    rows.push([
      "Audio intensity",
      "samples",
      formatNumber(audioRun.historySamples)
    ]);
    rows.push([
      "Audio intensity",
      "comboCorrelation",
      formatMetric(audioRun.comboCorrelation)
    ]);
    rows.push([
      "Audio intensity",
      "accuracyCorrelation",
      formatMetric(audioRun.accuracyCorrelation)
    ]);
    rows.push([
      "Audio intensity",
      "driftPercent",
      formatMetric(audioRun.driftPercent, "%")
    ]);
  } else {
    rows.push(["Audio intensity", "requested", "-"]);
    rows.push(["Audio intensity", "recorded", "-"]);
    rows.push(["Audio intensity", "average", "-"]);
    rows.push(["Audio intensity", "delta", "-"]);
    rows.push(["Audio intensity", "samples", "-"]);
    rows.push(["Audio intensity", "comboCorrelation", "-"]);
    rows.push(["Audio intensity", "accuracyCorrelation", "-"]);
    rows.push(["Audio intensity", "driftPercent", "-"]);
  }
  rows.push([
    "Audio intensity",
    "artifact",
    linkOrDash("audio-intensity", resolvedFiles.audioIntensity)
  ]);

  const condensedStatus =
    condensedSummary && typeof condensedSummary.ok === "boolean"
      ? condensedSummary.ok
      : null;
  rows.push([
    "Condensed audit",
    "status",
    condensedStatus === null ? "-" : condensedStatus ? "pass" : "fail"
  ]);
  rows.push([
    "Condensed audit",
    "coverage",
    condensedSummary
      ? `${formatNumber(condensedSummary.checks ?? 0)} checks / ${formatNumber(
          condensedSummary.panelsChecked ?? 0
        )} panels`
      : "-"
  ]);
  rows.push([
    "Condensed audit",
    "issues",
    condensedSummary ? summarizeCondensedFailures(condensedSummary.failures) : "-"
  ]);
  rows.push([
    "Condensed audit",
    "artifact",
    linkOrDash("condensed-audit", resolvedFiles.condensedAudit)
  ]);

  const comboWarning = tutorialPayload?.analytics?.comboWarning ?? null;
  const comboCount =
    typeof comboWarning?.count === "number" && comboWarning.count > 0
      ? comboWarning.count
      : Array.isArray(comboWarning?.history)
        ? comboWarning.history.length
        : null;
  rows.push([
    "Combo warning",
    "count",
    comboCount !== null ? formatNumber(comboCount) : "-"
  ]);
  const comboAvg =
    comboWarning?.count > 0 && typeof comboWarning?.deltaSum === "number"
      ? comboWarning.deltaSum / comboWarning.count
      : null;
  rows.push([
    "Combo warning",
    "avgDelta",
    comboAvg !== null ? formatMetric(comboAvg, "%") : "-"
  ]);
  rows.push([
    "Combo warning",
    "worstDelta",
    comboWarning?.deltaMin !== null && comboWarning?.deltaMin !== undefined
      ? formatMetric(comboWarning.deltaMin, "%")
      : "-"
  ]);
  rows.push([
    "Combo warning",
    "lastDelta",
    comboWarning?.lastDelta !== null && comboWarning?.lastDelta !== undefined
      ? formatMetric(comboWarning.lastDelta, "%")
      : "-"
  ]);
  const comboHistoryPreview = Array.isArray(comboWarning?.history)
    ? comboWarning.history
        .slice(-3)
        .map((entry) => {
          const waveLabel =
            typeof entry.waveIndex === "number" && Number.isFinite(entry.waveIndex)
              ? `W${entry.waveIndex}`
              : "W?";
          const delta =
            typeof entry.deltaPercent === "number" && Number.isFinite(entry.deltaPercent)
              ? `${formatNumber(entry.deltaPercent, 2)}%`
              : "";
          return delta ? `${waveLabel}:${delta}` : waveLabel;
        })
        .filter((value) => value.length > 0)
        .join(" | ")
    : null;
  rows.push([
    "Combo warning",
    "history",
    comboHistoryPreview && comboHistoryPreview.length ? comboHistoryPreview : "-"
  ]);

    if (monitor) {
      rows.push(["Dev monitor", "status", monitor.status ?? "-"]);
      rows.push([
        "Dev monitor",
        "lastLatencyMs",
        monitor.lastLatencyMs !== null && monitor.lastLatencyMs !== undefined
          ? formatNumber(Math.round(monitor.lastLatencyMs))
          : "-"
      ]);
      rows.push([
        "Dev monitor",
        "uptimeMs",
        monitor.uptimeMs !== null && monitor.uptimeMs !== undefined
          ? formatNumber(Math.round(monitor.uptimeMs))
          : "-"
      ]);
      rows.push([
        "Dev monitor",
        "flags",
        Array.isArray(monitor.flags) && monitor.flags.length
          ? monitor.flags.join(", ")
          : "-"
      ]);
      rows.push([
        "Dev monitor",
        "artifact",
        linkOrDash("dev-monitor", resolvedFiles.monitor)
      ]);
    }

    if (startSmoke) {
      rows.push(["Start smoke", "status", startSmoke.status ?? "-"]);
      const attemptCount = Array.isArray(startSmoke.attempts) ? startSmoke.attempts.length : "-";
      rows.push(["Start smoke", "attempts", attemptCount]);
      rows.push([
        "Start smoke",
        "artifact",
        linkOrDash("start-smoke", resolvedFiles.startSmoke)
      ]);
    }

  const perfMetrics = perfSummary?.metrics ?? null;
  rows.push(["Perf smoke", "status", perfSummary?.status ?? "-"]);
  rows.push(["Perf smoke", "fps", perfMetrics?.fps !== undefined ? String(perfMetrics.fps) : "-"]);
  rows.push([
    "Perf smoke",
    "frameMsP95",
    perfMetrics?.frameMs?.p95 !== undefined ? formatMetric(perfMetrics.frameMs.p95, "ms") : "-"
  ]);
  rows.push([
    "Perf smoke",
    "heapMax",
    perfMetrics?.heapUsedMB?.max !== undefined ? formatMetric(perfMetrics.heapUsedMB.max, "MB") : "-"
  ]);
  rows.push(["Perf smoke", "artifact", linkOrDash("perf-smoke", resolvedFiles.perf)]);

  rows.push([
    "Gold summary",
    "percentiles",
    extractPercentiles(goldSummary)
  ]);
  const medianGain =
    goldSummary && goldSummary.medianGain !== undefined
      ? goldSummary.medianGain
      : goldSummary?.median;
  rows.push([
    "Gold summary",
    "medianGain",
    medianGain !== undefined ? formatNumber(medianGain) : "-"
  ]);
  const p90Gain = goldSummary?.p90Gain ?? goldSummary?.percentile90Gain;
  rows.push([
    "Gold summary",
    "p90Gain",
    p90Gain !== undefined ? formatNumber(p90Gain) : "-"
  ]);
  rows.push([
    "Gold summary",
    "artifact",
    linkOrDash("gold", resolvedFiles.gold)
  ]);

  const shotCount = extractShotCount(screenshots);
  rows.push(["Screenshots", "captured", shotCount !== null ? formatNumber(shotCount) : "-"]);
  const starfieldScene = extractStarfieldScene(screenshots);
  rows.push([
    "Screenshots",
    "starfieldScene",
    starfieldScene ? starfieldScene : "-"
  ]);
  rows.push([
    "Screenshots",
    "artifact",
    linkOrDash("screenshots", resolvedFiles.screenshots)
  ]);

  if (breach) {
    rows.push([
      "Castle breach",
      "breached",
      breach.breached === undefined ? "-" : String(breach.breached)
    ]);
    rows.push([
      "Castle breach",
      "timeToBreachMs",
      breach.timeToBreachMs !== undefined ? formatNumber(breach.timeToBreachMs) : "-"
    ]);
  } else {
    rows.push(["Castle breach", "breached", "-"]);
    rows.push(["Castle breach", "timeToBreachMs", "-"]);
  }
  rows.push([
    "Castle breach",
    "artifact",
    linkOrDash("breach", resolvedFiles.breach)
  ]);

  rows.push([
    "Monitor",
    "artifact",
    linkOrDash("monitor-run", resolvedFiles.monitor)
  ]);

  console.log("### CI Summary (Codex Pack)");
  console.log();
  console.log(mdTable(rows));
}

main();
