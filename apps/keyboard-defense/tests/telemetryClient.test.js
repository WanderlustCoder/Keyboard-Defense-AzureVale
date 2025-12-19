import { describe, expect, test } from "vitest";
import { TelemetryClient } from "../src/telemetry/telemetryClient.ts";

const TELEMETRY_STORAGE_KEY = "keyboard-defense:telemetry-queue";

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
}

function installLocalStorage(storage) {
  const hadLocalStorage = Object.prototype.hasOwnProperty.call(globalThis, "localStorage");
  const originalLocalStorage = globalThis.localStorage;
  globalThis.localStorage = storage;
  return () => {
    if (hadLocalStorage) {
      globalThis.localStorage = originalLocalStorage;
    } else {
      // eslint-disable-next-line no-delete-var
      delete globalThis.localStorage;
    }
  };
}

describe("TelemetryClient", () => {
  test("track enqueues and persists", () => {
    const storage = new MemoryStorage();
    const restore = installLocalStorage(storage);
    try {
      const queueSizes = [];
      const client = new TelemetryClient({
        enabled: true,
        maxQueueSize: 10,
        onQueueChange: (size) => queueSizes.push(size)
      });

      expect(client.getQueue()).toEqual([]);
      client.track("test.event", { ok: true }, { source: "unit" });

      expect(client.getQueue()).toHaveLength(1);
      expect(queueSizes.at(-1)).toBe(1);

      const raw = storage.getItem(TELEMETRY_STORAGE_KEY);
      expect(raw).not.toBeNull();

      const parsed = JSON.parse(raw);
      expect(parsed.version).toBe(1);
      expect(parsed.queue).toHaveLength(1);
      expect(parsed.queue[0].type).toBe("test.event");
      expect(parsed.queue[0].metadata).toEqual({ source: "unit" });
    } finally {
      restore();
    }
  });

  test("maxQueueSize drops oldest events", () => {
    const storage = new MemoryStorage();
    const restore = installLocalStorage(storage);
    try {
      const client = new TelemetryClient({ enabled: true, maxQueueSize: 2 });
      client.track("a", 1);
      client.track("b", 2);
      client.track("c", 3);

      const queue = client.getQueue();
      expect(queue).toHaveLength(2);
      expect(queue.map((entry) => entry.type)).toEqual(["b", "c"]);

      const parsed = JSON.parse(storage.getItem(TELEMETRY_STORAGE_KEY));
      expect(parsed.queue).toHaveLength(2);
    } finally {
      restore();
    }
  });

  test("purge clears queue and removes storage key", () => {
    const storage = new MemoryStorage();
    const restore = installLocalStorage(storage);
    try {
      const client = new TelemetryClient({ enabled: true });
      client.track("event", { ok: true });
      expect(storage.getItem(TELEMETRY_STORAGE_KEY)).not.toBeNull();

      const removed = client.purge();
      expect(removed).toBe(1);
      expect(client.getQueue()).toEqual([]);
      expect(storage.getItem(TELEMETRY_STORAGE_KEY)).toBeNull();
    } finally {
      restore();
    }
  });

  test("flush is a no-op without an endpoint", () => {
    const storage = new MemoryStorage();
    const restore = installLocalStorage(storage);
    try {
      const client = new TelemetryClient({ enabled: true });
      client.track("event", { ok: true });

      const batch = client.flush();
      expect(batch).toEqual([]);
      expect(client.getQueue()).toHaveLength(1);
    } finally {
      restore();
    }
  });

  test("flush restores the batch when transport fails asynchronously", async () => {
    const storage = new MemoryStorage();
    const restore = installLocalStorage(storage);
    try {
      const client = new TelemetryClient({
        enabled: true,
        endpoint: "https://collector.example/ingest",
        batchSize: 2,
        transport: () => Promise.reject(new Error("network down"))
      });

      client.track("a", { ok: true });
      client.track("b", { ok: true });
      client.track("c", { ok: true });

      const batch = client.flush();
      expect(batch.map((entry) => entry.type)).toEqual(["a", "b"]);

      expect(client.getQueue().map((entry) => entry.type)).toEqual(["c"]);

      await new Promise((resolve) => setTimeout(resolve, 0));
      expect(client.getQueue().map((entry) => entry.type)).toEqual(["a", "b", "c"]);
    } finally {
      restore();
    }
  });
});

