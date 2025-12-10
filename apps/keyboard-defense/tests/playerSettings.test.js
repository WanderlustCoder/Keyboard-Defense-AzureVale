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

test("latency sparkline preference round-trips via player settings", () => {
  const storage = createMemoryStorage();
  const defaults = createDefaultPlayerSettings();
  assert.equal(defaults.latencySparklineEnabled, true);

  const patched = withPatchedPlayerSettings(defaults, { latencySparklineEnabled: false });
  writePlayerSettings(storage, patched);

  const loaded = readPlayerSettings(storage);
  assert.equal(loaded.latencySparklineEnabled, false);
});

test("focus outline preset persists and normalizes", () => {
  const storage = createMemoryStorage();
  const defaults = createDefaultPlayerSettings();
  assert.equal(defaults.focusOutlinePreset, "system");

  const patched = withPatchedPlayerSettings(defaults, { focusOutlinePreset: "glow" });
  writePlayerSettings(storage, patched);

  const loaded = readPlayerSettings(storage);
  assert.equal(loaded.focusOutlinePreset, "glow");

  const invalid = withPatchedPlayerSettings(defaults, { focusOutlinePreset: "neon" });
  assert.equal(invalid.focusOutlinePreset, "system");
});

test("audio narration preference persists", () => {
  const storage = createMemoryStorage();
  const defaults = createDefaultPlayerSettings();
  assert.equal(defaults.audioNarrationEnabled, false);

  const patched = withPatchedPlayerSettings(defaults, { audioNarrationEnabled: true });
  writePlayerSettings(storage, patched);
  const loaded = readPlayerSettings(storage);
  assert.equal(loaded.audioNarrationEnabled, true);
});

test("large subtitle preference persists", () => {
  const storage = createMemoryStorage();
  const defaults = createDefaultPlayerSettings();
  assert.equal(defaults.largeSubtitlesEnabled, false);

  const patched = withPatchedPlayerSettings(defaults, { largeSubtitlesEnabled: true });
  writePlayerSettings(storage, patched);
  const loaded = readPlayerSettings(storage);
  assert.equal(loaded.largeSubtitlesEnabled, true);
});

test("tutorial pacing persists and clamps", () => {
  const storage = createMemoryStorage();
  const defaults = createDefaultPlayerSettings();
  assert.equal(defaults.tutorialPacing, 1);

  const patched = withPatchedPlayerSettings(defaults, { tutorialPacing: 1.2 });
  writePlayerSettings(storage, patched);
  const loaded = readPlayerSettings(storage);
  assert.equal(loaded.tutorialPacing, 1.2);

  const clamped = withPatchedPlayerSettings(defaults, { tutorialPacing: 2 });
  assert.equal(clamped.tutorialPacing, 1.25);
});

test("accessibility preset flag persists", () => {
  const storage = createMemoryStorage();
  const defaults = createDefaultPlayerSettings();
  assert.equal(defaults.accessibilityPresetEnabled, false);

  const patched = withPatchedPlayerSettings(defaults, { accessibilityPresetEnabled: true });
  writePlayerSettings(storage, patched);
  const loaded = readPlayerSettings(storage);
  assert.equal(loaded.accessibilityPresetEnabled, true);
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

test("music settings clamp level and persist enabled flag", () => {
  const storage = createMemoryStorage();
  const defaults = createDefaultPlayerSettings();
  assert.equal(defaults.musicEnabled, true);
  assert.ok(defaults.musicLevel > 0);

  const patched = withPatchedPlayerSettings(defaults, {
    musicEnabled: false,
    musicLevel: 2
  });
  writePlayerSettings(storage, patched);
  const loaded = readPlayerSettings(storage);
  assert.equal(loaded.musicEnabled, false);
  assert.ok(loaded.musicLevel <= 1);
});
