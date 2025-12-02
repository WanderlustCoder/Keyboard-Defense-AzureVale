#!/usr/bin/env node
/**
 * Automated difficulty tuning powered by playtest-bot artifacts.
 *
 * Scans one or more playtest-bot JSON summaries, aggregates accuracy/WPM, and
 * emits a set of tuning recommendations:
 *   - difficultyBiasDelta: adjust baseline dynamic difficulty bias
 *   - wordWeightShifts: move word weights toward or away from harder tiers
 *   - spawnSpeedMultiplier: suggested multiplicative tweak for spawn cadence
 *
 * Usage examples:
 *   node scripts/analytics/difficultyTuning.mjs
 *   node scripts/analytics/difficultyTuning.mjs --inputs artifacts/summaries --out artifacts/summaries/difficulty-tuning.json
 *   node scripts/analytics/difficultyTuning.mjs --inputs artifacts/summaries/playtest-bot*.json --md artifacts/summaries/difficulty-tuning.md
 *
 * Defaults target the standard playtest-bot artifact path:
 *   artifacts/summaries/playtest-bot*.json
 */

import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";

const DEFAULT_INPUTS = [path.resolve("artifacts", "summaries", "playtest-bot*.json")];
const DEFAULT_OUT_JSON = path.resolve("artifacts", "summaries", "difficulty-tuning.json");
const DEFAULT_OUT_MD = path.resolve("artifacts", "summaries", "difficulty-tuning.md");

const TARGET_ACCURACY = 0.95; // 95% accuracy comfort target for ages 8-16
const TARGET_WPM = 45; // comfortable sustained pace target

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}

function escapeForRegex(text) {
  return text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function parseArgs(argv = []) {
  const args = {
    inputs: [...DEFAULT_INPUTS],
    outJson: DEFAULT_OUT_JSON,
    outMd: DEFAULT_OUT_MD
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--inputs":
        args.inputs = (argv[++i] ?? "")
          .split(",")
          .map((p) => p.trim())
          .filter(Boolean)
          .map((p) => path.isAbsolute(p) ? p : path.resolve(p));
        if (args.inputs.length === 0) {
          args.inputs = [...DEFAULT_INPUTS];
        }
        break;
      case "--out":
      case "--out-json":
        args.outJson = path.resolve(argv[++i] ?? DEFAULT_OUT_JSON);
        break;
      case "--md":
        args.outMd = path.resolve(argv[++i] ?? DEFAULT_OUT_MD);
        break;
      case "--help":
      case "-h":
        printHelp();
        process.exit(0);
        break;
      default:
        if (token && token.startsWith("-")) {
          throw new Error(`Unknown option: ${token}`);
        }
        break;
    }
  }

  return args;
}

function printHelp() {
  console.log(`difficultyTuning - analyze playtest-bot runs and suggest difficulty nudges

Options:
  --inputs <paths>     Comma-separated files/dirs/globs (default: ${DEFAULT_INPUTS.join(", ")})
  --out-json <path>    Where to write JSON recommendations (default: ${DEFAULT_OUT_JSON})
  --md <path>          Optional Markdown summary output (default: ${DEFAULT_OUT_MD})
  --help               Show this help

Examples:
  node scripts/analytics/difficultyTuning.mjs
  node scripts/analytics/difficultyTuning.mjs --inputs artifacts/summaries --md artifacts/summaries/difficulty-tuning.md
`);
}

async function expandPattern(pattern) {
  const hasWildcard = pattern.includes("*");
  const resolved = path.resolve(pattern);
  let stat;

  try {
    stat = await fs.stat(resolved);
  } catch {
    // best-effort for wildcard path or missing entry
  }

  if (stat?.isDirectory()) {
    const entries = await fs.readdir(resolved);
    return entries
      .filter((entry) => entry.toLowerCase().endsWith(".json"))
      .map((entry) => path.join(resolved, entry));
  }

  if (!hasWildcard) {
    return stat?.isFile() ? [resolved] : [];
  }

  const dir = path.dirname(resolved);
  const base = path.basename(resolved);
  let files = [];
  try {
    files = await fs.readdir(dir);
  } catch {
    return [];
  }
  const regex = new RegExp(`^${escapeForRegex(base).replace(/\\\*/g, ".*")}$`, "i");
  return files.filter((entry) => regex.test(entry)).map((entry) => path.join(dir, entry));
}

async function resolveInputs(inputs) {
  const discovered = [];
  for (const input of inputs) {
    const expanded = await expandPattern(input);
    discovered.push(...expanded);
  }
  const unique = Array.from(new Set(discovered));
  unique.sort();
  return unique;
}

async function readJson(filePath) {
  try {
    const raw = await fs.readFile(filePath, "utf8");
    return JSON.parse(raw);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.warn(`difficultyTuning: unable to read ${filePath} (${message})`);
    return null;
  }
}

function normalizeNumber(value) {
  const n = Number(value);
  return Number.isFinite(n) ? n : null;
}

function summarizeRun(filePath, data) {
  const accuracy = normalizeNumber(data?.state?.accuracy);
  const wpm = normalizeNumber(data?.state?.wpm);
  const wave = normalizeNumber(data?.state?.waveIndex ?? data?.state?.wave);
  const words = normalizeNumber(data?.state?.wordsCompleted ?? data?.wordsTyped);

  return {
    file: filePath,
    accuracy,
    wpm,
    waveIndex: wave,
    wordsCompleted: words,
    durationMs: normalizeNumber(data?.durationMs ?? data?.durationRequestedMs),
    errors: Array.isArray(data?.errors) ? data.errors.filter(Boolean) : []
  };
}

function aggregateRuns(runs) {
  const metrics = {
    count: runs.length,
    accuracy: [],
    wpm: [],
    wave: [],
    words: [],
    errored: 0
  };

  for (const run of runs) {
    if (run.errors.length > 0) {
      metrics.errored += 1;
    }
    if (run.accuracy !== null) metrics.accuracy.push(run.accuracy);
    if (run.wpm !== null) metrics.wpm.push(run.wpm);
    if (run.waveIndex !== null) metrics.wave.push(run.waveIndex);
    if (run.wordsCompleted !== null) metrics.words.push(run.wordsCompleted);
  }

  const avg = (arr) => (arr.length === 0 ? null : arr.reduce((a, b) => a + b, 0) / arr.length);

  return {
    count: metrics.count,
    avgAccuracy: avg(metrics.accuracy),
    avgWpm: avg(metrics.wpm),
    avgWave: avg(metrics.wave),
    avgWords: avg(metrics.words),
    errored: metrics.errored
  };
}

function deriveRecommendations(stats) {
  const notes = [];

  let difficultyBiasDelta = 0;
  if (stats.avgAccuracy !== null) {
    if (stats.avgAccuracy > TARGET_ACCURACY + 0.02) {
      difficultyBiasDelta += 0.1;
      notes.push("High accuracy; nudging bias upward toward harder content.");
    } else if (stats.avgAccuracy < TARGET_ACCURACY - 0.03) {
      difficultyBiasDelta -= 0.1;
      notes.push("Accuracy below target; biasing easier content to protect confidence.");
    }
  }
  if (stats.avgWpm !== null) {
    if (stats.avgWpm > TARGET_WPM + 15) {
      difficultyBiasDelta += 0.05;
      notes.push("High WPM; adding a small pacing bump.");
    } else if (stats.avgWpm < TARGET_WPM - 10) {
      difficultyBiasDelta -= 0.05;
      notes.push("Low WPM; easing pacing slightly.");
    }
  }
  difficultyBiasDelta = clamp(difficultyBiasDelta, -0.3, 0.3);

  let wordWeightShifts = { easy: 0, medium: 0, hard: 0 };
  if (stats.avgAccuracy !== null) {
    if (stats.avgAccuracy > TARGET_ACCURACY + 0.02) {
      wordWeightShifts = { easy: -0.1, medium: 0.05, hard: 0.05 };
      notes.push("Shift 10% weight from easy toward medium/hard.");
    } else if (stats.avgAccuracy < TARGET_ACCURACY - 0.03) {
      wordWeightShifts = { easy: 0.1, medium: -0.05, hard: -0.05 };
      notes.push("Shift 10% weight toward easy to stabilize accuracy.");
    }
  }

  // Spawn cadence suggestion mirrors the bias but keeps within a gentle window.
  const spawnSpeedMultiplier = clamp(1 + difficultyBiasDelta * 0.4, 0.88, 1.12);

  return {
    difficultyBiasDelta,
    wordWeightShifts,
    spawnSpeedMultiplier,
    targetAccuracy: TARGET_ACCURACY,
    targetWpm: TARGET_WPM,
    notes
  };
}

async function writeJson(outPath, payload) {
  await fs.mkdir(path.dirname(outPath), { recursive: true });
  await fs.writeFile(outPath, JSON.stringify(payload, null, 2));
}

async function writeMarkdown(outPath, payload) {
  const lines = [];
  lines.push("# Difficulty Tuning Recommendations");
  lines.push("");
  lines.push(`Runs analyzed: ${payload.runsAnalyzed}`);
  lines.push(
    `Average accuracy: ${payload.averages.accuracy !== null ? (payload.averages.accuracy * 100).toFixed(2) + "%" : "n/a"}`
  );
  lines.push(
    `Average WPM: ${payload.averages.wpm !== null ? payload.averages.wpm.toFixed(2) : "n/a"}`
  );
  lines.push("");
  lines.push("## Recommendations");
  lines.push(`- difficultyBiasDelta: ${payload.recommendations.difficultyBiasDelta.toFixed(2)}`);
  lines.push(
    `- wordWeightShifts: easy ${payload.recommendations.wordWeightShifts.easy >= 0 ? "+" : ""}${payload.recommendations.wordWeightShifts.easy.toFixed(2)}, ` +
      `medium ${payload.recommendations.wordWeightShifts.medium >= 0 ? "+" : ""}${payload.recommendations.wordWeightShifts.medium.toFixed(2)}, ` +
      `hard ${payload.recommendations.wordWeightShifts.hard >= 0 ? "+" : ""}${payload.recommendations.wordWeightShifts.hard.toFixed(2)}`
  );
  lines.push(
    `- spawnSpeedMultiplier: ${payload.recommendations.spawnSpeedMultiplier.toFixed(3)} (apply to spawn cadence or enemy speed in config)`
  );
  if (payload.recommendations.notes.length > 0) {
    lines.push("");
    lines.push("Notes:");
    for (const note of payload.recommendations.notes) {
      lines.push(`- ${note}`);
    }
  }
  lines.push("");
  lines.push("## Runs");
  lines.push("| File | Accuracy | WPM | Wave | Errors |");
  lines.push("| --- | --- | --- | --- | --- |");
  for (const run of payload.runs) {
    const acc = run.accuracy !== null ? `${(run.accuracy * 100).toFixed(2)}%` : "n/a";
    const wpm = run.wpm !== null ? run.wpm.toFixed(1) : "n/a";
    const wave = run.waveIndex ?? "n/a";
    const errorText = run.errors.length > 0 ? run.errors.join("; ") : "";
    lines.push(`| ${path.basename(run.file)} | ${acc} | ${wpm} | ${wave} | ${errorText} |`);
  }
  const contents = lines.join("\n");
  await fs.mkdir(path.dirname(outPath), { recursive: true });
  await fs.writeFile(outPath, contents, "utf8");
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const files = await resolveInputs(args.inputs);

  if (files.length === 0) {
    console.error("difficultyTuning: no playtest-bot artifacts found. Provide --inputs or run playtest bot first.");
    process.exitCode = 1;
    return;
  }

  const runs = [];
  for (const file of files) {
    const data = await readJson(file);
    if (!data) continue;
    runs.push(summarizeRun(file, data));
  }

  const stats = aggregateRuns(runs);
  const recommendations = deriveRecommendations(stats);
  const payload = {
    runsAnalyzed: runs.length,
    erroredRuns: stats.errored,
    averages: {
      accuracy: stats.avgAccuracy,
      wpm: stats.avgWpm,
      wave: stats.avgWave,
      wordsCompleted: stats.avgWords
    },
    recommendations,
    runs
  };

  await writeJson(args.outJson, payload);
  if (args.outMd) {
    await writeMarkdown(args.outMd, payload);
  }

  console.log(`difficultyTuning: analyzed ${runs.length} run(s). JSON -> ${args.outJson}`);
  if (args.outMd) {
    console.log(`difficultyTuning: markdown -> ${args.outMd}`);
  }
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exitCode = 1;
});
