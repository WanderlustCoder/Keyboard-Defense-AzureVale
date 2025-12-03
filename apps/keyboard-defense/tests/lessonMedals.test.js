import { expect, test } from "vitest";
import {
  LESSON_MEDAL_VERSION,
  buildLessonMedalViewState,
  evaluateLessonMedal,
  readLessonMedalProgress,
  recordLessonMedal,
  writeLessonMedalProgress
} from "../src/utils/lessonMedals.ts";

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

test("evaluateLessonMedal promotes tiers and returns next target", () => {
  const result = evaluateLessonMedal({
    mode: "burst",
    source: "cta",
    elapsedMs: 20000,
    accuracy: 0.92,
    bestCombo: 4,
    words: 5,
    errors: 1,
    wpm: 30,
    timestamp: Date.now()
  });
  expect(result.tier).toBe("silver");
  expect(result.nextTarget?.tier).toBe("gold");

  const topTier = evaluateLessonMedal({
    mode: "precision",
    source: "cta",
    elapsedMs: 24000,
    accuracy: 0.99,
    bestCombo: 8,
    words: 8,
    errors: 0,
    wpm: 48,
    timestamp: Date.now()
  });
  expect(topTier.tier).toBe("platinum");
  expect(topTier.nextTarget).toBeNull();
});

test("lesson medal history stores records and builds view state", () => {
  const base = readLessonMedalProgress(createMemoryStorage());
  const first = recordLessonMedal(base, {
    mode: "burst",
    source: "cta",
    elapsedMs: 18000,
    accuracy: 0.9,
    bestCombo: 3,
    words: 5,
    errors: 1,
    wpm: 26,
    timestamp: 1000
  });
  const second = recordLessonMedal(first.progress, {
    mode: "precision",
    source: "cta",
    elapsedMs: 25000,
    accuracy: 0.965,
    bestCombo: 7,
    words: 8,
    errors: 0,
    wpm: 42,
    timestamp: 2000
  });
  const view = buildLessonMedalViewState(second.progress);
  expect(view.last?.tier).toBe("gold");
  expect(view.recent.length).toBeGreaterThan(0);
  expect(view.bestByMode.precision?.tier).toBe("gold");
  expect(view.bestByMode.burst?.tier).toBe("silver");
});

test("lesson medal persistence trims history and keeps version", () => {
  const storage = createMemoryStorage();
  let progress = readLessonMedalProgress(storage);
  for (let i = 0; i < 20; i += 1) {
    const entry = recordLessonMedal(progress, {
      mode: "endurance",
      source: "cta",
      elapsedMs: 30000,
      accuracy: 0.82 + i * 0.002,
      bestCombo: 2 + i,
      words: 6,
      errors: 1,
      wpm: 24 + i,
      timestamp: i + 10
    });
    progress = entry.progress;
  }
  writeLessonMedalProgress(storage, progress);
  const raw = storage.getItem("keyboard-defense:lesson-medals");
  expect(raw).toBeTruthy();
  const parsed = JSON.parse(raw ?? "{}");
  expect(parsed.version).toBe(LESSON_MEDAL_VERSION);
  expect(Array.isArray(parsed.history)).toBe(true);
  expect(parsed.history.length).toBeLessThanOrEqual(14);
  const replayed = readLessonMedalProgress(storage);
  expect(replayed.history.length).toBeLessThanOrEqual(14);
});
