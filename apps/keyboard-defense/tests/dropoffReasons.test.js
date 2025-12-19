import { describe, expect, test } from "vitest";
import {
  DROPOFF_REASON_STORAGE_KEY,
  readDropoffReasons,
  recordDropoffReason
} from "../src/utils/dropoffReasons.ts";

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

describe("dropoffReasons", () => {
  test("readDropoffReasons returns empty list when storage is missing", () => {
    expect(readDropoffReasons(null)).toEqual([]);
  });

  test("recordDropoffReason prepends and trims history", () => {
    const storage = new MemoryStorage();
    recordDropoffReason(
      storage,
      { capturedAt: "2025-01-01T00:00:00.000Z", reasonId: "tired" },
      { maxEntries: 2 }
    );
    recordDropoffReason(
      storage,
      { capturedAt: "2025-01-01T00:01:00.000Z", reasonId: "break" },
      { maxEntries: 2 }
    );
    recordDropoffReason(
      storage,
      { capturedAt: "2025-01-01T00:02:00.000Z", reasonId: "done" },
      { maxEntries: 2 }
    );

    const entries = readDropoffReasons(storage);
    expect(entries.map((entry) => entry.reasonId)).toEqual(["done", "break"]);
    expect(entries).toHaveLength(2);
  });

  test("readDropoffReasons filters invalid entries", () => {
    const storage = new MemoryStorage({
      [DROPOFF_REASON_STORAGE_KEY]: JSON.stringify([
        { capturedAt: "2025-01-01T00:00:00.000Z", reasonId: "tired" },
        { capturedAt: "2025-01-01T00:01:00.000Z", reasonId: "" },
        null,
        { capturedAt: "2025-01-01T00:03:00.000Z" }
      ])
    });

    const entries = readDropoffReasons(storage);
    expect(entries.map((entry) => entry.reasonId)).toEqual(["tired"]);
  });

  test("recordDropoffReason normalizes numeric fields", () => {
    const storage = new MemoryStorage();
    recordDropoffReason(storage, {
      capturedAt: "2025-01-01T00:00:00.000Z",
      reasonId: "done",
      accuracy: 2,
      wpm: -5,
      waveIndex: 3.8,
      wavesCompleted: 4.2,
      breaches: 1.6
    });

    const entry = readDropoffReasons(storage)[0];
    expect(entry.accuracy).toBe(1);
    expect(entry.wpm).toBe(0);
    expect(entry.waveIndex).toBe(3);
    expect(entry.wavesCompleted).toBe(4);
    expect(entry.breaches).toBe(1);
  });
});

