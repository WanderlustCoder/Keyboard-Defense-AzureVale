#!/usr/bin/env node
/**
 * Throttled-device performance smoke.
 *
 * Starts the local dev server, opens the app in Playwright Chromium, applies a CPU throttle,
 * simulates light typing for a fixed duration, and records frame-time + heap metrics.
 *
 * Intended for CI guardrails (Season 4 #98).
 */

import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import { pathToFileURL } from "node:url";

import { startServer, stopServer } from "../devServer.mjs";

const DEFAULT_DURATION_MS = sanitizeInt(process.env.PERF_SMOKE_DURATION_MS, 12_000);
const DEFAULT_DELAY_MS = sanitizeInt(process.env.PERF_SMOKE_DELAY_MS, 35);
const DEFAULT_CPU_THROTTLE = sanitizeNumber(process.env.PERF_SMOKE_CPU_THROTTLE, 4);
const DEFAULT_TIMEOUT_MS = sanitizeInt(process.env.PERF_SMOKE_TIMEOUT_MS, 45_000);
const DEFAULT_SPAWN_COUNT = sanitizeInt(process.env.PERF_SMOKE_SPAWN_COUNT, 18);
const DEFAULT_WORDS = [
  "arrow",
  "shield",
  "castle",
  "tower",
  "flame",
  "stone",
  "guard",
  "brace"
];

const DEFAULT_ARTIFACT_DIR = path.resolve("artifacts", "perf");
const DEFAULT_ARTIFACT_NAME = "perf-smoke-summary.json";
const DEFAULT_ARTIFACT_NAME_CI = "perf-smoke-summary.ci.json";

function sanitizeInt(value, fallback) {
  const parsed = Number.parseInt(String(value ?? ""), 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

function sanitizeNumber(value, fallback) {
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

function percentile(values, p) {
  if (!Array.isArray(values) || values.length === 0) return null;
  const sorted = [...values].sort((a, b) => a - b);
  const rank = Math.max(0, Math.min(sorted.length - 1, Math.round(p * (sorted.length - 1))));
  return sorted[rank];
}

function summarizeFrames(deltas, durationMs) {
  const samples = Array.isArray(deltas)
    ? deltas.map((value) => Number(value)).filter((value) => Number.isFinite(value) && value >= 0)
    : [];
  const duration = Number.isFinite(durationMs) && durationMs > 0 ? durationMs : null;
  const frames = samples.length;
  const fps = duration ? frames / (duration / 1000) : null;
  const avg = frames ? samples.reduce((sum, value) => sum + value, 0) / frames : null;
  const p50 = percentile(samples, 0.5);
  const p95 = percentile(samples, 0.95);
  const max = frames ? Math.max(...samples) : null;
  const over50 = samples.filter((value) => value >= 50).length;
  const over100 = samples.filter((value) => value >= 100).length;
  const over200 = samples.filter((value) => value >= 200).length;

  return {
    frames,
    fps: fps !== null ? Math.round(fps * 100) / 100 : null,
    frameMs: {
      avg: avg !== null ? Math.round(avg * 100) / 100 : null,
      p50,
      p95,
      max
    },
    longFrames: { over50, over100, over200 }
  };
}

async function writeJson(outPath, payload) {
  const resolved = path.isAbsolute(outPath) ? outPath : path.resolve(outPath);
  await fs.mkdir(path.dirname(resolved), { recursive: true });
  await fs.writeFile(resolved, JSON.stringify(payload, null, 2) + "\n", "utf8");
  return resolved;
}

async function loadChromium() {
  try {
    const mod = await import("@playwright/test");
    return mod.chromium;
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    throw new Error(
      `Playwright Chromium is required for perf smoke. Run "npx playwright install --with-deps chromium". (${message})`
    );
  }
}

function parseArgs(argv) {
  const options = {
    ci: false,
    headful: false,
    noBuild: process.env.PERF_SMOKE_NO_BUILD === "1",
    timeoutMs: DEFAULT_TIMEOUT_MS,
    durationMs: DEFAULT_DURATION_MS,
    delayMs: DEFAULT_DELAY_MS,
    cpuThrottle: DEFAULT_CPU_THROTTLE,
    spawnCount: DEFAULT_SPAWN_COUNT,
    words: [...DEFAULT_WORDS],
    artifact: null,
    help: false
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--ci":
        options.ci = true;
        break;
      case "--headful":
        options.headful = true;
        break;
      case "--no-build":
      case "--skip-build":
        options.noBuild = true;
        break;
      case "--timeout":
        options.timeoutMs = sanitizeInt(argv[++i], options.timeoutMs);
        break;
      case "--duration":
        options.durationMs = sanitizeInt(argv[++i], options.durationMs);
        break;
      case "--delay":
        options.delayMs = sanitizeInt(argv[++i], options.delayMs);
        break;
      case "--cpu-throttle": {
        const parsed = Number(argv[++i]);
        if (Number.isFinite(parsed)) {
          options.cpuThrottle = parsed;
        }
        break;
      }
      case "--spawn":
        options.spawnCount = sanitizeInt(argv[++i], options.spawnCount);
        break;
      case "--words": {
        const raw = argv[++i] ?? "";
        const parsed = raw
          .split(",")
          .map((word) => word.trim())
          .filter(Boolean);
        if (parsed.length > 0) {
          options.words = parsed;
        }
        break;
      }
      case "--artifact":
        options.artifact = argv[++i] ?? null;
        break;
      case "--help":
      case "-h":
        options.help = true;
        break;
      default:
        if (token.startsWith("-")) {
          throw new Error(`Unknown option "${token}". Use --help for usage.`);
        }
        break;
    }
  }

  if (!Number.isFinite(options.cpuThrottle) || options.cpuThrottle < 1) {
    options.cpuThrottle = 1;
  }
  if (!Number.isFinite(options.spawnCount) || options.spawnCount < 0) {
    options.spawnCount = DEFAULT_SPAWN_COUNT;
  }

  const artifactName = options.ci ? DEFAULT_ARTIFACT_NAME_CI : DEFAULT_ARTIFACT_NAME;
  options.artifact =
    options.artifact ??
    path.join(DEFAULT_ARTIFACT_DIR, artifactName);

  return options;
}

function printHelp() {
  console.log(`Keyboard Defense perf smoke (throttled device)

Usage:
  node scripts/ci/perfSmoke.mjs [options]

Options:
  --ci                 Write a CI-friendly artifact name (default false)
  --no-build            Skip dev-server build step (default via PERF_SMOKE_NO_BUILD=1)
  --duration <ms>       Sample duration (default ${DEFAULT_DURATION_MS})
  --delay <ms>          Typing delay between characters (default ${DEFAULT_DELAY_MS})
  --cpu-throttle <n>    Chromium CPU throttle rate (default ${DEFAULT_CPU_THROTTLE})
  --spawn <n>           Extra enemies to spawn (default ${DEFAULT_SPAWN_COUNT})
  --words a,b,c         Words to loop through while typing (default built-in list)
  --timeout <ms>        Global timeout (default ${DEFAULT_TIMEOUT_MS})
  --artifact <path>     Output JSON file (default artifacts/perf/perf-smoke-summary*.json)
  --headful             Show browser window (default headless)
  --help                Show this help
`);
}

async function runTypingLoop(page, options) {
  const startedAt = Date.now();
  const deadline = startedAt + options.durationMs;
  let wordsTyped = 0;
  let charsTyped = 0;
  let index = 0;
  while (Date.now() < deadline) {
    const word = options.words[index % options.words.length] ?? "arrow";
    await page.type("#typing-input", `${word} `, { delay: options.delayMs });
    wordsTyped += 1;
    charsTyped += word.length + 1;
    index += 1;
  }
  return { wordsTyped, charsTyped };
}

async function measureFrames(page, durationMs) {
  return page.evaluate((windowDurationMs) => {
    return new Promise((resolve) => {
      const memory = performance?.memory ?? null;
      const memoryAvailable = Boolean(memory && typeof memory.usedJSHeapSize === "number");
      const heapStart = memoryAvailable ? memory.usedJSHeapSize : null;
      let heapMax = heapStart;
      const deltas = [];
      let last = performance.now();
      const start = last;

      const tick = (now) => {
        deltas.push(now - last);
        last = now;
        if (memoryAvailable) {
          heapMax = Math.max(heapMax ?? 0, memory.usedJSHeapSize);
        }
        if (now - start >= windowDurationMs) {
          resolve({
            durationMs: now - start,
            deltas,
            heapUsedStart: heapStart,
            heapUsedEnd: memoryAvailable ? memory.usedJSHeapSize : null,
            heapUsedMax: heapMax
          });
          return;
        }
        requestAnimationFrame(tick);
      };

      requestAnimationFrame(tick);
    });
  }, durationMs);
}

function bytesToMB(value) {
  const numeric = Number(value);
  if (!Number.isFinite(numeric) || numeric < 0) return null;
  return Math.round((numeric / 1024 / 1024) * 100) / 100;
}

async function runPerfSmoke(options) {
  const summary = {
    status: "pending",
    startedAt: new Date().toISOString(),
    finishedAt: null,
    options: {
      durationMs: options.durationMs,
      delayMs: options.delayMs,
      cpuThrottle: options.cpuThrottle,
      spawnCount: options.spawnCount,
      words: options.words,
      noBuild: options.noBuild,
      headful: options.headful
    },
    server: null,
    metrics: null,
    state: null,
    errors: [],
    warnings: [],
    artifact: null
  };

  let serverState = null;
  let browser = null;
  let stage = "init";
  const pageErrors = [];
  try {
    stage = "server:start";
    serverState = await startServer({ noBuild: options.noBuild, forceRestart: true });
    summary.server = {
      url: serverState.url ?? null,
      pid: serverState.pid ?? null,
      startedAt: serverState.startedAt ?? null,
      readyAt: serverState.readyAt ?? null,
      flags: serverState.flags ?? []
    };

    stage = "playwright:launch";
    const chromium = await loadChromium();
    browser = await chromium.launch({ headless: !options.headful });
    const context = await browser.newContext({ viewport: { width: 1280, height: 720 } });
    await context.addInitScript(() => {
      try {
        localStorage.clear();
        sessionStorage.clear();
      } catch {
        // ignore
      }
    });
    const page = await context.newPage();

    page.on("pageerror", (error) => {
      pageErrors.push(error instanceof Error ? error.message : String(error));
    });
    page.on("console", (msg) => {
      if (msg.type() === "error") {
        pageErrors.push(`console: ${msg.text()}`);
      }
    });

    if (options.cpuThrottle > 1) {
      try {
        stage = "playwright:cpu-throttle";
        const cdp = await context.newCDPSession(page);
        await cdp.send("Emulation.setCPUThrottlingRate", { rate: options.cpuThrottle });
      } catch (error) {
        summary.warnings.push(
          `Failed to apply CPU throttling rate ${options.cpuThrottle}: ${
            error instanceof Error ? error.message : String(error)
          }`
        );
      }
    }

    stage = "page:goto";
    await page.goto(serverState.url, { waitUntil: "networkidle", timeout: options.timeoutMs });
    stage = "page:boot";
    await page.waitForFunction(
      () => Boolean(window.keyboardDefense && typeof window.keyboardDefense.getState === "function"),
      null,
      { timeout: options.timeoutMs }
    );
    await page.waitForSelector("#typing-input", { timeout: options.timeoutMs });

    stage = "menu:await";
    await page.waitForFunction(
      () => {
        const overlay = document.getElementById("main-menu-overlay");
        const menuVisible = overlay?.getAttribute("data-visible") === "true";
        const state = window.keyboardDefense?.getState?.();
        const running = Boolean(state && typeof state.time === "number" && state.time > 0);
        return menuVisible || running;
      },
      null,
      { timeout: options.timeoutMs }
    );

    stage = "menu:dismiss";
    const menuVisible = await page.evaluate(() => {
      const overlay = document.getElementById("main-menu-overlay");
      return overlay?.getAttribute("data-visible") === "true";
    });
    if (menuVisible) {
      stage = "accessibility:dismiss";
      const accessibilityVisible = await page.evaluate(() => {
        const overlay = document.getElementById("accessibility-onboarding");
        return overlay?.getAttribute("data-visible") === "true";
      });
      if (accessibilityVisible) {
        try {
          await page.click("#accessibility-skip", { timeout: options.timeoutMs });
        } catch {
          await page.evaluate(() => {
            const button = document.getElementById("accessibility-skip");
            if (button instanceof HTMLButtonElement) {
              button.click();
            }
          });
        }
        await page.waitForFunction(
          () => {
            const overlay = document.getElementById("accessibility-onboarding");
            return !overlay || overlay.getAttribute("data-visible") === "false";
          },
          null,
          { timeout: options.timeoutMs }
        );
      }

      stage = "menu:dismiss";
      await page.click("#main-menu-skip-tutorial", { timeout: options.timeoutMs });
    }

    stage = "game:await-running";
    await page.waitForFunction(
      () => {
        const overlay = document.getElementById("main-menu-overlay");
        const menuHidden = !overlay || overlay.getAttribute("data-visible") === "false";
        const state = window.keyboardDefense?.getState?.();
        const running = Boolean(state && typeof state.time === "number" && state.time > 0);
        return menuHidden && running;
      },
      null,
      { timeout: options.timeoutMs }
    );

    stage = "scenario:setup";
    await page.evaluate(({ spawnCount, words }) => {
      const kd = window.keyboardDefense;
      if (!kd) return;
      try {
        kd.grantGold?.(5000);
        kd.placeTurret?.("slot-1", "arrow");
        kd.placeTurret?.("slot-2", "arcane");
        kd.upgradeTurret?.("slot-1");
        kd.upgradeTurret?.("slot-2");
      } catch {
        // ignore
      }

      const list = Array.isArray(words) && words.length > 0 ? words : ["arrow", "shield"];
      for (let i = 0; i < spawnCount; i += 1) {
        const word = list[i % list.length] ?? "arrow";
        try {
          kd.spawnEnemy?.({
            tierId: "grunt",
            lane: i % 3,
            order: 9000 + i,
            word
          });
        } catch {
          // ignore
        }
      }
    }, { spawnCount: options.spawnCount, words: options.words });

    stage = "scenario:type";
    await page.focus("#typing-input");

    const [frameSample, typed] = await Promise.all([
      measureFrames(page, options.durationMs),
      runTypingLoop(page, options)
    ]);

    const stateSummary = await page.evaluate(() => {
      const state = window.keyboardDefense?.getState?.();
      if (!state || typeof state !== "object") return null;
      const enemies = Array.isArray(state.enemies) ? state.enemies : [];
      const projectiles = Array.isArray(state.projectiles) ? state.projectiles : [];
      const alive = enemies.filter((enemy) => enemy && enemy.status === "alive").length;
      const breaches =
        state.analytics?.sessionBreaches ??
        state.core?.breaches ??
        state.breaches ??
        null;
      return {
        status: state.status ?? null,
        time: typeof state.time === "number" ? state.time : null,
        waveIndex: typeof state.wave?.index === "number" ? state.wave.index : null,
        enemiesAlive: alive,
        projectiles: projectiles.length,
        breaches
      };
    });

    if (pageErrors.length > 0) {
      summary.errors.push(...pageErrors);
    }

    const frameStats = summarizeFrames(frameSample.deltas, frameSample.durationMs);
    summary.metrics = {
      durationMs: Math.round(frameSample.durationMs),
      ...frameStats,
      heapUsedMB: {
        start: bytesToMB(frameSample.heapUsedStart),
        end: bytesToMB(frameSample.heapUsedEnd),
        max: bytesToMB(frameSample.heapUsedMax)
      },
      typedWords: typed.wordsTyped,
      typedChars: typed.charsTyped
    };
    summary.state = stateSummary;
    summary.status = summary.errors.length > 0 ? "fail" : "success";
  } catch (error) {
    summary.status = "fail";
    const message = error instanceof Error ? error.message : String(error);
    summary.errors.push(`[${stage}] ${message}`);
    if (pageErrors.length > 0) {
      summary.errors.push(...pageErrors.map((entry) => `[page] ${entry}`));
    }
  } finally {
    summary.finishedAt = new Date().toISOString();
    try {
      if (browser) {
        await browser.close();
      }
    } catch {
      // ignore
    }
    try {
      if (serverState?.pid) {
        await stopServer({ quiet: true });
      }
    } catch {
      // ignore
    }
  }

  summary.artifact = path.isAbsolute(options.artifact)
    ? options.artifact
    : path.resolve(options.artifact);
  await writeJson(summary.artifact, summary);
  return summary;
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  if (options.help) {
    printHelp();
    process.exit(0);
  }
  const result = await runPerfSmoke(options);
  if (result.status !== "success") {
    console.error(`[perf-smoke] Failed. See ${result.artifact ?? options.artifact}`);
    process.exitCode = 1;
  } else {
    console.log(
      `[perf-smoke] Success: ${result.metrics?.fps ?? "?"} fps (p95 ${
        result.metrics?.frameMs?.p95 ?? "?"
      } ms), heap max ${result.metrics?.heapUsedMB?.max ?? "?"} MB. Artifact: ${result.artifact}`
    );
  }
}

const entryPoint = process.argv[1];
if (typeof entryPoint === "string" && import.meta.url === pathToFileURL(entryPoint).href) {
  await main();
}

export { parseArgs, summarizeFrames, runPerfSmoke };
