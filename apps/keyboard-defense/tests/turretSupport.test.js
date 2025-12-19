import { describe, expect, it, vi } from "vitest";
import { defaultConfig } from "../src/core/config.js";
import { EventBus } from "../src/core/eventBus.js";
import { TurretSystem } from "../src/systems/turretSystem.js";

function makeState(overrides = {}) {
  return {
    turrets: [
      {
        id: "slot-1",
        lane: 0,
        unlocked: true,
        position: { x: 0.3, y: 0.5 },
        targetingPriority: "first",
        turret: { slotId: "slot-1", typeId: "arrow", level: 1, cooldown: 0 }
      }
    ],
    enemies: [
      {
        id: "enemy-1",
        tierId: "grunt",
        word: "abc",
        typed: 0,
        typingErrors: 0,
        maxHealth: 10,
        health: 10,
        speed: 0,
        baseSpeed: 0,
        distance: 0.95,
        lane: 0,
        damage: 0,
        reward: 1,
        status: "alive",
        effects: [],
        spawnedAt: 0,
        waveIndex: 0
      }
    ],
    laneHazards: [],
    supportBoost: {
      lane: null,
      remaining: 0,
      duration: 0,
      multiplier: 1,
      cooldownRemaining: 0
    },
    boss: { active: false, lane: null, shockwaveRemaining: 0, shockwaveMultiplier: 1 },
    typing: {
      combo: 0,
      recentAccuracy: 1
    },
    ...overrides
  };
}

describe("turret support (typing combo)", () => {
  it("scales the support multiplier with combo and accuracy", () => {
    const turretSystem = new TurretSystem(defaultConfig, new EventBus());
    const base = makeState({ typing: { combo: 0, recentAccuracy: 1 } });
    const lowCombo = makeState({ typing: { combo: 5, recentAccuracy: 1 } });
    const lowAccuracy = makeState({ typing: { combo: 10, recentAccuracy: 0.5 } });
    const highAccuracy = makeState({ typing: { combo: 10, recentAccuracy: 1 } });

    expect(turretSystem.resolveTypingSupportMultiplier(base)).toBe(1);
    expect(turretSystem.resolveTypingSupportMultiplier(lowCombo)).toBeGreaterThan(1);
    expect(turretSystem.resolveTypingSupportMultiplier(highAccuracy)).toBeGreaterThan(
      turretSystem.resolveTypingSupportMultiplier(lowAccuracy)
    );
  });

  it("reduces turret cooldown when combo is active", () => {
    const turretSystem = new TurretSystem(defaultConfig, new EventBus());
    const projectiles = { spawn: vi.fn() };

    const noCombo = makeState({ typing: { combo: 0, recentAccuracy: 1 } });
    turretSystem.update(noCombo, 0, projectiles);
    const cooldownNoCombo = noCombo.turrets[0].turret.cooldown;

    const combo = makeState({ typing: { combo: 20, recentAccuracy: 1 } });
    turretSystem.update(combo, 0, projectiles);
    const cooldownCombo = combo.turrets[0].turret.cooldown;

    expect(cooldownCombo).toBeGreaterThan(0);
    expect(cooldownNoCombo).toBeGreaterThan(0);
    expect(cooldownCombo).toBeLessThan(cooldownNoCombo);
  });
});

describe("support surge (lane boost)", () => {
  it("reduces turret cooldown when lane boost is active", () => {
    const turretSystem = new TurretSystem(defaultConfig, new EventBus());
    const projectiles = { spawn: vi.fn() };

    const baseline = makeState({
      typing: { combo: 0, recentAccuracy: 1 },
      supportBoost: { lane: null, remaining: 0, duration: 0, multiplier: 1, cooldownRemaining: 0 }
    });
    turretSystem.update(baseline, 0, projectiles);
    const cooldownBaseline = baseline.turrets[0].turret.cooldown;

    const boosted = makeState({
      typing: { combo: 0, recentAccuracy: 1 },
      supportBoost: { lane: 0, remaining: 3, duration: 3, multiplier: 1.2, cooldownRemaining: 10 }
    });
    turretSystem.update(boosted, 0, projectiles);
    const cooldownBoosted = boosted.turrets[0].turret.cooldown;

    expect(cooldownBoosted).toBeGreaterThan(0);
    expect(cooldownBoosted).toBeLessThan(cooldownBaseline);
  });
});
