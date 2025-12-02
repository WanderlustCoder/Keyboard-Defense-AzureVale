import { describe, expect, test } from "vitest";
import { defaultConfig } from "../src/core/config.js";
import { EventBus } from "../src/core/eventBus.js";
import { GameEngine } from "../src/engine/gameEngine.js";
import { PRNG } from "../src/utils/random.js";

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
    const startGold = engine.getState().resources.gold;
    advanceUntilEvac(engine);
    engine.update(30);
    const state = engine.getState();
    expect(state.evacuation.active).toBe(false);
    expect(state.analytics.evacuationFailures).toBe(1);
    expect(state.resources.gold).toBeLessThanOrEqual(
      startGold - defaultConfig.evacuation.failPenaltyGold
    );
    expect(state.enemies.some((enemy) => enemy.tierId === "evac-transport")).toBe(false);
  });

  test("evacuation completes when transport is destroyed", () => {
    const engine = createEngine();
    const startGold = engine.getState().resources.gold;
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
    const expectedGoldGain =
      defaultConfig.evacuation.rewardGold + defaultConfig.enemyTiers["evac-transport"].reward;
    expect(final.resources.gold).toBeGreaterThanOrEqual(startGold + expectedGoldGain - 1);
  });

  test("evacuation avoids lanes reserved by hazards/dynamic events", () => {
    const engine = createEngine({
      turretSlots: [
        { id: "lane-a", lane: 0, unlocked: true },
        { id: "lane-b", lane: 1, unlocked: true }
      ],
      waves: [
        {
          id: "evac-wave",
          duration: 28,
          rewardBonus: 0,
          spawns: []
        }
      ]
    });
    engine["hazardEvents"] = [{ time: 12, lane: 0, kind: "fog", duration: 10 }];
    engine["dynamicEvents"] = [{ time: 14, lane: 0, tierId: "grunt", order: 1000 }];
    engine["buildEvacuationEventForWave"](0, new PRNG(999));
    expect(engine["evacuationEvent"]).not.toBeNull();
    expect(engine["evacuationEvent"]?.lane).toBe(1);
  });

  test("evacuation skips scheduling when every lane is occupied", () => {
    const engine = createEngine({
      turretSlots: [
        { id: "lane-a", lane: 0, unlocked: true },
        { id: "lane-b", lane: 1, unlocked: true }
      ],
      waves: [
        {
          id: "evac-wave",
          duration: 26,
          rewardBonus: 0,
          spawns: []
        }
      ]
    });
    engine["hazardEvents"] = [
      { time: 10, lane: 0, kind: "fog", duration: 10 },
      { time: 12, lane: 1, kind: "storm", duration: 12 }
    ];
    engine["dynamicEvents"] = [
      { time: 16, lane: 0, tierId: "grunt", order: 1000 },
      { time: 15, lane: 1, tierId: "runner", order: 1001 }
    ];
    engine["buildEvacuationEventForWave"](0, new PRNG(123));
    expect(engine["evacuationEvent"]).toBeNull();
  });
});
