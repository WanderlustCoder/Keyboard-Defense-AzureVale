import { describe, expect, test } from "vitest";

import {
  clearTutorialCompletion,
  readTutorialCompletion,
  writeTutorialCompletion,
  TUTORIAL_COMPLETION_STORAGE_KEY
} from "../public/dist/src/tutorial/tutorialPersistence.js";

function createMemoryStorage() {
  const store = new Map();
  let sets = 0;
  let removes = 0;
  let gets = 0;
  const storage = {
    getItem: (key) => {
      gets += 1;
      return store.has(key) ? store.get(key) : null;
    },
    setItem: (key, value) => {
      sets += 1;
      store.set(key, String(value));
    },
    removeItem: (key) => {
      removes += 1;
      store.delete(key);
    }
  };
  return {
    storage,
    stats: () => ({ sets, removes, gets, size: store.size }),
    snapshot: () => store.has(TUTORIAL_COMPLETION_STORAGE_KEY) ? store.get(TUTORIAL_COMPLETION_STORAGE_KEY) : null
  };
}

describe("tutorial replay/skip soak", () => {
  test("alternating replay/skip preserves completion version integrity", () => {
    const version = "v2";
    const altVersion = "v3";
    const memory = createMemoryStorage();
    const log = [];

    for (let i = 0; i < 30; i += 1) {
      if (i % 3 === 0) {
        writeTutorialCompletion(memory.storage, version);
        log.push({ action: "write", version });
      } else if (i % 3 === 1) {
        clearTutorialCompletion(memory.storage);
        log.push({ action: "skip-clear" });
      } else {
        writeTutorialCompletion(memory.storage, altVersion);
        log.push({ action: "write-alt", version: altVersion });
      }
      // Ensure no state throw when reading mid-loop.
      expect(() => readTutorialCompletion(memory.storage, version)).not.toThrow();
    }

    // Final action writes an alternate version; primary version should read as incomplete.
    expect(memory.snapshot()).toBe(altVersion);
    expect(readTutorialCompletion(memory.storage, version)).toBe(false);
    expect(readTutorialCompletion(memory.storage, altVersion)).toBe(true);

    const stats = memory.stats();
    expect(stats.sets).toBeGreaterThan(0);
    expect(stats.removes).toBeGreaterThan(0);
    expect(stats.gets).toBeGreaterThan(0);
    expect(stats.size).toBe(1);

    const writes = log.filter((item) => item.action.startsWith("write"));
    const clears = log.filter((item) => item.action === "skip-clear");
    expect(writes.length).toBeGreaterThan(clears.length);
    expect(clears.length).toBeGreaterThan(5);
  });
});
