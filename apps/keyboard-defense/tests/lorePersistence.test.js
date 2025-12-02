import { describe, expect, it } from "vitest";

import { LORE_ENTRIES, listNewLoreForWave } from "../src/data/lore.ts";
import { readLoreProgress, writeLoreProgress } from "../src/utils/lorePersistence.ts";

function createMemoryStorage() {
  const map = new Map();
  return {
    getItem: (key) => map.get(key) ?? null,
    setItem: (key, value) => map.set(key, value),
    removeItem: (key) => map.delete(key)
  };
}

describe("lore catalog + persistence", () => {
  it("lists unlockable lore by wave", () => {
    expect(LORE_ENTRIES.length).toBeGreaterThanOrEqual(1);
    const unlocked = new Set();
    const wave3 = listNewLoreForWave(3, unlocked);
    expect(wave3.some((entry) => entry.unlockWave <= 3)).toBe(true);
  });

  it("persists unlocked lore ids with versioning", () => {
    const storage = createMemoryStorage();
    const version = "v-test";
    const initial = readLoreProgress(storage, version);
    expect(initial.unlocked).toEqual([]);

    writeLoreProgress(storage, ["a", "b"], version);
    const after = readLoreProgress(storage, version);
    expect(after.unlocked).toEqual(["a", "b"]);

    const differentVersion = readLoreProgress(storage, "v-next");
    expect(differentVersion.unlocked).toEqual([]);
  });
});
