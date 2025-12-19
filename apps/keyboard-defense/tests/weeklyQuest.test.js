import { describe, expect, test, vi, beforeEach, afterEach } from "vitest";
import {
  WEEKLY_QUEST_VERSION,
  buildWeeklyQuestBoardView,
  buildWeeklyTrialWaveConfig,
  readWeeklyQuestBoard,
  recordWeeklyQuestCampaignRun,
  recordWeeklyQuestDrill,
  recordWeeklyQuestTrialAttempt,
  writeWeeklyQuestBoard
} from "../src/utils/weeklyQuest.ts";

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

describe("weeklyQuest", () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  test("readWeeklyQuestBoard resets when week changes", () => {
    const storage = new MemoryStorage();
    const week1Ms = Date.parse("2025-01-01T12:00:00.000Z");
    const week2Ms = Date.parse("2025-01-08T12:00:00.000Z");

    const state = readWeeklyQuestBoard(storage, week1Ms);
    state.entries[0].progress = 5;
    writeWeeklyQuestBoard(storage, state);

    const next = readWeeklyQuestBoard(storage, week2Ms);
    expect(next.week).not.toBe(state.week);
    expect(next.entries.every((entry) => entry.progress === 0)).toBe(true);
    expect(next.trial.unlockedAt).toBe(null);
  });

  test("recordWeeklyQuestDrill increments drills and counts Gold medals", () => {
    vi.setSystemTime(new Date("2025-01-07T12:00:00.000Z"));
    const state = {
      version: WEEKLY_QUEST_VERSION,
      week: "2025-01-06",
      entries: [
        { id: "drills", progress: 0, target: 2, completedAt: null },
        { id: "gold-medal", progress: 0, target: 2, completedAt: null },
        { id: "campaign-waves", progress: 0, target: 3, completedAt: null }
      ],
      trial: { unlockedAt: null, completedAt: null, attempts: 0, lastOutcome: null },
      updatedAt: "2025-01-06T00:00:00.000Z"
    };

    const afterDrill = recordWeeklyQuestDrill(state, { medalTier: "silver" });
    expect(afterDrill.entries.find((entry) => entry.id === "drills")?.progress).toBe(1);
    expect(afterDrill.entries.find((entry) => entry.id === "gold-medal")?.progress).toBe(0);

    const afterGold = recordWeeklyQuestDrill(afterDrill, { medalTier: "gold" });
    expect(afterGold.entries.find((entry) => entry.id === "drills")?.progress).toBe(2);
    expect(afterGold.entries.find((entry) => entry.id === "drills")?.completedAt).toBeTruthy();
    expect(afterGold.entries.find((entry) => entry.id === "gold-medal")?.progress).toBe(1);

    const afterPlatinum = recordWeeklyQuestDrill(afterGold, { medalTier: "platinum" });
    expect(afterPlatinum.entries.find((entry) => entry.id === "gold-medal")?.progress).toBe(2);
    expect(afterPlatinum.entries.find((entry) => entry.id === "gold-medal")?.completedAt).toBeTruthy();
  });

  test("unlocks the Weekly Trial when all quests complete", () => {
    vi.setSystemTime(new Date("2025-01-09T12:00:00.000Z"));
    const state = {
      version: WEEKLY_QUEST_VERSION,
      week: "2025-01-06",
      entries: [
        { id: "drills", progress: 2, target: 2, completedAt: "2025-01-07T00:00:00.000Z" },
        { id: "gold-medal", progress: 2, target: 2, completedAt: "2025-01-08T00:00:00.000Z" },
        { id: "campaign-waves", progress: 2, target: 3, completedAt: null }
      ],
      trial: { unlockedAt: null, completedAt: null, attempts: 0, lastOutcome: null },
      updatedAt: "2025-01-09T00:00:00.000Z"
    };

    const afterCampaign = recordWeeklyQuestCampaignRun(state, { wavesCompleted: 3 });
    expect(afterCampaign.trial.unlockedAt).toBeTruthy();
    const view = buildWeeklyQuestBoardView(afterCampaign);
    expect(view.trial.status).toBe("ready");
  });

  test("recordWeeklyQuestTrialAttempt increments attempts and marks completion on victory", () => {
    vi.setSystemTime(new Date("2025-01-10T12:00:00.000Z"));
    const state = {
      version: WEEKLY_QUEST_VERSION,
      week: "2025-01-06",
      entries: [
        { id: "drills", progress: 1, target: 1, completedAt: "2025-01-06T00:00:00.000Z" },
        { id: "gold-medal", progress: 1, target: 1, completedAt: "2025-01-06T00:00:00.000Z" },
        { id: "campaign-waves", progress: 4, target: 4, completedAt: "2025-01-06T00:00:00.000Z" }
      ],
      trial: { unlockedAt: "2025-01-09T00:00:00.000Z", completedAt: null, attempts: 0, lastOutcome: null },
      updatedAt: "2025-01-10T00:00:00.000Z"
    };

    const afterDefeat = recordWeeklyQuestTrialAttempt(state, "defeat");
    expect(afterDefeat.trial.attempts).toBe(1);
    expect(afterDefeat.trial.lastOutcome).toBe("defeat");
    expect(afterDefeat.trial.completedAt).toBe(null);

    const afterVictory = recordWeeklyQuestTrialAttempt(afterDefeat, "victory");
    expect(afterVictory.trial.attempts).toBe(2);
    expect(afterVictory.trial.lastOutcome).toBe("victory");
    expect(afterVictory.trial.completedAt).toBeTruthy();
  });

  test("buildWeeklyTrialWaveConfig is deterministic", () => {
    const waveA = buildWeeklyTrialWaveConfig("2025-01-06");
    const waveB = buildWeeklyTrialWaveConfig("2025-01-06");
    expect(waveA.id).toBe(waveB.id);
    expect(waveA.duration).toBe(waveB.duration);
    expect(waveA.spawns).toEqual(waveB.spawns);
    expect(waveA.spawns.every((spawn) => spawn.lane >= 0 && spawn.lane <= 2)).toBe(true);
  });
});

