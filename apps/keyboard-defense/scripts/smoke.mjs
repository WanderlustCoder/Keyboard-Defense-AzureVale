#!/usr/bin/env node
/**
 * Smoke test orchestrator.
 * Calls the tutorial smoke CLI in skip mode and stores a run artifact.
 */

import { spawn } from "node:child_process";
import { mkdir, writeFile, readFile } from "node:fs/promises";
import path from "node:path";
import process from "node:process";

const startedAt = new Date().toISOString();
const DASHBOARD_PERCENTILES = [25, 50, 90];
const DASHBOARD_PERCENTILES_ARG = DASHBOARD_PERCENTILES.join(",");
const AUDIO_INTENSITY_MIN = 0.5;
const AUDIO_INTENSITY_MAX = 1.5;
const AUDIO_INTENSITY_DEFAULT = 1;
const AUDIO_INTENSITY_THRESHOLD_DEFAULT = 5;

export function parseArgs(argv) {
  const opts = {
    ci: false,
    mode: "skip",
    audioIntensity: AUDIO_INTENSITY_DEFAULT,
    audioIntensityThreshold: AUDIO_INTENSITY_THRESHOLD_DEFAULT
  };
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (token === "--ci") {
      opts.ci = true;
    } else if (token === "--mode") {
      const next = argv[i + 1];
      if (next) {
        opts.mode = next;
        i += 1;
      }
    } else if (token === "--audio-intensity" || token === "--sound-intensity") {
      const next = argv[i + 1];
      if (!next) {
        throw new Error("Missing value for --audio-intensity.");
      }
      opts.audioIntensity = parseAudioIntensityValue(next);
      i += 1;
    } else if (token === "--audio-intensity-threshold") {
      const next = argv[i + 1];
      if (!next) {
        throw new Error("Missing value for --audio-intensity-threshold.");
      }
      opts.audioIntensityThreshold = parseIntensityThreshold(next);
      i += 1;
    }
  }
  return opts;
}

function clampAudioIntensity(value) {
  if (!Number.isFinite(value)) {
    return AUDIO_INTENSITY_DEFAULT;
  }
  return Math.max(AUDIO_INTENSITY_MIN, Math.min(AUDIO_INTENSITY_MAX, value));
}

function parseAudioIntensityValue(raw) {
  const cleaned = typeof raw === "string" ? raw.trim().replace(/%$/, "") : String(raw);
  const parsed = Number.parseFloat(cleaned);
  if (!Number.isFinite(parsed)) {
    throw new Error(`Invalid audio intensity value "${raw}".`);
  }
  const normalized = parsed > AUDIO_INTENSITY_MAX ? parsed / 100 : parsed;
  return clampAudioIntensity(normalized);
}

function parseIntensityThreshold(raw) {
  const parsed = Number.parseFloat(raw);
  if (!Number.isFinite(parsed) || parsed < 0) {
    throw new Error(`Invalid audio intensity threshold "${raw}".`);
  }
  return parsed;
}

async function run(command, args, options = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      stdio: "inherit",
      shell: options.shell ?? process.platform === "win32",
      ...options
    });
    child.on("error", reject);
    child.on("exit", (code) => {
      if (code === 0) resolve();
      else reject(new Error(`${command} ${args.join(" ")} exited with code ${code}`));
    });
  });
}

export async function validateSummaryPercentiles(summaryPath, expected) {
  let payload;
  try {
    const content = await readFile(summaryPath, "utf8");
    payload = JSON.parse(content);
  } catch (error) {
    throw new Error(
      `Failed to parse gold summary at ${summaryPath}: ${
        error instanceof Error ? error.message : String(error)
      }`
    );
  }
  if (!payload || typeof payload !== "object" || !Array.isArray(payload.percentiles)) {
    throw new Error(`Gold summary at ${summaryPath} is missing the percentiles metadata.`);
  }
  const normalized = payload.percentiles.map((value) => Number(value));
  const mismatch =
    normalized.length !== expected.length ||
    normalized.some((value, index) => value !== expected[index]);
  if (mismatch) {
    throw new Error(
      `Expected percentiles ${expected.join(",")} but found ${normalized.join(",")} in ${summaryPath}.`
    );
  }
  return normalized;
}

async function generateGoldEconomyArtifacts(inputPath, artifactDir, summary, ciMode) {
  const timelineName = ciMode ? "gold-timeline.ci.json" : "gold-timeline.json";
  const timelinePath = path.join(artifactDir, timelineName);
  summary.commands.push(
    `${process.execPath} ./scripts/goldTimeline.mjs --merge-passives --passive-window 8 --out ${timelinePath} ${inputPath}`
  );
  try {
    await run(
      process.execPath,
      [
        "./scripts/goldTimeline.mjs",
        "--merge-passives",
        "--passive-window",
        "8",
        "--out",
        timelinePath,
        inputPath
      ],
      {
        shell: false
      }
    );
    summary.goldTimeline = timelinePath;
  } catch (error) {
    summary.status = summary.status === "failed" ? summary.status : "warning";
    summary.goldTimelineError = error instanceof Error ? error.message : String(error);
    return;
  }

  const summaryName = ciMode ? "gold-summary.ci.json" : "gold-summary.json";
  const summaryPath = path.join(artifactDir, summaryName);
  summary.commands.push(
    `${process.execPath} ./scripts/goldSummary.mjs --global --percentiles ${DASHBOARD_PERCENTILES_ARG} --out ${summaryPath} ${timelinePath}`
  );
  try {
    await run(
      process.execPath,
      [
        "./scripts/goldSummary.mjs",
        "--global",
        "--percentiles",
        DASHBOARD_PERCENTILES_ARG,
        "--out",
        summaryPath,
        timelinePath
      ],
      { shell: false }
    );
    summary.goldSummary = summaryPath;
    if (path.extname(summaryPath).toLowerCase() === ".json") {
      const verified = await validateSummaryPercentiles(summaryPath, DASHBOARD_PERCENTILES);
      summary.goldSummaryPercentiles = verified;
    }
  } catch (error) {
    summary.status = summary.status === "failed" ? summary.status : "warning";
    summary.goldSummaryError = error instanceof Error ? error.message : String(error);
    if (summary.goldSummaryPercentiles === undefined) {
      summary.goldSummaryPercentiles = null;
    }
  }
}

function computeDriftPercent(recorded, requested) {
  if (!Number.isFinite(recorded) || !Number.isFinite(requested) || requested === 0) {
    return null;
  }
  return (Math.abs(recorded - requested) / Math.abs(requested)) * 100;
}

function formatNumber(value, precision = 2) {
  if (!Number.isFinite(value)) {
    return null;
  }
  const factor = 10 ** precision;
  return Math.round(value * factor) / factor;
}

function formatCsvValue(value, precision = 2) {
  if (value === null || value === undefined) {
    return "";
  }
  if (!Number.isFinite(value)) {
    return String(value);
  }
  const rounded = formatNumber(value, precision);
  return rounded === null ? "" : String(rounded);
}

function extractAccuracy(artifact) {
  if (!artifact || typeof artifact !== "object") {
    return { value: null, source: null };
  }
  const overlayAccuracy = artifact.summaryOverlay?.accuracy;
  if (typeof overlayAccuracy === "string") {
    const match = overlayAccuracy.match(/([0-9]+(?:\\.[0-9]+)?)%/);
    if (match) {
      return { value: Number.parseFloat(match[1]) / 100, source: "summary-overlay" };
    }
  }
  const tutorialAccuracy = artifact.analytics?.tutorial?.accuracy;
  if (Number.isFinite(tutorialAccuracy)) {
    return { value: tutorialAccuracy, source: "analytics-tutorial" };
  }
  const typingAccuracy =
    artifact.analytics?.typing?.accuracy ??
    artifact.state?.typing?.accuracy ??
    artifact.state?.analytics?.typingAccuracy;
  if (Number.isFinite(typingAccuracy)) {
    return { value: typingAccuracy, source: "analytics-typing" };
  }
  return { value: null, source: null };
}

function extractCombo(artifact) {
  if (!artifact || typeof artifact !== "object") {
    return { value: null, source: null };
  }
  const candidates = [
    { value: artifact.analytics?.sessionBestCombo, source: "analytics-sessionBestCombo" },
    { value: artifact.analytics?.maxCombo, source: "analytics-maxCombo" },
    { value: artifact.analytics?.tutorial?.comboPeak, source: "tutorial-comboPeak" },
    { value: artifact.state?.analytics?.sessionBestCombo, source: "state-sessionBestCombo" }
  ];
  for (const candidate of candidates) {
    if (Number.isFinite(candidate.value)) {
      return candidate;
    }
  }
  return { value: null, source: null };
}

function computeCorrelation(pairs) {
  if (!Array.isArray(pairs) || pairs.length < 2) {
    return null;
  }
  const xs = pairs.map((pair) => pair.x);
  const ys = pairs.map((pair) => pair.y);
  const meanX = xs.reduce((sum, value) => sum + value, 0) / xs.length;
  const meanY = ys.reduce((sum, value) => sum + value, 0) / ys.length;
  let numerator = 0;
  let denomX = 0;
  let denomY = 0;
  for (let i = 0; i < pairs.length; i += 1) {
    const dx = xs[i] - meanX;
    const dy = ys[i] - meanY;
    numerator += dx * dy;
    denomX += dx * dx;
    denomY += dy * dy;
  }
  if (denomX === 0 || denomY === 0) {
    return null;
  }
  return formatNumber(numerator / Math.sqrt(denomX * denomY), 3);
}

function analyzeAudioIntensity({ artifact, scenario, requestedIntensity }) {
  const telemetry = artifact?.audioIntensity ?? {};
  const recorded =
    typeof telemetry.recorded === "number" ? telemetry.recorded : telemetry.soundIntensity ?? null;
  const average =
    typeof telemetry.average === "number"
      ? telemetry.average
      : typeof telemetry.mean === "number"
        ? telemetry.mean
        : recorded;
  const delta = typeof telemetry.delta === "number" ? telemetry.delta : null;
  const history = Array.isArray(telemetry.history) ? telemetry.history : [];
  const historySamples =
    typeof telemetry.historySamples === "number" ? telemetry.historySamples : history.length;
  const comboPairs = history
    .map((entry) =>
      Number.isFinite(entry?.to) && Number.isFinite(entry?.combo)
        ? { x: entry.to, y: entry.combo }
        : null
    )
    .filter((entry) => entry);
  const accuracyPairs = history
    .map((entry) =>
      Number.isFinite(entry?.to) && Number.isFinite(entry?.accuracy)
        ? { x: entry.to, y: entry.accuracy }
        : null
    )
    .filter((entry) => entry);
  const accuracy = extractAccuracy(artifact);
  const combo = extractCombo(artifact);
  return {
    scenario,
    requestedIntensity,
    recordedIntensity: recorded,
    averageIntensity: average,
    intensityDelta: delta,
    durationMs: artifact?.durationMs ?? null,
    accuracy: accuracy.value,
    accuracySource: accuracy.source,
    combo: combo.value,
    comboSource: combo.source,
    historySamples,
    comboCorrelation: computeCorrelation(comboPairs),
    accuracyCorrelation: computeCorrelation(accuracyPairs),
    driftPercent: computeDriftPercent(recorded, requestedIntensity)
  };
}

async function writeAudioIntensitySummaries(analysis, { ci }) {
  const summariesDir = path.resolve("artifacts", "summaries");
  await mkdir(summariesDir, { recursive: true });
  const baseName = ci ? "audio-intensity.ci" : "audio-intensity";
  const jsonPath = path.join(summariesDir, `${baseName}.json`);
  const csvPath = path.join(summariesDir, `${baseName}.csv`);
  const payload = {
    generatedAt: new Date().toISOString(),
    runs: [analysis]
  };
  await writeFile(jsonPath, JSON.stringify(payload, null, 2), "utf8");
  const csvHeader = [
    "scenario",
    "requestedIntensity",
    "recordedIntensity",
    "averageIntensity",
    "intensityDelta",
    "accuracy",
    "combo",
    "durationMs",
    "historySamples",
    "comboCorrelation",
    "accuracyCorrelation",
    "driftPercent"
  ];
  const csvRow = [
    analysis.scenario ?? "",
    formatCsvValue(analysis.requestedIntensity, 3),
    formatCsvValue(analysis.recordedIntensity, 3),
    formatCsvValue(analysis.averageIntensity, 3),
    formatCsvValue(analysis.intensityDelta, 3),
    formatCsvValue(analysis.accuracy, 4),
    formatCsvValue(analysis.combo, 0),
    formatCsvValue(analysis.durationMs, 0),
    formatCsvValue(analysis.historySamples, 0),
    formatCsvValue(analysis.comboCorrelation, 3),
    formatCsvValue(analysis.accuracyCorrelation, 3),
    formatCsvValue(analysis.driftPercent, 2)
  ].join(",");
  await writeFile(csvPath, [csvHeader.join(","), csvRow].join("\n"), "utf8");
  return { jsonPath, csvPath };
}

async function main() {
  const opts = parseArgs(process.argv.slice(2));
  const artifactDir = path.resolve("artifacts", "smoke");
  await mkdir(artifactDir, { recursive: true });

  const summary = {
    status: "success",
    startedAt,
    finishedAt: null,
    mode: opts.mode,
    artifact: null,
    commands: []
  };

  const smokeArtifactPath = path.resolve("smoke-artifacts", "tutorial-smoke.json");
  let serverStarted = false;

  try {
    summary.commands.push(`${process.execPath} ./scripts/startMonitored.mjs`);
    await run(process.execPath, ["./scripts/startMonitored.mjs"], { shell: false });
    serverStarted = true;

    const tutorialArgs = [
      "./scripts/tutorialSmoke.mjs",
      "--mode",
      opts.mode,
      "--audio-intensity",
      String(opts.audioIntensity)
    ];
    summary.commands.push(`${process.execPath} ${tutorialArgs.join(" ")}`);
    await run(process.execPath, tutorialArgs, { shell: false });
    summary.artifact = smokeArtifactPath;

    let tutorialArtifactRaw = null;
    let tutorialArtifact = null;
    try {
      tutorialArtifactRaw = await readFile(smokeArtifactPath, "utf8");
      tutorialArtifact = JSON.parse(tutorialArtifactRaw);
    } catch (artifactError) {
      summary.status = summary.status === "failed" ? summary.status : "warning";
      summary.audioIntensityError =
        artifactError instanceof Error ? artifactError.message : String(artifactError);
    }

    await generateGoldEconomyArtifacts(smokeArtifactPath, artifactDir, summary, opts.ci);

    if (tutorialArtifact) {
      try {
        const audioAnalysis = analyzeAudioIntensity({
          artifact: tutorialArtifact,
          scenario: `tutorial-${opts.mode}`,
          requestedIntensity: opts.audioIntensity
        });
        summary.audioIntensity = audioAnalysis;
        const intensityArtifacts = await writeAudioIntensitySummaries(audioAnalysis, {
          ci: opts.ci
        });
        summary.audioIntensitySummary = intensityArtifacts.jsonPath;
        summary.audioIntensitySummaryCsv = intensityArtifacts.csvPath;
        if (
          typeof opts.audioIntensityThreshold === "number" &&
          audioAnalysis.driftPercent !== null &&
          audioAnalysis.driftPercent > opts.audioIntensityThreshold &&
          summary.status !== "failed"
        ) {
          summary.status = "warning";
          summary.audioIntensity.thresholdBreached = opts.audioIntensityThreshold;
        }
      } catch (audioError) {
        summary.status = summary.status === "failed" ? summary.status : "warning";
        summary.audioIntensityError =
          audioError instanceof Error ? audioError.message : String(audioError);
      }
    }

    if (opts.ci) {
      try {
        const payload = tutorialArtifactRaw ?? (await readFile(smokeArtifactPath, "utf8"));
        await writeFile(path.join(artifactDir, "smoke-payload.json"), payload, "utf8");
      } catch (readError) {
        summary.status = "warning";
        summary.note = "Smoke run succeeded but artifact could not be copied.";
        summary.error = readError instanceof Error ? readError.message : String(readError);
      }
    }
  } catch (error) {
    summary.status = "failed";
    summary.error = error instanceof Error ? error.message : String(error);
  } finally {
    if (serverStarted) {
      summary.commands.push(`${process.execPath} ./scripts/devServer.mjs stop`);
      try {
        await run(process.execPath, ["./scripts/devServer.mjs", "stop"], { shell: false });
      } catch (stopError) {
        summary.status = summary.status === "failed" ? summary.status : "warning";
        summary.stopError = stopError instanceof Error ? stopError.message : String(stopError);
      }
    }

    summary.finishedAt = new Date().toISOString();
    const summaryPath = path.join(
      artifactDir,
      opts.ci ? "smoke-summary.ci.json" : "smoke-summary.json"
    );
    await writeFile(summaryPath, JSON.stringify(summary, null, 2), "utf8");
    if (summary.status === "failed") {
      process.exitCode = 1;
    }
  }
}

if (import.meta.url === `file://${process.argv[1]}` || process.argv[1]?.endsWith("smoke.mjs")) {
  await main();
}
