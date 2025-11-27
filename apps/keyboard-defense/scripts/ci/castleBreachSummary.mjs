#!/usr/bin/env node

import { promises as fs } from "node:fs";
import path from "node:path";
import process from "node:process";

const DEFAULT_TARGETS = [
  "artifacts/castle-breach.ci.json",
  "artifacts/e2e/castle-breach.ci.json"
];
const DEFAULT_SUMMARY_PATH = "artifacts/summaries/castle-breach.ci.json";
const DEFAULT_MODE = (process.env.CASTLE_BREACH_SUMMARY_MODE ?? "warn").toLowerCase();
const DEFAULT_MAX_TIME_MS = Number(process.env.CASTLE_BREACH_MAX_TIME_MS ?? 20000);
const DEFAULT_MIN_DAMAGE = Number(process.env.CASTLE_BREACH_MIN_DAMAGE ?? 5);
const VALID_MODES = new Set(["fail", "warn", "info"]);

function printHelp() {
  console.log(`Castle Breach Summary

Usage:
  node scripts/ci/castleBreachSummary.mjs [options] [artifact ...]

Options:
  --summary <path>         Output JSON path (default: ${DEFAULT_SUMMARY_PATH})
  --mode <fail|warn|info>  Failure behaviour when warnings occur (default: ${DEFAULT_MODE})
  --max-time-ms <n>        Maximum acceptable breach time in milliseconds (default: ${DEFAULT_MAX_TIME_MS})
  --min-damage <n>         Minimum expected castle damage when a breach occurs (default: ${DEFAULT_MIN_DAMAGE})
  --help                   Show this message

Arguments:
  artifact                 Breach artifact file or directory. Defaults to: ${DEFAULT_TARGETS.join(
    ", "
  )}
`);
}

function toNumber(value) {
  const num = Number(value);
  return Number.isFinite(num) ? num : null;
}

export function parseArgs(argv = []) {
  const options = {
    summaryPath: DEFAULT_SUMMARY_PATH,
    mode: DEFAULT_MODE,
    maxTimeMs: DEFAULT_MAX_TIME_MS,
    minDamage: DEFAULT_MIN_DAMAGE,
    targets: [],
    help: false
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--summary":
        options.summaryPath = argv[++i] ?? options.summaryPath;
        break;
      case "--mode":
        options.mode = (argv[++i] ?? options.mode).toLowerCase();
        break;
      case "--max-time-ms":
        options.maxTimeMs = toNumber(argv[++i]) ?? options.maxTimeMs;
        break;
      case "--min-damage":
        options.minDamage = toNumber(argv[++i]) ?? options.minDamage;
        break;
      case "--help":
        options.help = true;
        break;
      default:
        if (token.startsWith("-")) {
          throw new Error(`Unknown option "${token}". Use --help for usage.`);
        }
        options.targets.push(token);
    }
  }

  if (!VALID_MODES.has(options.mode)) {
    throw new Error(
      `Invalid mode "${options.mode}". Use one of: ${Array.from(VALID_MODES).join(", ")}.`
    );
  }

  if (options.targets.length === 0) {
    options.targets = [...DEFAULT_TARGETS];
  }

  return options;
}

async function collectArtifacts(targets) {
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

async function readJson(filePath) {
  const content = await fs.readFile(filePath, "utf8");
  return JSON.parse(content);
}

function summarizeTurrets(list) {
  if (!Array.isArray(list) || list.length === 0) return "none";
  return list
    .map((entry) => {
      const slot = entry.slotId ?? "slot";
      const type = entry.typeId ?? entry.type ?? "unknown";
      const level = toNumber(entry.level) ?? 1;
      return `${slot}:${type}${level > 1 ? `@${level}` : ""}`;
    })
    .join(", ");
}

function summarizeEnemies(list) {
  if (!Array.isArray(list) || list.length === 0) return "default";
  return list
    .map((entry) => {
      const tier = entry.tierId ?? entry.tier ?? "unknown";
      const lane = entry.lane ?? entry.laneIndex ?? "?";
      return `${tier}@L${lane}`;
    })
    .join(", ");
}

export function normalizeBreachPayload(payload, filePath) {
  const metrics = payload?.metrics ?? {};
  const scenario =
    payload?.options?.scenario ??
    payload?.options?.artifactLabel ??
    path.basename(filePath).replace(/\.json$/i, "");
  const status = payload?.status ?? "unknown";
  const timeMs =
    toNumber(metrics.timeToBreachMs) ??
    (payload?.breach?.time !== undefined ? Math.round(payload.breach.time * 1000) : null);
  const timeSeconds =
    toNumber(metrics.timeToBreachSeconds) ??
    (timeMs !== null ? Number((timeMs / 1000).toFixed(3)) : null);
  const castleHpStart =
    toNumber(metrics.castleHpStart) ??
    toNumber(payload?.finalState?.castleMaxHealth) ??
    toNumber(payload?.breach?.maxHealth);
  const castleHpEnd =
    toNumber(metrics.castleHpEnd) ??
    toNumber(payload?.finalState?.castleHealth) ??
    toNumber(payload?.breach?.healthAfter);
  let damageTaken = toNumber(metrics.damageTaken);
  if (!Number.isFinite(damageTaken) && Number.isFinite(castleHpStart) && Number.isFinite(castleHpEnd)) {
    damageTaken = Number((castleHpStart - castleHpEnd).toFixed(3));
  }
  const enemySpecs =
    (Array.isArray(payload?.options?.enemySpecs) && payload.options.enemySpecs.length > 0
      ? payload.options.enemySpecs
      : [
          {
            tierId: payload?.options?.tier ?? payload?.options?.enemyTier,
            lane: payload?.options?.lane ?? payload?.options?.enemyLane
          }
        ]) ?? [];
  const turrets = Array.isArray(payload?.turretPlacements)
    ? payload.turretPlacements
    : Array.isArray(payload?.options?.turrets)
    ? payload.options.turrets
    : [];
  return {
    file: filePath,
    scenario,
    status,
    timeMs,
    timeSeconds,
    castleHpStart,
    castleHpEnd,
    damageTaken,
    enemySpecs,
    enemiesLabel: summarizeEnemies(enemySpecs),
    turrets,
    turretsLabel: summarizeTurrets(turrets),
    passiveUnlockSummary: payload?.passiveUnlockSummary ?? null,
    warnings: [],
    breachSummary: payload?.breach ?? null
  };
}

function evaluateRow(row, options) {
  const warnings = [];
  if (row.status !== "breached") {
    warnings.push(`run ended with status "${row.status}"`);
  }
  if (Number.isFinite(row.timeMs) && Number.isFinite(options.maxTimeMs)) {
    if (row.timeMs > options.maxTimeMs) {
      warnings.push(`time-to-breach ${row.timeMs}ms exceeds limit ${options.maxTimeMs}ms`);
    }
  }
  if (Number.isFinite(row.damageTaken) && Number.isFinite(options.minDamage)) {
    if (row.damageTaken < options.minDamage) {
      warnings.push(
        `damage taken ${row.damageTaken} is below minimum ${options.minDamage} (possible partial breach)`
      );
    }
  }
  if (!Number.isFinite(row.damageTaken) && row.status === "breached") {
    warnings.push("breach detected but damage metrics missing");
  }
  return warnings;
}

function average(values) {
  const filtered = values.filter((value) => Number.isFinite(value));
  if (filtered.length === 0) return null;
  const sum = filtered.reduce((acc, value) => acc + value, 0);
  return Number((sum / filtered.length).toFixed(2));
}

export function buildSummary(rows, options) {
  const warnings = [];
  let breaches = 0;
  for (const row of rows) {
    const rowWarnings = evaluateRow(row, options);
    row.warnings = rowWarnings;
    if (row.status === "breached") breaches += 1;
    warnings.push(...rowWarnings.map((warning) => `${row.scenario}: ${warning}`));
  }
  const summary = {
    generatedAt: new Date().toISOString(),
    mode: options.mode,
    summaryPath: options.summaryPath,
    thresholds: {
      maxTimeMs: options.maxTimeMs,
      minDamage: options.minDamage
    },
    rows,
    warnings,
    metrics: {
      scenarios: rows.length,
      breaches,
      averageTimeMs: average(rows.map((row) => row.timeMs)),
      averageDamage: average(rows.map((row) => row.damageTaken))
    }
  };
  return summary;
}

export function buildMarkdown(summary) {
  const lines = [];
  lines.push("## Castle Breach Watch");
  lines.push(
    `Scenarios: ${summary.metrics.scenarios} · Breaches: ${summary.metrics.breaches} · Avg Time: ${
      summary.metrics.averageTimeMs ?? "n/a"
    } ms`
  );
  lines.push("");
  if (summary.rows.length > 0) {
    lines.push("| Scenario | Status | Time (s) | Damage | Turrets | Enemies |");
    lines.push("| --- | --- | --- | --- | --- | --- |");
    for (const row of summary.rows) {
      const statusBadge =
        row.status === "breached"
          ? row.warnings.length > 0
            ? "⚠️ Breached"
            : "✅ Breached"
          : "❌ Timeout";
      const damageLabel = Number.isFinite(row.damageTaken) ? row.damageTaken : "n/a";
      lines.push(
        `| ${row.scenario} | ${statusBadge} | ${row.timeSeconds ?? "n/a"} | ${damageLabel} | ${
          row.turretsLabel
        } | ${row.enemiesLabel} |`
      );
    }
    lines.push("");
  } else {
    lines.push("_No castle breach artifacts found._");
    lines.push("");
  }
  if (summary.warnings.length > 0) {
    lines.push("**Warnings**");
    for (const warning of summary.warnings) {
      lines.push(`- ${warning}`);
    }
    lines.push("");
  }
  lines.push(`Summary JSON: \`${summary.summaryPath}\``);
  return lines.join("\n");
}

async function appendStepSummary(markdown) {
  const target = process.env.GITHUB_STEP_SUMMARY;
  if (target) {
    await fs.appendFile(target, `${markdown}\n`);
  } else {
    console.log(markdown);
  }
}

async function writeSummary(summaryPath, payload) {
  const absolute = path.resolve(summaryPath);
  await fs.mkdir(path.dirname(absolute), { recursive: true });
  await fs.writeFile(absolute, JSON.stringify(payload, null, 2), "utf8");
}

export async function runSummary(options) {
  const files = await collectArtifacts(options.targets);
  if (files.length === 0) {
    throw new Error("No castle breach artifacts found. Provide at least one file or directory.");
  }
  const rows = [];
  for (const file of files) {
    try {
      const payload = await readJson(file);
      rows.push(normalizeBreachPayload(payload, file));
    } catch (error) {
      console.warn(error instanceof Error ? error.message : String(error));
    }
  }
  if (rows.length === 0) {
    throw new Error("Artifacts were found but none could be parsed.");
  }
  const summary = buildSummary(rows, options);
  await writeSummary(options.summaryPath, summary);
  await appendStepSummary(buildMarkdown(summary));
  if (summary.warnings.length > 0 && options.mode === "fail") {
    throw new Error(
      `${summary.warnings.length} castle breach warning(s) detected. See ${options.summaryPath}.`
    );
  }
  return summary;
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

  try {
    await runSummary(options);
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
  }
}

if (
  import.meta.url === `file://${process.argv[1]}` ||
  process.argv[1]?.endsWith("castleBreachSummary.mjs")
) {
  await main();
}
