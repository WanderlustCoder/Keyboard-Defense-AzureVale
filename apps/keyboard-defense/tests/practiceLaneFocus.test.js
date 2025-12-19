import { describe, expect, test } from "vitest";
import { defaultConfig } from "../src/core/config.js";
import { GameEngine } from "../src/engine/gameEngine.js";
import { PRNG } from "../src/utils/random.js";
import { readPracticeLaneFocus, writePracticeLaneFocus } from "../src/utils/practiceLaneFocus.ts";

const createMemoryStorage = () => {
  const store = new Map();
  return {
    getItem: (key) => (store.has(key) ? store.get(key) : null),
    setItem: (key, value) => {
      store.set(key, String(value));
    },
    removeItem: (key) => {
      store.delete(key);
    },
    clear: () => store.clear()
  };
};

describe("practice lane focus", () => {
  test("persists preference in storage", () => {
    const storage = createMemoryStorage();
    expect(readPracticeLaneFocus(storage)).toBe(null);
    writePracticeLaneFocus(storage, 1);
    expect(readPracticeLaneFocus(storage)).toBe(1);
    writePracticeLaneFocus(storage, null);
    expect(readPracticeLaneFocus(storage)).toBe(null);
  });

  test("filters wave spawns in practice mode", () => {
    const config = {
      ...defaultConfig,
      loopWaves: true,
      prepCountdownSeconds: 0,
      featureToggles: {
        ...defaultConfig.featureToggles,
        dynamicSpawns: false,
        evacuationEvents: false
      },
      waves: [
        {
          id: "focus-wave",
          duration: 10,
          rewardBonus: 0,
          spawns: [
            { at: 0, lane: 0, tierId: "grunt", count: 1, cadence: 1 },
            { at: 0, lane: 1, tierId: "grunt", count: 1, cadence: 1 },
            { at: 0, lane: 2, tierId: "grunt", count: 1, cadence: 1 }
          ]
        }
      ]
    };
    const engine = new GameEngine({ config, seed: 42 });
    engine.setLaneFocus(1);
    engine.update(0);
    const state = engine.getState();
    expect(state.mode).toBe("practice");
    expect(state.enemies).toHaveLength(1);
    expect(state.enemies.every((enemy) => enemy.lane === 1)).toBe(true);
  });

  test("does not affect spawns in campaign mode", () => {
    const config = {
      ...defaultConfig,
      loopWaves: false,
      prepCountdownSeconds: 0,
      featureToggles: {
        ...defaultConfig.featureToggles,
        dynamicSpawns: false,
        evacuationEvents: false
      },
      waves: [
        {
          id: "focus-wave",
          duration: 10,
          rewardBonus: 0,
          spawns: [
            { at: 0, lane: 0, tierId: "grunt", count: 1, cadence: 1 },
            { at: 0, lane: 1, tierId: "grunt", count: 1, cadence: 1 },
            { at: 0, lane: 2, tierId: "grunt", count: 1, cadence: 1 }
          ]
        }
      ]
    };
    const engine = new GameEngine({ config, seed: 42 });
    engine.setLaneFocus(1);
    engine.update(0);
    const state = engine.getState();
    expect(state.mode).toBe("campaign");
    const lanes = new Set(state.enemies.map((enemy) => enemy.lane));
    expect(lanes.has(0)).toBe(true);
    expect(lanes.has(1)).toBe(true);
    expect(lanes.has(2)).toBe(true);
  });

  test("filters upcoming spawns for focused lane", () => {
    const config = {
      ...defaultConfig,
      loopWaves: true,
      prepCountdownSeconds: 5,
      featureToggles: {
        ...defaultConfig.featureToggles,
        dynamicSpawns: false,
        evacuationEvents: false
      },
      waves: [
        {
          id: "focus-wave",
          duration: 60,
          rewardBonus: 0,
          spawns: [
            { at: 0, lane: 0, tierId: "grunt", count: 30, cadence: 1 },
            { at: 30, lane: 2, tierId: "runner", count: 6, cadence: 1 }
          ]
        }
      ]
    };
    const engine = new GameEngine({ config, seed: 7 });
    engine.setLaneFocus(2);
    const previews = engine.getUpcomingSpawns(6);
    expect(previews).toHaveLength(6);
    expect(previews.every((entry) => entry.lane === 2)).toBe(true);
  });

  test("schedules dynamic spawns + evacuation in focused lane", () => {
    const config = {
      ...defaultConfig,
      loopWaves: true,
      prepCountdownSeconds: 0,
      featureToggles: {
        ...defaultConfig.featureToggles,
        dynamicSpawns: true,
        evacuationEvents: true
      },
      waves: [
        {
          id: "focus-wave",
          duration: 24,
          rewardBonus: 0,
          spawns: []
        }
      ]
    };

    const engineDynamic = new GameEngine({ config, seed: 99 });
    engineDynamic.setLaneFocus(1);
    engineDynamic["buildDynamicEventsForWave"](0);
    const dyn = engineDynamic["dynamicEvents"] ?? [];
    expect(dyn.length).toBeGreaterThan(0);
    expect(dyn.every((event) => event.lane === 1)).toBe(true);

    const engineEvac = new GameEngine({ config, seed: 99 });
    engineEvac.setLaneFocus(1);
    engineEvac["buildEvacuationEventForWave"](0, new PRNG(123));
    expect(engineEvac["evacuationEvent"]).not.toBeNull();
    expect(engineEvac["evacuationEvent"]?.lane).toBe(1);
  });
});

