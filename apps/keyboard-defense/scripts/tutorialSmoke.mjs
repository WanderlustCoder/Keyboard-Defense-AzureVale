/**
 * Keyboard Defense tutorial smoke automation.
 *
 * Capabilities:
 * - Connects to a running dev server (default http://127.0.0.1:4173)
 * - Launches Playwright Chromium (headless) to drive the debug hooks
 * - Supports two modes:
 *      * skip  – call keyboardDefense.skipTutorial() for a fast signal
 *      * full  – replay the entire tutorial, validating each lesson
 * - Captures analytics, shield breaks, game status, and UI summary text
 *   into a JSON artifact so downstream tooling can verify the run.
 *
 * Usage:
 *   node scripts/tutorialSmoke.mjs --help
 */

import fs from "node:fs";
import path from "node:path";
import process from "node:process";
import url from "node:url";

const DEFAULT_BASE_URL = process.env.TUTORIAL_SMOKE_URL ?? "http://127.0.0.1:4173";
const DEFAULT_ARTIFACT =
  process.env.TUTORIAL_SMOKE_ARTIFACT ?? "smoke-artifacts/tutorial-smoke.json";
const DEFAULT_MODE = "full";
const SHIELD_LESSON_WORD = "bulwark";
const WAIT_INTERVAL_MS = 100;
const DEFAULT_RESUME_SPEED = 1;
const AUDIO_INTENSITY_MIN = 0.5;
const AUDIO_INTENSITY_MAX = 1.5;
const AUDIO_INTENSITY_DEFAULT = 1;
const PLAYER_SETTINGS_STORAGE_KEY = "keyboard-defense:player-settings";

function clampAudioIntensity(value) {
  if (!Number.isFinite(value)) {
    return AUDIO_INTENSITY_DEFAULT;
  }
  return Math.max(AUDIO_INTENSITY_MIN, Math.min(AUDIO_INTENSITY_MAX, value));
}

function roundTo(value, precision = 3) {
  if (!Number.isFinite(value)) {
    return null;
  }
  const factor = 10 ** precision;
  return Math.round(value * factor) / factor;
}

function parseAudioIntensityToken(rawValue) {
  if (rawValue === undefined || rawValue === null) {
    throw new Error("Missing value for --audio-intensity.");
  }
  const cleaned =
    typeof rawValue === "string" ? rawValue.trim().replace(/%$/, "") : String(rawValue);
  const parsed = Number.parseFloat(cleaned);
  if (!Number.isFinite(parsed)) {
    throw new Error(`Invalid audio intensity value "${rawValue}".`);
  }
  const normalized = parsed > AUDIO_INTENSITY_MAX ? parsed / 100 : parsed;
  return clampAudioIntensity(normalized);
}

function cloneSimple(value) {
  if (value === undefined || value === null) {
    return value;
  }
  return JSON.parse(JSON.stringify(value));
}

function formatPassiveUnlockSummary(unlock) {
  if (!unlock || typeof unlock !== "object") {
    return "";
  }
  const labelMap = { regen: "Regen", armor: "Armor", gold: "Gold" };
  const label = labelMap[unlock.id] ?? "Passive";
  const level = Number.isFinite(unlock.level) ? ` L${unlock.level}` : "";
  const total = Number.isFinite(unlock.total) ? unlock.total : 0;
  const delta = Number.isFinite(unlock.delta) ? unlock.delta : 0;
  let detail;
  switch (unlock.id) {
    case "regen": {
      const totalStr = total.toFixed(1);
      const deltaStr = delta > 0 ? ` (+${delta.toFixed(1)})` : "";
      detail = `${totalStr} HP/s${deltaStr}`;
      break;
    }
    case "armor": {
      const totalStr = Math.round(total);
      const deltaStr = Math.round(delta);
      detail = `+${totalStr} armor${deltaStr > 0 ? ` (+${deltaStr})` : ""}`;
      break;
    }
    case "gold": {
      const totalStr = Math.round(total * 100);
      const deltaStr = Math.round(delta * 100);
      detail = `+${totalStr}% gold${deltaStr > 0 ? ` (+${deltaStr}%)` : ""}`;
      break;
    }
    default: {
      const totalStr = total.toFixed(2);
      const deltaStr = delta > 0 ? ` (+${delta.toFixed(2)})` : "";
      detail = `${totalStr}${deltaStr}`;
    }
  }
  const time =
    unlock.time !== undefined && Number.isFinite(unlock.time)
      ? ` @ ${unlock.time.toFixed(2)}s`
      : "";
  return `${label}${level} ${detail}${time}`.trim();
}

function summarizePassiveUnlocks(unlocks) {
  if (!Array.isArray(unlocks) || unlocks.length === 0) {
    return "";
  }
  return unlocks
    .map((unlock) => formatPassiveUnlockSummary(unlock))
    .filter((entry) => entry.length > 0)
    .join(" | ");
}

function normalizeGoldEvents(events, referenceTime) {
  if (!Array.isArray(events) || events.length === 0) {
    return [];
  }
  const trimmed = events.slice(-3).map((event) => ({
    gold: Number.isFinite(event.gold) ? Number(event.gold) : null,
    delta: Number.isFinite(event.delta) ? Number(event.delta) : null,
    timestamp: Number.isFinite(event.timestamp) ? Number(event.timestamp) : null
  }));
  return trimmed.map((event) => {
    const timeSince =
      typeof referenceTime === "number" && typeof event.timestamp === "number"
        ? Math.max(0, referenceTime - event.timestamp)
        : null;
    return { ...event, timeSince };
  });
}

function extractSoundSettings(snapshot) {
  if (!snapshot || typeof snapshot !== "object") {
    return { soundEnabled: null, soundVolume: null, soundIntensity: null };
  }
  const intensityValue =
    typeof snapshot.soundIntensity === "number"
      ? snapshot.soundIntensity
      : typeof snapshot.audioIntensity === "number"
        ? snapshot.audioIntensity
        : null;
  return {
    soundEnabled:
      typeof snapshot.soundEnabled === "boolean" ? snapshot.soundEnabled : null,
    soundVolume: Number.isFinite(snapshot.soundVolume) ? roundTo(snapshot.soundVolume) : null,
    soundIntensity: Number.isFinite(intensityValue) ? roundTo(intensityValue) : null
  };
}

function sanitizeAudioIntensityHistory(history) {
  if (!Array.isArray(history)) {
    return [];
  }
  return history
    .map((entry) => {
      if (!entry || typeof entry !== "object") {
        return null;
      }
      const toValue = Number.isFinite(entry.to) ? roundTo(entry.to) : null;
      const fromValue = Number.isFinite(entry.from) ? roundTo(entry.from) : null;
      if (toValue === null && fromValue === null) {
        return null;
      }
      return {
        timestampMs: Number.isFinite(entry.timestampMs) ? Math.round(entry.timestampMs) : null,
        gameTime: Number.isFinite(entry.gameTime) ? roundTo(entry.gameTime, 3) : null,
        waveIndex:
          Number.isInteger(entry.waveIndex) || entry.waveIndex === 0 ? entry.waveIndex : null,
        combo: Number.isFinite(entry.combo) ? Math.round(entry.combo) : null,
        accuracy: Number.isFinite(entry.accuracy) ? roundTo(entry.accuracy, 4) : null,
        from: fromValue,
        to: toValue,
        source: typeof entry.source === "string" ? entry.source : null
      };
    })
    .filter((entry) => entry);
}

function average(values) {
  if (!Array.isArray(values) || values.length === 0) {
    return null;
  }
  const total = values.reduce((sum, value) => sum + value, 0);
  return roundTo(total / values.length);
}

export function parseArgs(argv = []) {
  const args = {
    baseUrl: DEFAULT_BASE_URL,
    artifact: DEFAULT_ARTIFACT,
    mode: DEFAULT_MODE,
    help: false,
    audioIntensity: AUDIO_INTENSITY_DEFAULT
  };

  for (let i = 0; i < argv.length; i++) {
    const token = argv[i];
    switch (token) {
      case "--url":
      case "--base-url": {
        const value = argv[++i];
        if (value) args.baseUrl = value;
        break;
      }
      case "--artifact": {
        const value = argv[++i];
        if (value) args.artifact = value;
        break;
      }
      case "--mode": {
        const value = (argv[++i] ?? "").toLowerCase();
        if (value) args.mode = value;
        break;
      }
      case "--audio-intensity":
      case "--sound-intensity": {
        const value = argv[++i];
        args.audioIntensity = parseAudioIntensityToken(value);
        break;
      }
      case "--help":
      case "-h":
        args.help = true;
        break;
      default: {
        throw new Error(`Unknown argument "${token}". Use --help for usage.`);
      }
    }
  }
  return args;
}


export function validateMode(mode) {
  if (mode !== "skip" && mode !== "full" && mode !== "campaign") {
    throw new Error(`Unsupported mode "${mode}". Use "skip", "full", or "campaign".`);
  }
  return mode;
}

function printHelp() {
  console.log(`Keyboard Defense tutorial smoke

Options:
  --url, --base-url   Base URL for the running dev server (default ${DEFAULT_BASE_URL})
  --artifact          Path to write the JSON artifact (default ${DEFAULT_ARTIFACT})
  --mode              "full" (default), "skip", or "campaign"
  --audio-intensity   Audio intensity multiplier (0.5-1.5 or percent, default ${AUDIO_INTENSITY_DEFAULT})
  --help, -h          Show this help

Requirements:
  - A running Keyboard Defense dev server
  - Playwright (@playwright/test) with Chromium installed (run "npx playwright install chromium")

Artifacts:
  The script writes a JSON summary capturing game state, analytics, tutorial events,
  and the run outcome so CI can assert success.`);
}

async function loadChromium() {
  try {
    const { chromium } = await import("@playwright/test");
    return chromium;
  } catch (error) {
    const message =
      error && typeof error === "object" && "message" in error ? error.message : String(error);
    throw new Error(
      `Playwright is required for tutorial smoke. Install @playwright/test and "npx playwright install chromium". (${message})`
    );
  }
}

async function waitForPageReady(page, timeoutMs = 10_000) {
  await page.waitForFunction(() => Boolean(window.keyboardDefense?.getState), {
    timeout: timeoutMs
  });
}

async function waitFor(predicate, { timeout = 10_000, description = "condition" } = {}) {
  const start = Date.now();
  for (;;) {
    const result = await predicate();
    if (result) {
      return result;
    }
    if (Date.now() - start >= timeout) {
      throw new Error(`Timed out waiting for ${description} after ${timeout}ms`);
    }
    await new Promise((resolve) => setTimeout(resolve, WAIT_INTERVAL_MS));
  }
}

async function fetchState(page) {
  return page.evaluate(({ settingsKey }) => {
    const kd = window.keyboardDefense;
    if (!kd) throw new Error("keyboardDefense debug API missing in page context.");
    let playerSettings = null;
    try {
      const rawSettings = window.localStorage.getItem(settingsKey);
      if (rawSettings) {
        playerSettings = JSON.parse(rawSettings);
      }
    } catch {
      playerSettings = null;
    }
    const audioState = window.__tutorialSmokeAudioIntensity
      ? JSON.parse(JSON.stringify(window.__tutorialSmokeAudioIntensity))
      : null;
    return {
      state: kd.getState(),
      tutorialAnalytics: kd.getTutorialAnalytics?.() ?? null,
      tutorialStorage: window.localStorage.getItem("keyboard-defense:tutorialCompleted"),
      playerSettings,
      audioIntensity: audioState,
      soundSettings: {
        soundIntensity: typeof kd.audioIntensity === "number" ? kd.audioIntensity : null,
        soundVolume: typeof kd.soundVolume === "number" ? kd.soundVolume : null,
        soundEnabled: typeof kd.soundEnabled === "boolean" ? kd.soundEnabled : null
      }
    };
  }, { settingsKey: PLAYER_SETTINGS_STORAGE_KEY });
}

async function ensureTypingFocus(page) {
  await page.evaluate(() => {
    const input = document.getElementById("typing-input");
    if (input instanceof HTMLInputElement) {
      input.focus();
      input.select();
    }
  });
}

async function initializeAudioIntensityProbe(page) {
  await page.evaluate(() => {
    if (window.__tutorialSmokeAudioIntensity?.hooked) {
      return;
    }
    const tracker =
      window.__tutorialSmokeAudioIntensity ??
      {
        requested: null,
        applied: null,
        history: []
      };
    const kd = window.keyboardDefense;
    if (!kd || typeof kd.setAudioIntensity !== "function") {
      window.__tutorialSmokeAudioIntensity = tracker;
      return;
    }
    const recordEntry = (from, to, source) => {
      const state = typeof kd.getState === "function" ? kd.getState() : null;
      tracker.history.push({
        timestampMs: typeof performance !== "undefined" ? performance.now() : Date.now(),
        gameTime: state?.time ?? null,
        waveIndex: state?.wave?.index ?? null,
        combo: state?.typing?.combo ?? null,
        accuracy: state?.typing?.accuracy ?? null,
        from: Number.isFinite(from) ? Number(from.toFixed(3)) : null,
        to: Number.isFinite(to) ? Number(to.toFixed(3)) : null,
        source: source ?? null
      });
      tracker.applied = Number.isFinite(to) ? Number(to.toFixed(3)) : tracker.applied;
    };

    const original = kd.setAudioIntensity?.bind(kd);
    if (typeof original !== "function") {
      window.__tutorialSmokeAudioIntensity = tracker;
      return;
    }

    kd.setAudioIntensity = function patchedSetAudioIntensity(value, options = {}) {
      const before = typeof kd.audioIntensity === "number" ? kd.audioIntensity : null;
      const result = original(value, options);
      const after = typeof kd.audioIntensity === "number" ? kd.audioIntensity : null;
      const source =
        typeof options.source === "string"
          ? options.source
          : options.silent
            ? "automation"
            : "ui";
      recordEntry(before, after, source);
      return result;
    };

    const initialValue = typeof kd.audioIntensity === "number" ? kd.audioIntensity : null;
    if (tracker.history.length === 0) {
      recordEntry(initialValue, initialValue, "initial");
    }
    tracker.hooked = true;
    window.__tutorialSmokeAudioIntensity = tracker;
  });
}

async function applyAudioIntensityPreference(page, requested) {
  if (!Number.isFinite(requested)) {
    return null;
  }
  const normalized = clampAudioIntensity(requested);
  await page.evaluate(({ value }) => {
    const kd = window.keyboardDefense;
    if (!kd || typeof kd.setAudioIntensity !== "function") {
      throw new Error("keyboardDefense debug API missing setAudioIntensity.");
    }
    const tracker =
      window.__tutorialSmokeAudioIntensity ??
      {
        requested: null,
        applied: null,
        history: []
      };
    tracker.requested = value;
    window.__tutorialSmokeAudioIntensity = tracker;
    kd.setAudioIntensity(value, { silent: true, persist: false, source: "cli" });
  }, { value: normalized });
  return normalized;
}

async function prepareAudioIntensity(page, requested) {
  await initializeAudioIntensityProbe(page);
  if (requested === undefined || requested === null) {
    return null;
  }
  return applyAudioIntensityPreference(page, requested);
}

export async function resumeGameplay(page, { speed = DEFAULT_RESUME_SPEED } = {}) {
  const normalizedSpeed = Number.isFinite(speed) ? speed : DEFAULT_RESUME_SPEED;
  await page.evaluate(
    ({ multiplier }) => {
      const kd = window.keyboardDefense;
      if (!kd) {
        throw new Error("keyboardDefense debug API missing during resume.");
      }
      if (typeof kd.resume === "function") {
        kd.resume();
      }
      if (typeof kd.setSpeed === "function") {
        kd.setSpeed(multiplier);
      }
    },
    { multiplier: normalizedSpeed }
  );
}

async function dismissMainMenu(page) {
  const overlaySelector = "#main-menu-overlay[data-visible='true']";
  const overlayHandle = await page
    .waitForSelector(overlaySelector, {
      timeout: 5000
    })
    .catch(() => null);
  if (!overlayHandle) {
    return;
  }

  const startButton = await page.$("#main-menu-start-tutorial");
  if (startButton) {
    await startButton.click();
  } else {
    const replayButton = await page.$("#main-menu-replay-tutorial");
    if (replayButton) {
      await replayButton.click();
    } else {
      const resumeButton = await page.$("#main-menu-skip-tutorial");
      if (resumeButton) {
        await resumeButton.click();
      }
    }
  }

  await page.waitForFunction(
    () => document.getElementById("main-menu-overlay")?.dataset.visible !== "true",
    { timeout: 5000 }
  );
}

function createTutorialEventWaiter(page) {
  let cursor = 0;
  return async function waitForTutorialEvent(matcher, { timeout, description }) {
    return waitFor(
      async () => {
        const analytics = await page.evaluate(() => {
          return window.keyboardDefense?.getTutorialAnalytics?.() ?? null;
        });
        if (!analytics) {
          return false;
        }
        const events = analytics.events ?? [];
        for (let i = cursor; i < events.length; i += 1) {
          const entry = events[i];
          if (matcher(entry)) {
            cursor = i + 1;
            return entry;
          }
        }
        cursor = events.length;
        return false;
      },
      { timeout, description }
    );
  };
}

async function waitForEnemyWord(page, word, { timeout = 6_000 } = {}) {
  await waitFor(
    () =>
      page.evaluate((target) => {
        const kd = window.keyboardDefense;
        if (!kd) return false;
        const enemies = kd.getState().enemies ?? [];
        return enemies.some((enemy) => enemy.word === target);
      }, word),
    { timeout, description: `enemy "${word}" spawn` }
  );
}

async function waitForCombo(page, minCombo, { timeout = 5_000 } = {}) {
  await waitFor(
    () =>
      page.evaluate((combo) => {
        const kd = window.keyboardDefense;
        if (!kd) return false;
        return (kd.getState().typing?.combo ?? 0) >= combo;
      }, minCombo),
    { timeout, description: `combo >= ${minCombo}` }
  );
}

async function waitForShieldLessonEnemy(page, { timeout = 7_000 } = {}) {
  return waitFor(
    () =>
      page.evaluate((word) => {
        const kd = window.keyboardDefense;
        if (!kd) return null;
        const enemies = kd.getState().enemies ?? [];
        const match = enemies.find((enemy) => enemy.word === word);
        if (!match) {
          return null;
        }
        return { id: match.id, word: match.word ?? word };
      }, SHIELD_LESSON_WORD),
    { timeout, description: "shield lesson enemy spawn" }
  );
}

async function waitForShieldBreak(page, enemyId, { timeout = 18_000 } = {}) {
  return waitFor(
    async () => {
      const status = await page.evaluate(
        ({ targetId, fallbackWord }) => {
          const kd = window.keyboardDefense;
          if (!kd) {
            return { status: "pending" };
          }
          const enemies = kd.getState().enemies ?? [];
          const match = enemies.find((enemy) => enemy.id === targetId);
          if (!match) {
            return { status: "missing" };
          }
          if (!match.shield || (match.shield.health ?? 0) <= 0) {
            return { status: "ready", word: match.word ?? fallbackWord };
          }
          return { status: "pending" };
        },
        { targetId: enemyId, fallbackWord: SHIELD_LESSON_WORD }
      );

      if (!status) {
        return false;
      }

      if (status.status === "missing") {
        throw new Error("Shield lesson enemy disappeared before the shield collapsed.");
      }

      if (status.status === "ready") {
        return status;
      }

      return false;
    },
    { timeout, description: "shield break" }
  );
}

async function clickTutorialSlotAction(page, { timeout = 5_000 } = {}) {
  const selector =
    'div.turret-slot[data-tutorial-highlight="true"] button.slot-action:not([disabled])';
  await page.waitForSelector(selector, { timeout, state: "visible" });
  const clicked = await page.evaluate((sel) => {
    const button = document.querySelector(sel);
    if (button instanceof HTMLButtonElement) {
      button.click();
      return true;
    }
    return false;
  }, selector);
  if (!clicked) {
    throw new Error("Failed to trigger highlighted slot action");
  }
}

async function extractTutorialSummaryOverlay(page, { timeout = 8_000 } = {}) {
  return waitFor(
    () =>
      page.evaluate(() => {
        const container = document.getElementById("tutorial-summary");
        if (!container || container.dataset.visible !== "true") return null;
        const stats = {};
        container.querySelectorAll("[data-field]").forEach((node) => {
          if (node instanceof HTMLElement && node.dataset.field) {
            stats[node.dataset.field] = node.textContent ?? "";
          }
        });
        return stats;
      }),
    { timeout, description: "tutorial summary overlay" }
  );
}

async function fetchStateSafe(page) {
  try {
    return await fetchState(page);
  } catch {
    return null;
  }
}

async function performSkipSmoke(page, options = {}) {
  await waitForPageReady(page);
  await prepareAudioIntensity(page, options.audioIntensity);

  const result = await page.evaluate(async () => {
    const kd = window.keyboardDefense;
    if (!kd) throw new Error("keyboardDefense debug API missing for skip run.");
    kd.skipTutorial();
    await new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)));
    const state = kd.getState();
    const analytics = kd.getTutorialAnalytics?.() ?? null;
    return {
      stateSnapshot: {
        time: state.time,
        waveIndex: state.wave.index,
        status: state.status,
        castleHealth: state.castle.health,
        gold: state.resources.gold
      },
      analytics,
      tutorialStorage: window.localStorage.getItem("keyboard-defense:tutorialCompleted")
    };
  });

  const stateBundle = await fetchState(page);
  const assetIntegrity = await fetchAssetIntegritySummary(page);

  return {
    mode: "skip",
    success: true,
    durationMs: 0,
    summaryOverlay: null,
    consoleLogs: [],
    ...result,
    playerSettings: stateBundle.playerSettings ?? null,
    soundSettings: stateBundle.soundSettings ?? null,
    audioIntensity: stateBundle.audioIntensity ?? null,
    assetIntegrity
  };
}

async function fetchAssetIntegritySummary(page) {
  try {
    return await page.evaluate(() => {
      const kd = window.keyboardDefense;
      if (!kd || typeof kd.getAssetIntegritySummary !== "function") {
        return null;
      }
      const summary = kd.getAssetIntegritySummary();
      return summary ? JSON.parse(JSON.stringify(summary)) : null;
    });
  } catch {
    return null;
  }
}

async function performFullTutorialSmoke(page, options = {}) {
  await waitForPageReady(page);
  await prepareAudioIntensity(page, options.audioIntensity);
  await dismissMainMenu(page);
  await ensureTypingFocus(page);
  const consoleLogs = [];
  page.on("console", (msg) => {
    if (msg.type() === "error") return;
    consoleLogs.push({ type: msg.type(), text: msg.text() });
  });
  const waitForEvent = createTutorialEventWaiter(page);

  try {
    await waitForEvent((entry) => entry.event === "start" && entry.stepId === "intro", {
      description: "tutorial start event",
      timeout: 5_000
    });

    await ensureTypingFocus(page);
    await page.keyboard.press("Enter");

    await waitForEvent((entry) => entry.event === "advance" && entry.stepId === "typing-basic", {
      description: "advance to typing-basic",
      timeout: 5_000
    });

    await waitForEnemyWord(page, "valor");
    await page.type("#typing-input", "valor");

    await waitForEvent(
      (entry) => entry.event === "advance" && entry.stepId === "combo-diagnostics",
      { description: "advance to combo-diagnostics", timeout: 5_000 }
    );

    await waitForEnemyWord(page, "focus");
    await page.type("#typing-input", "focus");

    await waitForEnemyWord(page, "flow");
    await page.type("#typing-input", "flow");

    await waitForCombo(page, 2);
    await page.evaluate(() => {
      const kd = window.keyboardDefense;
      kd?.toggleDiagnostics();
    });

    await waitForEvent((entry) => entry.event === "advance" && entry.stepId === "shielded-enemy", {
      description: "advance to shielded-enemy",
      timeout: 7_000
    });
    await resumeGameplay(page, { speed: 2 });
    let shieldStepComplete = false;
    try {
      while (!shieldStepComplete) {
        const shieldEnemy = await waitForShieldLessonEnemy(page);
        await resumeGameplay(page, { speed: 2 });
        await waitForEvent(
          (entry) => entry.stepId === "shielded-enemy" && entry.event === "shield-broken",
          { description: "shield break event", timeout: 20_000 }
        );
        const shieldStatus = await waitForShieldBreak(page, shieldEnemy.id, { timeout: 10_000 });
        const targetWord = shieldStatus.word ?? shieldEnemy.word ?? SHIELD_LESSON_WORD;
        await resumeGameplay(page, { speed: 1 });
        await ensureTypingFocus(page);
        await page.fill("#typing-input", "");
        await page.type("#typing-input", targetWord, { delay: 60 });
        const outcome = await waitForEvent(
          (entry) =>
            entry.stepId === "shielded-enemy" &&
            (entry.event === "typed-finish" ||
              entry.event === "event:typing:word-complete" ||
              entry.event === "retry"),
          { description: "shield enemy resolution", timeout: 8_000 }
        );
        if (outcome.event === "typed-finish" || outcome.event === "event:typing:word-complete") {
          if (outcome.event === "event:typing:word-complete") {
            await page.evaluate(() => {
              window.keyboardDefense?.completeTutorialStep?.("shielded-enemy");
            });
          }
          shieldStepComplete = true;
        } else {
          await resumeGameplay(page, { speed: 2 });
          await waitForEvent(
            (entry) => entry.stepId === "shielded-enemy" && entry.event === "spawned",
            { description: "shield retry spawn", timeout: 6_000 }
          );
        }
      }
    } finally {
      await resumeGameplay(page, { speed: 1 });
    }

    await waitForEvent(
      (entry) => entry.event === "advance" && entry.stepId === "turret-placement",
      { description: "advance to turret-placement", timeout: 5_000 }
    );

    await clickTutorialSlotAction(page, { timeout: 6_000 });

    await waitForEvent((entry) => entry.event === "advance" && entry.stepId === "turret-upgrade", {
      description: "advance to turret-upgrade",
      timeout: 6_000
    });

    await clickTutorialSlotAction(page, { timeout: 6_000 });

    await waitForEvent((entry) => entry.event === "advance" && entry.stepId === "castle-health", {
      description: "advance to castle-health",
      timeout: 6_000
    });

    await waitForEvent((entry) => entry.event === "advance" && entry.stepId === "wrap-up", {
      description: "advance to wrap-up",
      timeout: 15_000
    });

    const summaryOverlay = await extractTutorialSummaryOverlay(page);

    await page.click("#tutorial-summary-continue", { timeout: 5_000 });

    await waitForEvent((entry) => entry.event === "complete", {
      description: "tutorial completion",
      timeout: 6_000
    });

    const stateBundle = await fetchState(page);
    const analyticsPayload = stateBundle.state.analytics
      ? cloneSimple(stateBundle.state.analytics)
      : {};
    if (stateBundle.tutorialAnalytics) {
      analyticsPayload.tutorial = stateBundle.tutorialAnalytics;
    }

    const assetIntegrity = await fetchAssetIntegritySummary(page);
    return {
      mode: "full",
      success: true,
      durationMs: stateBundle.state.time * 1000,
      summaryOverlay,
      consoleLogs,
      stateSnapshot: {
        time: stateBundle.state.time,
        status: stateBundle.state.status,
        waveIndex: stateBundle.state.wave.index,
        castle: {
          level: stateBundle.state.castle.level,
          health: stateBundle.state.castle.health,
          maxHealth: stateBundle.state.castle.maxHealth
        },
        resources: { ...stateBundle.state.resources }
      },
      analytics: analyticsPayload,
      tutorialStorage: stateBundle.tutorialStorage,
      playerSettings: stateBundle.playerSettings ?? null,
      soundSettings: stateBundle.soundSettings ?? null,
      audioIntensity: stateBundle.audioIntensity ?? null,
      assetIntegrity
    };
  } catch (error) {
    const failureState = await fetchStateSafe(page);
    const failedIntegrity = await fetchAssetIntegritySummary(page);
    const context = {
      mode: "full",
      success: false,
      durationMs:
        failureState?.state?.time != null ? Math.round(failureState.state.time * 1000) : null,
      consoleLogs,
      stateSnapshot: failureState?.state ?? null,
      analytics: failureState?.state?.analytics ?? null,
      tutorialAnalytics: failureState?.tutorialAnalytics ?? null,
      tutorialStorage: failureState?.tutorialStorage ?? null,
      playerSettings: failureState?.playerSettings ?? null,
      soundSettings: failureState?.soundSettings ?? null,
      audioIntensity: failureState?.audioIntensity ?? null,
      assetIntegrity: failedIntegrity,
      error: {
        message: error instanceof Error ? error.message : String(error),
        stack: error instanceof Error ? (error.stack ?? null) : null
      }
    };
    if (error && typeof error === "object") {
      Reflect.set(error, "context", context);
    }
    throw error;
  }
}

async function performCampaignSmoke(page, options = {}) {
  await waitForPageReady(page);
  await prepareAudioIntensity(page, options.audioIntensity);
  await ensureTypingFocus(page);
  await page.evaluate(() => {
    const kd = window.keyboardDefense;
    kd?.skipTutorial?.();
  });
  await dismissMainMenu(page);
  await ensureTypingFocus(page);

  const campaignSetup = await page.evaluate(() => {
    const kd = window.keyboardDefense;
    if (!kd) throw new Error("keyboardDefense debug API unavailable for campaign smoke.");

    kd.resume?.();
    const state = kd.getState();
    const unlocked = state.turrets.find((slot) => slot.unlocked) ?? state.turrets[0];
    if (!unlocked) {
      throw new Error("No turret slot available for campaign smoke.");
    }

    kd.grantGold(1000);
    kd.placeTurret(unlocked.id, "arrow");
    kd.step?.(180);

    const enemyLane = unlocked.lane ?? 0;
    kd.spawnEnemy({
      tierId: "grunt",
      lane: enemyLane,
      word: "ember",
      waveIndex: state.wave.index
    });
    kd.step?.(30);
    kd.simulateTyping("ember");
    kd.step?.(240);

    const after = kd.getState();
    return {
      slotId: unlocked.id,
      lane: enemyLane,
      waveIndex: after.wave.index,
      time: after.time,
      gold: after.resources.gold,
      enemiesDefeated: after.analytics.enemiesDefeated,
      totalDamage: after.analytics.totalDamageDealt,
      analytics: after.analytics
    };
  });

  await waitFor(
    () =>
      page.evaluate(() => {
        const kd = window.keyboardDefense;
        return (kd?.getState?.().analytics.enemiesDefeated ?? 0) >= 1;
      }),
    { timeout: 5_000, description: "campaign enemy defeat" }
  );

  const stateBundle = await fetchState(page);
  const analyticsPayload = stateBundle.state.analytics
    ? cloneSimple(stateBundle.state.analytics)
    : {};
  analyticsPayload.metadata = campaignSetup;

  const assetIntegrity = await fetchAssetIntegritySummary(page);
  return {
    mode: "campaign",
    success: true,
    durationMs: stateBundle.state.time * 1000,
    consoleLogs: [],
    stateSnapshot: {
      time: stateBundle.state.time,
      status: stateBundle.state.status,
      waveIndex: stateBundle.state.wave.index,
      castle: {
        level: stateBundle.state.castle.level,
        health: stateBundle.state.castle.health,
        maxHealth: stateBundle.state.castle.maxHealth
      },
      resources: { ...stateBundle.state.resources }
    },
    analytics: analyticsPayload,
    tutorialStorage: stateBundle.tutorialStorage,
    playerSettings: stateBundle.playerSettings ?? null,
    soundSettings: stateBundle.soundSettings ?? null,
    audioIntensity: stateBundle.audioIntensity ?? null,
    assetIntegrity
  };
}

export function buildArtifact({ baseUrl, mode, result, startedAt, requestedAudioIntensity = null }) {
  const capturedAt = new Date().toISOString();
  const status = result.success ? "success" : "failure";
  const analyticsSource =
    result.analytics ?? result.stateSnapshot?.analytics ?? result.state?.analytics ?? null;
  const analytics = analyticsSource ? cloneSimple(analyticsSource) : null;
  const shieldBreaks =
    analytics?.totalShieldBreaks ??
    analytics?.tutorial?.events?.filter((event) => event.event === "shield-broken")?.length ??
    null;
  const passiveUnlocksSource =
    analytics?.castlePassiveUnlocks ?? result.stateSnapshot?.analytics?.castlePassiveUnlocks ?? [];
  const passiveUnlocks = Array.isArray(passiveUnlocksSource)
    ? cloneSimple(passiveUnlocksSource)
    : [];
  const passiveUnlockSummary =
    passiveUnlocks.length > 0 ? summarizePassiveUnlocks(passiveUnlocks) : null;
  const lastPassiveUnlock =
    passiveUnlocks.length > 0
      ? formatPassiveUnlockSummary(passiveUnlocks[passiveUnlocks.length - 1])
      : null;
  const castlePassivesSource =
    result.state?.castle?.passives ??
    result.stateSnapshot?.castle?.passives ??
    analytics?.passives ??
    [];
  const activeCastlePassives = Array.isArray(castlePassivesSource)
    ? cloneSimple(castlePassivesSource)
    : [];
  const referenceTime =
    result.stateSnapshot?.time ?? result.state?.time ?? analytics?.time ?? null;
  const recentGoldEvents = normalizeGoldEvents(
    analytics?.goldEvents ??
      result.stateSnapshot?.analytics?.goldEvents ??
      result.state?.analytics?.goldEvents ??
      result.stateSnapshot?.state?.analytics?.goldEvents,
    referenceTime
  );
  const soundLive = extractSoundSettings(result.soundSettings);
  const soundStored = extractSoundSettings(
    result.playerSettings
      ? {
          soundEnabled: result.playerSettings.soundEnabled,
          soundVolume: result.playerSettings.soundVolume,
          audioIntensity: result.playerSettings.audioIntensity
        }
      : null
  );
  const settings = {
    soundEnabled: soundLive.soundEnabled ?? soundStored.soundEnabled,
    soundVolume: soundLive.soundVolume ?? soundStored.soundVolume,
    soundIntensity: soundLive.soundIntensity ?? soundStored.soundIntensity,
    sources: {
      live: soundLive,
      stored: soundStored
    }
  };
  const audioProbe = result.audioIntensity ?? null;
  const historySource =
    audioProbe?.history ?? analytics?.audioIntensityHistory ?? result.audioIntensityHistory ?? [];
  const audioHistory = sanitizeAudioIntensityHistory(historySource);
  if (analytics && !analytics.audioIntensityHistory && audioHistory.length > 0) {
    analytics.audioIntensityHistory = audioHistory;
  }
  const requested =
    Number.isFinite(requestedAudioIntensity) && requestedAudioIntensity > 0
      ? roundTo(requestedAudioIntensity)
      : null;
  const recordedProbe =
    typeof audioProbe?.applied === "number" ? roundTo(audioProbe.applied) : null;
  const recordedSettings = settings.soundIntensity ?? null;
  const recorded = recordedProbe ?? recordedSettings ?? null;
  const historyValues = audioHistory
    .map((entry) => entry.to)
    .filter((value) => value !== null);
  const averageIntensity = average(historyValues) ?? recorded;
  const deltaIntensity =
    historyValues.length >= 2
      ? roundTo(historyValues[historyValues.length - 1] - historyValues[0])
      : null;
  const audioIntensity = {
    requested,
    recorded,
    recordedSource: recordedProbe !== null ? "probe" : recordedSettings !== null ? "settings" : null,
    average: averageIntensity,
    delta: deltaIntensity,
    historySamples: audioHistory.length,
    history: audioHistory
  };
  const flags = {};
  if (requested !== null) {
    flags.audioIntensity = requested;
  }

  const artifact = {
    baseUrl,
    mode,
    startedAt,
    capturedAt,
    status,
    durationMs: result.durationMs ?? null,
    tutorialStorage: result.tutorialStorage ?? null,
    state: result.stateSnapshot ?? result.state ?? null,
    analytics,
    summaryOverlay: result.summaryOverlay ?? null,
    consoleLogs: result.consoleLogs ?? [],
    error: result.error ?? null,
    assetIntegrity: result.assetIntegrity ?? null,
    shieldBreaks,
    tutorialEvents: analytics?.tutorial?.events ?? null,
    passiveUnlockCount: passiveUnlocks.length,
    passiveUnlocks,
    passiveUnlockSummary,
    lastPassiveUnlock,
    activeCastlePassives,
    recentGoldEvents,
    settings,
    audioIntensity
  };

  if (Object.keys(flags).length > 0) {
    artifact.flags = flags;
  }

  return artifact;
}

async function runSmoke(baseUrl, artifactPath, mode, options = {}) {
  const chromium = await loadChromium();
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    storageState: { origins: [] }
  });
  const page = await context.newPage();
  const startedAt = new Date().toISOString();

  try {
    await page.goto(baseUrl, { waitUntil: "networkidle" });
  } catch (error) {
    throw new Error(
      `Failed to load ${baseUrl}. Ensure the dev server is running. ${
        error instanceof Error ? error.message : String(error)
      }`
    );
  }

  let result;
  let failureError = null;
  try {
    if (mode === "skip") {
      result = await performSkipSmoke(page, options);
    } else if (mode === "campaign") {
      result = await performCampaignSmoke(page, options);
    } else {
      result = await performFullTutorialSmoke(page, options);
    }
  } catch (error) {
    failureError = error instanceof Error ? error : new Error(String(error));
    const context =
      error && typeof error === "object" && "context" in error
        ? Reflect.get(error, "context")
        : null;
    if (context && typeof context === "object") {
      result = context;
    } else {
      result = {
        mode,
        success: false,
        consoleLogs: [],
        error: {
          message: failureError.message,
          stack: failureError.stack ?? null
        }
      };
    }
  } finally {
    await browser.close();
  }

  if (!result) {
    throw failureError ?? new Error("Tutorial smoke failed without producing a result.");
  }

  const artifactDir = path.dirname(artifactPath);
  fs.mkdirSync(artifactDir, { recursive: true });
  const artifact = buildArtifact({
    baseUrl,
    mode,
    result,
    startedAt,
    requestedAudioIntensity: options.audioIntensity ?? null
  });
  fs.writeFileSync(artifactPath, JSON.stringify(artifact, null, 2));
  console.log(
    `Tutorial smoke (${mode}) complete with status "${artifact.status}". Artifact written to ${artifactPath}`
  );

  if (!result.success) {
    throw failureError ?? new Error(`Tutorial smoke (${mode}) failed.`);
  }
}

async function main() {
  const argv = process.argv.slice(2);
  let args;
  try {
    args = parseArgs(argv);
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
    return;
  }

  if (args.help) {
    printHelp();
    process.exit(0);
    return;
  }

  try {
    const mode = validateMode(args.mode);
    const validatedUrl = new url.URL(args.baseUrl);
    await runSmoke(validatedUrl.toString(), args.artifact, mode, {
      audioIntensity: args.audioIntensity
    });
  } catch (error) {
    console.error(
      error instanceof Error ? error.message : `Tutorial smoke error: ${String(error)}`
    );
    process.exit(1);
  }
}

if (
  import.meta.url === `file://${process.argv[1]}` ||
  process.argv[1]?.endsWith("tutorialSmoke.mjs")
) {
  await main();
}
