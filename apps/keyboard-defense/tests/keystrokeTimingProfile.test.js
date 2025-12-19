import { describe, expect, test } from "vitest";

import {
  buildKeystrokeTimingGate,
  buildKeystrokeTimingMetrics,
  classifyTempoBand,
  computeSpawnSpeedGateMultiplier,
  computeTempoWpmFromMedianMs,
  createDefaultKeystrokeTimingProfileState,
  recordKeystrokeTimingProfileRun
} from "../src/utils/keystrokeTimingProfile.ts";

describe("keystrokeTimingProfile", () => {
  test("computeTempoWpmFromMedianMs converts median ms into WPM", () => {
    expect(computeTempoWpmFromMedianMs(200)).toBe(60);
    expect(computeTempoWpmFromMedianMs(0)).toBe(0);
    expect(computeTempoWpmFromMedianMs(-10)).toBe(0);
  });

  test("classifyTempoBand maps tempo WPM into bands", () => {
    expect(classifyTempoBand(10)).toBe("starter");
    expect(classifyTempoBand(25)).toBe("steady");
    expect(classifyTempoBand(40)).toBe("swift");
    expect(classifyTempoBand(55)).toBe("turbo");
    expect(classifyTempoBand(null)).toBeNull();
  });

  test("buildKeystrokeTimingMetrics summarizes jitter and tempo", () => {
    const samples = Array.from({ length: 60 }, () => 200);
    const metrics = buildKeystrokeTimingMetrics(samples);
    expect(metrics.sampleCount).toBe(60);
    expect(metrics.medianMs).toBe(200);
    expect(metrics.p90Ms).toBe(200);
    expect(metrics.jitterMs).toBe(0);
    expect(metrics.tempoWpm).toBe(60);
    expect(metrics.band).toBe("turbo");
  });

  test("computeSpawnSpeedGateMultiplier returns 1 without enough samples", () => {
    expect(
      computeSpawnSpeedGateMultiplier({
        sampleCount: 10,
        medianMs: 400,
        jitterMs: 200,
        tempoWpm: 30
      })
    ).toBe(1);
  });

  test("computeSpawnSpeedGateMultiplier reduces ramp for jittery + slow profiles", () => {
    const multiplier = computeSpawnSpeedGateMultiplier({
      sampleCount: 50,
      medianMs: 520,
      jitterMs: 240,
      tempoWpm: 23
    });
    expect(multiplier).toBeLessThan(1);
    expect(multiplier).toBeGreaterThanOrEqual(0.85);
  });

  test("recordKeystrokeTimingProfileRun captures lastRun and updates the model", () => {
    const base = createDefaultKeystrokeTimingProfileState();
    const samples = Array.from({ length: 80 }, () => 200);
    const next = recordKeystrokeTimingProfileRun(base, {
      capturedAt: "2025-12-17T00:00:00.000Z",
      outcome: "victory",
      samples
    });
    expect(next.model.runs).toBe(1);
    expect(next.lastRun).not.toBeNull();
    expect(next.lastRun.outcome).toBe("victory");
    expect(next.lastRun.sampleCount).toBe(80);
    expect(next.model.medianMsEma).toBe(200);
    expect(next.model.jitterMsEma).toBe(0);
    expect(next.model.tempoWpmEma).toBe(60);
  });

  test("buildKeystrokeTimingGate falls back to stored model when samples are missing", () => {
    const seeded = {
      ...createDefaultKeystrokeTimingProfileState(),
      model: { runs: 2, medianMsEma: 400, jitterMsEma: 180, tempoWpmEma: 30 }
    };
    const gate = buildKeystrokeTimingGate({ samples: [], profile: seeded });
    expect(gate.source).toBe("model");
    expect(gate.multiplier).toBeLessThanOrEqual(1);
    expect(gate.multiplier).toBeGreaterThanOrEqual(0.85);
  });
});

