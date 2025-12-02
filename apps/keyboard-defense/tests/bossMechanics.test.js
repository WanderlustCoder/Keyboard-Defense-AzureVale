import { describe, expect, test } from "vitest";
import { defaultConfig } from "../src/core/config.js";
import { EventBus } from "../src/core/eventBus.js";
import { GameEngine } from "../src/engine/gameEngine.js";
import { EnemySystem } from "../src/systems/enemySystem.js";
import { TurretSystem } from "../src/systems/turretSystem.js";
import { createInitialState } from "../src/core/gameState.js";
import { PRNG } from "../src/utils/random.js";

describe("boss mechanics", () => {
  test("activates boss state and emits intro on spawn", () => {
    const events = new EventBus();
    const introEvents = [];
    events.on("boss:intro", (payload) => introEvents.push(payload));
    const config = {
      ...defaultConfig,
      prepCountdownSeconds: 0,
      featureToggles: {
        ...defaultConfig.featureToggles,
        bossMechanics: true,
        dynamicSpawns: false,
        eliteAffixes: false
      },
      waves: [
        {
          id: "boss-wave",
          duration: 18,
          rewardBonus: 0,
          spawns: [{ at: 0, lane: 1, tierId: "archivist", count: 1, cadence: 0, shield: 60 }]
        }
      ]
    };
    const engine = new GameEngine({ config, events, seed: 123 });
    engine.update(0);
    const state = engine.getState();
    expect(state.boss.active).toBe(true);
    expect(state.boss.enemyId).not.toBeNull();
    expect(state.analytics.bossActive).toBe(true);
    expect(introEvents.length).toBeGreaterThan(0);
  });

  test("boss vulnerability multiplies incoming turret damage", () => {
    const state = createInitialState(defaultConfig);
    const events = new EventBus();
    const rng = new PRNG("boss-vuln");
    const enemySystem = new EnemySystem(defaultConfig, events, rng);
    const difficulty = defaultConfig.difficultyBands[0];
    const enemy = enemySystem.spawn(state, {
      tierId: "archivist",
      lane: 0,
      waveIndex: 0,
      difficulty
    });
    expect(enemy).not.toBeNull();
    if (!enemy) return;
    state.boss.active = true;
    state.boss.enemyId = enemy.id;
    state.boss.vulnerabilityRemaining = 5;
    state.boss.vulnerabilityMultiplier = 1.5;
    enemy.shield = { current: 50, max: 50 };
    const result = enemySystem.damageEnemy(state, enemy.id, 20, "turret");
    expect(result.damage).toBeCloseTo(30);
    expect(enemy.shield?.current).toBeCloseTo(20);
  });

  test("boss shockwave applies lane slow to turret fire rate", () => {
    const state = createInitialState(defaultConfig);
    const events = new EventBus();
    const turretSystem = new TurretSystem(defaultConfig, events);
    state.boss.active = true;
    state.boss.lane = 1;
    state.boss.shockwaveRemaining = 2;
    state.boss.shockwaveMultiplier = 0.6;
    const multiplier = turretSystem.resolveLaneFireRateMultiplier(state, 1);
    expect(multiplier).toBeCloseTo(0.6);
  });
});
