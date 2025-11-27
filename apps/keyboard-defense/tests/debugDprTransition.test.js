import { describe, it, expect } from "vitest";
import { simulateDprTransitions, formatTransitionMarkdown } from "../scripts/debug/dprTransition.mjs";

describe("simulateDprTransitions", () => {
  const fixedNow = () => new Date("2025-11-13T12:00:00.000Z");

  it("generates deterministic entries for custom steps", () => {
    const payload = simulateDprTransitions({
      steps: ["1:960:init", "1.5:840:pinch", "1.25:900:return"],
      fadeMs: 120,
      holdMs: 30,
      baseWidth: 960,
      baseHeight: 540,
      prefersCondensedHud: true,
      hudLayout: "condensed",
      now: fixedNow
    });

    expect(payload.fadeMs).toBe(120);
    expect(payload.holdMs).toBe(30);
    expect(payload.steps).toHaveLength(3);
    expect(payload.steps[0]).toMatchObject({
      cause: "init",
      fromDpr: 1,
      toDpr: 1,
      cssWidth: 960,
      renderWidth: 960,
      transitionMs: 150,
      prefersCondensedHud: true,
      hudLayout: "condensed"
    });
    expect(payload.steps[1]).toMatchObject({
      cause: "pinch",
      fromDpr: 1,
      toDpr: 1.5,
      cssWidth: 840,
      renderWidth: 1260
    });
  });

  it("falls back to defaults when steps omitted", () => {
    const payload = simulateDprTransitions({ now: fixedNow });
    expect(payload.steps.length).toBeGreaterThan(0);
    expect(payload.steps[0].cause).toBe("init");
  });

  it("formats markdown summaries", () => {
    const payload = simulateDprTransitions({ steps: ["1:960:init", "1.5:840:pinch"], now: fixedNow });
    const markdown = formatTransitionMarkdown(payload);
    expect(markdown).toContain("# Canvas DPR Transition");
    expect(markdown).toContain("| 1 | init");
    expect(markdown).toContain("| 2 | pinch");
  });
});
