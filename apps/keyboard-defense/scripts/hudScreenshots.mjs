#!/usr/bin/env node
/**
 * Capture deterministic HUD screenshots for documentation and regression review.
 *
 * Produces PNGs under artifacts/screenshots/ by default:
 *   - hud-main.png: Core HUD during an active wave.
 *   - options-overlay.png: Pause/options overlay with accessibility controls.
 *   - tutorial-summary.png: Tutorial wrap-up modal with mocked stats.
 *   - wave-scorecard.png: Wave-end scorecard highlighting DPS and rewards.
 *
 * Usage:
 *   node scripts/hudScreenshots.mjs [--url http://127.0.0.1:4173] [--out artifacts/screenshots] [--ci]
 *   node scripts/hudScreenshots.mjs --no-server --url http://127.0.0.1:4173
 */

import { spawn } from "node:child_process";
import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";

const DEFAULT_BASE_URL = process.env.HUD_SCREENSHOT_URL ?? "http://127.0.0.1:4173";
const DEFAULT_OUTPUT_DIR =
  process.env.HUD_SCREENSHOT_OUTPUT ?? path.resolve("artifacts", "screenshots");

const SHOTS = [
  { id: "hud-main", file: "hud-main.png" },
  { id: "options-overlay", file: "options-overlay.png" },
  { id: "tutorial-summary", file: "tutorial-summary.png" },
  { id: "wave-scorecard", file: "wave-scorecard.png" }
];

function parseArgs(argv) {
  const opts = {
    baseUrl: DEFAULT_BASE_URL,
    outputDir: DEFAULT_OUTPUT_DIR,
    ci: false,
    noServer: false,
    help: false
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--url":
      case "--base-url": {
        const value = argv[++i];
        if (!value) throw new Error(`Missing value for ${token}`);
        opts.baseUrl = value;
        break;
      }
      case "--out":
      case "--output":
      case "--dir": {
        const value = argv[++i];
        if (!value) throw new Error(`Missing value for ${token}`);
        opts.outputDir = path.resolve(value);
        break;
      }
      case "--ci":
        opts.ci = true;
        break;
      case "--no-server":
        opts.noServer = true;
        break;
      case "--help":
      case "-h":
        opts.help = true;
        break;
      default:
        if (token.startsWith("-")) {
          throw new Error(`Unknown argument "${token}". Try --help.`);
        }
        break;
    }
  }

  return opts;
}

function printHelp() {
  console.log(`Keyboard Defense HUD screenshot capture

Options:
  --url, --base-url   Base URL for the running dev server (default ${DEFAULT_BASE_URL})
  --out, --output     Directory to write PNG screenshots (default ${DEFAULT_OUTPUT_DIR})
  --no-server         Do not launch the dev server; assume the URL is already serving the app
  --ci                Emit a CI-friendly summary file (screenshots-summary.ci.json)
  --help, -h          Show this help`);
}

async function run(command, args, options = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      stdio: "inherit",
      shell: options.shell ?? process.platform === "win32",
      ...options
    });
    child.on("error", reject);
    child.on("exit", (code) => {
      if (code === 0) resolve();
      else reject(new Error(`${command} ${args.join(" ")} exited with code ${code}`));
    });
  });
}

async function waitForReady(page, timeout = 10_000) {
  await page.waitForFunction(() => Boolean(window.keyboardDefense?.getState), {
    timeout
  });
}

async function withPlaywright(callback) {
  try {
    const { chromium } = await import("@playwright/test");
    return await callback(chromium);
  } catch (error) {
    const message =
      error && typeof error === "object" && "message" in error ? error.message : String(error);
    throw new Error(
      `Playwright is required to capture screenshots. Install @playwright/test and run "npx playwright install chromium". (${message})`
    );
  }
}

async function ensureDir(outDir) {
  await fs.mkdir(outDir, { recursive: true });
}

async function collectUiSnapshot(page) {
  return page.evaluate(() => {
    try {
      const kd = window.keyboardDefense;
      if (!kd || typeof kd.getUiSnapshot !== "function") {
        return null;
      }
      const snapshot = kd.getUiSnapshot();
      return snapshot ?? null;
    } catch (error) {
      const message =
        error && typeof error === "object" && "message" in error ? error.message : String(error);
      return { error: message };
    }
  });
}

async function captureHudMain(page, outPath) {
  await page.evaluate(() => {
    const kd = window.keyboardDefense;
    if (!kd) throw new Error("keyboardDefense debug API unavailable.");
    kd.skipTutorial();
    kd.grantGold(600);
    kd.placeTurret("slot-1", "arrow");
    kd.upgradeTurret("slot-1");
    kd.spawnEnemy({ tierId: "runner", lane: 1 });
    kd.spawnEnemy({ tierId: "brute", lane: 0, shield: { health: 40 } });
    kd.resume();
  });
  await page.waitForTimeout(2500);
  await page.evaluate(() => window.keyboardDefense?.pause());
  await page.waitForTimeout(200);
  await page.screenshot({ path: outPath, fullPage: true });
  return collectUiSnapshot(page);
}

async function captureOptionsOverlay(page, outPath) {
  await page.evaluate(() => {
    const pauseButton = document.getElementById("pause-button");
    pauseButton?.click();
  });
  await page.waitForTimeout(400);
  await page.screenshot({ path: outPath, fullPage: true });
  const snapshot = await collectUiSnapshot(page);
  await page.keyboard.press("Escape");
  await page.waitForTimeout(200);
  return snapshot;
}

async function captureTutorialSummaryOverlay(page, outPath) {
  await page.evaluate(() => {
    const kd = window.keyboardDefense;
    if (!kd || typeof kd.showTutorialSummary !== "function") {
      throw new Error("keyboardDefense debug API missing showTutorialSummary.");
    }
    kd.pause?.();
    kd.showTutorialSummary({
      accuracy: 0.97,
      bestCombo: 42,
      breaches: 1,
      gold: 380
    });
  });
  await page.waitForTimeout(400);
  await page.screenshot({ path: outPath, fullPage: true });
  const snapshot = await collectUiSnapshot(page);
  await page.evaluate(() => window.keyboardDefense?.hideTutorialSummary?.());
  return snapshot;
}

async function captureWaveScorecard(page, outPath) {
  await page.evaluate(() => {
    const kd = window.keyboardDefense;
    if (!kd || typeof kd.showWaveScorecard !== "function") {
      throw new Error("keyboardDefense debug API missing showWaveScorecard.");
    }
    kd.showWaveScorecard({
      waveIndex: 4,
      waveTotal: 7,
      mode: "campaign",
      accuracy: 0.91,
      enemiesDefeated: 18,
      breaches: 1,
      perfectWords: 6,
      averageReaction: 1.1,
      dps: 32,
      turretDps: 18,
      typingDps: 14,
      turretDamage: 640,
      typingDamage: 498,
      shieldBreaks: 3,
      repairsUsed: 1,
      repairHealth: 80,
      repairGold: 200,
      goldEarned: 210,
      bonusGold: 35,
      castleBonusGold: 24,
      bestCombo: 28,
      sessionBestCombo: 35
    });
  });
  await page.waitForTimeout(400);
  await page.screenshot({ path: outPath, fullPage: true });
  const snapshot = await collectUiSnapshot(page);
  await page.evaluate(() => window.keyboardDefense?.hideWaveScorecard?.());
  return snapshot;
}

async function captureScreenshots(opts) {
  const summary = {
    status: "success",
    startedAt: new Date().toISOString(),
    finishedAt: null,
    baseUrl: opts.baseUrl,
    outputDir: opts.outputDir,
    screenshots: []
  };

  let serverStarted = false;

  try {
    if (!opts.noServer) {
      await run(process.execPath, ["./scripts/startMonitored.mjs"], {
        cwd: path.resolve("."),
        shell: false
      });
      serverStarted = true;
    }

    await ensureDir(opts.outputDir);

    await withPlaywright(async (chromium) => {
      const browser = await chromium.launch({ headless: true });
      try {
        const context = await browser.newContext({
          viewport: { width: 1280, height: 720 },
          deviceScaleFactor: 1
        });
        const page = await context.newPage();
        await page.goto(opts.baseUrl, { waitUntil: "networkidle" });
        await waitForReady(page);
        await page.evaluate(() => window.keyboardDefense?.pause());

        for (const shot of SHOTS) {
          const outPath = path.join(opts.outputDir, shot.file);
          let uiSnapshot = null;
          if (shot.id === "hud-main") {
            uiSnapshot = await captureHudMain(page, outPath);
          } else if (shot.id === "options-overlay") {
            uiSnapshot = await captureOptionsOverlay(page, outPath);
          } else if (shot.id === "tutorial-summary") {
            uiSnapshot = await captureTutorialSummaryOverlay(page, outPath);
          } else if (shot.id === "wave-scorecard") {
            uiSnapshot = await captureWaveScorecard(page, outPath);
          }
          summary.screenshots.push({
            id: shot.id,
            path: outPath,
            uiSnapshot: uiSnapshot ?? (await collectUiSnapshot(page))
          });
        }
      } finally {
        await browser.close();
      }
    });
  } catch (error) {
    summary.status = "failed";
    summary.error = error instanceof Error ? error.message : String(error);
  } finally {
    if (serverStarted) {
      try {
        await run(process.execPath, ["./scripts/devServer.mjs", "stop"], {
          cwd: path.resolve("."),
          shell: false
        });
      } catch (stopError) {
        summary.stopError = stopError instanceof Error ? stopError.message : String(stopError);
        if (summary.status === "success") {
          summary.status = "warning";
        }
      }
    }
    summary.finishedAt = new Date().toISOString();
    const summaryName = opts.ci ? "screenshots-summary.ci.json" : "screenshots-summary.json";
    const summaryPath = path.join(opts.outputDir, summaryName);
    await fs.writeFile(summaryPath, JSON.stringify(summary, null, 2), "utf8");
    if (summary.status !== "success") {
      process.exitCode = 1;
    }
  }
}

async function main() {
  let opts;
  try {
    opts = parseArgs(process.argv.slice(2));
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
    return;
  }

  if (opts.help) {
    printHelp();
    return;
  }

  await captureScreenshots(opts);
}

await main();
