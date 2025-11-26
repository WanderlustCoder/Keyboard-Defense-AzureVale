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
const uiSnapshotGalleryPath = path.join(appRoot, "artifacts", "summaries", "ui-snapshot-gallery.json");
const portalPath = path.join(docsDir, "CODEX_PORTAL.md");
const PORTAL_MARKER_START = "<!-- GOLD_ANALYTICS_BOARD:START -->";
const PORTAL_MARKER_END = "<!-- GOLD_ANALYTICS_BOARD:END -->";
const PORTAL_UI_MARKER_START = "<!-- UI_SNAPSHOT_GALLERY:START -->";
const PORTAL_UI_MARKER_END = "<!-- UI_SNAPSHOT_GALLERY:END -->";
const priorityOrder = { P1: 1, P2: 2, P3: 3 };

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

function buildPortalGoldSection(board) {
  const lines = [];
  if (!board) {
    lines.push("_No gold analytics board snapshot found. Run `npm run analytics:gold:report` followed by `node scripts/ci/goldAnalyticsBoard.mjs ...` to regenerate before rerunning `npm run codex:dashboard`._");
    return lines.join("\n");
  }
  lines.push(
    "_Re-run `npm run codex:dashboard` after `npm run analytics:gold:report` to refresh this table with the latest CI artifacts._"
  );
  const statusLabel = board.status === "pass" ? "[PASS]" : "[WARN]";
  lines.push(`Generated: ${board.generatedAt ?? "unknown"} (${statusLabel}, warnings: ${board.warnings?.length ?? 0})`);
  if (board.summary?.metrics?.starfield) {
    const starfield = board.summary.metrics.starfield;
    lines.push(
      `Starfield avg depth: ${starfield.depthAvg ?? "n/a"}, drift: ${starfield.driftAvg ?? "n/a"}, wave: ${starfield.waveProgressAvg ?? "n/a"}%, castle: ${starfield.castleRatioAvg ?? "n/a"}%, last tint: ${starfield.lastTint ?? "n/a"}`
    );
  }
  lines.push("");
  lines.push("| Scenario | Net delta | Median Gain | Median Spend | Starfield | Last Gold delta | Last Passive | Sparkline (delta@t) | Alerts |");
  lines.push("| --- | --- | --- | --- | --- | --- | --- | --- | --- |");
  const scenarios = Array.isArray(board.scenarios) ? board.scenarios.slice(0, 5) : [];
  for (const scenario of scenarios) {
    const net = scenario.summary?.netDelta ?? scenario.summary?.metrics?.netDelta ?? "-";
    const medianGain = scenario.summary?.medianGain ?? scenario.summary?.metrics?.medianGain ?? "-";
    const medianSpend =
      scenario.summary?.medianSpend ?? scenario.summary?.metrics?.medianSpend ?? "-";
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
    lines.push(
      `| ${scenario.id ?? "-"} | ${net} | ${medianGain} | ${medianSpend} | ${starfieldNote} | ${goldNote} | ${passiveNote} | ${formatSparkline(scenario.timelineSparkline)} | ${alertBadge} |`
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
  for (const shot of gallery.shots.slice(0, 5)) {
    lines.push(`| ${shot.id ?? "-"} | ${shot.starfieldScene ?? "auto"} | ${shot.summary ?? ""} |`);
  }
  if (gallery.shots.length > 5) {
    lines.push(`| ... | ... | ${gallery.shots.length - 5} more entries |`);
  }
  lines.push("");
  lines.push(
    `Artifacts: \`apps/keyboard-defense/artifacts/summaries/ui-snapshot-gallery.json\``
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
  const goldBoard = await readJsonIfExists(goldAnalyticsBoardPath);
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
    if (Array.isArray(goldBoard.scenarios) && goldBoard.scenarios.length > 0) {
      lines.push("");
      lines.push(
        "| Scenario | Net delta | Median Gain | Median Spend | Last Gold delta | Last Passive | Sparkline (delta@t) | Alerts |"
      );
      lines.push("| --- | --- | --- | --- | --- | --- | --- | --- |");
      const sample = goldBoard.scenarios.slice(0, 5);
      for (const scenario of sample) {
        const net = scenario.summary?.netDelta ?? scenario.summary?.metrics?.netDelta ?? "-";
        const medianGain = scenario.summary?.medianGain ?? scenario.summary?.metrics?.medianGain ?? "-";
        const medianSpend =
          scenario.summary?.medianSpend ?? scenario.summary?.metrics?.medianSpend ?? "-";
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
        lines.push(
          `| ${scenario.id ?? "-"} | ${net} | ${medianGain} | ${medianSpend} | ${goldNote} | ${passiveNote} | ${formatSparkline(
            scenario.timelineSparkline
          )} | ${alertBadge} |`
        );
      }
      if (goldBoard.scenarios.length > 5) {
        lines.push(
          `| ... | ... | ... | ... | ... | ... | ... | ${goldBoard.scenarios.length - 5} more |`
        );
      }
    }
  }
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
    for (const shot of uiGallery.shots.slice(0, 6)) {
      const starfieldScene = shot.starfieldScene ?? "auto";
      lines.push(`| ${shot.id ?? "-"} | ${starfieldScene} | ${shot.summary ?? ""} |`);
    }
    if (uiGallery.shots.length > 6) {
      lines.push(`| ... | ... | ${uiGallery.shots.length - 6} more entries |`);
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
  await updatePortalGoldSnapshot(goldBoard);
  await updatePortalUiSnapshot(uiGallery);
};

main().catch((error) => {
  console.error("Failed to generate Codex dashboard:", error);
  process.exit(1);
});
