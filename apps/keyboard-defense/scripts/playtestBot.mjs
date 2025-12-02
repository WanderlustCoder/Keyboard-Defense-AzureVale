#!/usr/bin/env node
/**
 * Playtest bot for perf smoke: opens the game, types words for a fixed duration,
 * and emits a JSON summary (words/characters typed + basic HUD/state metrics).
 *
 * Usage:
 *   node scripts/playtestBot.mjs [--url http://127.0.0.1:4173] [--duration 20000] [--delay 40] [--words camp,focus,defend] [--artifact artifacts/summaries/playtest-bot.json] [--headful]
 *
 * Requirements:
 *   - Dev server running and reachable at --url
 *   - Playwright Chromium installed: npm exec playwright install chromium
 */

import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";

const DEFAULT_URL = process.env.PLAYTEST_BOT_URL ?? "http://127.0.0.1:4173";
const DEFAULT_DURATION_MS = Number.parseInt(process.env.PLAYTEST_BOT_DURATION_MS ?? "20000", 10);
const DEFAULT_DELAY_MS = Number.parseInt(process.env.PLAYTEST_BOT_DELAY_MS ?? "40", 10);
const DEFAULT_ARTIFACT =
  process.env.PLAYTEST_BOT_ARTIFACT ?? path.resolve("artifacts", "summaries", "playtest-bot.json");
const DEFAULT_WORDS = ["camp", "focus", "defend", "castle", "shield", "ready", "attack", "tower"];

function parseArgs(argv = []) {
  const args = {
    url: DEFAULT_URL,
    durationMs: DEFAULT_DURATION_MS,
    delayMs: DEFAULT_DELAY_MS,
    artifact: DEFAULT_ARTIFACT,
    headful: false,
    words: DEFAULT_WORDS
  };
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--url":
        args.url = argv[++i] ?? args.url;
        break;
      case "--duration":
        args.durationMs = Number.parseInt(argv[++i] ?? `${DEFAULT_DURATION_MS}`, 10);
        break;
      case "--delay":
        args.delayMs = Number.parseInt(argv[++i] ?? `${DEFAULT_DELAY_MS}`, 10);
        break;
      case "--words":
        args.words = (argv[++i] ?? "")
          .split(",")
          .map((w) => w.trim())
          .filter(Boolean);
        if (args.words.length === 0) {
          args.words = DEFAULT_WORDS;
        }
        break;
      case "--artifact":
        args.artifact = argv[++i] ?? args.artifact;
        break;
      case "--headful":
        args.headful = true;
        break;
      case "--help":
      case "-h":
        printHelp();
        process.exit(0);
        break;
      default:
        if (token.startsWith("--")) {
          throw new Error(`Unknown option: ${token}`);
        }
        break;
    }
  }
  return args;
}

function printHelp() {
  console.log(`Playtest bot - perf/typing smoke

Options:
  --url <string>       Target game URL (default: ${DEFAULT_URL})
  --duration <ms>      Duration to type before stopping (default: ${DEFAULT_DURATION_MS})
  --delay <ms>         Delay between characters (default: ${DEFAULT_DELAY_MS})
  --words a,b,c        Comma-separated words to loop through (default: built-in set)
  --artifact <path>    Where to write the JSON summary (default: ${DEFAULT_ARTIFACT})
  --headful            Run browser with a visible window (default: headless)
  --help               Show this help

Ensure the dev server is running, then:
  npm run playtest:bot -- --duration 30000 --delay 30
`);
}

async function loadChromium() {
  try {
    const mod = await import("@playwright/test");
    return mod.chromium;
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    throw new Error(
      `Playwright is required for playtestBot. Install @playwright/test and run "npx playwright install chromium". (${message})`
    );
  }
}

async function writeJson(filePath, data) {
  const resolved = path.isAbsolute(filePath) ? filePath : path.resolve(filePath);
  await fs.mkdir(path.dirname(resolved), { recursive: true });
  await fs.writeFile(resolved, JSON.stringify(data, null, 2));
}

function pickWord(words, index) {
  if (!Array.isArray(words) || words.length === 0) {
    return DEFAULT_WORDS[index % DEFAULT_WORDS.length];
  }
  return words[index % words.length];
}

async function collectState(page) {
  return page.evaluate(() => {
    const kd = globalThis.keyboardDefense;
    if (!kd || typeof kd.getState !== "function") {
      return null;
    }
    const state = kd.getState();
    return {
      accuracy: state.typing?.accuracy ?? null,
      wpm: state.typing?.wpm ?? null,
      combo: state.typing?.combo ?? null,
      wordsCompleted: state.typing?.wordsCompleted ?? null,
      enemiesDefeated: state.core?.enemiesDefeated ?? null,
      breaches: state.core?.breaches ?? null,
      waveIndex: state.core?.wave ?? null
    };
  });
}

async function runBot(options) {
  const chromium = await loadChromium();
  const browser = await chromium.launch({ headless: !options.headful });
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  const summary = {
    startedAt: new Date().toISOString(),
    url: options.url,
    durationRequestedMs: options.durationMs,
    delayMs: options.delayMs,
    words: options.words,
    wordsTyped: 0,
    charsTyped: 0,
    errors: [],
    state: null
  };

  const startTime = Date.now();
  try {
    await page.goto(options.url, { waitUntil: "networkidle", timeout: 20000 });
    await page.waitForSelector("#typing-input", { timeout: 15000 });
    const deadline = startTime + options.durationMs;
    let index = 0;
    while (Date.now() < deadline) {
      const word = pickWord(options.words, index);
      await page.type("#typing-input", `${word} `, { delay: options.delayMs });
      summary.wordsTyped += 1;
      summary.charsTyped += word.length + 1;
      index += 1;
    }
    summary.state = await collectState(page);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    summary.errors.push(message);
  } finally {
    summary.endedAt = new Date().toISOString();
    summary.durationMs = Date.now() - startTime;
    await browser.close();
  }
  await writeJson(options.artifact, summary);
  if (summary.errors.length > 0) {
    console.error(`[playtest-bot] Completed with errors. See ${options.artifact}`);
    process.exitCode = 1;
  } else {
    console.log(
      `[playtest-bot] Typed ${summary.wordsTyped} words (${summary.charsTyped} chars) in ${summary.durationMs}ms. Summary: ${options.artifact}`
    );
  }
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  await runBot(args);
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exitCode = 1;
});
