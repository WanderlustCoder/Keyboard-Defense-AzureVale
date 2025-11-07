#!/usr/bin/env node

import { promises as fs } from "node:fs";
import path from "node:path";
import process from "node:process";

const SUPPORTED_EXTS = new Set([".json", ".csv"]);
const DEFAULT_PERCENTILES = [25, 50, 90];

function printHelp() {
  console.log(`Keyboard Defense gold summary integrity checker

Usage:
  node scripts/goldSummaryCheck.mjs [options] <file-or-directory> [...]

Options:
  --percentiles <list>   Expected percentile cutlines (comma-separated, default 25,50,90)
  --help                 Show this message

Description:
  Validates that each gold summary artifact embeds the requested percentile list:
    • JSON: expects { percentiles: number[], rows: [...] }
    • CSV: expects a "summaryPercentiles" column whose values match the list (pipe-delimited)
  Any deviation causes a non-zero exit so dashboards/alerts can detect mismatches early.`);
}

export function parseArgs(argv = []) {
  const options = {
    percentiles: [...DEFAULT_PERCENTILES],
    targets: [],
    help: false
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--percentiles": {
        const value = argv[++i];
        if (!value) throw new Error("Expected list after --percentiles");
        const parsed = value
          .split(",")
          .map((part) => Number.parseFloat(part.trim()))
          .filter((num) => Number.isFinite(num));
        if (parsed.length === 0) {
          throw new Error("Provide at least one numeric percentile between 0 and 100.");
        }
        if (parsed.some((num) => num < 0 || num > 100)) {
          throw new Error("Percentiles must fall within 0-100.");
        }
        options.percentiles = parsed;
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
    }
  }

  if (!options.help && options.targets.length === 0) {
    throw new Error("Provide at least one file or directory to validate.");
  }

  return options;
}

async function resolveTargets(targets) {
  const files = [];
  for (const target of targets) {
    const absolute = path.resolve(target);
    let stat;
    try {
      stat = await fs.stat(absolute);
    } catch {
      continue;
    }
    if (stat.isDirectory()) {
      const entries = await fs.readdir(absolute);
      for (const entry of entries) {
        const candidate = path.join(absolute, entry);
        const ext = path.extname(candidate).toLowerCase();
        if (SUPPORTED_EXTS.has(ext)) {
          files.push(candidate);
        }
      }
    } else {
      const ext = path.extname(absolute).toLowerCase();
      if (SUPPORTED_EXTS.has(ext)) {
        files.push(absolute);
      }
    }
  }
  return files;
}

async function readJson(file) {
  const content = await fs.readFile(file, "utf8");
  try {
    return JSON.parse(content);
  } catch (error) {
    throw new Error(
      `Failed to parse JSON from ${file}: ${error instanceof Error ? error.message : String(error)}`
    );
  }
}

function normalizePercentiles(list) {
  return list.map((value) => Number(value));
}

function comparePercentiles(actual, expected) {
  if (actual.length !== expected.length) return false;
  for (let i = 0; i < actual.length; i += 1) {
    if (Number(actual[i]) !== Number(expected[i])) return false;
  }
  return true;
}

function splitCsvLine(line) {
  const values = [];
  let current = "";
  let inQuotes = false;
  for (let i = 0; i < line.length; i += 1) {
    const char = line[i];
    if (inQuotes) {
      if (char === '"') {
        if (line[i + 1] === '"') {
          current += '"';
          i += 1;
        } else {
          inQuotes = false;
        }
      } else {
        current += char;
      }
    } else if (char === '"') {
      inQuotes = true;
    } else if (char === ",") {
      values.push(current);
      current = "";
    } else {
      current += char;
    }
  }
  values.push(current);
  return values;
}

async function verifyJsonFile(file, expected) {
  const payload = await readJson(file);
  if (!payload || typeof payload !== "object" || !Array.isArray(payload.percentiles)) {
    throw new Error(`${file}: missing percentiles metadata.`);
  }
  const normalized = normalizePercentiles(payload.percentiles);
  if (!comparePercentiles(normalized, expected)) {
    throw new Error(
      `${file}: percentiles mismatch. Expected ${expected.join(",")} but found ${normalized.join(",")}.`
    );
  }
}

async function verifyCsvFile(file, expected) {
  const content = await fs.readFile(file, "utf8");
  const lines = content
    .trim()
    .split(/\r?\n/)
    .filter((line) => line.length > 0);
  if (lines.length === 0) {
    throw new Error(`${file}: empty CSV file.`);
  }
  const headers = splitCsvLine(lines[0]);
  const columnIndex = headers.findIndex((header) => header === "summaryPercentiles");
  if (columnIndex === -1) {
    throw new Error(`${file}: missing summaryPercentiles column.`);
  }
  for (let i = 1; i < lines.length; i += 1) {
    const cells = splitCsvLine(lines[i]);
    const value = cells[columnIndex];
    if (!value) {
      throw new Error(`${file}: summaryPercentiles column empty on line ${i + 1}.`);
    }
    const normalized = value.split("|").map((part) => Number(part.trim()));
    if (!comparePercentiles(normalized, expected)) {
      throw new Error(
        `${file}: percentiles mismatch on line ${i + 1}. Expected ${expected.join(
          ","
        )} but found ${normalized.join(",")}.`
      );
    }
  }
}

export async function runGoldSummaryCheck(options) {
  const files = await resolveTargets(options.targets);
  if (files.length === 0) {
    throw new Error("No gold summary files found. Supported extensions: .json, .csv");
  }
  const expected = options.percentiles;
  const failures = [];
  for (const file of files) {
    try {
      const ext = path.extname(file).toLowerCase();
      if (ext === ".json") {
        await verifyJsonFile(file, expected);
      } else if (ext === ".csv") {
        await verifyCsvFile(file, expected);
      } else {
        throw new Error(`${file}: unsupported file type.`);
      }
      console.log(`✔ ${file} (percentiles: ${expected.join(",")})`);
    } catch (error) {
      failures.push(error instanceof Error ? error.message : String(error));
      console.error(`✖ ${file}: ${failures[failures.length - 1]}`);
    }
  }
  if (failures.length > 0) {
    throw new Error(`${failures.length} file(s) failed validation.`);
  }
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
    await runGoldSummaryCheck(options);
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
  }
}

if (
  import.meta.url === `file://${process.argv[1]}` ||
  process.argv[1]?.endsWith("goldSummaryCheck.mjs")
) {
  await main();
}
