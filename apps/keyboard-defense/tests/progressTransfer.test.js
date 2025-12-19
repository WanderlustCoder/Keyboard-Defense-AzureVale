import { describe, expect, test } from "vitest";
import {
  PROGRESS_TRANSFER_FORMAT,
  PROGRESS_TRANSFER_VERSION,
  exportProgressTransferPayload,
  importProgressTransferPayload
} from "../src/utils/progressTransfer.ts";

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

describe("progressTransfer", () => {
  test("exportProgressTransferPayload only exports allowed keys", () => {
    const storage = new MemoryStorage({
      "keyboard-defense:lesson-progress": "{\"version\":\"v1\"}",
      "lore.codex.unlocked": "{\"version\":\"v1\"}",
      "other-app:data": "nope"
    });

    const payload = exportProgressTransferPayload(storage);
    expect(payload.format).toBe(PROGRESS_TRANSFER_FORMAT);
    expect(payload.version).toBe(PROGRESS_TRANSFER_VERSION);
    expect(payload.entries["keyboard-defense:lesson-progress"]).toBe("{\"version\":\"v1\"}");
    expect(payload.entries["lore.codex.unlocked"]).toBe("{\"version\":\"v1\"}");
    expect(payload.entries["other-app:data"]).toBeUndefined();
  });

  test("importProgressTransferPayload applies allowed keys and skips others", () => {
    const storage = new MemoryStorage({
      "keyboard-defense:lesson-progress": "old",
      "keyboard-defense:obsolete": "bye"
    });

    const payload = {
      format: PROGRESS_TRANSFER_FORMAT,
      version: PROGRESS_TRANSFER_VERSION,
      exportedAt: "2025-01-01T00:00:00.000Z",
      entries: {
        "keyboard-defense:lesson-progress": "new",
        "lore.codex.unlocked": "{\"unlocked\":[]}",
        "keyboard-defense:obsolete": null,
        "other-app:data": "ignored",
        "keyboard-defense:bad-value": 123
      }
    };

    const result = importProgressTransferPayload(storage, payload);
    expect(result.errors).toEqual([]);
    expect(result.applied).toBe(2);
    expect(result.removed).toBe(1);
    expect(result.skipped).toBe(2);

    expect(storage.getItem("keyboard-defense:lesson-progress")).toBe("new");
    expect(storage.getItem("lore.codex.unlocked")).toBe("{\"unlocked\":[]}");
    expect(storage.getItem("keyboard-defense:obsolete")).toBeNull();
    expect(storage.getItem("other-app:data")).toBeNull();
    expect(storage.getItem("keyboard-defense:bad-value")).toBeNull();
  });

  test("importProgressTransferPayload rejects unknown formats", () => {
    const storage = new MemoryStorage();
    const result = importProgressTransferPayload(storage, {
      format: "not-keyboard-defense",
      version: PROGRESS_TRANSFER_VERSION,
      exportedAt: "2025-01-01T00:00:00.000Z",
      entries: {}
    });
    expect(result.errors.length).toBeGreaterThan(0);
  });
});

