import { test, expect } from "vitest";
import {
  PLACEMENT_TEST_STORAGE_KEY,
  classifyHand,
  buildPlacementRecommendation,
  createPlacementTestResult,
  readPlacementTestResult,
  writePlacementTestResult
} from "../src/utils/placementTest.ts";

const createMemoryStorage = () => {
  const store = new Map();
  return {
    getItem: (key) => (store.has(key) ? store.get(key) : null),
    setItem: (key, value) => {
      store.set(key, String(value));
    },
    removeItem: (key) => {
      store.delete(key);
    }
  };
};

test("classifyHand tags left/right characters and neutral fallbacks", () => {
  expect(classifyHand("q")).toBe("left");
  expect(classifyHand("p")).toBe("right");
  expect(classifyHand("1")).toBe("left");
  expect(classifyHand("9")).toBe("right");
  expect(classifyHand(" ")).toBe("neutral");
});

test("buildPlacementRecommendation suggests slower pacing for low accuracy", () => {
  const rec = buildPlacementRecommendation({
    accuracy: 0.8,
    wpm: 28,
    leftAccuracy: 0.75,
    rightAccuracy: 0.9,
    leftSamples: 20,
    rightSamples: 22
  });
  expect(rec.tutorialPacing).toBeLessThan(1);
  expect(rec.focus).toBe("left");
  expect(rec.note).toContain("Suggested tutorial pace");
});

test("placement test results persist and normalize through storage", () => {
  const storage = createMemoryStorage();
  const result = createPlacementTestResult({
    elapsedMs: 45000,
    accuracy: 0.93,
    wpm: 42,
    leftCorrect: 18,
    leftTotal: 20,
    rightCorrect: 19,
    rightTotal: 20
  });

  writePlacementTestResult(storage, result);
  const raw = storage.getItem(PLACEMENT_TEST_STORAGE_KEY);
  expect(raw).toBeTruthy();

  const loaded = readPlacementTestResult(storage);
  expect(loaded).toBeTruthy();
  expect(loaded?.accuracy).toBeCloseTo(0.93, 4);
  expect(loaded?.leftSamples).toBe(20);
  expect(loaded?.rightSamples).toBe(20);
  expect(loaded?.recommendation.tutorialPacing).toBeGreaterThan(0.7);
});

