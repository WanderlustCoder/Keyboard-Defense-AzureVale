import { describe, expect, it } from "vitest";
import { rollEliteAffixes } from "../src/data/eliteAffixes.js";
import { EnemySystem } from "../src/systems/enemySystem.js";
import { TurretSystem } from "../src/systems/turretSystem.js";
import { defaultConfig } from "../src/core/config.js";
import { createInitialState } from "../src/core/gameState.js";
import { EventBus } from "../src/core/eventBus.js";
import { PRNG } from "../public/dist/src/utils/random.js";

describe("elite affixes", () => {
  it("rolls deterministic affixes and filters shielded when a shield already exists", () => {
    const rng = {
      next: () => 0.01,
      pick: (items) => items[0]
    };
    const affixes = rollEliteAffixes({
      tierId: "brute",
      waveIndex: 2,
      rng,
      baseShield: 40
    });
    expect(affixes).toHaveLength(1);
    expect(affixes[0].id).toBe("armored");
  });

  it("applies armored affix mitigation and bonus shield on spawn", () => {
    const events = new EventBus();
    const rng = new PRNG(7);
    const enemySystem = new EnemySystem(defaultConfig, events, rng);
    const state = createInitialState(defaultConfig);
    const armored = {
      id: "armored",
      label: "Armored",
      description: "",
      effects: { turretDamageTakenMultiplier: 0.5 }
    };
    const enemy = enemySystem.spawn(state, {
      tierId: "brute",
      lane: 0,
      order: 1,
      affixes: [armored],
      waveIndex: 0
    });
    expect(enemy?.affixes?.[0]?.id).toBe("armored");
    expect(enemy?.shield).toBeUndefined();
    const result = enemySystem.damageEnemy(state, enemy.id, 20, "turret");
    expect(result.damage).toBeCloseTo(10);

    const shielded = enemySystem.spawn(state, {
      tierId: "brute",
      lane: 1,
      order: 2,
      affixes: [
        {
          id: "shielded",
          label: "Aegis",
          description: "",
          effects: { bonusShield: 20 }
        }
      ],
      waveIndex: 0
    });
    expect(shielded?.shield?.current).toBeGreaterThan(0);
  });

  it("honors slow-aura lane fire-rate multipliers", () => {
    const turretSystem = new TurretSystem(defaultConfig, new EventBus());
    const state = { enemies: [] };
    state.enemies.push({
      id: "enemy-1",
      tierId: "brute",
      status: "alive",
      lane: 0,
      distance: 0.2,
      laneFireRateMultiplier: 0.6,
      effects: []
    });
    state.enemies.push({
      id: "enemy-2",
      tierId: "witch",
      status: "alive",
      lane: 0,
      distance: 0.3,
      affixes: [{ effects: { laneFireRateMultiplier: 0.5 } }],
      effects: []
    });
    const multiplier = turretSystem.resolveLaneFireRateMultiplier(state, 0);
    expect(multiplier).toBeCloseTo(0.5);
  });
});
