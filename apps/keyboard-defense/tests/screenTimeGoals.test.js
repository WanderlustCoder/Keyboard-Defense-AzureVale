import { test } from "vitest";
import assert from "node:assert/strict";
import {
  SCREEN_TIME_SETTINGS_STORAGE_KEY,
  computeLockoutUntilMs,
  getLocalDayKey,
  getLockoutRemainingMs,
  isLockoutActive,
  readScreenTimeSettings,
  readScreenTimeUsage,
  writeScreenTimeSettings,
  writeScreenTimeUsage
} from "../public/dist/src/utils/screenTimeGoals.js";

const createMemoryStorage = () => {
  const data = new Map();
  return {
    getItem: (key) => (data.has(key) ? data.get(key) : null),
    setItem: (key, value) => data.set(key, value),
    removeItem: (key) => data.delete(key)
  };
};

test("screen time settings normalize and persist", () => {
  const storage = createMemoryStorage();
  const defaults = readScreenTimeSettings(storage);
  assert.deepEqual(defaults, { goalMinutes: 0, lockoutMode: "off" });

  const next = writeScreenTimeSettings(storage, { goalMinutes: 30, lockoutMode: "REST-15" });
  assert.equal(next.goalMinutes, 30);
  assert.equal(next.lockoutMode, "rest-15");

  const stored = storage.getItem(SCREEN_TIME_SETTINGS_STORAGE_KEY);
  assert.ok(stored && stored.includes("\"goalMinutes\":30"));

  const invalid = writeScreenTimeSettings(storage, { goalMinutes: 999, lockoutMode: "nope" });
  assert.deepEqual(invalid, { goalMinutes: 0, lockoutMode: "off" });
});

test("screen time usage resets when day changes", () => {
  const storage = createMemoryStorage();
  const nowMs = new Date(2025, 0, 2, 12, 0, 0).getTime();
  const today = getLocalDayKey(nowMs);
  const yesterday = getLocalDayKey(nowMs - 24 * 60 * 60 * 1000);

  writeScreenTimeUsage(storage, { day: yesterday, totalMs: 12345, lockoutUntilMs: nowMs + 1000 });
  const loaded = readScreenTimeUsage(storage, nowMs);
  assert.equal(loaded.day, today);
  assert.equal(loaded.totalMs, 0);
  assert.equal(loaded.lockoutUntilMs, null);
});

test("lockout helpers calculate and report remaining time", () => {
  const nowMs = new Date(2025, 0, 2, 12, 0, 0).getTime();
  const tomorrowMidnight = new Date(2025, 0, 3, 0, 0, 0, 0).getTime();

  assert.equal(computeLockoutUntilMs("off", nowMs), null);
  assert.equal(computeLockoutUntilMs("rest-15", nowMs), nowMs + 15 * 60_000);
  assert.equal(computeLockoutUntilMs("today", nowMs), tomorrowMidnight);

  const usage = { day: getLocalDayKey(nowMs), totalMs: 0, lockoutUntilMs: nowMs + 60_000 };
  assert.equal(isLockoutActive(usage, nowMs), true);
  assert.equal(getLockoutRemainingMs(usage, nowMs), 60_000);
  assert.equal(isLockoutActive(usage, nowMs + 60_000), false);
  assert.equal(getLockoutRemainingMs(usage, nowMs + 60_000), 0);
});

