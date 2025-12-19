import { describe, expect, test } from "vitest";

import {
  createFatigueDetectorState,
  snoozeFatigueDetector,
  updateFatigueDetector
} from "../src/utils/fatigueDetector.ts";

function feed(state, entry, options) {
  return updateFatigueDetector(state, entry, options);
}

describe("fatigueDetector", () => {
  test("does not prompt before the minimum history is collected", () => {
    let state = createFatigueDetectorState();
    let result = feed(state, { waveIndex: 0, capturedAtMs: 6 * 60_000, accuracy: 0.92, p50Ms: 220 });
    state = result.state;
    expect(result.prompt).toBeNull();

    result = feed(state, { waveIndex: 1, capturedAtMs: 7 * 60_000, accuracy: 0.91, p50Ms: 215 });
    state = result.state;
    expect(result.prompt).toBeNull();

    result = feed(state, { waveIndex: 2, capturedAtMs: 8 * 60_000, accuracy: 0.9, p50Ms: 225 });
    expect(result.prompt).toBeNull();
  });

  test("prompts when accuracy drops and latency rises across waves", () => {
    let state = createFatigueDetectorState();
    const samples = [
      { waveIndex: 0, capturedAtMs: 5 * 60_000, accuracy: 0.92, p50Ms: 210 },
      { waveIndex: 1, capturedAtMs: 6 * 60_000, accuracy: 0.91, p50Ms: 205 },
      { waveIndex: 2, capturedAtMs: 7 * 60_000, accuracy: 0.9, p50Ms: 215 },
      { waveIndex: 3, capturedAtMs: 8 * 60_000, accuracy: 0.83, p50Ms: 285 },
      { waveIndex: 4, capturedAtMs: 9 * 60_000, accuracy: 0.82, p50Ms: 300 }
    ];
    let prompt = null;
    for (const entry of samples) {
      const result = feed(state, entry);
      state = result.state;
      prompt = result.prompt ?? prompt;
    }
    expect(prompt).not.toBeNull();
    expect(prompt.kind).toBe("fatigue-break");
    expect(prompt.accuracyDropPct).toBeGreaterThanOrEqual(6);
    expect(prompt.latencyRiseMs).toBeGreaterThanOrEqual(60);
  });

  test("respects the cooldown window after prompting", () => {
    let state = createFatigueDetectorState();
    const samples = [
      { waveIndex: 0, capturedAtMs: 5 * 60_000, accuracy: 0.92, p50Ms: 210 },
      { waveIndex: 1, capturedAtMs: 6 * 60_000, accuracy: 0.91, p50Ms: 205 },
      { waveIndex: 2, capturedAtMs: 7 * 60_000, accuracy: 0.9, p50Ms: 215 },
      { waveIndex: 3, capturedAtMs: 8 * 60_000, accuracy: 0.83, p50Ms: 285 },
      { waveIndex: 4, capturedAtMs: 9 * 60_000, accuracy: 0.82, p50Ms: 300 }
    ];
    for (const entry of samples) {
      const result = feed(state, entry);
      state = result.state;
    }

    const withinCooldown = feed(state, {
      waveIndex: 5,
      capturedAtMs: 12 * 60_000,
      accuracy: 0.8,
      p50Ms: 320
    });
    expect(withinCooldown.prompt).toBeNull();
  });

  test("snooze suppresses prompts until the window expires", () => {
    let state = createFatigueDetectorState();
    state = snoozeFatigueDetector(state, 10 * 60_000, 10 * 60_000);
    const samples = [
      { waveIndex: 0, capturedAtMs: 11 * 60_000, accuracy: 0.92, p50Ms: 210 },
      { waveIndex: 1, capturedAtMs: 12 * 60_000, accuracy: 0.91, p50Ms: 205 },
      { waveIndex: 2, capturedAtMs: 13 * 60_000, accuracy: 0.9, p50Ms: 215 },
      { waveIndex: 3, capturedAtMs: 14 * 60_000, accuracy: 0.83, p50Ms: 285 },
      { waveIndex: 4, capturedAtMs: 15 * 60_000, accuracy: 0.82, p50Ms: 300 }
    ];
    let prompted = false;
    for (const entry of samples) {
      const result = feed(state, entry);
      state = result.state;
      prompted = prompted || Boolean(result.prompt);
    }
    expect(prompted).toBe(false);
  });
});

