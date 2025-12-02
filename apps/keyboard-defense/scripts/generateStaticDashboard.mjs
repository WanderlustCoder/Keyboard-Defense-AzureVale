#!/usr/bin/env node
/**
 * Builds a simple static dashboard from existing CI artifacts.
 * Outputs HTML + JSON under apps/keyboard-defense/static-dashboard.
 */
import fs from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const APP_ROOT = path.resolve(__dirname, "..");
const OUTPUT_DIR = path.join(APP_ROOT, "static-dashboard");

const SOURCE_MAP = {
  smokeSummary: path.join(APP_ROOT, "artifacts", "smoke", "smoke-summary.ci.json"),
  tutorialPayload: path.join(APP_ROOT, "smoke-artifacts", "tutorial-smoke.json"),
  ciMatrix: path.join(APP_ROOT, "artifacts", "ci-matrix-summary.json"),
  goldSummarySmoke: path.join(APP_ROOT, "artifacts", "smoke", "gold-summary.ci.json"),
  goldSummaryE2E: path.join(APP_ROOT, "artifacts", "e2e", "gold-summary.ci.json"),
  screenshotSummary: path.join(
    APP_ROOT,
    "artifacts",
    "screenshots",
    "screenshots-summary.ci.json"
  )
};

function readJson(file) {
  if (!file || !fs.existsSync(file)) return null;
  try {
    return JSON.parse(fs.readFileSync(file, "utf8"));
  } catch (error) {
    console.warn(
      `[dashboard] Failed to parse ${path.relative(APP_ROOT, file)}: ${
        error instanceof Error ? error.message : error
      }`
    );
    return null;
  }
}

const pickNumber = (...values) => {
  for (const value of values) {
    if (value === undefined || value === null) continue;
    const num = Number(value);
    if (Number.isFinite(num)) return num;
  }
  return null;
};

function extractTutorialAnalytics(source) {
  if (!source) return {};
  const analytics =
    source.analytics?.tutorial ??
    source.analytics ??
    source.tutorialAnalytics ??
    source;
  return {
    attemptedRuns: pickNumber(
      analytics?.attemptedRuns,
      analytics?.attempted,
      source.attemptedRuns
    ),
    completedRuns: pickNumber(
      analytics?.completedRuns,
      analytics?.completed,
      source.completedRuns
    ),
    replayedRuns: pickNumber(analytics?.replayedRuns, source.replayedRuns),
    skippedRuns: pickNumber(analytics?.skippedRuns, source.skippedRuns),
    assistsShown: pickNumber(analytics?.assistsShown, source.assistsShown)
  };
}

function deriveTutorialMetrics(sources = {}) {
  const candidates = [];
  if (sources.tutorialPayload) candidates.push(extractTutorialAnalytics(sources.tutorialPayload));
  if (sources.smokeSummary) candidates.push(extractTutorialAnalytics(sources.smokeSummary));
  if (Array.isArray(sources.ciMatrix?.tutorialRuns)) {
    for (const run of sources.ciMatrix.tutorialRuns) {
      candidates.push(extractTutorialAnalytics(run));
    }
  }
  const pick = (key) => {
    for (const entry of candidates) {
      if (entry[key] !== null && entry[key] !== undefined) return entry[key];
    }
    return null;
  };
  const attemptedRuns = pick("attemptedRuns");
  const completedRuns = pick("completedRuns");
  const completionRate =
    Number.isFinite(attemptedRuns) &&
    Number.isFinite(completedRuns) &&
    attemptedRuns > 0
      ? completedRuns / attemptedRuns
      : null;
  return {
    attemptedRuns,
    completedRuns,
    completionRate,
    skippedRuns: pick("skippedRuns"),
    assistsShown: pick("assistsShown"),
    replayedRuns: pick("replayedRuns")
  };
}

function buildPayload(sourceMap = SOURCE_MAP) {
  const sources = {
    smokeSummary: readJson(sourceMap.smokeSummary),
    tutorialPayload: readJson(sourceMap.tutorialPayload),
    ciMatrix: readJson(sourceMap.ciMatrix),
    goldSummarySmoke: readJson(sourceMap.goldSummarySmoke),
    goldSummaryE2E: readJson(sourceMap.goldSummaryE2E),
    screenshotSummary: readJson(sourceMap.screenshotSummary)
  };
  return {
    generatedAt: new Date().toISOString(),
    sources,
    tutorialMetrics: deriveTutorialMetrics(sources)
  };
}

function buildHtml(payload) {
  const encoded = JSON.stringify(payload);
  return `<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Keyboard Defense CI Dashboard</title>
    <style>
      :root {
        color-scheme: light dark;
        font-family: "Segoe UI", Tahoma, sans-serif;
      }
      body {
        margin: 0;
        padding: 2rem;
        background: #0f172a;
        color: #e2e8f0;
      }
      main {
        max-width: 960px;
        margin: 0 auto;
      }
      h1 {
        margin-bottom: 0.25rem;
      }
      section {
        background: #1e293b;
        border-radius: 12px;
        padding: 1.5rem;
        margin-bottom: 1.5rem;
        box-shadow: 0 15px 35px rgba(15, 23, 42, 0.45);
      }
      table {
        width: 100%;
        border-collapse: collapse;
        margin-top: 0.75rem;
      }
      th,
      td {
        border-bottom: 1px solid rgba(148, 163, 184, 0.25);
        padding: 0.4rem 0;
        text-align: left;
      }
      th {
        text-transform: uppercase;
        font-size: 0.75rem;
        letter-spacing: 0.08em;
        color: #a5b4fc;
      }
      .status-pill {
        display: inline-flex;
        align-items: center;
        gap: 0.3rem;
        padding: 0.2rem 0.75rem;
        border-radius: 999px;
        font-size: 0.8rem;
        font-weight: 600;
      }
      .status-success {
        background: rgba(16, 185, 129, 0.15);
        color: #4ade80;
      }
      .status-failed {
        background: rgba(239, 68, 68, 0.2);
        color: #f87171;
      }
      .status-unknown {
        background: rgba(148, 163, 184, 0.2);
        color: #cbd5f5;
      }
      .subtle {
        color: #94a3b8;
        font-size: 0.9rem;
      }
      @media (max-width: 640px) {
        body {
          padding: 1rem;
        }
        section {
          padding: 1rem;
        }
      }
    </style>
  </head>
  <body>
    <main>
      <header>
        <h1>Keyboard Defense CI Dashboard</h1>
        <p class="subtle">
          Generated at <span id="generatedAt"></span>. Displays the most recent smoke, matrix, breach,
          and gold metrics captured by CI.
        </p>
      </header>

      <section id="tutorial-section">
        <h2>Tutorial Smoke</h2>
        <div id="tutorial-content" class="subtle">No tutorial summary found.</div>
      </section>

      <section id="matrix-section">
        <h2>Scenario Matrix</h2>
        <div id="matrix-content" class="subtle">No matrix summary found.</div>
      </section>

      <section id="breach-section">
        <h2>Castle Breach Seeds</h2>
        <div id="breach-content" class="subtle">No breach runs recorded.</div>
      </section>

      <section id="gold-section">
        <h2>Gold Percentiles</h2>
        <div id="gold-content" class="subtle">No gold summary available.</div>
      </section>

      <section id="screens-section">
        <h2>HUD Screenshot Run</h2>
        <div id="screens-content" class="subtle">No screenshot summary captured.</div>
      </section>
    </main>

    <script>
      const DATA = ${encoded};

      const formatDate = (value) => {
        if (!value) return "-";
        const d = new Date(value);
        if (Number.isNaN(d.getTime())) return value;
        return d.toLocaleString();
      };

      const pill = (status) => {
        const normalized = (status ?? "unknown").toLowerCase();
        const map = {
          success: "status-success",
          passed: "status-success",
          ready: "status-success",
          failed: "status-failed",
          breached: "status-success",
          timeout: "status-failed"
        };
        const cls = map[normalized] ?? "status-unknown";
        return '<span class="status-pill ' + cls + '">' + (status ?? "unknown") + "</span>";
      };

      const formatCompletion = (completed, attempted, rate) => {
        const completedNum = Number(completed);
        const attemptedNum = Number(attempted);
        if (Number.isFinite(completedNum) && Number.isFinite(attemptedNum) && attemptedNum > 0) {
          const pct = Number.isFinite(rate) ? rate * 100 : (completedNum / attemptedNum) * 100;
          return completedNum + "/" + attemptedNum + " (" + pct.toFixed(1) + "%)";
        }
        if (Number.isFinite(completedNum)) return String(completedNum);
        return "-";
      };

      document.getElementById("generatedAt").textContent = formatDate(DATA.generatedAt);

      const tutorialTarget = document.getElementById("tutorial-content");
      const tutorialPayload = DATA.sources.tutorialPayload;
      const smokeSummary = DATA.sources.smokeSummary ?? tutorialPayload;
      const tutorialMetrics = DATA.tutorialMetrics ?? {};
      const tutorialAnalytics = tutorialPayload?.analytics ?? smokeSummary?.analytics ?? {};
      const attemptedRuns = Number.isFinite(tutorialMetrics.attemptedRuns)
        ? tutorialMetrics.attemptedRuns
        : Number.isFinite(tutorialAnalytics.attemptedRuns)
          ? tutorialAnalytics.attemptedRuns
          : null;
      const completedRuns = Number.isFinite(tutorialMetrics.completedRuns)
        ? tutorialMetrics.completedRuns
        : Number.isFinite(tutorialAnalytics.completedRuns)
          ? tutorialAnalytics.completedRuns
          : null;
      const skippedRuns = Number.isFinite(tutorialMetrics.skippedRuns)
        ? tutorialMetrics.skippedRuns
        : Number.isFinite(tutorialAnalytics.skippedRuns)
          ? tutorialAnalytics.skippedRuns
          : null;
      const assistsShown = Number.isFinite(tutorialMetrics.assistsShown)
        ? tutorialMetrics.assistsShown
        : Number.isFinite(tutorialAnalytics.assistsShown)
          ? tutorialAnalytics.assistsShown
          : null;
      const completionRate = formatCompletion(
        completedRuns,
        attemptedRuns,
        tutorialMetrics.completionRate
      );
      if (smokeSummary) {
        const rows = [
          ["Mode", smokeSummary.mode ?? "-"],
          ["Status", pill(smokeSummary.status)],
          ["Started", formatDate(smokeSummary.startedAt)],
          ["Finished", formatDate(smokeSummary.finishedAt ?? smokeSummary.capturedAt)],
          ["Duration (ms)", smokeSummary.durationMs ?? "-"],
          ["Completed runs", completedRuns ?? "-"],
          ["Attempted runs", attemptedRuns ?? "-"],
          ["Completion rate", completionRate],
          ["Skipped runs", skippedRuns ?? "-"],
          ["Assists shown", assistsShown ?? "-"]
        ];
        tutorialTarget.innerHTML =
          "<table>" +
          "<tbody>" +
          rows.map(([label, value]) => "<tr><th>" + label + "</th><td>" + value + "</td></tr>").join("") +
          "</tbody></table>";
      }

      const matrixTarget = document.getElementById("matrix-content");
      const matrix = DATA.sources.ciMatrix;
      if (matrix) {
        const aggs = matrix.aggregates ?? {};
        let html = "";
        if (Array.isArray(matrix.tutorialRuns) && matrix.tutorialRuns.length) {
          html += "<h3>Tutorial runs</h3><table><thead><tr><th>Mode</th><th>Status</th><th>Duration (ms)</th><th>Completions</th><th>Notes</th></tr></thead><tbody>";
          html += matrix.tutorialRuns
            .map((run) => {
              const duration =
                run.durationMs ??
                (run.finishedAt && run.startedAt
                  ? Date.parse(run.finishedAt) - Date.parse(run.startedAt) || ""
                  : "-");
              const completions = formatCompletion(run.completedRuns, run.attemptedRuns);
              return "<tr><td>" + run.mode + "</td><td>" + pill(run.status) + "</td><td>" + (duration ?? "-") + "</td><td>" + completions + "</td><td>" + (run.failureReason ?? "") + "</td></tr>";
            })
            .join("");
          html += "</tbody></table>";
        }
        html +=
          "<p>Median duration: <strong>" +
          (aggs.tutorialDuration?.p50 ?? "-") +
          " ms</strong> · P90: <strong>" +
          (aggs.tutorialDuration?.p90 ?? "-") +
          " ms</strong></p>";
        matrixTarget.innerHTML = html;
      }

      const breachTarget = document.getElementById("breach-content");
      const breaches = DATA.sources.ciMatrix?.breachRuns;
      if (Array.isArray(breaches) && breaches.length) {
        breachTarget.innerHTML =
          "<table><thead><tr><th>Seed</th><th>Status</th><th>Time to Breach (ms)</th><th>Notes</th></tr></thead><tbody>" +
          breaches
            .map(
              (run) =>
                "<tr><td>" +
                run.seed +
                "</td><td>" +
                pill(run.status) +
                "</td><td>" +
                (run.timeToBreachMs ?? "-") +
                "</td><td>" +
                (Array.isArray(run.failures) ? run.failures.join(", ") : run.failures ?? "") +
                "</td></tr>"
            )
            .join("") +
          "</tbody></table>" +
          "<p>Median: <strong>" +
          (DATA.sources.ciMatrix?.aggregates?.breachTime?.p50 ?? "-") +
          " ms</strong> · P90: <strong>" +
          (DATA.sources.ciMatrix?.aggregates?.breachTime?.p90 ?? "-") +
          " ms</strong></p>";
      }

      const goldTarget = document.getElementById("gold-content");
      const goldSummary =
        DATA.sources.goldSummaryE2E ??
        DATA.sources.goldSummarySmoke ??
        DATA.sources.ciMatrix?.goldSummary ??
        null;
      if (goldSummary) {
        const percentiles =
          goldSummary.percentiles ??
          goldSummary.summaryPercentiles ??
          goldSummary.goldSummaryPercentiles ??
          [];
        const lines = [
          ["Percentiles", Array.isArray(percentiles) ? percentiles.join(", ") : percentiles ?? "-"],
          ["Median gain", goldSummary.medianGain ?? "-"],
          ["P90 gain", goldSummary.p90Gain ?? "-"],
          ["Median spend", goldSummary.medianSpend ?? "-"],
          ["P90 spend", goldSummary.p90Spend ?? "-"]
        ];
        goldTarget.innerHTML =
          "<table><tbody>" +
          lines.map(([label, value]) => "<tr><th>" + label + "</th><td>" + value + "</td></tr>").join("") +
          "</tbody></table>";
      }

      const screenTarget = document.getElementById("screens-content");
      const screens = DATA.sources.screenshotSummary;
      if (screens) {
        screenTarget.innerHTML =
          "<p>Status: " +
          pill(screens.status ?? "unknown") +
          "</p>" +
          "<p>Shots captured: <strong>" +
          (Array.isArray(screens.screenshots) ? screens.screenshots.length : screens.count ?? "-") +
          "</strong></p>";
      }
    </script>
  </body>
</html>`;
}

function main() {
  const payload = buildPayload();

  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  fs.writeFileSync(path.join(OUTPUT_DIR, "dashboard-data.json"), JSON.stringify(payload, null, 2));
  fs.writeFileSync(path.join(OUTPUT_DIR, "index.html"), buildHtml(payload), "utf8");

  console.log(`[dashboard] Static dashboard written to ${OUTPUT_DIR}`);
}

const isCliInvocation =
  typeof process.argv[1] === "string" &&
  fileURLToPath(import.meta.url) === path.resolve(process.argv[1]);

if (isCliInvocation) {
  main();
}

export { buildHtml, buildPayload, deriveTutorialMetrics, readJson, SOURCE_MAP };
