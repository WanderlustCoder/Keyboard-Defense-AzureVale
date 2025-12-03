#!/usr/bin/env node

/**
 * Input Stress Test Harness
 *
 * Simulates rapid key bursts (including holds, wrong keys, and backspaces)
 * against TypingSystem to flush out buffer overflow regressions and
 * performance cliffs. Outputs a JSON summary to stdout and an optional file.
 */

import { promises as fs } from "node:fs";
import path from "node:path";
import process from "node:process";
import { performance } from "node:perf_hooks";

import { defaultConfig } from "../../public/dist/src/core/config.js";
import { TypingSystem } from "../../public/dist/src/systems/typingSystem.js";

const DEFAULT_BURSTS = 25;
const DEFAULT_BURST_SIZE = 400;
const DEFAULT_OUT_PATH = "artifacts/summaries/input-stress.json";

function printHelp() {
  console.log(`Input Stress Test Harness

Usage:
  node scripts/ci/inputStressTest.mjs [options]

Options:
  --bursts <n>        Number of bursts to run (default: ${DEFAULT_BURSTS})
  --burst-size <n>    Inputs per burst (default: ${DEFAULT_BURST_SIZE})
  --out <path>        Write summary JSON to path (default: ${DEFAULT_OUT_PATH})
  --help              Show this help message

Description:
  Generates rapid key bursts mixing correct characters, wrong keys, holds, and
  backspaces. Verifies buffers never exceed word length, counts outcomes, and
  reports throughput (ops/sec) so CI can catch input regressions early.`);
}

function parseArgs(argv) {
  const options = {
    bursts: DEFAULT_BURSTS,
    burstSize: DEFAULT_BURST_SIZE,
    out: DEFAULT_OUT_PATH,
    help: false
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--bursts":
        options.bursts = Number.parseInt(argv[++i] ?? options.bursts, 10);
        break;
      case "--burst-size":
        options.burstSize = Number.parseInt(argv[++i] ?? options.burstSize, 10);
        break;
      case "--out":
        options.out = argv[++i] ?? options.out;
        break;
      case "--help":
        options.help = true;
        break;
      default:
        throw new Error(`Unknown option '${token}'. Use --help for usage.`);
    }
  }

  if (!Number.isFinite(options.bursts) || options.bursts <= 0) {
    options.bursts = DEFAULT_BURSTS;
  }
  if (!Number.isFinite(options.burstSize) || options.burstSize <= 0) {
    options.burstSize = DEFAULT_BURST_SIZE;
  }
  return {
    ...options,
    out: options.out ? path.resolve(options.out) : null
  };
}

function createEnemy(word, id) {
  return {
    id,
    word,
    typed: 0,
    distance: 1,
    status: "alive",
    maxHealth: 50,
    health: 50,
    lane: 0,
    spawnedAt: 0
  };
}

function createState(word, id) {
  return {
    time: 0,
    typing: {
      buffer: "",
      activeEnemyId: id,
      errors: 0,
      combo: 0,
      comboTimer: 0,
      comboWarning: false,
      totalInputs: 0,
      correctInputs: 0,
      recentInputs: [],
      recentCorrectInputs: 0,
      recentAccuracy: 1,
      dynamicDifficultyBias: 0
    },
    enemies: [createEnemy(word, id)],
    analytics: {
      waveReactionTime: 0,
      waveReactionSamples: 0,
      totalReactionTime: 0,
      reactionSamples: 0,
      waveTypingDamage: 0,
      wavePerfectWords: 0,
      totalPerfectWords: 0,
      waveMaxCombo: 0,
      sessionBestCombo: 0,
      totalTypingDamage: 0,
      totalDamageDealt: 0
    }
  };
}

const fakeEvents = {
  emitted: [],
  emit(event, payload) {
    this.emitted.push({ event, payload });
  }
};

const fakeEnemySystem = {
  damageEnemy(_state, _enemyId, damage) {
    return { damage };
  }
};

function pickWord(wordBank) {
  const index = Math.floor(Math.random() * wordBank.length);
  return wordBank[index];
}

function pickAction() {
  const roll = Math.random();
  if (roll < 0.1) return "backspace";
  if (roll < 0.25) return "hold";
  if (roll < 0.45) return "wrong";
  return "correct";
}

function ensureActive(state, wordBank, enemyCounter) {
  const activeId = state.typing.activeEnemyId;
  const activeEnemy = state.enemies.find((enemy) => enemy.id === activeId);
  if (activeEnemy && activeEnemy.status === "alive") {
    return activeEnemy;
  }
  const word = pickWord(wordBank);
  const enemy = createEnemy(word, `enemy-${enemyCounter}`);
  state.enemies = [enemy];
  state.typing.activeEnemyId = enemy.id;
  return enemy;
}

function runBurst(typing, state, wordBank, burstSize, stats, enemyCounterRef) {
  let lastChar = "a";
  for (let i = 0; i < burstSize; i += 1) {
    const enemy = ensureActive(state, wordBank, ++enemyCounterRef.count);
    const action = pickAction();
    let char = "";
    switch (action) {
      case "backspace":
        typing.handleBackspace(state);
        stats.backspaces += 1;
        state.time += 0.05;
        continue;
      case "hold":
        char = lastChar;
        stats.holds += 1;
        break;
      case "wrong":
        char = "z";
        stats.wrong += 1;
        break;
      default:
        char = enemy.word.charAt(enemy.typed) || enemy.word.slice(-1);
        stats.correct += 1;
        break;
    }
    lastChar = char;
    const result = typing.inputCharacter(state, char, fakeEnemySystem);
    stats.ops += 1;
    stats[result.status] = (stats[result.status] ?? 0) + 1;
    stats.maxBuffer = Math.max(stats.maxBuffer, state.typing.buffer.length);
    stats.maxCombo = Math.max(stats.maxCombo, state.typing.combo ?? 0);
    if (result.status === "completed") {
      stats.completions += 1;
      // reset for next enemy
      state.typing.activeEnemyId = null;
    } else if (result.status === "error") {
      stats.errors += 1;
    } else if (result.status === "ignored") {
      stats.ignored += 1;
    }
    state.time += 0.05;
    if (state.typing.buffer.length > enemy.word.length + 1) {
      throw new Error(
        `Buffer overflow detected (len=${state.typing.buffer.length}, word=${enemy.word.length})`
      );
    }
  }
}

async function writeSummary(outPath, summary) {
  if (!outPath) return;
  const dir = path.dirname(outPath);
  await fs.mkdir(dir, { recursive: true });
  await fs.writeFile(outPath, JSON.stringify(summary, null, 2), "utf-8");
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    printHelp();
    return;
  }
  const typing = new TypingSystem(defaultConfig, fakeEvents);
  const wordBank = [
    "castle",
    "defense",
    "arcane",
    "fortify",
    "warden",
    "shield",
    "typing",
    "practice",
    "focus",
    "turret",
    "combo",
    "accuracy"
  ];
  const stats = {
    ops: 0,
    bursts: args.bursts,
    burstSize: args.burstSize,
    completions: 0,
    errors: 0,
    ignored: 0,
    progress: 0,
    purged: 0,
    backspaces: 0,
    holds: 0,
    wrong: 0,
    correct: 0,
    maxBuffer: 0,
    maxCombo: 0
  };
  const enemyCounterRef = { count: 0 };
  const wallStart = performance.now();
  for (let i = 0; i < args.bursts; i += 1) {
    const word = pickWord(wordBank);
    const enemyId = `enemy-${++enemyCounterRef.count}`;
    const state = createState(word, enemyId);
    runBurst(typing, state, wordBank, args.burstSize, stats, enemyCounterRef);
  }
  const wallEnd = performance.now();
  const durationMs = wallEnd - wallStart;
  const summary = {
    bursts: args.bursts,
    burstSize: args.burstSize,
    ops: stats.ops,
    completions: stats.completions,
    errors: stats.errors,
    ignored: stats.ignored,
    backspaces: stats.backspaces,
    holds: stats.holds,
    wrong: stats.wrong,
    correct: stats.correct,
    maxBuffer: stats.maxBuffer,
    maxCombo: stats.maxCombo,
    durationMs,
    opsPerSecond: Number((stats.ops / (durationMs / 1000)).toFixed(2))
  };
  await writeSummary(args.out, summary);
  console.log(JSON.stringify(summary, null, 2));
}

main().catch((error) => {
  console.error("[input-stress] failed:", error);
  process.exitCode = 1;
});
