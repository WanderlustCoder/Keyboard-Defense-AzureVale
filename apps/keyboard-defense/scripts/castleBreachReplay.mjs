#!/usr/bin/env node
/**
 * Castle breach replay CLI.
 *
 * Spins up the headless GameEngine with a minimal wave configuration,
 * spawns a deterministic enemy, and advances the simulation until the
 * castle takes damage (or a timeout is reached). Designed for nightly
 * regression drills so we can ensure the scripted breach used in the
 * tutorial remains intact.
 *
 * Usage:
 *   node scripts/castleBreachReplay.mjs --help
 */

import { promises as fs } from "node:fs";
import path from "node:path";
import process from "node:process";

import { GameEngine } from "../public/dist/src/engine/gameEngine.js";
import { defaultConfig } from "../public/dist/src/core/config.js";

const DEFAULT_SEED = 424242;
const DEFAULT_STEP = 0.1;
const DEFAULT_MAX_TIME = 45;
const DEFAULT_SAMPLE = 0.5;
const DEFAULT_ARTIFACT = "artifacts/castle-breach.json";
const DEFAULT_TIER = "brute";
const DEFAULT_LANE = 1;
const DEFAULT_PREP = 1.5;
const DEFAULT_SPEED_MULT = 1.25;
const DEFAULT_HEALTH_MULT = 1.0;
const DEFAULT_TURRET_GOLD_BUFFER = 5000;

function parseTurretArg(value) {
  if (!value) {
    throw new Error("Expected value after --turret (slot:type[@level]).");
  }
  const [slotId, rest] = value.split(":");
  if (!slotId || !rest) {
    throw new Error(
      `Invalid --turret "${value}". Expected format slot-id:type[@level].`
    );
  }
  const [typeId, levelPart] = rest.split("@");
  if (!typeId) {
    throw new Error(`Missing turret type in "${value}".`);
  }
  let level = 1;
  if (levelPart !== undefined) {
    level = Number.parseInt(levelPart, 10);
    if (!Number.isFinite(level) || level < 1) {
      throw new Error(`Invalid turret level in "${value}".`);
    }
  }
  return { slotId, typeId, level };
}

function parseEnemyArg(value) {
  if (!value) {
    throw new Error("Expected value after --enemy (tier[:lane]).");
  }
  const [tierId, lanePart] = value.split(":");
  if (!tierId) {
    throw new Error(`Invalid --enemy "${value}". Expected tier[:lane].`);
  }
  let lane = null;
  if (lanePart !== undefined) {
    lane = Number.parseInt(lanePart, 10);
    if (!Number.isFinite(lane) || lane < 0) {
      throw new Error(`Invalid lane for --enemy "${value}". Expected >= 0.`);
    }
  }
  return { tierId, lane };
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

function cloneConfig() {
  if (typeof structuredClone === "function") {
    return structuredClone(defaultConfig);
  }
  return JSON.parse(JSON.stringify(defaultConfig));
}

function ensureDirectoryForFile(filePath) {
  const dir = path.dirname(filePath);
  return fs.mkdir(dir, { recursive: true });
}

function resolveEnemySpecs(options) {
  const explicit = Array.isArray(options.enemySpecs) ? options.enemySpecs : [];
  if (explicit.length > 0) {
    return explicit.map((enemy) => ({
      tierId: enemy.tierId ?? options.tier,
      lane:
        enemy.lane !== undefined && enemy.lane !== null ? enemy.lane : options.lane ?? DEFAULT_LANE
    }));
  }
  return [
    {
      tierId: options.tier ?? DEFAULT_TIER,
      lane: options.lane ?? DEFAULT_LANE
    }
  ];
}

function applyTurretLoadout(engine, loadout = []) {
  if (!Array.isArray(loadout) || loadout.length === 0) {
    return [];
  }
  const state = engine.getState();
  const placements = [];
  engine.unlockSlotsForWave(Number.MAX_SAFE_INTEGER);
  const beforeGold = state.resources.gold;
  if (beforeGold < DEFAULT_TURRET_GOLD_BUFFER) {
    engine.grantGold(DEFAULT_TURRET_GOLD_BUFFER - beforeGold);
  }
  for (const entry of loadout) {
    const slotId = entry.slotId;
    const typeId = entry.typeId;
    const level = Math.max(1, Number.parseInt(entry.level ?? 1, 10) || 1);
    if (!slotId || !typeId) {
      throw new Error("Turret loadout entries require slotId and typeId.");
    }
    const placementResult = engine.placeTurret(slotId, typeId);
    if (!placementResult?.success) {
      throw new Error(
        `Failed to place turret ${typeId} in ${slotId}: ${placementResult?.reason ?? "unknown"}`
      );
    }
    if (level > 1) {
      for (let upgradeLevel = 2; upgradeLevel <= level; upgradeLevel += 1) {
        const upgradeResult = engine.upgradeTurret(slotId);
        if (!upgradeResult?.success) {
          throw new Error(
            `Failed to upgrade turret ${slotId} to level ${level}: ${
              upgradeResult?.reason ?? "unknown"
            }`
          );
        }
      }
    }
    placements.push({ slotId, typeId, level });
  }
  const remainingGold = engine.getState().resources.gold;
  if (remainingGold > 0) {
    engine.grantGold(-remainingGold);
  }
  return placements;
}

export function parseArgs(argv = []) {
  const options = {
    seed: DEFAULT_SEED,
    step: DEFAULT_STEP,
    maxTime: DEFAULT_MAX_TIME,
    sample: DEFAULT_SAMPLE,
    artifact: DEFAULT_ARTIFACT,
    tier: DEFAULT_TIER,
    lane: DEFAULT_LANE,
    prep: DEFAULT_PREP,
    speedMultiplier: DEFAULT_SPEED_MULT,
    healthMultiplier: DEFAULT_HEALTH_MULT,
    turrets: [],
    enemySpecs: [],
    help: false
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--help":
      case "-h":
        options.help = true;
        break;
      case "--seed": {
        const value = Number.parseInt(argv[++i] ?? "", 10);
        if (!Number.isFinite(value)) throw new Error("Expected --seed <number>.");
        options.seed = value;
        break;
      }
      case "--step": {
        const value = Number.parseFloat(argv[++i] ?? "");
        if (!Number.isFinite(value) || value <= 0) {
          throw new Error("Expected --step to be a positive number of seconds.");
        }
        options.step = value;
        break;
      }
      case "--max-time": {
        const value = Number.parseFloat(argv[++i] ?? "");
        if (!Number.isFinite(value) || value <= 0) {
          throw new Error("Expected --max-time to be a positive number of seconds.");
        }
        options.maxTime = value;
        break;
      }
      case "--sample": {
        const value = Number.parseFloat(argv[++i] ?? "");
        if (!Number.isFinite(value) || value <= 0) {
          throw new Error("Expected --sample to be a positive number of seconds.");
        }
        options.sample = value;
        break;
      }
      case "--artifact": {
        const value = argv[++i];
        if (!value) throw new Error("Expected path after --artifact.");
        options.artifact = value;
        break;
      }
      case "--no-artifact":
        options.artifact = null;
        break;
      case "--tier": {
        const value = argv[++i];
        if (!value) throw new Error("Expected tier id after --tier.");
        options.tier = value;
        break;
      }
      case "--lane": {
        const value = Number.parseInt(argv[++i] ?? "", 10);
        if (!Number.isFinite(value) || value < 0) {
          throw new Error("Expected --lane to be a non-negative integer.");
        }
        options.lane = value;
        break;
      }
      case "--prep": {
        const value = Number.parseFloat(argv[++i] ?? "");
        if (!Number.isFinite(value) || value < 0) {
          throw new Error("Expected --prep to be >= 0.");
        }
        options.prep = value;
        break;
      }
      case "--speed-mult": {
        const value = Number.parseFloat(argv[++i] ?? "");
        if (!Number.isFinite(value) || value <= 0) {
          throw new Error("Expected --speed-mult to be a positive number.");
        }
        options.speedMultiplier = value;
        break;
      }
      case "--health-mult": {
        const value = Number.parseFloat(argv[++i] ?? "");
        if (!Number.isFinite(value) || value <= 0) {
          throw new Error("Expected --health-mult to be a positive number.");
        }
        options.healthMultiplier = value;
        break;
      }
      case "--turret": {
        const spec = parseTurretArg(argv[++i]);
        options.turrets.push(spec);
        break;
      }
      case "--enemy": {
        const spec = parseEnemyArg(argv[++i]);
        options.enemySpecs.push(spec);
        break;
      }
      default:
        if (token.startsWith("-")) {
          throw new Error(`Unknown argument "${token}". Use --help for usage.`);
        }
    }
  }

  return options;
}

export function printHelp() {
  console.log(`Keyboard Defense Castle Breach Replay

Runs a deterministic simulation to ensure the scripted castle-breach drill
still lands. Requires a fresh build so dist/ artifacts exist.

Options:
  --seed <n>           RNG seed (default ${DEFAULT_SEED})
  --step <seconds>     Simulation timestep per update (default ${DEFAULT_STEP})
  --max-time <seconds> Maximum simulated seconds before timeout (default ${DEFAULT_MAX_TIME})
  --sample <seconds>   Interval for timeline samples (default ${DEFAULT_SAMPLE})
  --artifact <path>    JSON artifact output (default ${DEFAULT_ARTIFACT})
  --no-artifact        Skip writing the artifact
  --tier <id>          Enemy tier id to spawn (default "${DEFAULT_TIER}")
  --lane <index>       Lane to spawn the enemy in (default ${DEFAULT_LANE})
  --prep <seconds>     Countdown duration before the wave starts (default ${DEFAULT_PREP})
  --speed-mult <n>     Multiplier applied to enemy speed (default ${DEFAULT_SPEED_MULT})
  --health-mult <n>    Multiplier applied to enemy health (default ${DEFAULT_HEALTH_MULT})
  --enemy <tier[:lane]> Repeatable enemy spec (defaults to --tier/--lane when omitted)
  --turret <slot:type[@level]>  Pre-place turret loadout before the drill starts (repeatable)
  --help, -h           Show this help message

Example:
  node scripts/castleBreachReplay.mjs --seed 1337 --lane 2 --speed-mult 1.4`);
}

function buildConfig(options) {
  const config = cloneConfig();
  config.prepCountdownSeconds = options.prep;
  config.loopWaves = false;
  config.waves = [
    {
      id: "breach-drill",
      duration: Math.max(options.maxTime + 5, 30),
      rewardBonus: 0,
      spawns: []
    }
  ];
  config.castleLevels = config.castleLevels.map((level, index) =>
    index === 0
      ? {
          ...level,
          unlockSlots: 0
        }
      : level
  );
  return config;
}

function createDifficulty(options) {
  return {
    fromWave: 0,
    wordWeights: { easy: 1, medium: 0, hard: 0 },
    enemyHealthMultiplier: options.healthMultiplier,
    enemySpeedMultiplier: options.speedMultiplier,
    rewardMultiplier: 1
  };
}

export async function runBreachDrill(options) {
  const turretLoadout = Array.isArray(options.turrets) ? options.turrets : [];
  const enemyLoadout = resolveEnemySpecs(options);
  const engine = new GameEngine({
    seed: options.seed,
    config: buildConfig(options)
  });

  // Remove starter gold to keep the scenario sterile.
  engine.grantGold(-engine.getState().resources.gold);
  const turretPlacements = applyTurretLoadout(engine, turretLoadout);

  const events = [];
  const timeline = [];
  let breachEvent = null;
  const castleHpStart = engine.getState().castle.health;

  engine.events.on("enemy:spawned", (enemy) => {
    events.push({
      type: "enemy:spawned",
      time: engine.getState().time,
      enemy: {
        id: enemy.id,
        tier: enemy.tierId,
        lane: enemy.lane,
        maxHealth: enemy.maxHealth,
        speed: enemy.speed
      }
    });
  });

  engine.events.on("enemy:escaped", ({ enemy }) => {
    events.push({
      type: "enemy:escaped",
      time: engine.getState().time,
      enemy: { id: enemy.id, tier: enemy.tierId, lane: enemy.lane }
    });
  });

  engine.events.on("castle:damaged", ({ amount, health }) => {
    if (breachEvent) return;
    const state = engine.getState();
    breachEvent = {
      time: state.time,
      amount,
      healthAfter: health,
      maxHealth: state.castle.maxHealth,
      wave: state.wave.index
    };
    events.push({
      type: "castle:damaged",
      time: state.time,
      amount,
      health
    });
  });

  const difficulty = createDifficulty(options);
  let enemiesSpawned = false;
  let nextSample = 0;
  const maxIterations = Math.ceil(options.maxTime / options.step) + 10;

  for (let iteration = 0; iteration < maxIterations; iteration += 1) {
    const state = engine.getState();

    if (!enemiesSpawned && !state.wave.inCountdown) {
      for (const enemySpec of enemyLoadout) {
        const beforeCount = engine.getState().enemies.length;
        engine.spawnEnemy({
          tierId: enemySpec.tierId,
          lane: enemySpec.lane,
          waveIndex: state.wave.index,
          difficulty
        });
        const afterCount = engine.getState().enemies.length;
        if (afterCount <= beforeCount) {
          throw new Error(
            `Failed to spawn enemy "${enemySpec.tierId}" in lane ${enemySpec.lane}.`
          );
        }
      }
      enemiesSpawned = true;
    }

    engine.update(options.step);
    const updated = engine.getState();

    if (updated.time >= nextSample) {
      timeline.push({
        time: Number(updated.time.toFixed(3)),
        castleHealth: updated.castle.health,
        enemiesAlive: updated.enemies.filter((enemy) => enemy.status === "alive").length,
        distanceClosestEnemy: updated.enemies.length
          ? Math.min(...updated.enemies.map((enemy) => enemy.distance))
          : null
      });
      nextSample += options.sample;
    }

    if (breachEvent || updated.time >= options.maxTime) {
      break;
    }
  }

  const finalState = engine.getState();
  const passiveUnlocks = Array.isArray(finalState.analytics?.castlePassiveUnlocks)
    ? cloneSimple(finalState.analytics.castlePassiveUnlocks)
    : [];
  const passiveUnlockSummary =
    passiveUnlocks.length > 0 ? summarizePassiveUnlocks(passiveUnlocks) : null;
  const lastPassiveUnlock =
    passiveUnlocks.length > 0
      ? formatPassiveUnlockSummary(passiveUnlocks[passiveUnlocks.length - 1])
      : null;
  const activeCastlePassives = Array.isArray(finalState.castle?.passives)
    ? cloneSimple(finalState.castle.passives)
    : [];
  const result = {
    status: breachEvent ? "breached" : "timeout",
    options: {
      seed: options.seed,
      step: options.step,
      maxTime: options.maxTime,
      sample: options.sample,
      tier: options.tier,
      lane: options.lane,
      prep: options.prep,
      speedMultiplier: options.speedMultiplier,
      healthMultiplier: options.healthMultiplier,
      enemySpecs: enemyLoadout,
      turrets: turretLoadout
    },
    startedAt: null,
    finishedAt: null,
    timeline,
    events,
    breach: breachEvent,
    passiveUnlockCount: passiveUnlocks.length,
    passiveUnlocks,
    passiveUnlockSummary,
    lastPassiveUnlock,
    activeCastlePassives,
    turretPlacements,
    finalState: {
      time: Number(finalState.time.toFixed(3)),
      castleHealth: finalState.castle.health,
      castleMaxHealth: finalState.castle.maxHealth,
      status: finalState.status,
      passives: activeCastlePassives
    },
    metrics: {
      timeToBreachMs: breachEvent ? Math.round(breachEvent.time * 1000) : null,
      timeToBreachSeconds: breachEvent ? Number(breachEvent.time.toFixed(3)) : null,
      castleHpStart: castleHpStart ?? finalState.castle.maxHealth,
      castleHpEnd: finalState.castle.health,
      castleHpDelta:
        castleHpStart !== undefined
          ? Number((finalState.castle.health - castleHpStart).toFixed(3))
          : null,
      damageTaken:
        castleHpStart !== undefined
          ? Number((castleHpStart - finalState.castle.health).toFixed(3))
          : null,
      enemiesSpawned: enemyLoadout.length,
      turretsPlaced: turretPlacements.length
    }
  };

  return result;
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

  const startedAt = new Date().toISOString();
  let result;

  try {
    result = await runBreachDrill(options);
    result.startedAt = startedAt;
    result.finishedAt = new Date().toISOString();
    if (options.artifact) {
      const resolved = path.resolve(options.artifact);
      await ensureDirectoryForFile(resolved);
      await fs.writeFile(resolved, JSON.stringify(result, null, 2), "utf8");
      console.log(
        result.status === "breached"
          ? `Castle breached at ${result.breach.time.toFixed(2)}s. Artifact: ${resolved}`
          : `Timeout reached without breach. Artifact: ${resolved}`
      );
    } else {
      console.log(
        result.status === "breached"
          ? `Castle breached at ${result.breach.time.toFixed(2)}s.`
          : "Timeout reached without breach."
      );
    }
    if (result.status !== "breached") {
      console.error(
        "Castle breach replay did not reach a breach before timing out; investigate tutorial drill."
      );
      process.exitCode = 1;
    }
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
    return;
  }
}

if (
  import.meta.url === `file://${process.argv[1]}` ||
  process.argv[1]?.endsWith("castleBreachReplay.mjs")
) {
  await main();
}
