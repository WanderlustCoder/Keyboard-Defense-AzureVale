import { test, expect } from "vitest";
import {
  ERROR_CLUSTER_STORAGE_KEY,
  readErrorClusterProgress,
  recordErrorClusterEntry,
  writeErrorClusterProgress,
  getTopExpectedKeys
} from "../src/utils/errorClusters.ts";

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

test("error cluster progress persists and ranks recent trouble keys", () => {
  const storage = createMemoryStorage();
  const originalNow = Date.now;
  const nowMs = 1700000000000;
  Date.now = () => nowMs;

  try {
    let progress = readErrorClusterProgress(storage);
    expect(progress.history.length).toBe(0);

    progress = recordErrorClusterEntry(progress, { expected: "t", received: "r", timestamp: nowMs - 1000 });
    progress = recordErrorClusterEntry(progress, { expected: "t", received: "r", timestamp: nowMs - 900 });
    progress = recordErrorClusterEntry(progress, { expected: "t", received: "e", timestamp: nowMs - 800 });
    progress = recordErrorClusterEntry(progress, { expected: "t", received: "s", timestamp: nowMs - 700 });
    progress = recordErrorClusterEntry(progress, { expected: "e", received: "w", timestamp: nowMs - 600 });
    progress = recordErrorClusterEntry(progress, { expected: "e", received: "q", timestamp: nowMs - 500 });
    progress = recordErrorClusterEntry(progress, { expected: null, received: "a", timestamp: nowMs - 400 });
    progress = recordErrorClusterEntry(progress, { expected: "z", received: "x", timestamp: nowMs - 1000 * 60 * 11 });

    writeErrorClusterProgress(storage, progress);
    const raw = storage.getItem(ERROR_CLUSTER_STORAGE_KEY);
    expect(raw).toBeTruthy();

    const loaded = readErrorClusterProgress(storage);
    const topKeys = getTopExpectedKeys(loaded, { nowMs, windowMs: 1000 * 60 * 10, limit: 3 });
    expect(topKeys[0]).toEqual({ key: "t", count: 4 });
    expect(topKeys[1]).toEqual({ key: "e", count: 2 });
    expect(topKeys.some((entry) => entry.key === "z")).toBe(false);
  } finally {
    Date.now = originalNow;
  }
});

