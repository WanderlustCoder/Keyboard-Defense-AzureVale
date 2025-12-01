#!/usr/bin/env node
import { promises as fs } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { parse as parseYaml } from "yaml";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, "..", "..", "..");
const codexDir = path.join(repoRoot, "docs", "codex_pack");
const docsDir = path.join(repoRoot, "docs");
const appRoot = path.join(repoRoot, "apps", "keyboard-defense");
const backlogPath = path.join(appRoot, "docs", "season1_backlog.md");
const condensedAuditSummaryPath = path.join(appRoot, "artifacts", "summaries", "condensed-audit.json");
const goldAnalyticsBoardPath = path.join(appRoot, "artifacts", "summaries", "gold-analytics-board.ci.json");
const goldBaselineGuardPath = path.join(appRoot, "artifacts", "summaries", "gold-baseline-guard.json");
const uiSnapshotGalleryPath = path.join(appRoot, "artifacts", "summaries", "ui-snapshot-gallery.json");
const typingTelemetrySummaryPath = path.join(
  appRoot,
  "artifacts",
  "summaries",
  "typing-drill-telemetry.json"
);
const runtimeLogSummaryPath = path.join(
  appRoot,
  "artifacts",
  "summaries",
  "runtime-log-summary.json"
);
const portalPath = path.join(docsDir, "CODEX_PORTAL.md");
const PORTAL_MARKER_START = "<!-- GOLD_ANALYTICS_BOARD:START -->";
const PORTAL_MARKER_END = "<!-- GOLD_ANALYTICS_BOARD:END -->";
const PORTAL_STARFIELD_MARKER_START = "<!-- STARFIELD_TELEMETRY:START -->";
const PORTAL_STARFIELD_MARKER_END = "<!-- STARFIELD_TELEMETRY:END -->";
const PORTAL_UI_MARKER_START = "<!-- UI_SNAPSHOT_GALLERY:START -->";
const PORTAL_UI_MARKER_END = "<!-- UI_SNAPSHOT_GALLERY:END -->";
const PORTAL_TYPING_MARKER_START = "<!-- TYPING_DRILL_QUICKSTART:START -->";
const PORTAL_TYPING_MARKER_END = "<!-- TYPING_DRILL_QUICKSTART:END -->";
const PORTAL_RUNTIME_LOGS_MARKER_START = "<!-- RUNTIME_LOG_SUMMARY:START -->";
const PORTAL_RUNTIME_LOGS_MARKER_END = "<!-- RUNTIME_LOG_SUMMARY:END -->";
const priorityOrder = { P1: 1, P2: 2, P3: 3 };
const STARFIELD_SEVERITY_THRESHOLDS = {
  warnCastlePercent: 65,
  breachCastlePercent: 50
};
const UI_SNAPSHOT_LIMIT = 10;

const dashboardPath = path.join(docsDir, "codex_dashboard.md");

const readYaml = async (filePath) => parseYaml(await fs.readFile(filePath, "utf8"));

const readManifest = async () => {
  const manifest = await readYaml(path.join(codexDir, "manifest.yml"));
  const status = await readYaml(path.join(codexDir, "task_status.yml"));
  const tasks = manifest.tasks ?? [];
  return tasks.map((task) => {
    const tracker = status?.tasks?.[task.id] ?? {};
    return {
      id: task.id,
      title: task.title,
      priority: task.priority ?? "P?",
      status: tracker.state ?? task.status ?? "todo",
      owner: tracker.owner ?? "unassigned",
      status_note: task.status_note,
      backlog_refs: task.backlog_refs ?? [],
      depends_on: task.depends_on ?? []
    };
  });
};

const extractBacklogRefs = async () => {
  const content = await fs.readFile(backlogPath, "utf8");
  const lines = content.split(/\r?\n/);
  const references = {};
  for (const line of lines) {
    const match = line.match(/^(\d+)\.\s+.*?\(Codex:\s+`([A-Za-z0-9-]+)`/);
    if (match) {
      const backlogId = `#${match[1]}`;
      const taskId = match[2];
      references[taskId] = backlogId;
    }
  }
  return references;
};

const readJsonIfExists = async (filePath) => {
  try {
    const raw = await fs.readFile(filePath, "utf8");
    return JSON.parse(raw);
  } catch {
    return null;
  }
};

const formatDelta = (value) => {
  if (typeof value !== "number" || !Number.isFinite(value)) return value ?? "?";
  const sign = value > 0 ? "+" : "";
  return `${sign}${value}`;
};

const deriveStarfieldSeverity = (starfield) => {
  const castle =
    typeof starfield?.castlePercent === "number"
      ? starfield.castlePercent
      : typeof starfield?.castleRatioAvg === "number"
        ? starfield.castleRatioAvg
        : null;
  if (castle === null) return null;
  if (castle < STARFIELD_SEVERITY_THRESHOLDS.breachCastlePercent) return "breach";
  if (castle < STARFIELD_SEVERITY_THRESHOLDS.warnCastlePercent) return "warn";
  return "calm";
};

const formatSparkline = (points) => {
  if (!Array.isArray(points) || points.length === 0) return "-";
  return points
    .map((point) => {
      const delta = formatDelta(point?.delta);
      const time =
        typeof point?.timestamp === "number" && Number.isFinite(point.timestamp)
          ? point.timestamp
          : "?";
      return `${delta}@${time}`;
    })
    .join(", ");
};

const formatSparklineBar = (points) => {
  if (!Array.isArray(points) || points.length === 0) return "-";
  const deltas = points.map((p) =>
    Number.isFinite(p?.delta) ? Math.abs(p.delta) : 0
  );
  const max = Math.max(...deltas, 1);
  const bins = ".:-=*#";
  return points
    .map((point) => {
      const delta = Number.isFinite(point?.delta) ? point.delta : 0;
      const level = Math.min(
        bins.length - 1,
        Math.floor((Math.abs(delta) / max) * (bins.length - 1))
      );
      const symbol = bins[level];
      const sign = delta > 0 ? "+" : delta < 0 ? "-" : " ";
      return `${sign}${symbol}`;
    })
    .join("");
};

const formatCountMap = (map) => {
  if (!map || typeof map !== "object") return "-";
  const entries = Object.entries(map)
    .filter(([, value]) => typeof value === "number")
    .sort((a, b) => b[1] - a[1]);
  if (entries.length === 0) return "-";
  return entries.map(([key, value]) => `${key} ${value}`).join(", ");
};

const formatShare = (value) => {
  if (!Number.isFinite(value)) return "n/a";
  return `${Math.round(value * 1000) / 10}%`;
};

const formatTimestamp = (value) => {
  if (!Number.isFinite(value)) return "n/a";
  try {
    return new Date(value).toISOString();
  } catch {
    return "n/a";
  }
};

const formatPercent = (value) => {
  if (!Number.isFinite(value)) return "n/a";
  return `${Math.round(value * 1000) / 10}%`;
};

const formatNumber = (value) => {
  if (!Number.isFinite(value)) return "n/a";
  return Math.round(value * 10) / 10;
};

function buildRuntimeLogSection(summary) {
  const lines = [];
  lines.push("## Runtime Log Summary");
  if (!summary) {
    lines.push(
      "- No runtime log summary found. Run `npm run logs:summary` after monitor/dev-server runs to populate `artifacts/summaries/runtime-log-summary.json` then rerun `npm run codex:dashboard`."
    );
    return lines.join("\n");
  }
  lines.push(
    `- Files scanned: ${summary.files?.length ?? 0}; events: ${summary.events ?? 0}; warnings: ${summary.warnings ?? 0}; errors: ${summary.errors ?? 0}.`
  );
  lines.push(
    `- Breaches sum/max: ${summary.breaches?.sum ?? 0}/${summary.breaches?.max ?? 0}; last accuracy: ${formatPercent(
      summary.accuracy?.last
    )}.`
  );
  return lines.join("\n");
}

function buildPortalGoldSection(board, baselineGuard) {
  const lines = [];
  if (!board) {
    lines.push("_No gold analytics board snapshot found. Run `npm run analytics:gold:report` followed by `node scripts/ci/goldAnalyticsBoard.mjs ...` to regenerate before rerunning `npm run codex:dashboard`._");
    return lines.join("\n");
  }
  const starfieldThresholds = board.thresholds?.starfield ?? STARFIELD_SEVERITY_THRESHOLDS;
  lines.push(
    "_Re-run `npm run codex:dashboard` after `npm run analytics:gold:report` to refresh this table with the latest CI artifacts._"
  );
  const statusLabel = board.status === "pass" ? "[PASS]" : "[WARN]";
  lines.push(`Generated: ${board.generatedAt ?? "unknown"} (${statusLabel}, warnings: ${board.warnings?.length ?? 0})`);
  if (Array.isArray(board.warnings) && board.warnings.length > 0) {
    lines.push(`Warnings (sample): ${board.warnings[0]}`);
  }
  if (baselineGuard) {
    const missing = baselineGuard.totals?.missing ?? 0;
    const scenarios = baselineGuard.totals?.scenarios ?? "?";
    const entries = baselineGuard.totals?.baselineEntries ?? "?";
    const missingList =
      Array.isArray(baselineGuard.missing) && baselineGuard.missing.length > 0
        ? ` (missing: ${baselineGuard.missing.join(", ")})`
        : "";
    lines.push(
      `Baseline guard: ${missing > 0 ? "[WARN]" : "[PASS]"} ${missing}/${scenarios} missing (baseline entries: ${entries})${missingList}`
    );
    if (baselineGuard.inputs?.baseline) {
      lines.push(`Baseline guard artifact: \`${path.relative(repoRoot, goldBaselineGuardPath)}\``);
    }
  } else {
    lines.push(
      "Baseline guard: _missing_ (run `node scripts/ci/goldBaselineGuard.mjs --timeline artifacts/summaries/gold-timeline.ci.json --baseline docs/codex_pack/fixtures/gold/gold-percentiles.baseline.json --out-json artifacts/summaries/gold-baseline-guard.json --mode warn` to populate)"
    );
  }
  if (board.timelineBaseline) {
    const matched = board.timelineBaseline.matched ?? 0;
    const total = board.timelineBaseline.totalEntries ?? 0;
    const missing = board.timelineBaseline.missing ?? 0;
    const missingList =
      Array.isArray(board.timelineBaseline.missingScenarios) &&
      board.timelineBaseline.missingScenarios.length > 0
        ? `; missing: ${board.timelineBaseline.missingScenarios.join(", ")}`
        : "";
    lines.push(
      `Timeline baseline: ${board.timelineBaseline.summaryPath ?? "n/a"} (${matched}/${total} matched${missing ? `, missing ${missing}` : ""}${missingList})`
    );
  }
  if (board.summary?.metrics?.starfield) {
    const starfield = board.summary.metrics.starfield;
    const severity = starfield.severity ?? deriveStarfieldSeverity(starfield, starfieldThresholds);
    const severityLabel = severity ? ` (Severity: ${String(severity).toUpperCase()})` : "";
    const thresholdNote =
      typeof starfieldThresholds.warnCastlePercent === "number"
        ? ` (warn < ${starfieldThresholds.warnCastlePercent}%, breach < ${starfieldThresholds.breachCastlePercent}%)`
        : "";
    lines.push(
      `Starfield avg depth: ${starfield.depthAvg ?? "n/a"}, drift: ${starfield.driftAvg ?? "n/a"}, wave: ${starfield.waveProgressAvg ?? "n/a"}%, castle: ${starfield.castleRatioAvg ?? "n/a"}%, last tint: ${starfield.lastTint ?? "n/a"}${severityLabel}${thresholdNote}`
    );
  }
  lines.push("");
  lines.push(
    "| Scenario | Net delta | Median Gain | Median Spend | Timeline Drift (med/p90) | Baseline Drift (med/p90) | Starfield | Last Gold delta | Last Passive | Sparkline (delta@t + bars) | Alerts |"
  );
  lines.push("| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |");
  const scenarios = Array.isArray(board.scenarios) ? board.scenarios.slice(0, 5) : [];
  for (const scenario of scenarios) {
    const net = scenario.summary?.netDelta ?? scenario.summary?.metrics?.netDelta ?? "-";
    const medianGain = scenario.summary?.medianGain ?? scenario.summary?.metrics?.medianGain ?? "-";
    const medianSpend =
      scenario.summary?.medianSpend ?? scenario.summary?.metrics?.medianSpend ?? "-";
    const drift =
      typeof scenario.timelineVariance?.medianGain === "number" ||
      typeof scenario.timelineVariance?.p90Gain === "number"
        ? `${scenario.timelineVariance?.medianGain ?? "n/a"}/${scenario.timelineVariance?.p90Gain ?? "n/a"}`
        : "-";
    const baselineDrift =
      typeof scenario.timelineBaselineVariance?.medianGain === "number" ||
      typeof scenario.timelineBaselineVariance?.p90Gain === "number"
        ? `${scenario.timelineBaselineVariance?.medianGain ?? "n/a"}/${scenario.timelineBaselineVariance?.p90Gain ?? "n/a"}`
        : "-";
    const lastGold = scenario.timelineEvents?.[0];
    const lastPassive = scenario.passiveUnlocks?.[0];
    const alertCount = (scenario.alerts ?? []).filter(
      (alert) => alert.status && alert.status !== "pass"
    ).length;
    const alertBadge =
      scenario.alerts && scenario.alerts.length
        ? alertCount > 0
          ? `[WARN ${alertCount}/${scenario.alerts.length}]`
          : `[PASS ${scenario.alerts.length}]`
        : "-";
    const goldNote = lastGold ? `${formatDelta(lastGold.delta)} @ ${lastGold.timestamp ?? "?"}s` : "-";
    const passiveNote = lastPassive
      ? `${lastPassive.id ?? "passive"} L${lastPassive.level ?? "?"} (+${lastPassive.delta ?? "?"}) @ ${
          lastPassive.time ?? "?"
        }s`
      : "-";
    const starfieldParts = [];
    const starfield = scenario.summary?.starfield;
    if (starfield) {
      const severity = starfield.severity ?? deriveStarfieldSeverity(starfield, starfieldThresholds);
      if (severity) {
        starfieldParts.push(`[${String(severity).toUpperCase()}]`);
      }
      if (typeof starfield.depth === "number") {
        starfieldParts.push(`depth ${starfield.depth}`);
      }
      if (typeof starfield.drift === "number") {
        starfieldParts.push(`drift ${starfield.drift}`);
      }
      if (typeof starfield.wavePercent === "number") {
        starfieldParts.push(`${starfield.wavePercent}% wave`);
      }
      if (typeof starfield.castlePercent === "number") {
        starfieldParts.push(`${starfield.castlePercent}% castle`);
      }
      if (starfield.tint) {
        starfieldParts.push(starfield.tint);
      }
    }
      const starfieldNote = starfieldParts.length ? starfieldParts.join(" / ") : "-";
      const sparkline = formatSparkline(scenario.timelineSparkline);
      const sparkbar = formatSparklineBar(scenario.timelineSparkline);
      lines.push(
        `| ${scenario.id ?? "-"} | ${net} | ${medianGain} | ${medianSpend} | ${drift} | ${baselineDrift} | ${starfieldNote} | ${goldNote} | ${passiveNote} | ${sparkline}${sparkbar === "-" ? "" : ` ${sparkbar}`} | ${alertBadge} |`
      );
  }
  if (Array.isArray(board.scenarios) && board.scenarios.length > 5) {
    lines.push(
      `| ... | ... | ... | ... | ... | ... | ... | ... | ${board.scenarios.length - 5} more |`
    );
  }
  lines.push("");
  lines.push(
    `Artifacts: \`${board.outputs?.json ?? "apps/keyboard-defense/artifacts/summaries/gold-analytics-board.ci.json"}\``
  );
  return lines.join("\n");
}

async function updatePortalGoldSnapshot(board) {
  let portal;
  try {
    portal = await fs.readFile(portalPath, "utf8");
  } catch (error) {
    console.warn(
      `codex portal update skipped: unable to read ${portalPath} (${error instanceof Error ? error.message : String(
        error
      )})`
    );
    return;
  }
  const start = portal.indexOf(PORTAL_MARKER_START);
  const end = portal.indexOf(PORTAL_MARKER_END);
  if (start === -1 || end === -1 || end <= start) {
    console.warn("codex portal update skipped: gold analytics markers missing.");
    return;
  }
  const before = portal.slice(0, start + PORTAL_MARKER_START.length);
  const after = portal.slice(end);
  const section = `\n\n${buildPortalGoldSection(board)}\n`;
  const updated = `${before}${section}${after}`;
  await fs.writeFile(portalPath, updated, "utf8");
  console.log(`Codex portal updated: ${path.relative(repoRoot, portalPath)}`);
}

function buildTypingTelemetrySection(summary) {
  const lines = [];
  lines.push("## Typing Drills Quickstart Telemetry");
  if (!summary) {
    lines.push(
      "- Telemetry summary missing; run `npm run telemetry:typing-drills -- --telemetry docs/codex_pack/fixtures/telemetry/typing-drill-quickstart.json` to refresh `apps/keyboard-defense/artifacts/summaries/typing-drill-telemetry.json`."
    );
    return lines.join("\n");
  }
  const totals = summary.totals ?? {};
  const quick = summary.menuQuickstart ?? {};
  const starts = summary.starts ?? {};
  const completions = summary.completions ?? {};
  const avgAcc = formatPercent(completions.metrics?.avgAccuracy);
  const avgWpm = formatNumber(completions.metrics?.avgWpm);
  const completionShareSource = formatCountMap(completions.shareBySource ?? {});
  const completionRateSource = formatCountMap(completions.rateBySource ?? {});
  lines.push(
    `- Latest summary (${summary.generatedAt ?? "unknown"}) scanned ${totals.events ?? 0} telemetry event(s) with ${totals.drillStarts ?? 0} drill start(s).`
  );
  lines.push(
    `- Menu quickstarts: ${quick.count ?? 0} (recommended ${quick.recommended ?? 0}, fallback ${quick.fallback ?? 0}); share of menu starts: ${formatShare(quick.menuStartShare)}.`
  );
  lines.push(
    `- Recommendation mix: recommended ${formatShare(quick.recommendedRate)} | fallback ${formatShare(quick.fallbackRate)}.`
  );
  lines.push(
    `- Drill starts by source: ${formatCountMap(starts.bySource ?? {})}; share: ${formatCountMap(
      starts.shareBySource ?? {}
    )}; modes: ${formatCountMap(starts.byMode ?? {})}.`
  );
  lines.push(
    `- Drill completions: ${completions.count ?? 0} (rate: ${formatShare(completions.rate)}; per-source: ${completionRateSource}; avg: ${avgAcc} / ${avgWpm} wpm; sources: ${completionShareSource}; modes: ${formatCountMap(completions.shareByMode ?? {})}).`
  );
  lines.push(
    `- Quickstart reasons: ${formatCountMap(quick.byReason ?? {})}; modes: ${formatCountMap(quick.byMode ?? {})}.`
  );
  if (Array.isArray(quick.recent) && quick.recent.length > 0) {
    lines.push("");
    lines.push("| Timestamp | Mode | Recommendation | Reason |");
    lines.push("| --- | --- | --- | --- |");
    for (const entry of quick.recent.slice(0, 6)) {
      lines.push(
        `| ${formatTimestamp(entry.timestamp)} | ${entry.mode ?? "-"} | ${entry.hadRecommendation ? "recommended" : "fallback"} | ${entry.reason ?? "-"} |`
      );
    }
  }
  if (Array.isArray(summary.warnings) && summary.warnings.length > 0) {
    lines.push("");
    lines.push("Warnings:");
    for (const warning of summary.warnings.slice(0, 5)) {
      lines.push(`- ${warning}`);
    }
    if (summary.warnings.length > 5) {
      lines.push(`- ...and ${summary.warnings.length - 5} more warning(s).`);
    }
  }
  return lines.join("\n");
}

function buildPortalTypingSection(summary) {
  const lines = [];
  if (!summary) {
    lines.push(
      "_No typing drill telemetry summary found. Run `npm run telemetry:typing-drills` (optionally pointing at exported telemetry JSON) then rerun `npm run codex:dashboard`._"
    );
    return lines.join("\n");
  }
  const totals = summary.totals ?? {};
  const quick = summary.menuQuickstart ?? {};
  const starts = summary.starts ?? {};
  const completions = summary.completions ?? {};
  const avgAcc = formatPercent(completions.metrics?.avgAccuracy);
  const avgWpm = formatNumber(completions.metrics?.avgWpm);
  const completionShareSource = formatCountMap(completions.shareBySource ?? {});
  const completionRateSource = formatCountMap(completions.rateBySource ?? {});
  lines.push(
    `_Re-run \`npm run telemetry:typing-drills\` after exporting telemetry to refresh this snapshot, then rerun \`npm run codex:dashboard\`._`
  );
  lines.push(
    `Latest summary: ${summary.generatedAt ?? "unknown"} (events: ${totals.events ?? 0}, drill starts: ${totals.drillStarts ?? 0}, menu quickstarts: ${quick.count ?? 0}, share of menu starts: ${formatShare(quick.menuStartShare)}).`
  );
  lines.push(
    `Starts by source: ${formatCountMap(starts.bySource ?? {})}; share: ${formatCountMap(
      starts.shareBySource ?? {}
    )}; quickstart reasons: ${formatCountMap(quick.byReason ?? {})}.`
  );
  lines.push(
    `Recommendation mix: recommended ${formatShare(quick.recommendedRate)} | fallback ${formatShare(quick.fallbackRate)}.`
  );
  lines.push(
    `Drill completions: ${completions.count ?? 0} (rate: ${formatShare(
      completions.rate
    )}; per-source: ${completionRateSource}; avg: ${avgAcc} / ${avgWpm} wpm; sources: ${completionShareSource}; modes: ${formatCountMap(completions.shareByMode ?? {})}).`
  );
  if (Array.isArray(quick.recent) && quick.recent.length > 0) {
    lines.push("");
    lines.push("| Timestamp | Mode | Recommendation | Reason |");
    lines.push("| --- | --- | --- | --- |");
    for (const entry of quick.recent.slice(0, 5)) {
      lines.push(
        `| ${formatTimestamp(entry.timestamp)} | ${entry.mode ?? "-"} | ${entry.hadRecommendation ? "recommended" : "fallback"} | ${entry.reason ?? "-"} |`
      );
    }
  }
  if (Array.isArray(summary.warnings) && summary.warnings.length > 0) {
    lines.push("");
    lines.push(
      `Warnings: ${summary.warnings.slice(0, 2).join("; ")}${
        summary.warnings.length > 2 ? ` (+${summary.warnings.length - 2} more)` : ""
      }`
    );
  }
  return lines.join("\n");
}

async function updatePortalTypingTelemetry(summary) {
  let portal;
  try {
    portal = await fs.readFile(portalPath, "utf8");
  } catch (error) {
    console.warn(
      `codex portal update skipped: unable to read ${portalPath} (${error instanceof Error ? error.message : String(
        error
      )})`
    );
    return;
  }
  const start = portal.indexOf(PORTAL_TYPING_MARKER_START);
  const end = portal.indexOf(PORTAL_TYPING_MARKER_END);
  if (start === -1 || end === -1 || end <= start) {
    console.warn("codex portal update skipped: typing drill telemetry markers missing.");
    return;
  }
  const before = portal.slice(0, start + PORTAL_TYPING_MARKER_START.length);
  const after = portal.slice(end);
  const section = `\n\n${buildPortalTypingSection(summary)}\n`;
  const updated = `${before}${section}${after}`;
  await fs.writeFile(portalPath, updated, "utf8");
  console.log(`Codex portal updated: ${path.relative(repoRoot, portalPath)}`);
}

function buildPortalStarfieldSection(board) {
  const lines = [];
  if (!board || !board.summary?.metrics?.starfield) {
    lines.push(
      "_No starfield telemetry found. Run the gold analytics board (`npm run analytics:gold:board`) then rerun `npm run codex:dashboard`._"
    );
    return lines.join("\n");
  }
  const thresholds = board.thresholds?.starfield ?? STARFIELD_SEVERITY_THRESHOLDS;
  const starfield = board.summary.metrics.starfield;
  const severity = starfield.severity ?? deriveStarfieldSeverity(starfield, thresholds);
  lines.push(
    "_Re-run `npm run analytics:gold:board` followed by `npm run codex:dashboard` to refresh this snapshot with the latest starfield telemetry._"
  );
  const severityLabel = severity ? `[${String(severity).toUpperCase()}]` : "[N/A]";
  const thresholdNote =
    typeof thresholds.warnCastlePercent === "number"
      ? `warn < ${thresholds.warnCastlePercent}%, breach < ${thresholds.breachCastlePercent}%`
      : "";
  lines.push(
    `Latest avg: ${severityLabel} depth ${starfield.depthAvg ?? "n/a"}, drift ${starfield.driftAvg ?? "n/a"}, wave ${starfield.waveProgressAvg ?? "n/a"}%, castle ${starfield.castleRatioAvg ?? "n/a"}%, tint ${starfield.lastTint ?? "n/a"}${thresholdNote ? ` (${thresholdNote})` : ""}`
  );
  lines.push("");
  lines.push("| Scenario | Severity | Depth | Drift | Wave % | Castle % | Tint |");
  lines.push("| --- | --- | --- | --- | --- | --- | --- |");
  const scenarios = Array.isArray(board.scenarios) ? board.scenarios.slice(0, 5) : [];
  for (const scenario of scenarios) {
    const note = scenario.summary?.starfield ?? {};
    const sev = note.severity ?? deriveStarfieldSeverity(note, thresholds);
    lines.push(
      `| ${scenario.id ?? "-"} | ${sev ? sev.toUpperCase() : "-"} | ${note.depth ?? "-"} | ${note.drift ?? "-"} | ${note.wavePercent ?? "-"} | ${note.castlePercent ?? "-"} | ${note.tint ?? "-"} |`
    );
  }
  if (Array.isArray(board.scenarios) && board.scenarios.length > 5) {
    lines.push(`| ... | ... | ... | ... | ... | ... | ${board.scenarios.length - 5} more |`);
  }
  lines.push("");
  lines.push(
    `Artifacts: \`${board.outputs?.json ?? "apps/keyboard-defense/artifacts/summaries/gold-analytics-board.ci.json"}\``
  );
  return lines.join("\n");
}

async function updatePortalStarfieldSnapshot(board) {
  let portal;
  try {
    portal = await fs.readFile(portalPath, "utf8");
  } catch (error) {
    console.warn(
      `codex portal update skipped: unable to read ${portalPath} (${error instanceof Error ? error.message : String(
        error
      )})`
    );
    return;
  }
  const start = portal.indexOf(PORTAL_STARFIELD_MARKER_START);
  const end = portal.indexOf(PORTAL_STARFIELD_MARKER_END);
  if (start === -1 || end === -1 || end <= start) {
    console.warn("codex portal update skipped: starfield telemetry markers missing.");
    return;
  }
  const before = portal.slice(0, start + PORTAL_STARFIELD_MARKER_START.length);
  const after = portal.slice(end);
  const section = `\n\n${buildPortalStarfieldSection(board)}\n`;
  const updated = `${before}${section}${after}`;
  await fs.writeFile(portalPath, updated, "utf8");
  console.log(`Codex portal updated: ${path.relative(repoRoot, portalPath)}`);
}

function buildPortalUiSection(gallery) {
  const lines = [];
  if (!gallery || !Array.isArray(gallery.shots) || gallery.shots.length === 0) {
    lines.push(
      "_Run `npm run docs:gallery` after refreshing HUD screenshots to repopulate `artifacts/summaries/ui-snapshot-gallery.json`, then rerun `npm run codex:dashboard`._"
    );
    return lines.join("\n");
  }
  lines.push(
    "_Re-run `npm run docs:gallery` after capturing screenshots, then `npm run codex:dashboard` to refresh this HUD snapshot summary._"
  );
  lines.push(`Generated: ${gallery.generatedAt ?? "unknown"} (shots: ${gallery.shots.length})`);
  lines.push("");
  lines.push("| Shot | Starfield | Summary |");
  lines.push("| --- | --- | --- |");
  const shotsToShow = gallery.shots.slice(0, UI_SNAPSHOT_LIMIT);
  for (const shot of shotsToShow) {
    lines.push(`| ${shot.id ?? "-"} | ${shot.starfieldScene ?? "auto"} | ${shot.summary ?? ""} |`);
  }
  if (gallery.shots.length > UI_SNAPSHOT_LIMIT) {
    lines.push(`| ... | ... | ${gallery.shots.length - UI_SNAPSHOT_LIMIT} more entries |`);
  }
  lines.push("");
  const metaSources = new Set();
  for (const shot of gallery.shots) {
    const sources = Array.isArray(shot.metaFiles) ? shot.metaFiles : shot.metaFile ? [shot.metaFile] : [];
    sources.filter(Boolean).forEach((source) => metaSources.add(source));
  }
  lines.push(
    `Artifacts: \`apps/keyboard-defense/artifacts/summaries/ui-snapshot-gallery.json\``
  );
  lines.push(
    `Metadata sources: ${metaSources.size} file(s) across ${gallery.shots.length} shot(s) (deduped).`
  );
  return lines.join("\n");
}

async function updatePortalUiSnapshot(gallery) {
  let portal;
  try {
    portal = await fs.readFile(portalPath, "utf8");
  } catch (error) {
    console.warn(
      `codex portal update skipped: unable to read ${portalPath} (${error instanceof Error ? error.message : String(
        error
      )})`
    );
    return;
  }
  const start = portal.indexOf(PORTAL_UI_MARKER_START);
  const end = portal.indexOf(PORTAL_UI_MARKER_END);
  if (start === -1 || end === -1 || end <= start) {
    console.warn("codex portal update skipped: UI snapshot markers missing.");
    return;
  }
  const before = portal.slice(0, start + PORTAL_UI_MARKER_START.length);
  const after = portal.slice(end);
  const section = `\n\n${buildPortalUiSection(gallery)}\n`;
  const updated = `${before}${section}${after}`;
  await fs.writeFile(portalPath, updated, "utf8");
  console.log(`Codex portal updated: ${path.relative(repoRoot, portalPath)}`);
}

async function updatePortalRuntimeLogs(summary) {
  let portal;
  try {
    portal = await fs.readFile(portalPath, "utf8");
  } catch (error) {
    console.warn(
      `codex portal update skipped: unable to read ${portalPath} (${error instanceof Error ? error.message : String(
        error
      )})`
    );
    return;
  }
  const start = portal.indexOf(PORTAL_RUNTIME_LOGS_MARKER_START);
  const end = portal.indexOf(PORTAL_RUNTIME_LOGS_MARKER_END);
  if (start === -1 || end === -1 || end <= start) {
    console.warn("codex portal update skipped: runtime log summary markers missing.");
    return;
  }
  const before = portal.slice(0, start + PORTAL_RUNTIME_LOGS_MARKER_START.length);
  const after = portal.slice(end);
  const section = `\n\n${buildRuntimeLogSection(summary)}\n`;
  const updated = `${before}${section}${after}`;
  await fs.writeFile(portalPath, updated, "utf8");
  console.log(`Codex portal updated: ${path.relative(repoRoot, portalPath)}`);
}

const main = async () => {
  const tasks = await readManifest();
  const backlogMap = await extractBacklogRefs();
  const sorted = tasks.sort((a, b) => {
    const pa = priorityOrder[a.priority] ?? 99;
    const pb = priorityOrder[b.priority] ?? 99;
    if (pa !== pb) return pa - pb;
    if (a.status !== b.status) {
      const order = { "in-progress": 0, todo: 1, done: 2 };
      return (order[a.status] ?? 3) - (order[b.status] ?? 3);
    }
    return a.id.localeCompare(b.id);
  });

  const lines = [];
  lines.push("# Codex Dashboard");
  lines.push("");
  lines.push("| Task | Priority | State | Owner | Status Note | Backlog |");
  lines.push("| --- | --- | --- | --- | --- | --- |");
  for (const task of sorted) {
    const backlogRefs = task.backlog_refs.length
      ? task.backlog_refs.join(", ")
      : backlogMap[task.id] ?? "";
    lines.push(
      `| \`${task.id}\` | ${task.priority} | ${task.status} | ${task.owner} | ${task.status_note} | ${backlogRefs} |`
    );
  }
  lines.push("");
  lines.push("## Passive Unlock & Gold Dashboard");
  lines.push(
    "- CI smoke & e2e jobs publish `artifacts/summaries/passive-gold*.json` plus a Markdown snippet for `$GITHUB_STEP_SUMMARY`."
  );
  lines.push(
    "- Local dry-run: `node scripts/ci/passiveGoldDashboard.mjs docs/codex_pack/fixtures/passives/sample.json --summary temp/passive-gold.fixture.json --mode warn`."
  );
  lines.push("");
  lines.push("## Gold Timeline Dashboard");
  lines.push(
    "- CI publishes `artifacts/summaries/gold-timeline*.json` alongside percentile/passive summaries; Markdown appears in CI summaries."
  );
  lines.push(
    "- Local dry-run: `node scripts/ci/goldTimelineDashboard.mjs docs/codex_pack/fixtures/gold-timeline/smoke.json --summary temp/gold-timeline.fixture.json --mode warn`."
  );
  lines.push("");
  lines.push("## Gold Summary Report");
  lines.push(
    "- CI publishes `artifacts/summaries/gold-summary-report*.json`; thresholds live in `scripts/ci/gold-percentile-thresholds.json`."
  );
  lines.push(
    "- Local dry-run: `node scripts/ci/goldSummaryReport.mjs docs/codex_pack/fixtures/gold/gold-summary-report.json --summary temp/gold-summary-report.fixture.json --mode warn`."
  );
  lines.push("");
  lines.push("## Gold Analytics Board");
  lines.push(
    "- Aggregate gold summary, timeline, passive, guard, and percentile alerts via `node scripts/ci/goldAnalyticsBoard.mjs --summary artifacts/summaries/gold-summary-report.ci.json --timeline artifacts/summaries/gold-timeline.ci.json --passive artifacts/summaries/passive-gold.ci.json --percentile-guard artifacts/summaries/gold-percentile-guard.ci.json --percentile-alerts artifacts/summaries/gold-percentiles.ci.json --out-json artifacts/summaries/gold-analytics-board.ci.json --markdown artifacts/summaries/gold-analytics-board.ci.md`."
  );
  lines.push(
    "- Fixture dry-run: `node scripts/ci/goldAnalyticsBoard.mjs --summary docs/codex_pack/fixtures/gold/gold-summary-report.json --timeline docs/codex_pack/fixtures/gold/gold-timeline-summary.json --passive docs/codex_pack/fixtures/gold/passive-gold-summary.json --percentile-guard docs/codex_pack/fixtures/gold/percentile-guard.json --percentile-alerts docs/codex_pack/fixtures/gold/gold-percentiles.baseline.json --out-json temp/gold-analytics-board.fixture.json --markdown temp/gold-analytics-board.fixture.md`."
  );
  lines.push(
    "- Baseline guard: `node scripts/ci/goldBaselineGuard.mjs --timeline artifacts/summaries/gold-timeline.ci.json --baseline docs/codex_pack/fixtures/gold/gold-percentiles.baseline.json --out-json artifacts/summaries/gold-baseline-guard.json --mode warn` (nightly runs fail if coverage is missing)."
  );
  const goldBoard = await readJsonIfExists(goldAnalyticsBoardPath);
  const baselineGuard = await readJsonIfExists(goldBaselineGuardPath);
  const typingTelemetrySummary = await readJsonIfExists(typingTelemetrySummaryPath);
  const runtimeLogSummary = await readJsonIfExists(runtimeLogSummaryPath);
  if (!goldBoard) {
    lines.push(
      "- Latest board JSON not found; run the gold dashboards (`npm run analytics:gold:report`, `node scripts/ci/goldAnalyticsBoard.mjs ...`) to refresh `artifacts/summaries/gold-analytics-board.ci.json`."
    );
  } else {
    const statusBadge = goldBoard.status === "pass" ? "[PASS]" : "[WARN]";
    lines.push(
      `- Latest board (${goldBoard.generatedAt ?? "unknown"}) status ${statusBadge} with ${
        goldBoard.scenarios?.length ?? 0
      } scenario(s); warnings: ${goldBoard.warnings?.length ?? 0}.`
    );
    if (Array.isArray(goldBoard.warnings) && goldBoard.warnings.length > 0) {
      lines.push(`- Warnings (sample): ${goldBoard.warnings[0]}`);
    }
    if (!baselineGuard) {
      lines.push(
        "- Baseline guard report missing; run `node scripts/ci/goldBaselineGuard.mjs --timeline artifacts/summaries/gold-timeline.ci.json --baseline docs/codex_pack/fixtures/gold/gold-percentiles.baseline.json --out-json artifacts/summaries/gold-baseline-guard.json --mode warn`."
      );
    }
    if (goldBoard.timelineBaseline) {
      const matched = goldBoard.timelineBaseline.matched ?? 0;
      const total = goldBoard.timelineBaseline.totalEntries ?? 0;
      const missing = goldBoard.timelineBaseline.missing ?? 0;
      const missingList =
        Array.isArray(goldBoard.timelineBaseline.missingScenarios) &&
        goldBoard.timelineBaseline.missingScenarios.length > 0
          ? `; missing: ${goldBoard.timelineBaseline.missingScenarios.join(", ")}`
          : "";
      lines.push(
        `- Timeline baseline: ${goldBoard.timelineBaseline.summaryPath ?? "n/a"} (${matched}/${total} matched${missing ? `, missing ${missing}` : ""}${missingList})`
      );
    }
    if (Array.isArray(goldBoard.scenarios) && goldBoard.scenarios.length > 0) {
      lines.push("");
      lines.push(
        "| Scenario | Net delta | Median Gain | Median Spend | Timeline Drift (med/p90) | Baseline Drift (med/p90) | Last Gold delta | Last Passive | Sparkline (delta@t + bars) | Alerts |"
      );
      lines.push("| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |");
      const sample = goldBoard.scenarios.slice(0, 5);
      for (const scenario of sample) {
        const net = scenario.summary?.netDelta ?? scenario.summary?.metrics?.netDelta ?? "-";
        const medianGain = scenario.summary?.medianGain ?? scenario.summary?.metrics?.medianGain ?? "-";
        const medianSpend =
          scenario.summary?.medianSpend ?? scenario.summary?.metrics?.medianSpend ?? "-";
        const drift =
          typeof scenario.timelineVariance?.medianGain === "number" ||
          typeof scenario.timelineVariance?.p90Gain === "number"
            ? `${scenario.timelineVariance?.medianGain ?? "n/a"}/${scenario.timelineVariance?.p90Gain ?? "n/a"}`
            : "-";
    const baselineDrift =
      typeof scenario.timelineBaselineVariance?.medianGain === "number" ||
      typeof scenario.timelineBaselineVariance?.p90Gain === "number"
        ? `${scenario.timelineBaselineVariance?.medianGain ?? "n/a"}/${scenario.timelineBaselineVariance?.p90Gain ?? "n/a"}`
        : "-";
        const lastGold = scenario.timelineEvents?.[0];
        const lastPassive = scenario.passiveUnlocks?.[0];
        const alertCount = (scenario.alerts ?? []).filter(
          (alert) => alert.status && alert.status !== "pass"
        ).length;
        const alertBadge =
          scenario.alerts && scenario.alerts.length
            ? alertCount > 0
              ? `[WARN ${alertCount}/${scenario.alerts.length}]`
              : `[PASS ${scenario.alerts.length}]`
            : "-";
        const goldNote = lastGold
          ? `${formatDelta(lastGold.delta)} @ ${lastGold.timestamp ?? "?"}s`
          : "-";
        const passiveNote = lastPassive
          ? `${lastPassive.id ?? "passive"} L${lastPassive.level ?? "?"} (+${lastPassive.delta ?? "?"}) @ ${
              lastPassive.time ?? "?"
            }s`
          : "-";
        const sparkline = formatSparkline(scenario.timelineSparkline);
        const sparkbar = formatSparklineBar(scenario.timelineSparkline);
        lines.push(
      `| ${scenario.id ?? "-"} | ${net} | ${medianGain} | ${medianSpend} | ${drift} | ${baselineDrift} | ${goldNote} | ${passiveNote} | ${sparkline}${sparkbar === "-" ? "" : ` ${sparkbar}`} | ${alertBadge} |`
      );
    }
      if (goldBoard.scenarios.length > 5) {
        lines.push(
          `| ... | ... | ... | ... | ... | ... | ... | ... | ... | ${goldBoard.scenarios.length - 5} more |`
        );
      }
    }
  }
  lines.push("");
  lines.push(buildTypingTelemetrySection(typingTelemetrySummary));
  lines.push("");
  lines.push(buildRuntimeLogSection(runtimeLogSummary));
  lines.push("");
  lines.push("## UI Snapshot Gallery");
  const uiGallery = await readJsonIfExists(uiSnapshotGalleryPath);
  if (!uiGallery || !Array.isArray(uiGallery.shots) || uiGallery.shots.length === 0) {
    lines.push(
      "- Snapshot gallery JSON missing; run `npm run docs:gallery` after refreshing screenshots to repopulate `artifacts/summaries/ui-snapshot-gallery.json`."
    );
  } else {
    lines.push("");
    lines.push("| Shot | Starfield | Summary |");
    lines.push("| --- | --- | --- |");
    const shotsToShow = uiGallery.shots.slice(0, UI_SNAPSHOT_LIMIT);
    for (const shot of shotsToShow) {
      const starfieldScene = shot.starfieldScene ?? "auto";
      lines.push(`| ${shot.id ?? "-"} | ${starfieldScene} | ${shot.summary ?? ""} |`);
    }
    if (uiGallery.shots.length > UI_SNAPSHOT_LIMIT) {
      lines.push(`| ... | ... | ${uiGallery.shots.length - UI_SNAPSHOT_LIMIT} more entries |`);
    }
  }
  lines.push("");
  lines.push("## Responsive Condensed Audit");
  const condensedSummary = await readJsonIfExists(condensedAuditSummaryPath);
  if (!condensedSummary) {
    lines.push(
      "- No condensed audit summary found. Run `npm run docs:verify-hud-snapshots` to regenerate HUD metadata and the audit report."
    );
  } else {
    lines.push(
      `- Latest run (${condensedSummary.generatedAt ?? "unknown"}) ${
        condensedSummary.ok ? "passed" : "failed"
      } with ${condensedSummary.checks ?? 0} checks across ${
        condensedSummary.panelsChecked ?? "?"
      } panels (snapshots scanned: ${condensedSummary.snapshotsChecked ?? "?"}).`
    );
    if (Array.isArray(condensedSummary.failures) && condensedSummary.failures.length > 0) {
      lines.push("- Outstanding issues:");
      lines.push("");
      lines.push("| Panel | Snapshot | Breakpoint | Detail |");
      lines.push("| --- | --- | --- | --- |");
      for (const failure of condensedSummary.failures.slice(0, 10)) {
        lines.push(
          `| ${failure.panelId ?? "-"} | ${failure.snapshot ?? "-"} | ${failure.breakpoint ?? "-"} | ${failure.message} |`
        );
      }
      if (condensedSummary.failures.length > 10) {
        lines.push(
          `| ... | ... | ... | ${condensedSummary.failures.length - 10} additional issue(s) |`
        );
      }
    } else {
      lines.push("- No outstanding issues; all required panels/breakpoints are covered.");
    }
  }
  lines.push("");
  lines.push("Generated automatically via `npm run codex:dashboard`.");
  await fs.writeFile(dashboardPath, lines.join("\n"), "utf8");
  console.log(`Codex dashboard updated: ${path.relative(repoRoot, dashboardPath)}`);
  await updatePortalGoldSnapshot(goldBoard, baselineGuard);
  await updatePortalStarfieldSnapshot(goldBoard);
  await updatePortalUiSnapshot(uiGallery);
  await updatePortalTypingTelemetry(typingTelemetrySummary);
  await updatePortalRuntimeLogs(runtimeLogSummary);
};

main().catch((error) => {
  console.error("Failed to generate Codex dashboard:", error);
  process.exit(1);
});
