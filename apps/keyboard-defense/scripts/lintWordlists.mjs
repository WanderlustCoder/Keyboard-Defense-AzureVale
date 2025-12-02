#!/usr/bin/env node

import { promises as fs } from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const APP_ROOT = path.resolve(__dirname, "..");
const WORDLIST_DIR = path.join(APP_ROOT, "data", "wordlists");
const DENYLIST_PATH = path.join(WORDLIST_DIR, "denylist.txt");
const DEFAULT_ALLOWED_CHARS = ".,?!;:'\"- ";
const DEFAULT_MIN_LEN = 1;
const DEFAULT_MAX_LEN_WORD = 16;
const DEFAULT_MAX_LEN_PHRASE = 32;

function parseArgs(argv = []) {
  const options = {
    fixSort: false,
    strict: false,
    out: null,
    help: false
  };
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--fix-sort":
        options.fixSort = true;
        break;
      case "--strict":
        options.strict = true;
        break;
      case "--out":
        options.out = argv[++i] ?? null;
        break;
      case "--help":
      case "-h":
        options.help = true;
        break;
      default:
        throw new Error(`Unknown option: ${token}`);
    }
  }
  return options;
}

function printHelp() {
  console.log(`Keyboard Defense wordlist/lesson linter

Usage:
  npm run lint:wordlists -- [--fix-sort] [--strict] [--out <path>] [--help]

Description:
  Validates lesson/word bank JSON files under data/wordlists against safety and gating rules:
  - allowed characters (letters + allowedCharacters/punctuation)
  - denylist/profanity checks (data/wordlists/denylist.txt)
  - length bounds (default max 16, phrases max 32)
  - duplicates, proper noun gating, weights sanity, deterministic ordering
  - lesson gating when introducedLetters/allowedCharacters is provided
`);
}

async function readDenylist() {
  try {
    const raw = await fs.readFile(DENYLIST_PATH, "utf8");
    return new Set(
      raw
        .split(/\r?\n/)
        .map((line) => line.trim().toLowerCase())
        .filter(Boolean)
    );
  } catch {
    return new Set();
  }
}

function normalizeWord(word) {
  return typeof word === "string" ? word.trim() : "";
}

function isSortedCaseInsensitive(list) {
  for (let i = 1; i < list.length; i += 1) {
    if (list[i - 1].toLowerCase() > list[i].toLowerCase()) return false;
  }
  return true;
}

function buildRegex({ introducedLetters, allowedCharacters }) {
  const letters = introducedLetters?.trim().toLowerCase() || "abcdefghijklmnopqrstuvwxyz";
  const extras = (allowedCharacters ?? DEFAULT_ALLOWED_CHARS).replace(/[-/\\^$*+?.()|[\]{}]/g, "\\$&");
  const pattern = `^[${letters}${extras}]+$`;
  return new RegExp(pattern);
}

function detectHasSpace(word) {
  return word.includes(" ");
}

function lintFileContent(filePath, json, denylist) {
  const errors = [];
  const warnings = [];
  const allowedCharacters = json.allowedCharacters;
  const introducedLetters = json.introducedLetters;
  const allowProper = Boolean(json.allowProper);
  const regex = buildRegex({ introducedLetters, allowedCharacters });
  if (!Array.isArray(json.words)) {
    errors.push("words must be an array");
    return { errors, warnings, fixed: false, nextWords: null };
  }
  const words = json.words.map(normalizeWord).filter(Boolean);
  if (words.length === 0) {
    errors.push("words array is empty after trimming");
  }
  const seen = new Set();
  const nextWords = [...json.words];
  const hasWeights = Array.isArray(json.weights);
  if (hasWeights && json.weights.length !== json.words.length) {
    errors.push("weights length must match words length");
  }
  let weightSum = 0;
  let weightOk = true;
  if (hasWeights) {
    for (const w of json.weights) {
      if (!Number.isFinite(w) || w <= 0) {
        errors.push("weights must be positive numbers");
        weightOk = false;
        break;
      }
      weightSum += w;
    }
    if (weightOk && (weightSum < 0.99 || weightSum > 1.01)) {
      errors.push(`weights must sum to 1 (+/-0.01), got ${weightSum.toFixed(3)}`);
    }
  }
  words.forEach((word, index) => {
    if (!regex.test(word.toLowerCase())) {
      errors.push(`invalid characters in "${word}"`);
    }
    const maxLen = detectHasSpace(word) ? DEFAULT_MAX_LEN_PHRASE : DEFAULT_MAX_LEN_WORD;
    if (word.length < DEFAULT_MIN_LEN || word.length > maxLen) {
      errors.push(`length out of bounds for "${word}" (min ${DEFAULT_MIN_LEN}, max ${maxLen})`);
    }
    if (!allowProper && /^[A-Z]/.test(json.words[index])) {
      errors.push(`proper nouns not allowed: "${json.words[index]}"`);
    }
    const lower = word.toLowerCase();
    if (seen.has(lower)) {
      errors.push(`duplicate word: "${word}"`);
    } else {
      seen.add(lower);
    }
    if (denylist.has(lower)) {
      errors.push(`denylist hit: "${word}"`);
    }
  });
  if (!isSortedCaseInsensitive(words)) {
    warnings.push("words are not sorted case-insensitively");
  }
  return { errors, warnings, fixed: false, nextWords };
}

async function lintWordlists(options) {
  const result = { files: [] };
  let dirStat;
  try {
    dirStat = await fs.stat(WORDLIST_DIR);
  } catch {
    console.log("No wordlists found (data/wordlists missing); skipping.");
    return result;
  }
  if (!dirStat.isDirectory()) {
    throw new Error("data/wordlists exists but is not a directory");
  }
  const denylist = await readDenylist();
  const entries = await fs.readdir(WORDLIST_DIR);
  const targets = entries.filter((name) => name.toLowerCase().endsWith(".json"));
  if (targets.length === 0) {
    console.log("No wordlist JSON files found; nothing to lint.");
    return result;
  }
  for (const name of targets) {
    const fullPath = path.join(WORDLIST_DIR, name);
    const raw = await fs.readFile(fullPath, "utf8");
    let json;
    try {
      json = JSON.parse(raw);
    } catch (error) {
      result.files.push({
        file: name,
        errors: [`Failed to parse JSON: ${error instanceof Error ? error.message : String(error)}`],
        warnings: [],
        fixed: false
      });
      continue;
    }
    const report = lintFileContent(fullPath, json, denylist);
    if (report.nextWords && options.fixSort) {
      const sorted = [...report.nextWords].map(normalizeWord).filter(Boolean).sort((a, b) => {
        const al = a.toLowerCase();
        const bl = b.toLowerCase();
        if (al === bl) return 0;
        return al < bl ? -1 : 1;
      });
      json.words = sorted;
      await fs.writeFile(fullPath, JSON.stringify(json, null, 2) + "\n", "utf8");
      report.fixed = true;
      // Re-run lint after sort to clear the warning.
      const rerun = lintFileContent(fullPath, json, denylist);
      report.errors = rerun.errors;
      report.warnings = rerun.warnings;
    }
    result.files.push({
      file: name,
      errors: report.errors,
      warnings: report.warnings,
      fixed: report.fixed
    });
  }
  return result;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    printHelp();
    process.exit(0);
  }
  const summary = await lintWordlists(args);
  const errors = summary.files.flatMap((f) => f.errors.map((msg) => `${f.file}: ${msg}`));
  const warnings = summary.files.flatMap((f) => f.warnings.map((msg) => `${f.file}: ${msg}`));
  if (args.out) {
    const outPath = path.isAbsolute(args.out) ? args.out : path.join(process.cwd(), args.out);
    await fs.mkdir(path.dirname(outPath), { recursive: true });
    await fs.writeFile(outPath, JSON.stringify(summary, null, 2) + "\n", "utf8");
  }
  warnings.forEach((w) => console.warn("[wordlist][warn]", w));
  errors.forEach((e) => console.error("[wordlist][error]", e));
  if (errors.length > 0) {
    process.exit(1);
  }
  if (warnings.length > 0 && args.strict) {
    process.exit(1);
  }
  console.log(
    `Wordlist lint complete. Files checked: ${summary.files.length}. Errors: ${errors.length}. Warnings: ${warnings.length}.`
  );
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
