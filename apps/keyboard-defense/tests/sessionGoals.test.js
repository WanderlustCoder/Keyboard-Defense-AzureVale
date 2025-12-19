import { describe, expect, test } from "vitest";

import {
  buildSessionGoalsMetrics,
  buildSessionGoalsView,
  computeSessionWpm,
  computeWaveAccuracyRangePct,
  createDefaultSessionGoalsState,
  recordSessionGoalsRun,
  seedSessionGoalsFromPlacement
} from "../src/utils/sessionGoals.ts";

describe("sessionGoals", () => {
  test("computeSessionWpm converts correct inputs + elapsed seconds into WPM", () => {
    expect(computeSessionWpm(250, 60)).toBe(50);
    expect(computeSessionWpm(0, 60)).toBe(0);
    expect(computeSessionWpm(25, 0)).toBeGreaterThanOrEqual(0);
  });

  test("computeWaveAccuracyRangePct requires the full window", () => {
    const waves = [
      { accuracy: 0.9 },
      { accuracy: 0.8 },
      { accuracy: 0.95 }
    ];
    const range = computeWaveAccuracyRangePct(waves, 3);
    expect(range.waveCount).toBe(3);
    expect(range.rangePct).toBe(15);
    const insufficient = computeWaveAccuracyRangePct(waves.slice(0, 2), 3);
    expect(insufficient.waveCount).toBe(2);
    expect(insufficient.rangePct).toBeNull();
  });

  test("seedSessionGoalsFromPlacement initializes targets when runs are empty", () => {
    const state = createDefaultSessionGoalsState();
    const seeded = seedSessionGoalsFromPlacement(state, { accuracy: 0.96, wpm: 45 });
    expect(seeded.seededFromPlacement).toBe(true);
    expect(seeded.goals.accuracyPct).toBeGreaterThanOrEqual(90);
    expect(seeded.goals.wpm).toBeGreaterThanOrEqual(25);
  });

  test("recordSessionGoalsRun updates the model and derives new targets", () => {
    const state = createDefaultSessionGoalsState();
    const metrics = {
      durationSeconds: 600,
      wavesCompleted: 5,
      accuracyPct: 98,
      wpm: 80,
      consistencyRangePct: 5,
      consistencyWaveCount: 3
    };
    const next = recordSessionGoalsRun(state, {
      capturedAt: "2025-12-17T00:00:00.000Z",
      mode: "campaign",
      outcome: "victory",
      metrics,
      status: "victory"
    });
    expect(next.model.runs).toBe(1);
    expect(next.lastRun).not.toBeNull();
    expect(next.lastRun.outcome).toBe("victory");
    expect(next.lastRun.goals.accuracyPct).toBe(state.goals.accuracyPct);
    expect(next.goals.accuracyPct).toBeGreaterThanOrEqual(state.goals.accuracyPct);
    expect(next.goals.wpm).toBeGreaterThan(state.goals.wpm);
    expect(next.goals.consistencyRangePct).toBeLessThan(state.goals.consistencyRangePct);
  });

  test("buildSessionGoalsView shows next goals when the run has ended", () => {
    const base = createDefaultSessionGoalsState();
    const metrics = {
      durationSeconds: 600,
      wavesCompleted: 3,
      accuracyPct: 91,
      wpm: 29,
      consistencyRangePct: 10,
      consistencyWaveCount: 3
    };
    const updated = recordSessionGoalsRun(base, {
      capturedAt: "2025-12-17T00:00:00.000Z",
      mode: "campaign",
      outcome: "defeat",
      metrics,
      status: "defeat"
    });
    const view = buildSessionGoalsView(updated, metrics, "defeat");
    expect(view.goals.length).toBe(3);
    expect(view.goals.every((goal) => goal.status === "pending")).toBe(true);
    expect(view.summary).toContain("Last run:");
    expect(view.summary).toContain("New goals ready");
  });

  test("buildSessionGoalsMetrics computes consistency from wave summaries", () => {
    const metrics = buildSessionGoalsMetrics({
      mode: "campaign",
      status: "running",
      elapsedSeconds: 120,
      correctInputs: 250,
      accuracy: 0.93,
      waveSummaries: [
        { accuracy: 0.92 },
        { accuracy: 0.88 },
        { accuracy: 0.95 }
      ]
    });
    expect(metrics.wpm).toBeGreaterThan(0);
    expect(metrics.consistencyWaveCount).toBe(3);
    expect(metrics.consistencyRangePct).toBe(7);
  });
});

