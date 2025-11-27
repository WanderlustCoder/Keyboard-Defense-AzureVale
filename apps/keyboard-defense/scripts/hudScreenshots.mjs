#!/usr/bin/env node
/**
 * Capture deterministic HUD screenshots for documentation and regression review.
 *
 * Produces PNGs under artifacts/screenshots/ by default:
 *   - hud-main.png: Core HUD during an active wave.
 *   - diagnostics-overlay.png: Diagnostics overlay with metrics/sections expanded.
 *   - options-overlay.png: Pause/options overlay with accessibility controls.
 *   - shortcut-overlay.png: Keyboard shortcut reference overlay.
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
import { fileURLToPath } from "node:url";

const DEFAULT_BASE_URL = process.env.HUD_SCREENSHOT_URL ?? "http://127.0.0.1:4173";
const DEFAULT_OUTPUT_DIR =
  process.env.HUD_SCREENSHOT_OUTPUT ?? path.resolve("artifacts", "screenshots");
const TAUNT_CATALOG_SOURCE = path.resolve("docs", "taunts", "catalog.json");
const TAUNT_CATALOG_DIST = path.resolve("public", "dist", "docs", "taunts", "catalog.json");

const SHOTS = [
  { id: "hud-main", file: "hud-main.png", label: "Active HUD" },
  { id: "diagnostics-overlay", file: "diagnostics-overlay.png", label: "Diagnostics overlay" },
  { id: "options-overlay", file: "options-overlay.png", label: "Options overlay" },
  { id: "shortcut-overlay", file: "shortcut-overlay.png", label: "Shortcut overlay" },
  { id: "tutorial-summary", file: "tutorial-summary.png", label: "Tutorial summary" },
  { id: "wave-scorecard", file: "wave-scorecard.png", label: "Wave scorecard" }
];

const STARFIELD_SCENE_CHOICES = ["tutorial", "warning", "breach"];
const STARFIELD_SCENE_PRESETS = {
  tutorial: "calm",
  warning: "warning",
  breach: "breach"
};

function normalizeStarfieldScene(value) {
  if (value === undefined || value === null) {
    return { label: null, preset: null };
  }
  const normalized = String(value).trim().toLowerCase();
  if (!normalized || normalized === "auto" || normalized === "default" || normalized === "none") {
    return { label: null, preset: null };
  }
  const preset = STARFIELD_SCENE_PRESETS[normalized];
  if (!preset) {
    throw new Error(
      `Unsupported starfield scene "${value}". Use one of: ${STARFIELD_SCENE_CHOICES.join(
        ", "
      )}, or "auto" to reset to live gameplay.`
    );
  }
  return { label: normalized, preset };
}

function parseHudScreenshotArgs(argv) {
  const opts = {
    baseUrl: DEFAULT_BASE_URL,
    outputDir: DEFAULT_OUTPUT_DIR,
    ci: false,
    noServer: false,
    help: false,
    starfieldScene: null,
    starfieldPreset: null
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
      case "--starfield-scene": {
        const value = argv[++i];
        if (!value) throw new Error(`Missing value for ${token}`);
        const resolved = normalizeStarfieldScene(value);
        opts.starfieldScene = resolved.label;
        opts.starfieldPreset = resolved.preset;
        break;
      }
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
  --starfield-scene   Force a starfield preset (tutorial, warning, breach, auto)
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

async function ensureTauntCatalog() {
  try {
    await fs.access(TAUNT_CATALOG_SOURCE);
  } catch {
    return;
  }
  try {
    await fs.mkdir(path.dirname(TAUNT_CATALOG_DIST), { recursive: true });
    await fs.copyFile(TAUNT_CATALOG_SOURCE, TAUNT_CATALOG_DIST);
  } catch (error) {
    console.warn(
      `hudScreenshots: unable to copy taunt catalog (${error instanceof Error ? error.message : String(error)})`
    );
  }
}

function deriveUiBadges(snapshot, badgesContext = {}) {
  if (!snapshot || typeof snapshot !== "object") {
    return ["ui:unknown"];
  }
  const badges = [];

  if (snapshot.compactHeight === true) {
    badges.push("viewport:compact-height");
  } else if (snapshot.compactHeight === false) {
    badges.push("viewport:default-height");
  }

  const tutorial = snapshot.tutorialBanner ?? {};
  if (tutorial.condensed) {
    badges.push("tutorial:condensed");
  } else if (tutorial.expanded) {
    badges.push("tutorial:expanded");
  } else {
    badges.push("tutorial:default");
  }

  const hud = snapshot.hud ?? {};
  if (hud.passivesCollapsed === true) {
    badges.push("hud-passives:collapsed");
  } else if (hud.passivesCollapsed === false) {
    badges.push("hud-passives:expanded");
  }
  if (hud.goldEventsCollapsed === true) {
    badges.push("hud-gold-events:collapsed");
  } else if (hud.goldEventsCollapsed === false) {
    badges.push("hud-gold-events:expanded");
  }
  if (hud.prefersCondensedLists === true) {
    badges.push("hud:prefers-condensed");
  }

  const options = snapshot.options ?? {};
  if (options.passivesCollapsed === true) {
    badges.push("options-passives:collapsed");
  } else if (options.passivesCollapsed === false) {
    badges.push("options-passives:expanded");
  }

  const diagnostics = snapshot.diagnostics ?? {};
  if (diagnostics.condensed === true) {
    badges.push("diagnostics:condensed");
  } else if (diagnostics.condensed === false) {
    badges.push("diagnostics:expanded");
  }
  if (diagnostics.sectionsCollapsed === true) {
    badges.push("diagnostics:sections-collapsed");
  } else if (diagnostics.sectionsCollapsed === false) {
    badges.push("diagnostics:sections-expanded");
  }
  const diagSections = diagnostics.collapsedSections ?? {};
  const diagEntries = Object.entries(diagSections).filter(
    ([, value]) => typeof value === "boolean"
  );
  for (const [sectionId, collapsed] of diagEntries) {
    badges.push(`diagnostics:${sectionId}:${collapsed ? "collapsed" : "expanded"}`);
  }
  if (diagEntries.length === 0 && diagnostics.sectionsCollapsed === true) {
    badges.push("diagnostics:collapsed:unknown-sections");
  }

  const preferences = snapshot.preferences ?? {};
  if (preferences.hudPassivesCollapsed === true) {
    badges.push("pref:hud-passives-collapsed");
  }
  if (preferences.hudGoldEventsCollapsed === true) {
    badges.push("pref:hud-gold-events-collapsed");
  }
  if (preferences.optionsPassivesCollapsed === true) {
    badges.push("pref:options-passives-collapsed");
  }
  const prefDiagnostics = preferences.diagnosticsSections ?? {};
  for (const [sectionId, collapsed] of Object.entries(prefDiagnostics)) {
    if (typeof collapsed === "boolean") {
      badges.push(`pref:diagnostics:${sectionId}:${collapsed ? "collapsed" : "expanded"}`);
    }
  }
  if (typeof badgesContext.starfieldScene === "string" && badgesContext.starfieldScene.length > 0) {
    badges.push(`starfield:${badgesContext.starfieldScene}`);
  }

  return badges;
}

function describeUiSnapshot(snapshot) {
  if (!snapshot || typeof snapshot !== "object") {
    return "UI snapshot unavailable for this capture.";
  }
  const parts = [];
  if (snapshot.compactHeight) {
    parts.push("Compact viewport");
  }
  if (snapshot.tutorialBanner?.condensed) {
    parts.push("Tutorial banner condensed");
  } else if (snapshot.tutorialBanner?.expanded) {
    parts.push("Tutorial banner expanded");
  }
  if (snapshot.hud?.passivesCollapsed === true) {
    parts.push("HUD passives collapsed");
  } else if (snapshot.hud?.passivesCollapsed === false) {
    parts.push("HUD passives expanded");
  }
  if (snapshot.hud?.goldEventsCollapsed === true) {
    parts.push("HUD gold events collapsed");
  } else if (snapshot.hud?.goldEventsCollapsed === false) {
    parts.push("HUD gold events expanded");
  }
  if (snapshot.options?.passivesCollapsed === true) {
    parts.push("Options passives collapsed");
  }
  if (snapshot.diagnostics?.condensed === true) {
    parts.push("Diagnostics condensed");
  }
  const diagnosticsSectionsState = snapshot.diagnostics?.sectionsCollapsed;
  if (diagnosticsSectionsState === true) {
    parts.push("Diagnostics sections collapsed");
  } else if (diagnosticsSectionsState === false) {
    parts.push("Diagnostics sections expanded");
  }
  const diagSections = snapshot.diagnostics?.collapsedSections ?? {};
  const diagEntries = Object.entries(diagSections).filter(
    ([, value]) => typeof value === "boolean"
  );
  if (diagEntries.length > 0) {
    const detail = diagEntries
      .map(([section, collapsed]) => `${section}:${collapsed ? "collapsed" : "expanded"}`)
      .join(", ");
    parts.push(`Diagnostics sections — ${detail}`);
  }
  if (snapshot.hud?.prefersCondensedLists) {
    parts.push("HUD prefers condensed lists");
  }
  return parts.length > 0 ? parts.join("; ") : "UI snapshot recorded.";
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

async function collectTauntMetadata(page) {
  return page.evaluate(() => {
    try {
      const kd = window.keyboardDefense;
      if (!kd || typeof kd.getAnalyticsSnapshot !== "function") {
        return null;
      }
      const snapshot = kd.getAnalyticsSnapshot();
      const taunt = snapshot?.analytics?.taunt;
      if (!taunt) {
        return null;
      }
      const clean = {
        active: Boolean(taunt.active),
        text: typeof taunt.text === "string" ? taunt.text : null,
        enemyType: typeof taunt.enemyType === "string" ? taunt.enemyType : null,
        lane: typeof taunt.lane === "number" ? taunt.lane : null,
        waveIndex: typeof taunt.waveIndex === "number" ? taunt.waveIndex : null,
        timestampMs: typeof taunt.timestampMs === "number" ? taunt.timestampMs : null,
        id: typeof taunt.id === "string" ? taunt.id : null
      };
      const history = Array.isArray(taunt.history) ? taunt.history : [];
      const last = history.length > 0 ? history[history.length - 1] : null;
      if (last) {
        clean.last = {
          id: typeof last.id === "string" ? last.id : null,
          text: typeof last.text === "string" ? last.text : null,
          enemyType: typeof last.enemyType === "string" ? last.enemyType : null,
          lane: typeof last.lane === "number" ? last.lane : null,
          waveIndex: typeof last.waveIndex === "number" ? last.waveIndex : null,
          timestamp: typeof last.timestamp === "number" ? last.timestamp : null
        };
      }
      return clean;
    } catch (error) {
      const message =
        error && typeof error === "object" && "message" in error ? error.message : String(error);
      return { error: message };
    }
  });
}

async function applyStarfieldScene(page, preset) {
  await page.evaluate((scene) => {
    const kd = window.keyboardDefense;
    if (!kd || typeof kd.setStarfieldScene !== "function") {
      throw new Error("keyboardDefense debug API missing setStarfieldScene.");
    }
    kd.setStarfieldScene(scene);
  }, preset);
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

async function captureDiagnosticsOverlay(page, outPath) {
  await page.evaluate(() => {
    const kd = window.keyboardDefense;
    if (!kd || typeof kd.showDiagnostics !== "function") {
      throw new Error("keyboardDefense debug API missing showDiagnostics.");
    }
    kd.showDiagnostics();
  });
  await page.waitForTimeout(350);
  await page.evaluate(() => {
    const expandAll = document.querySelector("[data-action='expand-all']");
    if (expandAll instanceof HTMLButtonElement) {
      expandAll.click();
    }
  });
  await page.waitForTimeout(200);
  await page.screenshot({ path: outPath, fullPage: true });
  const snapshot = await collectUiSnapshot(page);
  await page.evaluate(() => window.keyboardDefense?.hideDiagnostics?.());
  await page.waitForTimeout(150);
  return snapshot;
}

async function captureShortcutOverlay(page, outPath) {
  await page.evaluate(() => {
    const launchButton = document.getElementById("shortcut-launch");
    launchButton?.click();
  });
  await page.waitForTimeout(250);
  await page.screenshot({ path: outPath, fullPage: true });
  const snapshot = await collectUiSnapshot(page);
  await page.evaluate(() => {
    const closeButton = document.getElementById("shortcut-overlay-close");
    if (closeButton instanceof HTMLButtonElement) {
      closeButton.click();
    } else {
      const overlay = document.getElementById("shortcut-overlay");
      if (overlay instanceof HTMLElement) {
        overlay.dataset.visible = "false";
      }
    }
  });
  await page.waitForTimeout(150);
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
    starfieldScene: opts.starfieldScene,
    parameters: {
      starfieldScene: opts.starfieldScene
    },
    screenshots: []
  };

  let serverStarted = false;

  try {
    if (!opts.noServer) {
      await ensureTauntCatalog();
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
          if (opts.starfieldPreset) {
            await applyStarfieldScene(page, opts.starfieldPreset);
          }
          const outPath = path.join(opts.outputDir, shot.file);
          let uiSnapshot = null;
          if (shot.id === "hud-main") {
            uiSnapshot = await captureHudMain(page, outPath);
          } else if (shot.id === "diagnostics-overlay") {
            uiSnapshot = await captureDiagnosticsOverlay(page, outPath);
          } else if (shot.id === "options-overlay") {
            uiSnapshot = await captureOptionsOverlay(page, outPath);
          } else if (shot.id === "shortcut-overlay") {
            uiSnapshot = await captureShortcutOverlay(page, outPath);
          } else if (shot.id === "tutorial-summary") {
            uiSnapshot = await captureTutorialSummaryOverlay(page, outPath);
          } else if (shot.id === "wave-scorecard") {
            uiSnapshot = await captureWaveScorecard(page, outPath);
          }
          const snapshot = uiSnapshot ?? (await collectUiSnapshot(page));
          const tauntDetails = await collectTauntMetadata(page);
          const metadata = {
            id: shot.id,
            description: shot.label,
            file: path.relative(process.cwd(), outPath).replace(/\\/g, "/"),
            badges: deriveUiBadges(snapshot, { starfieldScene: opts.starfieldScene }),
            summary: describeUiSnapshot(snapshot),
            capturedAt: new Date().toISOString(),
            uiSnapshot: snapshot,
            taunt: tauntDetails,
            starfieldScene: opts.starfieldScene
          };
          const metaPath = path.join(opts.outputDir, `${shot.id}.meta.json`);
          await fs.writeFile(metaPath, JSON.stringify(metadata, null, 2), "utf8");
          summary.screenshots.push({
            id: shot.id,
            path: outPath,
            description: shot.label,
            uiSnapshot: metadata.uiSnapshot,
            badges: metadata.badges,
            meta: metaPath,
            taunt: metadata.taunt ?? null,
            starfieldScene: metadata.starfieldScene
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
    opts = parseHudScreenshotArgs(process.argv.slice(2));
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

const isCliInvocation =
  fileURLToPath(import.meta.url) === path.resolve(process.argv[1] ?? "") ||
  process.argv[1]?.endsWith("hudScreenshots.mjs");

if (isCliInvocation) {
  await main();
}

export { deriveUiBadges, describeUiSnapshot, parseHudScreenshotArgs };
