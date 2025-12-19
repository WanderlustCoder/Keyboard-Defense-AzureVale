import { describe, expect, test, vi, beforeEach, afterEach } from "vitest";
import {
  DAILY_QUESTS_VERSION,
  readDailyQuestBoard,
  recordDailyQuestCampaignRun,
  recordDailyQuestDrill,
  writeDailyQuestBoard
} from "../src/utils/dailyQuests.ts";

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

describe("dailyQuests", () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  test("readDailyQuestBoard resets when day changes", () => {
    const storage = new MemoryStorage();
    const day1Ms = Date.parse("2025-01-01T12:00:00.000Z");
    const day2Ms = Date.parse("2025-01-02T12:00:00.000Z");

    const state = readDailyQuestBoard(storage, day1Ms);
    state.entries[0].progress = 2;
    writeDailyQuestBoard(storage, state);

    const next = readDailyQuestBoard(storage, day2Ms);
    expect(next.day).toBe("2025-01-02");
    expect(next.entries.every((entry) => entry.progress === 0)).toBe(true);
  });

  test("recordDailyQuestDrill increments drills and records Gold medals", () => {
    vi.setSystemTime(new Date("2025-01-03T12:00:00.000Z"));
    const state = {
      version: DAILY_QUESTS_VERSION,
      day: "2025-01-03",
      entries: [
        { id: "drills", progress: 0, target: 2, completedAt: null },
        { id: "gold-medal", progress: 0, target: 1, completedAt: null },
        { id: "campaign-waves", progress: 0, target: 3, completedAt: null }
      ],
      updatedAt: "2025-01-03T00:00:00.000Z"
    };

    const afterDrill = recordDailyQuestDrill(state, { medalTier: "silver" });
    expect(afterDrill.entries.find((entry) => entry.id === "drills")?.progress).toBe(1);
    expect(afterDrill.entries.find((entry) => entry.id === "gold-medal")?.progress).toBe(0);

    const afterGold = recordDailyQuestDrill(afterDrill, { medalTier: "gold" });
    expect(afterGold.entries.find((entry) => entry.id === "drills")?.progress).toBe(2);
    expect(afterGold.entries.find((entry) => entry.id === "drills")?.completedAt).toBeTruthy();
    expect(afterGold.entries.find((entry) => entry.id === "gold-medal")?.progress).toBe(1);
    expect(afterGold.entries.find((entry) => entry.id === "gold-medal")?.completedAt).toBeTruthy();
  });

  test("recordDailyQuestCampaignRun tracks best waves", () => {
    vi.setSystemTime(new Date("2025-01-04T12:00:00.000Z"));
    const state = {
      version: DAILY_QUESTS_VERSION,
      day: "2025-01-04",
      entries: [
        { id: "drills", progress: 0, target: 1, completedAt: null },
        { id: "gold-medal", progress: 0, target: 1, completedAt: null },
        { id: "campaign-waves", progress: 0, target: 4, completedAt: null }
      ],
      updatedAt: "2025-01-04T00:00:00.000Z"
    };

    const afterShort = recordDailyQuestCampaignRun(state, { wavesCompleted: 2 });
    expect(afterShort.entries.find((entry) => entry.id === "campaign-waves")?.progress).toBe(2);

    const afterLong = recordDailyQuestCampaignRun(afterShort, { wavesCompleted: 6 });
    expect(afterLong.entries.find((entry) => entry.id === "campaign-waves")?.progress).toBe(4);
    expect(afterLong.entries.find((entry) => entry.id === "campaign-waves")?.completedAt).toBeTruthy();
  });

  test("recordDailyQuestCampaignRun tracks best accuracy", () => {
    vi.setSystemTime(new Date("2025-01-05T12:00:00.000Z"));
    const state = {
      version: DAILY_QUESTS_VERSION,
      day: "2025-01-05",
      entries: [
        { id: "drills", progress: 0, target: 1, completedAt: null },
        { id: "gold-medal", progress: 0, target: 1, completedAt: null },
        { id: "campaign-accuracy", progress: 0, target: 90, completedAt: null }
      ],
      updatedAt: "2025-01-05T00:00:00.000Z"
    };

    const afterMiss = recordDailyQuestCampaignRun(state, { accuracyPct: 85 });
    expect(afterMiss.entries.find((entry) => entry.id === "campaign-accuracy")?.progress).toBe(85);

    const afterHit = recordDailyQuestCampaignRun(afterMiss, { accuracyPct: 93 });
    expect(afterHit.entries.find((entry) => entry.id === "campaign-accuracy")?.progress).toBe(90);
    expect(afterHit.entries.find((entry) => entry.id === "campaign-accuracy")?.completedAt).toBeTruthy();
  });
});

