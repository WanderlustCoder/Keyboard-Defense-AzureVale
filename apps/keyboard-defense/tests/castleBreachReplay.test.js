import { describe, expect, it } from "vitest";

import {
  parseArgs,
  runBreachDrill
} from "../scripts/castleBreachReplay.mjs";

describe("castleBreachReplay CLI", () => {
  it("parses defaults without arguments", () => {
    const options = parseArgs([]);
    expect(options.seed).toBeTypeOf("number");
    expect(options.step).toBeGreaterThan(0);
    expect(options.maxTime).toBeGreaterThan(0);
    expect(options.tier).toBe("brute");
    expect(options.lane).toBeGreaterThanOrEqual(0);
  });

  it("records a breach when running the default drill", async () => {
    const result = await runBreachDrill({
      seed: 2025,
      step: 0.12,
      maxTime: 30,
      sample: 0.5,
      artifact: null,
      tier: "brute",
      lane: 1,
      prep: 0.5,
      speedMultiplier: 1.35,
      healthMultiplier: 1
    });

    expect(result.status).toBe("breached");
    expect(result.breach).toBeTruthy();
    expect(result.breach.time).toBeGreaterThan(0);
    expect(result.timeline.length).toBeGreaterThan(0);
    expect(result.timeline[result.timeline.length - 1].castleHealth).toBeLessThan(
      result.finalState.castleMaxHealth + 1e-6
    );
  });
});
