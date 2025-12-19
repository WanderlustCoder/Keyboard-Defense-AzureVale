import { describe, expect, test } from "vitest";
import {
  CHALLENGE_MODIFIERS_VERSION,
  buildChallengeModifiersViewState,
  computeChallengeScoreMultiplier,
  readChallengeModifiers,
  writeChallengeModifiers
} from "../src/utils/challengeModifiers.ts";

class MemoryStorage {
  constructor(entries = {}) {
    this.entries = new Map(Object.entries(entries));
  }

  get length() {
    return this.entries.size;
  }

  key(index) {
    return Array.from(this.entries.keys())[index] ?? null;
  }

  getItem(key) {
    return this.entries.has(key) ? this.entries.get(key) : null;
  }

  setItem(key, value) {
    this.entries.set(key, String(value));
  }

  removeItem(key) {
    this.entries.delete(key);
  }

  clear() {
    this.entries.clear();
  }
}

describe("challengeModifiers", () => {
  test("readChallengeModifiers returns defaults when storage empty", () => {
    const storage = new MemoryStorage();
    const state = readChallengeModifiers(storage);
    expect(state.version).toBe(CHALLENGE_MODIFIERS_VERSION);
    expect(state.selection.enabled).toBe(false);
    expect(state.selection.fog).toBe(false);
    expect(state.selection.fastSpawns).toBe(false);
    expect(state.selection.limitedMistakes).toBe(false);
    expect(state.selection.mistakeBudget).toBeGreaterThan(0);
  });

  test("buildChallengeModifiersViewState computes the score multiplier", () => {
    const state = {
      version: CHALLENGE_MODIFIERS_VERSION,
      selection: {
        enabled: true,
        fog: true,
        fastSpawns: true,
        limitedMistakes: false,
        mistakeBudget: 10
      },
      updatedAt: "2025-01-01T00:00:00.000Z"
    };
    const view = buildChallengeModifiersViewState(state);
    expect(view.active.map((entry) => entry.id)).toEqual(["fog", "fast-spawns"]);
    expect(view.scoreMultiplier).toBeCloseTo(1.15 * 1.25, 3);
  });

  test("computeChallengeScoreMultiplier ignores modifiers when disabled", () => {
    const multiplier = computeChallengeScoreMultiplier({
      enabled: false,
      fog: true,
      fastSpawns: true,
      limitedMistakes: true,
      mistakeBudget: 5
    });
    expect(multiplier).toBe(1);
  });

  test("writeChallengeModifiers clamps mistakeBudget to a safe range", () => {
    const storage = new MemoryStorage();
    const saved = writeChallengeModifiers(storage, {
      version: CHALLENGE_MODIFIERS_VERSION,
      selection: {
        enabled: true,
        fog: false,
        fastSpawns: false,
        limitedMistakes: true,
        mistakeBudget: 5000
      },
      updatedAt: ""
    });
    expect(saved.selection.mistakeBudget).toBeLessThanOrEqual(50);
    const loaded = readChallengeModifiers(storage);
    expect(loaded.selection.mistakeBudget).toBeLessThanOrEqual(50);
  });
});

