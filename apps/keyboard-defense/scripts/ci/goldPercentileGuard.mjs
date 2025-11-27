#!/usr/bin/env node

import { promises as fs } from "node:fs";
import path from "node:path";
import process from "node:process";

import { collectGoldSummaryResults } from "../goldSummaryCheck.mjs";

const DEFAULT_PERCENTILES = [25, 50, 90];
const DEFAULT_TARGETS = ["artifacts/smoke", "artifacts/e2e"];
const DEFAULT_SUMMARY_PATH = "artifacts/summaries/gold-percentile-guard.ci.json";
const VALID_MODES = new Set(["fail", "warn"]);

function parsePercentileList(raw) {
  if (!raw) return null;
  const values = raw
    .split(",")
    .map((part) => Number.parseFloat(part.trim()))
    .filter((value) => Number.isFinite(value));
  if (values.length === 0) {
    throw new Error("Percentile list must contain numeric values.");
  }
  if (values.some((value) => value < 0 || value > 100)) {
    throw new Error("Percentiles must fall between 0 and 100.");
  }
  return values;
}

function printHelp() {
  console.log(`Gold Percentile Guard

Usage:
  node scripts/ci/goldPercentileGuard.mjs [options] [target ...]

Options:
  --percentiles <list>   Override expected percentile cutlines (comma-separated).
  --mode <fail|warn>     Control failure behavior (default: fail).
  --summary <path>       Output JSON summary path (default: ${DEFAULT_SUMMARY_PATH}).
  --help                 Show this message.

Arguments:
  target                 File or directory containing gold summary artifacts.
                         Defaults to ${DEFAULT_TARGETS.join(", ")} when omitted.
`);
}

function parseArgs(argv) {
  const envPercentiles = parsePercentileList(process.env.GOLD_PERCENTILES ?? "");
  const options = {
    percentiles: envPercentiles ?? [...DEFAULT_PERCENTILES],
    mode: (process.env.GOLD_GUARD_MODE ?? "fail").toLowerCase(),
    summaryPath: process.env.GOLD_GUARD_SUMMARY ?? DEFAULT_SUMMARY_PATH,
    targets: [],
    help: false
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--percentiles": {
        const value = argv[++i];
        if (!value) throw new Error("Expected list after --percentiles.");
        options.percentiles = parsePercentileList(value);
        break;
      }
      case "--mode": {
        const value = argv[++i];
        if (!value) throw new Error("Expected value after --mode.");
        options.mode = value.toLowerCase();
        if (!VALID_MODES.has(options.mode)) {
          throw new Error(`Invalid mode '${value}'. Use one of: ${Array.from(VALID_MODES).join(", ")}.`);
        }
        break;
      }
      case "--summary": {
        const value = argv[++i];
        if (!value) throw new Error("Expected path after --summary.");
        options.summaryPath = value;
        break;
      }
      case "--help":
        options.help = true;
        break;
      default:
        if (token.startsWith("-")) {
          throw new Error(`Unknown option: ${token}`);
        }
        options.targets.push(token);
        break;
    }
  }

  if (!VALID_MODES.has(options.mode)) {
    throw new Error(`Invalid mode '${options.mode}'. Use one of: ${Array.from(VALID_MODES).join(", ")}.`);
  }

  if (options.targets.length === 0) {
    options.targets = [...DEFAULT_TARGETS];
  }

  return options;
}

function buildMarkdown(summary) {
  const lines = [];
  lines.push("## Gold Percentile Guard");
  lines.push(`Mode: \`${summary.mode}\``);
  lines.push(`Expected percentiles: \`${summary.percentiles.join(", ")}\``);
  lines.push(`Checked files: **${summary.totals.checked}**, Failures: **${summary.totals.failures}**`);
  lines.push("");
  if (summary.files.length === 0) {
    lines.push("_No gold summary artifacts found._");
  } else {
    lines.push("| File | Status | Details |");
    lines.push("| --- | --- | --- |");
    for (const file of summary.files) {
      const status = file.ok ? "✅ Pass" : "❌ Fail";
      lines.push(`| ${file.path} | ${status} | ${file.error ?? ""} |`);
    }
  }
  lines.push("");
  lines.push(`Summary JSON: \`${summary.summaryPath}\``);
  return lines.join("\n");
}

async function writeSummary(summaryPath, payload) {
  const absolute = path.resolve(summaryPath);
  await fs.mkdir(path.dirname(absolute), { recursive: true });
  await fs.writeFile(absolute, JSON.stringify(payload, null, 2));
}

async function appendStepSummary(markdown) {
  const target = process.env.GITHUB_STEP_SUMMARY;
  if (!target) {
    console.log(markdown);
    return;
  }
  await fs.appendFile(target, `${markdown}\n`);
}

async function runGuard(options) {
  const results = await collectGoldSummaryResults(options.targets, options.percentiles);
  const normalized = results.map((entry) => ({
    path: path.relative(process.cwd(), entry.file),
    ok: entry.ok,
    error: entry.error
  }));
  const summary = {
    generatedAt: new Date().toISOString(),
    mode: options.mode,
    percentiles: options.percentiles,
    totals: {
      checked: normalized.length,
      failures: normalized.filter((entry) => !entry.ok).length
    },
    files: normalized,
    summaryPath: options.summaryPath
  };
  await writeSummary(options.summaryPath, summary);
  const markdown = buildMarkdown(summary);
  await appendStepSummary(markdown);
  if (summary.totals.failures > 0 && options.mode === "fail") {
    throw new Error(
      `${summary.totals.failures} gold summary artifact(s) failed percentile validation. See ${options.summaryPath}.`
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
    await runGuard(options);
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    if (options?.mode === "warn") {
      process.exitCode = 0;
    } else {
      process.exitCode = 1;
    }
  }
}

if (
  import.meta.url === `file://${process.argv[1]}` ||
  process.argv[1]?.endsWith("goldPercentileGuard.mjs")
) {
  await main();
}
