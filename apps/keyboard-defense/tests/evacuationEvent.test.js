import { describe, expect, test } from "vitest";
import { defaultConfig } from "../src/core/config.js";
import { EventBus } from "../src/core/eventBus.js";
import { GameEngine } from "../src/engine/gameEngine.js";

function createEngine(overrides = {}) {
  const config = {
    ...defaultConfig,
    prepCountdownSeconds: 0,
    featureToggles: {
      ...defaultConfig.featureToggles,
      dynamicSpawns: true,
      evacuationEvents: true
    },
    waves: [
      {
        id: "evac-wave",
        duration: 20,
        rewardBonus: 0,
        spawns: []
      }
    ],
    ...overrides
  };
  return new GameEngine({ config, events: new EventBus(), seed: 12345 });
}

function advanceUntilEvac(engine) {
  let iterations = 0;
  while (!engine.getState().evacuation.active && iterations < 30) {
    engine.update(1);
    iterations += 1;
  }
  return engine.getState();
}

describe("evacuation event", () => {
  test("schedules and spawns deterministically mid-wave", () => {
    const engineA = createEngine();
    const engineB = createEngine();

    const stateA = advanceUntilEvac(engineA);
    const stateB = advanceUntilEvac(engineB);

    expect(stateA.evacuation.active).toBe(true);
    expect(stateB.evacuation.active).toBe(true);
    expect(stateA.evacuation.lane).toBe(stateB.evacuation.lane);

    const evacEnemyA = stateA.enemies.find((enemy) => enemy.tierId === "evac-transport");
    const evacEnemyB = stateB.enemies.find((enemy) => enemy.tierId === "evac-transport");
    expect(evacEnemyA?.tierId).toBe("evac-transport");
    expect(evacEnemyB?.tierId).toBe("evac-transport");
    expect(evacEnemyA?.word).toBe(evacEnemyB?.word);
  });

  test("evacuation fails when timer expires", () => {
    const engine = createEngine();
    advanceUntilEvac(engine);
    engine.update(30);
    const state = engine.getState();
    expect(state.evacuation.active).toBe(false);
    expect(state.analytics.evacuationFailures).toBe(1);
    expect(state.enemies.some((enemy) => enemy.tierId === "evac-transport")).toBe(false);
  });

  test("evacuation completes when transport is destroyed", () => {
    const engine = createEngine();
    advanceUntilEvac(engine);
    const runtime = engine;
    const evacState = runtime.getState().evacuation;
    const evacId = evacState.enemyId;
    expect(evacId).toBeTruthy();
    if (evacId) {
      runtime["enemySystem"].damageEnemy(runtime["state"], evacId, 999, "turret");
      runtime.update(0);
    }
    const final = engine.getState();
    expect(final.analytics.evacuationSuccesses).toBe(1);
    expect(final.evacuation.active).toBe(false);
  });
});
