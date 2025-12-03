import { test } from "vitest";
import assert from "node:assert/strict";
import {
  PLAYER_SETTINGS_STORAGE_KEY,
  createDefaultPlayerSettings,
  readPlayerSettings,
  withPatchedPlayerSettings,
  writePlayerSettings
} from "../public/dist/src/utils/playerSettings.js";

const createMemoryStorage = () => {
  const data = new Map();
  return {
    getItem: (key) => (data.has(key) ? data.get(key) : null),
    setItem: (key, value) => data.set(key, value),
    removeItem: (key) => data.delete(key)
  };
};

test("reduced cognitive load preference round-trips through storage", () => {
  const storage = createMemoryStorage();
  const defaults = createDefaultPlayerSettings();
  assert.equal(defaults.reducedCognitiveLoadEnabled, false);

  const patched = withPatchedPlayerSettings(defaults, { reducedCognitiveLoadEnabled: true });
  assert.equal(patched.reducedCognitiveLoadEnabled, true);

  writePlayerSettings(storage, patched);
  const stored = storage.getItem(PLAYER_SETTINGS_STORAGE_KEY);
  assert.ok(stored && stored.includes("reducedCognitiveLoadEnabled"));

  const loaded = readPlayerSettings(storage);
  assert.equal(loaded.reducedCognitiveLoadEnabled, true);
});

test("screen shake preference clamps intensity and persists enabled flag", () => {
  const storage = createMemoryStorage();
  const defaults = createDefaultPlayerSettings();
  assert.equal(defaults.screenShakeEnabled, false);
  assert.ok(defaults.screenShakeIntensity > 0);

  const patched = withPatchedPlayerSettings(defaults, {
    screenShakeEnabled: true,
    screenShakeIntensity: 2
  });
  writePlayerSettings(storage, patched);

  const loaded = readPlayerSettings(storage);
  assert.equal(loaded.screenShakeEnabled, true);
  assert.ok(loaded.screenShakeIntensity <= 1.2);
});

test("accessibility self-test state persists confirmations and timestamps", () => {
  const storage = createMemoryStorage();
  const defaults = createDefaultPlayerSettings();
  assert.equal(defaults.accessibilitySelfTest.soundConfirmed, false);
  assert.equal(defaults.accessibilitySelfTest.lastRunAt, null);

  const patched = withPatchedPlayerSettings(defaults, {
    accessibilitySelfTest: {
      lastRunAt: "2025-12-14T10:00:00.000Z",
      soundConfirmed: true,
      visualConfirmed: true,
      motionConfirmed: false
    }
  });

  writePlayerSettings(storage, patched);
  const loaded = readPlayerSettings(storage);
  assert.equal(loaded.accessibilitySelfTest.lastRunAt, "2025-12-14T10:00:00.000Z");
  assert.equal(loaded.accessibilitySelfTest.soundConfirmed, true);
  assert.equal(loaded.accessibilitySelfTest.visualConfirmed, true);
  assert.equal(loaded.accessibilitySelfTest.motionConfirmed, false);
});

test("castle skin selection normalizes and persists", () => {
  const storage = createMemoryStorage();
  const defaults = createDefaultPlayerSettings();
  assert.equal(defaults.castleSkin, "classic");

  const patched = withPatchedPlayerSettings(defaults, { castleSkin: "aurora" });
  writePlayerSettings(storage, patched);
  const loaded = readPlayerSettings(storage);
  assert.equal(loaded.castleSkin, "aurora");

  const invalid = withPatchedPlayerSettings(defaults, { castleSkin: "midnight" });
  assert.equal(invalid.castleSkin, "classic");
});
