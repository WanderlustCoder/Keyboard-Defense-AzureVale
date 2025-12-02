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
});
