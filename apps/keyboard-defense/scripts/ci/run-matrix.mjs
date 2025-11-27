#!/usr/bin/env node
/**
 * Scenario matrix runner.
 * Executes tutorial smoke modes and castle breach drills across multiple variants,
 * aggregates medians/p90s, and writes artifacts/ci-matrix-summary.json.
 */
import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const APP_ROOT = path.resolve(__dirname, "..", "..");
const DEFAULT_OUTPUT = path.join(APP_ROOT, "artifacts", "ci-matrix-summary.json");
const MATRIX_DIR = path.join(APP_ROOT, "artifacts", "ci-matrix");

function parseList(value, fallback) {
  if (!value) return [...fallback];
  return value
    .split(",")
    .map((entry) => entry.trim())
    .filter(Boolean);
}

function parseNumberList(value, fallback) {
  if (!value) return [...fallback];
  return value
    .split(",")
    .map((entry) => Number(entry.trim()))
    .filter((num) => Number.isFinite(num));
}

function parseArgs(argv) {
  const options = {
    tutorialModes: undefined,
    breachSeeds: undefined,
    output: DEFAULT_OUTPUT,
    dryRun: false
  };
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--tutorial-modes":
        options.tutorialModes = parseList(argv[++i] ?? "", []);
        break;
      case "--breach-seeds":
        options.breachSeeds = parseNumberList(argv[++i] ?? "", []);
        break;
      case "--output":
        options.output = path.resolve(APP_ROOT, argv[++i] ?? DEFAULT_OUTPUT);
        break;
      case "--dry-run":
        options.dryRun = true;
        break;
      case "--help":
      case "-h":
        printHelp();
        process.exit(0);
        break;
      default:
        if (token?.startsWith("-")) {
          throw new Error(`Unknown option "${token}". Use --help for usage.`);
        }
        break;
    }
  }
  options.tutorialModes = options.tutorialModes?.length
    ? options.tutorialModes
    : ["skip", "full"];
  options.breachSeeds = options.breachSeeds?.length ? options.breachSeeds : [2025, 1337];
  return options;
}

function printHelp() {
  console.log(`Keyboard Defense CI matrix runner

Usage:
  node scripts/ci/run-matrix.mjs [options]

Options:
  --tutorial-modes <list>   Comma-separated tutorial smoke modes (default skip,full)
  --breach-seeds <list>     Comma-separated castle breach seeds (default 2025,1337)
  --output <path>           Output JSON path (default artifacts/ci-matrix-summary.json)
  --dry-run                 Print the planned matrix without executing anything
  --help                    Show this message

Example:
  node scripts/ci/run-matrix.mjs --tutorial-modes skip,campaign --breach-seeds 42,77
`);
}

function readJson(file) {
  if (!fs.existsSync(file)) return null;
  try {
    return JSON.parse(fs.readFileSync(file, "utf8"));
  } catch (error) {
    console.warn(`[matrix] Failed to parse ${file}: ${error instanceof Error ? error.message : error}`);
    return null;
  }
}

function copyFileIfPossible(source, destination) {
  if (!source || !fs.existsSync(source)) return;
  fs.mkdirSync(path.dirname(destination), { recursive: true });
  fs.copyFileSync(source, destination);
}

function quantile(values, percentile) {
  if (!values.length) return null;
  const sorted = [...values].sort((a, b) => a - b);
  const idx = Math.max(
    0,
    Math.min(sorted.length - 1, Math.round((percentile / 100) * (sorted.length - 1)))
  );
  return sorted[idx];
}

function deriveDurationMs(primary, secondary) {
  if (primary && Number.isFinite(primary.durationMs)) {
    return primary.durationMs;
  }
  const start = secondary?.startedAt ?? primary?.startedAt;
  const end = secondary?.finishedAt ?? primary?.capturedAt;
  if (!start || !end) return null;
  const startTs = Date.parse(start);
  const endTs = Date.parse(end);
  if (!Number.isFinite(startTs) || !Number.isFinite(endTs)) return null;
  return Math.max(0, endTs - startTs);
}

async function runCommand(command, args) {
  execFileSync(process.execPath, [command, ...args], {
    cwd: APP_ROOT,
    stdio: "inherit",
    env: { ...process.env }
  });
}

async function runTutorialMode(mode, matrixDir) {
  await runCommand("./scripts/smoke.mjs", ["--ci", "--mode", mode]);
  const tutorialPayloadPath = path.join(APP_ROOT, "smoke-artifacts", "tutorial-smoke.json");
  const smokeSummaryPath = path.join(APP_ROOT, "artifacts", "smoke", "smoke-summary.ci.json");
  const tutorialData = readJson(tutorialPayloadPath) ?? {};
  const smokeSummary = readJson(smokeSummaryPath) ?? {};
  const variantDir = path.join(matrixDir, "tutorial");
  copyFileIfPossible(
    tutorialPayloadPath,
    path.join(variantDir, `tutorial-${mode}-payload.json`)
  );
  copyFileIfPossible(
    smokeSummaryPath,
    path.join(variantDir, `tutorial-${mode}-summary.json`)
  );
  return {
    mode,
    status: tutorialData.status ?? smokeSummary.status ?? "unknown",
    durationMs: deriveDurationMs(tutorialData, smokeSummary),
    startedAt: smokeSummary.startedAt ?? tutorialData.startedAt ?? null,
    finishedAt: smokeSummary.finishedAt ?? tutorialData.capturedAt ?? null,
    skippedRuns: tutorialData.analytics?.skippedRuns ?? null,
    assistsShown: tutorialData.analytics?.assistsShown ?? null,
    failureReason: tutorialData.error ?? smokeSummary.error ?? null
  };
}

async function runBreachSeed(seed, matrixDir) {
  const breachDir = path.join(matrixDir, "breach");
  fs.mkdirSync(breachDir, { recursive: true });
  const artifactPath = path.join(breachDir, `breach-seed-${seed}.json`);
  await runCommand("./scripts/castleBreachReplay.mjs", [
    "--seed",
    String(seed),
    "--artifact",
    artifactPath
  ]);
  const data = readJson(artifactPath) ?? {};
  return {
    seed,
    status: data.status ?? data.result ?? "unknown",
    timeToBreachMs: data.timeToBreachMs ?? null,
    breached: data.breached ?? (data.status === "breached"),
    failures: data.failures ?? null
  };
}

function appendStepSummary(summary, options) {
  const target = process.env.GITHUB_STEP_SUMMARY;
  if (!target) return;
  const lines = [];
  lines.push("## Scenario Matrix");
  lines.push("");
  lines.push(
    `Tutorial modes: ${options.tutorialModes.join(", ")} | Breach seeds: ${options.breachSeeds.join(", ")}`
  );
  lines.push("");
  if (summary.tutorialRuns.length) {
    lines.push("| Tutorial Mode | Status | Duration ms | Skipped Runs | Notes |");
    lines.push("| --- | --- | --- | --- | --- |");
    for (const run of summary.tutorialRuns) {
      lines.push(
        `| ${run.mode} | ${run.status} | ${run.durationMs ?? "-"} | ${
          run.skippedRuns ?? "-"
        } | ${run.failureReason ?? ""} |`
      );
    }
    lines.push("");
  }
  if (summary.breachRuns.length) {
    lines.push("| Breach Seed | Status | Time to Breach ms | Notes |");
    lines.push("| --- | --- | --- | --- |");
    for (const run of summary.breachRuns) {
      lines.push(
        `| ${run.seed} | ${run.status} | ${run.timeToBreachMs ?? "-"} | ${
          run.failures ? JSON.stringify(run.failures) : ""
        } |`
      );
    }
    lines.push("");
  }
  lines.push(
    `Tutorial duration median: ${summary.aggregates.tutorialDuration.p50 ?? "-"} ms · p90: ${
      summary.aggregates.tutorialDuration.p90 ?? "-"
    } ms`
  );
  lines.push(
    `Breach time median: ${summary.aggregates.breachTime.p50 ?? "-"} ms · p90: ${
      summary.aggregates.breachTime.p90 ?? "-"
    } ms`
  );
  fs.appendFileSync(target, `${lines.join("\n")}\n`);
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

  if (options.dryRun) {
    console.log(
      JSON.stringify(
        {
          tutorialModes: options.tutorialModes,
          breachSeeds: options.breachSeeds,
          output: options.output
        },
        null,
        2
      )
    );
    return;
  }

  fs.mkdirSync(MATRIX_DIR, { recursive: true });

  const tutorialRuns = [];
  const breachRuns = [];
  const errors = [];

  for (const mode of options.tutorialModes) {
    try {
      tutorialRuns.push(await runTutorialMode(mode, MATRIX_DIR));
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      console.error(`[matrix] Tutorial mode "${mode}" failed: ${message}`);
      tutorialRuns.push({ mode, status: "failed", durationMs: null, failureReason: message });
      errors.push(`tutorial:${mode}`);
    }
  }

  for (const seed of options.breachSeeds) {
    try {
      breachRuns.push(await runBreachSeed(seed, MATRIX_DIR));
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      console.error(`[matrix] Breach seed "${seed}" failed: ${message}`);
      breachRuns.push({ seed, status: "failed", timeToBreachMs: null, failures: message });
      errors.push(`breach:${seed}`);
    }
  }

  const tutorialDurations = tutorialRuns
    .map((run) => run.durationMs)
    .filter((value) => Number.isFinite(value));
  const breachTimes = breachRuns
    .map((run) => run.timeToBreachMs)
    .filter((value) => Number.isFinite(value));

  const summary = {
    generatedAt: new Date().toISOString(),
    tutorialModes: options.tutorialModes,
    breachSeeds: options.breachSeeds,
    tutorialRuns,
    breachRuns,
    aggregates: {
      tutorialDuration: {
        p50: quantile(tutorialDurations, 50),
        p90: quantile(tutorialDurations, 90)
      },
      breachTime: {
        p50: quantile(breachTimes, 50),
        p90: quantile(breachTimes, 90)
      }
    }
  };

  fs.mkdirSync(path.dirname(options.output), { recursive: true });
  fs.writeFileSync(options.output, JSON.stringify(summary, null, 2));
  console.log(`[matrix] Summary written to ${options.output}`);
  appendStepSummary(summary, options);

  if (errors.length > 0) {
    console.error(`[matrix] ${errors.length} scenario(s) failed: ${errors.join(", ")}`);
    process.exitCode = 1;
  }
}

await main();
