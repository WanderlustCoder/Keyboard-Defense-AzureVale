import { describe, expect, it } from "vitest";
import { GameEngine } from "../src/engine/gameEngine.js";
import { TurretSystem } from "../src/systems/turretSystem.js";
import { EventBus } from "../src/core/eventBus.js";

describe("lane hazards", () => {
  it("reduces turret fire rate when storm hazard active", () => {
    const engine = new GameEngine({ seed: 99 });
    // skip countdown and advance to spawn hazards
    engine.update(8);
    // manually insert a hazard
    const state = engine.getState();
    state.laneHazards.push({
      lane: 0,
      kind: "storm",
      remaining: 5,
      duration: 5,
      fireRateMultiplier: 0.8
    });
    const turretSystem = new TurretSystem(engine.config, new EventBus());
    const multiplier = turretSystem.resolveLaneFireRateMultiplier(state, 0);
    expect(multiplier).toBeLessThan(1);
  });

  it("assigns a default turret fire rate debuff for fog hazards", () => {
    const engine = new GameEngine({ seed: 1 });
    let nextCalls = 0;
    const rng = {
      next() {
        nextCalls += 1;
        // First call: ensure hazardCount=1. Second call: choose fog.
        return nextCalls === 1 ? 0.9 : 0.4;
      },
      pick(values) {
        return values[0];
      },
      range(min) {
        return min;
      }
    };

    engine["buildLaneHazardsForWave"](1, rng);
    const hazardEvents = engine["hazardEvents"] ?? [];
    expect(hazardEvents.length).toBe(1);
    expect(hazardEvents[0].kind).toBe("fog");
    expect(hazardEvents[0].fireRateMultiplier).toBe(0.9);
  });
});
