import { describe, expect, it } from "vitest";

import { parseArgs, runBreachDrill } from "../scripts/castleBreachReplay.mjs";

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
    expect(result.passiveUnlockCount).toBeGreaterThanOrEqual(0);
    expect(Array.isArray(result.passiveUnlocks)).toBe(true);
    expect(Array.isArray(result.activeCastlePassives)).toBe(true);
    expect(result.finalState.passives).toEqual(result.activeCastlePassives);
    if (result.passiveUnlockCount === 0) {
      expect(result.passiveUnlockSummary).toBe(null);
      expect(result.lastPassiveUnlock).toBe(null);
    } else {
      expect(typeof result.passiveUnlockSummary).toBe("string");
      expect(result.passiveUnlockSummary?.length).toBeGreaterThan(0);
    }
  });

  it("parses turret and enemy overrides", () => {
    const options = parseArgs([
      "--enemy",
      "brute:2",
      "--enemy",
      "witch",
      "--turret",
      "slot-2:arcane@2"
    ]);
    expect(options.enemySpecs).toEqual([
      { tierId: "brute", lane: 2 },
      { tierId: "witch", lane: null }
    ]);
    expect(options.turrets).toEqual([{ slotId: "slot-2", typeId: "arcane", level: 2 }]);
  });

  it("applies turret loadouts and exposes metrics", async () => {
    const result = await runBreachDrill({
      seed: 3141,
      step: 0.1,
      maxTime: 25,
      sample: 0.5,
      artifact: null,
      tier: "brute",
      lane: 1,
      prep: 0.5,
      speedMultiplier: 1.2,
      healthMultiplier: 1,
      turrets: [{ slotId: "slot-1", typeId: "arrow", level: 1 }],
      enemySpecs: [
        { tierId: "brute", lane: 1 },
        { tierId: "brute", lane: 1 }
      ]
    });
    expect(result.turretPlacements).toHaveLength(1);
    expect(result.metrics.turretsPlaced).toBe(1);
    expect(result.metrics.enemiesSpawned).toBe(2);
    expect(Array.isArray(result.options.enemySpecs)).toBe(true);
    expect(result.options.enemySpecs.length).toBe(2);
    expect(result.metrics.timeToBreachSeconds === null || result.metrics.timeToBreachSeconds > 0).toBe(
      true
    );
  });
});
