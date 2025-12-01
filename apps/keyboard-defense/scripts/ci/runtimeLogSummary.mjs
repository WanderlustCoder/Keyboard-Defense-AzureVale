#!/usr/bin/env node

import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import { pathToFileURL } from "node:url";

const DEFAULT_INPUTS = [
  "artifacts/monitor",
  "artifacts/monitor/*.log",
  "artifacts/monitor/*.json",
  ".devserver/server.log"
];

const DEFAULT_OUTPUT_JSON = "artifacts/summaries/runtime-log-summary.json";
const DEFAULT_OUTPUT_MD = "artifacts/summaries/runtime-log-summary.md";

const BREACH_KEYS = ["breaches", "sessionBreaches", "breachCount"];
const ACCURACY_KEYS = ["accuracy", "accuracyPct", "sessionAccuracy", "accuracyPercent"];

function log(message) {
  console.log(`[runtime-log-summary] ${message}`);
}

function isGlobPattern(input) {
  return ["*", "?", "["].some((char) => input.includes(char));
}

export function parseArgs(argv = process.argv.slice(2)) {
  const options = {
    inputs: [...DEFAULT_INPUTS],
    outJson: DEFAULT_OUTPUT_JSON,
    outMarkdown: DEFAULT_OUTPUT_MD,
    help: false
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--input":
      case "-i": {
        const value = argv[++i];
        if (!value) throw new Error("Expected path after --input");
        options.inputs.push(value);
        break;
      }
      case "--out-json":
        options.outJson = argv[++i];
        break;
      case "--out-md":
      case "--out-markdown":
        options.outMarkdown = argv[++i];
        break;
      case "--no-md":
        options.outMarkdown = null;
        break;
      case "--no-json":
        options.outJson = null;
        break;
      case "--help":
      case "-h":
        options.help = true;
        break;
      default:
        if (token.startsWith("-")) throw new Error(`Unknown option: ${token}`);
    }
  }

  options.inputs = Array.from(new Set(options.inputs));
  return options;
}

async function pathExists(target) {
  try {
    await fs.stat(target);
    return true;
  } catch {
    return false;
  }
}

async function listFiles(target) {
  const files = [];
  const stat = await fs.stat(target);
  if (stat.isDirectory()) {
    const entries = await fs.readdir(target, { withFileTypes: true });
    for (const entry of entries) {
      const full = path.join(target, entry.name);
      if (entry.isDirectory()) {
        files.push(...(await listFiles(full)));
      } else {
        files.push(full);
      }
    }
  } else {
    files.push(target);
  }
  return files;
}

async function expandInputs(inputs) {
  const files = new Set();
  for (const input of inputs) {
    if (isGlobPattern(input)) {
      const [dir, pattern] = splitGlob(input);
      const matched = await globFiles(dir, pattern);
      matched.forEach((m) => files.add(m));
    } else if (await pathExists(input)) {
      const resolved = path.resolve(input);
      const expanded = await listFiles(resolved);
      expanded.forEach((m) => files.add(m));
    }
  }
  return Array.from(files);
}

function splitGlob(pattern) {
  const parts = pattern.split(/[/\\]/);
  const idx = parts.findIndex((p) => isGlobPattern(p));
  if (idx === -1) return [pattern, null];
  const base = parts.slice(0, idx).join(path.sep) || ".";
  const rest = parts.slice(idx).join(path.sep);
  return [base, rest];
}

async function globFiles(dir, pattern) {
  const results = [];
  const entries = await fs.readdir(dir, { withFileTypes: true }).catch(() => []);
  for (const entry of entries) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      results.push(...(await globFiles(full, pattern)));
    } else if (matchesPattern(entry.name, pattern)) {
      results.push(full);
    }
  }
  return results;
}

function matchesPattern(name, pattern) {
  if (!pattern) return true;
  const escaped = pattern.replace(/\./g, "\\.").replace(/\*/g, ".*").replace(/\?/g, ".");
  const regex = new RegExp(`^${escaped}$`);
  return regex.test(name);
}

function extractNumber(entry, keys) {
  for (const key of keys) {
    if (entry && Object.prototype.hasOwnProperty.call(entry, key)) {
      const value = Number(entry[key]);
      if (Number.isFinite(value)) return value;
    }
  }
  if (entry?.analytics) {
    const nested = extractNumber(entry.analytics, keys);
    if (Number.isFinite(nested)) return nested;
  }
  return null;
}

function parseLines(content) {
  const lines = content.split(/\r?\n/);
  const entries = [];
  let warnCount = 0;
  let errorCount = 0;
  for (const line of lines) {
    if (!line.trim()) continue;
    const lower = line.toLowerCase();
    if (lower.includes("error")) errorCount += 1;
    if (lower.includes("warn")) warnCount += 1;
    const parsed = tryParseJson(line.trim());
    if (parsed) {
      entries.push(parsed);
      continue;
    }
    const metrics = {};
    const breachMatch = line.match(/breach(?:es)?[:=]\s*([0-9.]+)/i);
    if (breachMatch) metrics.breaches = Number(breachMatch[1]);
    const accMatch = line.match(/accuracy[:=]\s*([0-9.]+)/i);
    if (accMatch) metrics.accuracy = Number(accMatch[1]);
    if (Object.keys(metrics).length) entries.push(metrics);
  }
  return { entries, warn: warnCount, error: errorCount };
}

function tryParseJson(payload) {
  if (!payload.startsWith("{") && !payload.startsWith("[")) return null;
  try {
    return JSON.parse(payload);
  } catch {
    return null;
  }
}

async function parseFile(filePath) {
  const content = await fs.readFile(filePath, "utf8");
  const json = tryParseJson(content.trim());
  if (json !== null) {
    const entries = Array.isArray(json) ? json : [json];
    return { entries, warn: 0, error: 0 };
  }
  return parseLines(content);
}

export async function summarizeLogs(files) {
  const summary = {
    files: [],
    events: 0,
    breaches: { sum: 0, max: 0 },
    accuracy: { last: null },
    warnings: 0,
    errors: 0
  };

  for (const file of files) {
    // eslint-disable-next-line no-await-in-loop
    const { entries, warn: warnCount, error: errorCount } = await parseFile(file);
    summary.files.push(file);
    summary.warnings += warnCount;
    summary.errors += errorCount;
    for (const entry of entries) {
      summary.events += 1;
      const breaches = extractNumber(entry, BREACH_KEYS);
      if (Number.isFinite(breaches)) {
        summary.breaches.sum += breaches;
        summary.breaches.max = Math.max(summary.breaches.max, breaches);
      }
      const accuracy = extractNumber(entry, ACCURACY_KEYS);
      if (Number.isFinite(accuracy)) {
        summary.accuracy.last = accuracy;
      }
    }
  }

  return summary;
}

function formatMarkdown(summary) {
  const lines = [];
  lines.push("# Runtime Log Summary");
  lines.push("");
  lines.push(
    `Files scanned: ${summary.files.length} · Events parsed: ${summary.events} · Warnings: ${summary.warnings} · Errors: ${summary.errors}`
  );
  lines.push(
    `Breaches (sum/max): ${summary.breaches.sum} / ${summary.breaches.max} · Last accuracy: ${
      summary.accuracy.last ?? "-"
    }`
  );
  lines.push("");
  lines.push("| Metric | Value |");
  lines.push("| --- | --- |");
  lines.push(`| Events | ${summary.events} |`);
  lines.push(`| Breaches sum | ${summary.breaches.sum} |`);
  lines.push(`| Breaches max | ${summary.breaches.max} |`);
  lines.push(`| Last accuracy | ${summary.accuracy.last ?? "-"} |`);
  lines.push(`| Warnings | ${summary.warnings} |`);
  lines.push(`| Errors | ${summary.errors} |`);
  return lines.join("\n");
}

async function writeIfPath(target, content) {
  if (!target) return;
  const resolved = path.resolve(target);
  await fs.mkdir(path.dirname(resolved), { recursive: true });
  await fs.writeFile(resolved, content, "utf8");
}

async function main(argv = process.argv.slice(2)) {
  const options = parseArgs(argv);
  if (options.help) {
    console.log(`runtimeLogSummary

Aggregate runtime logs into a breach/accuracy summary for dashboards.

Usage:
  node scripts/ci/runtimeLogSummary.mjs [--input <path|glob>] [--out-json <file>] [--out-md <file>]

Options:
  --input, -i    Additional file/glob/directory to scan (repeatable).
  --out-json     Output JSON path (default: ${DEFAULT_OUTPUT_JSON}, pass --no-json to skip).
  --out-md       Output Markdown path (default: ${DEFAULT_OUTPUT_MD}, pass --no-md to skip).
  --help, -h     Show this help text.
`);
    return;
  }

  const files = await expandInputs(options.inputs);
  if (!files.length) {
    throw new Error("No log files found. Provide at least one --input path or glob.");
  }

  log(`Scanning ${files.length} file(s)...`);
  const summary = await summarizeLogs(files);
  if (options.outJson) {
    await writeIfPath(options.outJson, JSON.stringify(summary, null, 2));
    log(`JSON summary written to ${options.outJson}`);
  }
  if (options.outMarkdown) {
    await writeIfPath(options.outMarkdown, formatMarkdown(summary));
    log(`Markdown summary written to ${options.outMarkdown}`);
  }
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch((error) => {
    console.error(`[runtime-log-summary] ${error.message}`);
    process.exitCode = 1;
  });
}
