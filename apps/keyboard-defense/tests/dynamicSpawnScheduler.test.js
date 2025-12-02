import { describe, expect, it } from "vitest";
import { GameEngine } from "../src/engine/gameEngine.js";

describe("dynamic spawn scheduler", () => {
  it("injects dynamic events into upcoming spawns when enabled", () => {
    const engine = new GameEngine({ seed: 123 });
    // Start wave (skip countdown)
    engine.update(4);
    const previews = engine.getUpcomingSpawns(10);
    const dynamicEntries = previews.filter((entry) => entry.order >= 1000);
    expect(dynamicEntries.length).toBeGreaterThan(0);
  });

  it("omits dynamic events when feature toggle is off", () => {
    const engine = new GameEngine({
      seed: 123,
      config: { featureToggles: { dynamicSpawns: false } }
    });
    engine.update(4);
    const previews = engine.getUpcomingSpawns(10);
    const dynamicEntries = previews.filter((entry) => entry.order >= 1000);
    expect(dynamicEntries.length).toBe(0);
  });
});
