#!/usr/bin/env node

import { promises as fs } from "node:fs";
import path from "node:path";
import process from "node:process";

const DEFAULT_TELEMETRY = "artifacts/summaries/asset-integrity.json";
const DEFAULT_HISTORY = "artifacts/history/asset-integrity.log";
const DEFAULT_OUT_JSON = "artifacts/summaries/asset-integrity-report.json";
const DEFAULT_OUT_MD = "artifacts/summaries/asset-integrity-report.md";
const VALID_MODES = new Set(["fail", "warn"]);
const HISTORY_LIMIT = 10;

function printHelp() {
  console.log(`Asset Integrity Summary

Usage:
  node scripts/ci/assetIntegritySummary.mjs [options] [telemetry ...]

Options:
  --telemetry <path>  Telemetry JSON file or directory (default: ${DEFAULT_TELEMETRY})
  --history <path>    History log path (default: ${DEFAULT_HISTORY})
  --out-json <path>   Output JSON summary path (default: ${DEFAULT_OUT_JSON})
  --markdown <path>   Markdown output path (default: ${DEFAULT_OUT_MD})
  --mode <fail|warn>  Failure mode when warnings exist (default: fail)
  --help              Show this help message

Arguments:
  telemetry           Additional telemetry files or directories to include.`);
}

function parseArgs(argv) {
  const options = {
    telemetryPaths: [],
    historyPath: DEFAULT_HISTORY,
    outJson: DEFAULT_OUT_JSON,
    markdown: DEFAULT_OUT_MD,
    mode: "fail",
    help: false
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--telemetry":
        options.telemetryPaths.push(argv[++i] ?? "");
        break;
      case "--history":
        options.historyPath = argv[++i] ?? options.historyPath;
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
        options.telemetryPaths.push(token);
        break;
    }
  }

  if (!VALID_MODES.has(options.mode)) {
    throw new Error(`Invalid mode '${options.mode}'. Use fail or warn.`);
  }

  if (options.telemetryPaths.length === 0) {
    options.telemetryPaths.push(DEFAULT_TELEMETRY);
  }

  return {
    ...options,
    historyPath: options.historyPath ? path.resolve(options.historyPath) : null,
    outJson: options.outJson ? path.resolve(options.outJson) : null,
    markdown: options.markdown ? path.resolve(options.markdown) : null,
    telemetryPaths: options.telemetryPaths.map((entry) => path.resolve(entry))
  };
}

async function readJson(filePath) {
  const content = await fs.readFile(filePath, "utf8");
  return JSON.parse(content);
}

async function collectTelemetry(paths) {
  const entries = [];
  const warnings = [];
  for (const target of paths) {
    let stats;
    try {
      stats = await fs.stat(target);
    } catch {
      warnings.push(`Telemetry path not found: ${target}`);
      continue;
    }
    if (stats.isDirectory()) {
      const files = await fs.readdir(target);
      for (const file of files) {
        if (!file.toLowerCase().endsWith(".json")) continue;
        const absolute = path.join(target, file);
        try {
          entries.push(await readJson(absolute));
        } catch (error) {
          warnings.push(`${absolute}: ${error?.message ?? error}`);
        }
      }
    } else {
      try {
        entries.push(await readJson(target));
      } catch (error) {
        warnings.push(`${target}: ${error?.message ?? error}`);
      }
    }
  }
  return { entries, warnings };
}

async function readHistory(historyPath) {
  if (!historyPath) return [];
  try {
    const content = await fs.readFile(historyPath, "utf8");
    const lines = content.split(/\r?\n/).filter(Boolean);
    return lines.slice(-HISTORY_LIMIT).map((line) => {
      try {
        return JSON.parse(line);
      } catch {
        return null;
      }
    }).filter(Boolean);
  } catch (error) {
    if (error?.code === "ENOENT") {
      return [];
    }
    throw error;
  }
}

function normalizeEntry(entry) {
  if (!entry || typeof entry !== "object") return null;
  return {
    scenario: entry.scenario ?? "",
    manifest: entry.manifest ?? "",
    strictMode: Boolean(entry.strictMode),
    mode: entry.mode ?? "",
    checked: entry.checked ?? 0,
    missingHash: entry.missingHash ?? 0,
    failed: entry.failed ?? 0,
    extraEntries: entry.extraEntries ?? 0,
    totalImages: entry.totalImages ?? 0,
    timestamp: entry.timestamp ?? null,
    durationMs: entry.durationMs ?? null,
    firstFailure: entry.firstFailure ?? null
  };
}

function buildSummary({ telemetryEntries, historyEntries, warnings }) {
  const normalized = telemetryEntries.map(normalizeEntry).filter(Boolean);
  const latest = normalized[normalized.length - 1] ?? historyEntries.map(normalizeEntry).filter(Boolean).pop() ?? null;
  const totals = normalized.reduce(
    (acc, entry) => {
      acc.runs += 1;
      acc.checked += entry.checked ?? 0;
      acc.missing += entry.missingHash ?? 0;
      acc.failed += entry.failed ?? 0;
      return acc;
    },
    { runs: 0, checked: 0, missing: 0, failed: 0 }
  );
  return {
    generatedAt: new Date().toISOString(),
    latest,
    entries: normalized,
    history: historyEntries.map(normalizeEntry).filter(Boolean),
    totals,
    warnings: [...warnings]
  };
}

function formatMarkdown(summary) {
  const lines = [];
  lines.push("## Asset Integrity Summary");
  lines.push(`Generated: ${summary.generatedAt}`);
  lines.push("");
  if (summary.latest) {
    const latest = summary.latest;
    lines.push(`Scenario: ${latest.scenario || "unknown"}`);
    lines.push(`Manifest: ${latest.manifest || "?"}`);
    lines.push(
      `Checked: ${latest.checked} • Missing: ${latest.missingHash} • Failed: ${latest.failed} • Extra: ${latest.extraEntries}`
    );
    lines.push(`Strict mode: ${latest.strictMode ? "yes" : "no"} • Timestamp: ${latest.timestamp ?? "n/a"}`);
    if (latest.firstFailure) {
      const failure = latest.firstFailure;
      const location = failure.path ? `${failure.key} (${failure.path})` : failure.key;
      lines.push(`First failure: ${location} [${failure.type}]`);
    }
    lines.push("");
  } else {
    lines.push("_No telemetry entries found._");
    lines.push("");
  }
  if (summary.entries.length > 0) {
    lines.push("| Scenario | Checked | Missing | Failed | Strict | Timestamp |");
    lines.push("| --- | --- | --- | --- | --- | --- |");
    for (const entry of summary.entries) {
      lines.push(
        `| ${entry.scenario || "unknown"} | ${entry.checked} | ${entry.missingHash} | ${entry.failed} | ${
          entry.strictMode ? "✅" : "⚠️"
        } | ${entry.timestamp ?? ""} |`
      );
    }
    lines.push("");
  }
  if (summary.warnings.length > 0) {
    lines.push("### Warnings");
    for (const warning of summary.warnings) {
      lines.push(`- ${warning}`);
    }
    lines.push("");
  }
  if (summary.history.length > 0) {
    lines.push("### History (latest)");
    lines.push("| Scenario | Checked | Missing | Failed | Timestamp |");
    lines.push("| --- | --- | --- | --- | --- |");
    for (const entry of summary.history.slice(-5)) {
      lines.push(
        `| ${entry.scenario || "unknown"} | ${entry.checked} | ${entry.missingHash} | ${entry.failed} | ${
          entry.timestamp ?? ""
        } |`
      );
    }
    lines.push("");
  }
  if (summary.outputs?.json) {
    lines.push(`JSON: \`${summary.outputs.json}\``);
  }
  if (summary.outputs?.markdown) {
    lines.push(`Markdown: \`${summary.outputs.markdown}\``);
  }
  return lines.join("\n");
}

async function appendStepSummary(markdown) {
  const summaryFile = process.env.GITHUB_STEP_SUMMARY;
  if (!summaryFile) {
    console.log(markdown);
    return;
  }
  await fs.appendFile(summaryFile, `${markdown}\n`);
}

async function writeFileEnsuringDir(targetPath, contents) {
  if (!targetPath) return;
  await fs.mkdir(path.dirname(targetPath), { recursive: true });
  await fs.writeFile(targetPath, contents);
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

  const { entries, warnings } = await collectTelemetry(options.telemetryPaths);
  const historyEntries = await readHistory(options.historyPath);
  if (entries.length === 0 && historyEntries.length === 0) {
    warnings.push("No telemetry or history entries found.");
  }
  const summary = buildSummary({
    telemetryEntries: entries,
    historyEntries,
    warnings
  });
  summary.outputs = {
    json: options.outJson ? path.relative(process.cwd(), options.outJson) : null,
    markdown: options.markdown ? path.relative(process.cwd(), options.markdown) : null
  };

  if (options.outJson) {
    await writeFileEnsuringDir(options.outJson, `${JSON.stringify(summary, null, 2)}\n`);
  }
  const markdown = formatMarkdown(summary);
  if (options.markdown) {
    await writeFileEnsuringDir(options.markdown, `${markdown}\n`);
  }
  await appendStepSummary(markdown);

  if (summary.warnings.length > 0 && options.mode === "fail") {
    throw new Error(
      `${summary.warnings.length} asset integrity warning(s) detected. See ${options.outJson ?? "logs"}.`
    );
  }
}

if (
  import.meta.url === `file://${process.argv[1]}` ||
  process.argv[1]?.endsWith("assetIntegritySummary.mjs")
) {
  main().catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
  });
}

export {
  parseArgs,
  collectTelemetry,
  readHistory,
  buildSummary,
  formatMarkdown
};
