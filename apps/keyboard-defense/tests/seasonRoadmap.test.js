import { describe, expect, test } from "vitest";
import { evaluateRoadmap } from "../src/data/roadmap.ts";
import {
  DEFAULT_ROADMAP_PREFERENCES,
  mergeRoadmapPreferences,
  readRoadmapPreferences,
  writeRoadmapPreferences
} from "../src/utils/roadmapPreferences.ts";

describe("season roadmap evaluation", () => {
  test("marks tutorial step active before completion", () => {
    const result = evaluateRoadmap({
      tutorialCompleted: false,
      currentWave: 1,
      completedWaves: 0,
      totalWaves: 3,
      castleLevel: 1,
      loreUnlocked: 0
    });

    const tutorialStep = result.entries.find((entry) => entry.id === "tutorial-complete");
    const waveOne = result.entries.find((entry) => entry.id === "wave-one");

    expect(tutorialStep?.status).toBe("active");
    expect(waveOne?.status).toBe("active");
    expect(result.activeId).toBe(tutorialStep?.id);
  });

  test("surfaces the next wave milestone and hides completed items by default", () => {
    const result = evaluateRoadmap({
      tutorialCompleted: true,
      currentWave: 2,
      completedWaves: 1,
      totalWaves: 3,
      castleLevel: 2,
      loreUnlocked: 1
    });

    const tutorialStep = result.entries.find((entry) => entry.id === "tutorial-complete");
    const waveOne = result.entries.find((entry) => entry.id === "wave-one");
    const waveTwo = result.entries.find((entry) => entry.id === "wave-two");

    expect(tutorialStep?.status).toBe("done");
    expect(waveOne?.status).toBe("done");
    expect(waveTwo?.status).toBe("active");
    expect(result.completed).toBeGreaterThan(0);
    expect(result.activeId).toBe("wave-two");
  });

  test("reports all steps done once the finale is cleared", () => {
    const result = evaluateRoadmap({
      tutorialCompleted: true,
      currentWave: 3,
      completedWaves: 3,
      totalWaves: 3,
      castleLevel: 3,
      loreUnlocked: 3
    });

    expect(result.entries.every((entry) => entry.status === "done")).toBe(true);
    expect(result.activeId).toBeNull();
  });
});

describe("season roadmap preferences", () => {
  test("normalize and persist preferences safely", () => {
    const storage = {
      store: new Map(),
      getItem(key) {
        return this.store.has(key) ? this.store.get(key) : null;
      },
      setItem(key, value) {
        this.store.set(key, value);
      },
      removeItem(key) {
        this.store.delete(key);
      }
    };

    const defaults = readRoadmapPreferences(storage);
    expect(defaults.trackedId).toBeNull();
    expect(defaults.filters.completed).toBe(false);
    const merged = mergeRoadmapPreferences(DEFAULT_ROADMAP_PREFERENCES, {
      trackedId: "wave-two",
      filters: { completed: true }
    });
    writeRoadmapPreferences(storage, merged);
    const restored = readRoadmapPreferences(storage);
    expect(restored.trackedId).toBe("wave-two");
    expect(restored.filters.completed).toBe(true);
    expect(restored.filters.story).toBe(true);
  });
});
