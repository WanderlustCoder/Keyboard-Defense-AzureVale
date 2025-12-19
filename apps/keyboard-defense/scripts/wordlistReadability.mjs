#!/usr/bin/env node
import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import { fileURLToPath, pathToFileURL } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const APP_ROOT = path.resolve(__dirname, "..");
const DEFAULT_WORDLIST_DIR = path.join(APP_ROOT, "data", "wordlists");
const DEFAULT_WORDBANK_PATH = path.join(APP_ROOT, "public", "dist", "src", "core", "wordBank.js");

const VOWELS = new Set(["a", "e", "i", "o", "u", "y"]);
const RARE_LETTERS = new Set(["q", "x", "z", "j"]);
const HARD_PUNCTUATION = new Set([".", ",", "?", "!", ";", ":", "\"", "(", ")", "[", "]"]);
const SOFT_PUNCTUATION = new Set(["-", "'"]);

function usage() {
  console.log(`Grade wordlists/word bank for readability (age-appropriate typing complexity).

Usage:
  node scripts/wordlistReadability.mjs [--wordlists <dir>] [--wordbank <file>] [--out <path>] [--strict]

Options:
  --wordlists <dir>   Wordlist directory (default: data/wordlists)
  --wordbank <file>   Word bank module path (default: public/dist/src/core/wordBank.js)
  --out <path>        Write JSON report
  --strict            Fail on threshold violations
  --help, -h          Show this help
`);
}

function parseArgs(argv) {
  const options = {
    wordlists: DEFAULT_WORDLIST_DIR,
    wordbank: DEFAULT_WORDBANK_PATH,
    out: null,
    strict: false,
    help: false
  };
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--help":
      case "-h":
        options.help = true;
        break;
      case "--wordlists":
        options.wordlists = argv[++i] ?? options.wordlists;
        break;
      case "--wordbank":
        options.wordbank = argv[++i] ?? options.wordbank;
        break;
      case "--out":
        options.out = argv[++i] ?? null;
        break;
      case "--strict":
        options.strict = true;
        break;
      default:
        throw new Error(`Unknown option: ${token}`);
    }
  }
  return options;
}

function percentile(values, p) {
  if (!Array.isArray(values) || values.length === 0) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  const index = Math.min(sorted.length - 1, Math.max(0, Math.floor((sorted.length - 1) * p)));
  return sorted[index];
}

export function estimateSyllables(value) {
  const raw = typeof value === "string" ? value.toLowerCase() : "";
  const cleaned = raw.replace(/[^a-z]/g, "");
  if (!cleaned) return 0;
  if (cleaned.length <= 3) return 1;

  const groups = cleaned.match(/[aeiouy]+/g);
  let count = groups ? groups.length : 0;

  if (cleaned.endsWith("e")) {
    count -= 1;
  }
  if (
    cleaned.endsWith("le") &&
    cleaned.length > 2 &&
    !VOWELS.has(cleaned[cleaned.length - 3])
  ) {
    count += 1;
  }
  return Math.max(1, count);
}

function countCharSet(text, set) {
  let count = 0;
  for (const char of text) {
    if (set.has(char)) count += 1;
  }
  return count;
}

function hasRareLetter(text) {
  for (const char of text) {
    if (RARE_LETTERS.has(char)) return true;
  }
  return false;
}

function countConsonantClusters(text) {
  const cleaned = text.replace(/[^a-z]/g, "");
  if (!cleaned) return 0;
  const matches = cleaned.match(/[^aeiouy]{3,}/g);
  return matches ? matches.length : 0;
}

export function scoreEntry(entry) {
  const raw = typeof entry === "string" ? entry.trim() : "";
  const lower = raw.toLowerCase();
  const tokens = lower.match(/[a-z]+|[0-9]+/g) ?? [];
  const hardPunctuationCount = countCharSet(raw, HARD_PUNCTUATION);
  const softPunctuationCount = countCharSet(raw, SOFT_PUNCTUATION);

  let score = 0;
  let maxTokenLength = 0;
  let containsDigits = false;
  for (const token of tokens) {
    maxTokenLength = Math.max(maxTokenLength, token.length);
    if (/^[0-9]+$/.test(token)) {
      containsDigits = true;
      score += token.length + 2;
      continue;
    }
    const syllables = estimateSyllables(token);
    score += token.length;
    score += Math.max(0, syllables - 1) * 2;
    if (token.length >= 10) score += 2;
    if (hasRareLetter(token)) score += 2;
    score += countConsonantClusters(token);
  }

  const tokenPenalty = Math.max(0, tokens.length - 1);
  score += tokenPenalty;
  score += hardPunctuationCount * 2;
  score += softPunctuationCount;

  const recommendedAge = Math.min(16, Math.max(8, 7 + Math.round(score / 2.6)));

  return {
    raw,
    tokens,
    score,
    recommendedAge,
    hardPunctuationCount,
    softPunctuationCount,
    maxTokenLength,
    containsDigits
  };
}

export function gradeEntries(entries) {
  const items = (entries ?? [])
    .map((entry) => scoreEntry(entry))
    .filter((item) => item.raw.length > 0);
  const scores = items.map((item) => item.score);
  const ages = items.map((item) => item.recommendedAge);
  const hardPunctuation = items.map((item) => item.hardPunctuationCount);
  const tokenLengths = items.map((item) => item.maxTokenLength);
  const tokenCounts = items.map((item) => item.tokens.length);

  const digitCount = items.filter((item) => item.containsDigits).length;
  const punctuationCount = items.filter((item) => item.hardPunctuationCount + item.softPunctuationCount > 0).length;

  return {
    count: items.length,
    scores: {
      min: scores.length ? Math.min(...scores) : 0,
      max: scores.length ? Math.max(...scores) : 0,
      avg: scores.length ? scores.reduce((a, b) => a + b, 0) / scores.length : 0,
      p50: percentile(scores, 0.5),
      p90: percentile(scores, 0.9)
    },
    recommendedAge: {
      min: ages.length ? Math.min(...ages) : 0,
      max: ages.length ? Math.max(...ages) : 0,
      avg: ages.length ? ages.reduce((a, b) => a + b, 0) / ages.length : 0,
      p50: percentile(ages, 0.5),
      p90: percentile(ages, 0.9)
    },
    tokens: {
      maxTokenLength: tokenLengths.length ? Math.max(...tokenLengths) : 0,
      p90TokenLength: percentile(tokenLengths, 0.9),
      maxTokenCount: tokenCounts.length ? Math.max(...tokenCounts) : 0,
      p90TokenCount: percentile(tokenCounts, 0.9)
    },
    punctuation: {
      maxHardPunctuation: hardPunctuation.length ? Math.max(...hardPunctuation) : 0,
      p90HardPunctuation: percentile(hardPunctuation, 0.9),
      rate: items.length ? punctuationCount / items.length : 0
    },
    digits: {
      rate: items.length ? digitCount / items.length : 0
    },
    items
  };
}

export function gradeWordlists(wordlistDir) {
  const results = [];
  return fs
    .readdir(wordlistDir, { withFileTypes: true })
    .then(async (entries) => {
      for (const entry of entries) {
        if (!entry.isFile()) continue;
        if (!entry.name.toLowerCase().endsWith(".json")) continue;
        const fullPath = path.join(wordlistDir, entry.name);
        const raw = await fs.readFile(fullPath, "utf8");
        let json;
        try {
          json = JSON.parse(raw);
        } catch (error) {
          results.push({
            file: entry.name,
            ok: false,
            errors: [
              `Failed to parse JSON: ${error instanceof Error ? error.message : String(error)}`
            ]
          });
          continue;
        }
        const words = Array.isArray(json.words) ? json.words : [];
        results.push({
          file: entry.name,
          id: typeof json.id === "string" ? json.id : null,
          lesson: typeof json.lesson === "number" ? json.lesson : null,
          ok: true,
          summary: gradeEntries(words)
        });
      }
      return results;
    });
}

async function loadWordBank(wordBankPath) {
  const resolved = path.isAbsolute(wordBankPath)
    ? wordBankPath
    : path.join(process.cwd(), wordBankPath);
  const url = pathToFileURL(resolved).href;
  const module = await import(url);
  if (!module || typeof module.defaultWordBank !== "object" || !module.defaultWordBank) {
    throw new Error("Word bank module missing defaultWordBank export.");
  }
  return module.defaultWordBank;
}

export async function gradeDefaultWordBank(wordBankPath) {
  const wordBank = await loadWordBank(wordBankPath);
  const summaries = {
    easy: gradeEntries(wordBank.easy ?? []),
    medium: gradeEntries(wordBank.medium ?? []),
    hard: gradeEntries(wordBank.hard ?? [])
  };
  return summaries;
}

function checkThresholds({ report }) {
  const violations = [];

  const checkSummary = (label, summary) => {
    if (!summary || typeof summary !== "object") return;
    const maxHardPunctuation = summary.punctuation?.maxHardPunctuation ?? 0;
    if (maxHardPunctuation > 2) {
      violations.push(`${label}: too many punctuation marks (max ${maxHardPunctuation}, expected <= 2)`);
    }
    const maxTokenCount = summary.tokens?.maxTokenCount ?? 0;
    if (maxTokenCount > 6) {
      violations.push(`${label}: too many tokens (max ${maxTokenCount}, expected <= 6)`);
    }
  };

  for (const file of report.wordlists ?? []) {
    if (!file.ok) continue;
    checkSummary(`wordlist:${file.file}`, file.summary);
  }

  const bank = report.wordBank ?? null;
  if (bank) {
    checkSummary("wordBank:easy", bank.easy);
    checkSummary("wordBank:medium", bank.medium);
    checkSummary("wordBank:hard", bank.hard);

    const easyP90 = bank.easy?.recommendedAge?.p90 ?? 0;
    const mediumP90 = bank.medium?.recommendedAge?.p90 ?? 0;
    if (easyP90 > 12) {
      violations.push(`wordBank:easy p90 recommended age too high (${easyP90}, expected <= 12)`);
    }
    if (mediumP90 > 14) {
      violations.push(
        `wordBank:medium p90 recommended age too high (${mediumP90}, expected <= 14)`
      );
    }
  }

  return violations;
}

export async function generateReadabilityReport(options) {
  const wordlistDir = options?.wordlists ?? DEFAULT_WORDLIST_DIR;
  const wordBankPath = options?.wordbank ?? DEFAULT_WORDBANK_PATH;

  const report = {
    generatedAt: new Date().toISOString(),
    wordlistsDir: wordlistDir,
    wordBankPath: wordBankPath,
    wordlists: [],
    wordBank: null,
    failures: []
  };

  let wordlistStat;
  try {
    wordlistStat = await fs.stat(wordlistDir);
  } catch {
    report.failures.push(`Wordlist directory missing: ${wordlistDir}`);
    return report;
  }
  if (!wordlistStat.isDirectory()) {
    report.failures.push(`Wordlist path is not a directory: ${wordlistDir}`);
    return report;
  }

  report.wordlists = await gradeWordlists(wordlistDir);

  try {
    report.wordBank = await gradeDefaultWordBank(wordBankPath);
  } catch (error) {
    report.failures.push(error instanceof Error ? error.message : String(error));
  }

  return report;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    usage();
    process.exit(0);
  }

  const report = await generateReadabilityReport(args);
  const violations = checkThresholds({ report });

  if (args.out) {
    const outPath = path.isAbsolute(args.out) ? args.out : path.join(process.cwd(), args.out);
    await fs.mkdir(path.dirname(outPath), { recursive: true });
    await fs.writeFile(outPath, JSON.stringify({ ...report, violations }, null, 2) + "\n", "utf8");
  }

  for (const failure of report.failures) {
    console.error("[wordlist][readability][error]", failure);
  }
  for (const violation of violations) {
    console.warn("[wordlist][readability][warn]", violation);
  }

  if (report.failures.length > 0) {
    process.exit(1);
  }
  if (args.strict && violations.length > 0) {
    process.exit(1);
  }

  console.log(
    `Wordlist readability report complete. Wordlists: ${report.wordlists.length}. Violations: ${violations.length}.`
  );
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  await main();
}

