import { describe, expect, test } from "vitest";
import { createStuckKeyDetectorState, updateStuckKeyDetector } from "../src/utils/inputAnomalies.ts";

describe("inputAnomalies", () => {
  test("warns once per key after repeated identical typing errors", () => {
    let state = createStuckKeyDetectorState();
    let warning = null;
    for (let i = 0; i < 7; i += 1) {
      const result = updateStuckKeyDetector(
        state,
        { expected: "b", received: i % 2 === 0 ? "a" : "A" },
        i * 100,
        { streakThreshold: 8, maxGapMs: 500, cooldownMs: 0 }
      );
      state = result.state;
      warning = result.warning;
      expect(warning).toBeNull();
    }

    const eighth = updateStuckKeyDetector(
      state,
      { expected: "b", received: "A" },
      700,
      { streakThreshold: 8, maxGapMs: 500, cooldownMs: 0 }
    );
    state = eighth.state;
    expect(eighth.warning).toEqual({ kind: "stuck-key", key: "a", streak: 8 });

    const ninth = updateStuckKeyDetector(
      state,
      { expected: "b", received: "a" },
      800,
      { streakThreshold: 8, maxGapMs: 500, cooldownMs: 0 }
    );
    expect(ninth.warning).toBeNull();

    let nextState = ninth.state;
    for (let i = 0; i < 7; i += 1) {
      const step = updateStuckKeyDetector(
        nextState,
        { expected: "y", received: i % 2 === 0 ? "x" : "X" },
        900 + i * 100,
        { streakThreshold: 8, maxGapMs: 500, cooldownMs: 0 }
      );
      nextState = step.state;
    }
    const xWarning = updateStuckKeyDetector(
      nextState,
      { expected: "y", received: "X" },
      1600,
      { streakThreshold: 8, maxGapMs: 500, cooldownMs: 0 }
    );
    expect(xWarning.warning).toEqual({ kind: "stuck-key", key: "x", streak: 8 });
  });

  test("resets streak when time gap exceeds threshold", () => {
    let state = createStuckKeyDetectorState();
    const options = { streakThreshold: 3, maxGapMs: 100, cooldownMs: 0 };

    const first = updateStuckKeyDetector(state, { expected: "b", received: "a" }, 0, options);
    expect(first.warning).toBeNull();

    const second = updateStuckKeyDetector(first.state, { expected: "b", received: "a" }, 90, options);
    expect(second.warning).toBeNull();

    const gapReset = updateStuckKeyDetector(second.state, { expected: "b", received: "a" }, 300, options);
    expect(gapReset.warning).toBeNull();
    expect(gapReset.state.streak).toBe(1);
  });
});
