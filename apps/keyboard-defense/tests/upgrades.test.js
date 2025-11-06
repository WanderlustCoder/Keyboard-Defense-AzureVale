import { test } from "vitest";
import assert from "node:assert/strict";
import { GameEngine } from "../dist/src/engine/gameEngine.js";

test("castle upgrade increases stats and unlocks slots", () => {
  const engine = new GameEngine({ seed: 99, config: { waves: [] } });
  const initialState = engine.getState();
  assert.equal(initialState.castle.level, 1);
  assert.equal(initialState.turrets.filter((slot) => slot.unlocked).length, 2);

  engine.grantGold(1000);
  const result = engine.upgradeCastle();
  assert.ok(result.success, result.message ?? "castle upgrade should succeed");

  const updated = engine.getState();
  assert.equal(updated.castle.level, 2);
  assert.ok(updated.castle.maxHealth > initialState.castle.maxHealth);
  assert.equal(updated.turrets.filter((slot) => slot.unlocked).length, 3);
});

test("castle upgrade emits passive unlock events", () => {
  const engine = new GameEngine({ seed: 7, config: { waves: [] } });
  const passives = [];
  engine.events.on("castle:passive-unlocked", ({ passive }) => passives.push(passive));

  engine.grantGold(1000);
  engine.upgradeCastle();

  assert.ok(passives.length > 0, "expected at least one passive unlock");
  assert.equal(passives[0].id, "regen");
});

test("turret upgrade consumes gold and raises level", () => {
  const engine = new GameEngine({ seed: 11, config: { waves: [] } });
  engine.grantGold(1000);

  const place = engine.placeTurret("slot-1", "arrow");
  assert.ok(place.success, place.message ?? "placement should succeed");

  const stateAfterPlace = engine.getState();
  const slot = stateAfterPlace.turrets.find((s) => s.id === "slot-1");
  assert.equal(slot?.turret?.level, 1);

  const upgrade = engine.upgradeTurret("slot-1");
  assert.ok(upgrade.success, upgrade.message ?? "upgrade should succeed");

  const after = engine.getState();
  const upgradedSlot = after.turrets.find((s) => s.id === "slot-1");
  assert.equal(upgradedSlot?.turret?.level, 2);
  assert.ok(after.resources.gold < stateAfterPlace.resources.gold);
});

test("castle repair restores health, applies cooldown, and costs gold", () => {
  const engine = new GameEngine({ seed: 21, config: { waves: [] } });
  const initialHealth = engine.getState().castle.health;
  const startingGold = engine.getState().resources.gold;
  engine.damageCastle(60);

  const damagedState = engine.getState();
  assert.equal(damagedState.castle.health, initialHealth - 60);
  assert.equal(Math.round(damagedState.castle.repairCooldownRemaining), 0);

  const repair = engine.repairCastle();
  assert.ok(repair.success, repair.message ?? "repair should succeed");
  assert.equal(Math.round(repair.healed ?? 0), 60);

  const afterRepair = engine.getState();
  assert.equal(afterRepair.castle.health, afterRepair.castle.maxHealth);
  assert.ok(afterRepair.castle.repairCooldownRemaining > 0);
  assert.equal(
    Math.round(afterRepair.castle.repairCooldownRemaining),
    engine.config.castleRepair.cooldownSeconds
  );
  assert.ok(afterRepair.resources.gold < startingGold);
  assert.equal(afterRepair.analytics.totalCastleRepairs, 1);
  assert.equal(afterRepair.analytics.totalRepairHealth, 60);
  assert.equal(afterRepair.analytics.totalRepairGold, engine.config.castleRepair.cost);
  assert.equal(afterRepair.analytics.waveRepairs, 1);
  assert.equal(afterRepair.analytics.waveRepairHealth, 60);
  assert.equal(afterRepair.analytics.waveRepairGold, engine.config.castleRepair.cost);

  engine.damageCastle(20);
  const cooldownFailure = engine.repairCastle();
  assert.equal(cooldownFailure.success, false);
  assert.match(cooldownFailure.message ?? "", /cool(ing\s+down|down)/i);
  const afterCooldownAttempt = engine.getState();
  assert.equal(afterCooldownAttempt.analytics.totalCastleRepairs, 1);
  assert.equal(afterCooldownAttempt.analytics.waveRepairs, 1);
});

test("castle repair fails without gold or missing health", () => {
  const engine = new GameEngine({ seed: 8, config: { waves: [] } });
  const initialResult = engine.repairCastle();
  assert.equal(initialResult.success, false);
  assert.match(initialResult.message ?? "", /full health/i);

  engine.damageCastle(40);
  const currentGold = engine.getState().resources.gold;
  engine.grantGold(10 - currentGold);
  const goldFailure = engine.repairCastle();
  assert.equal(goldFailure.success, false);
  assert.match(goldFailure.message ?? "", /Not enough gold/i);
  const failureState = engine.getState();
  assert.equal(failureState.analytics.totalCastleRepairs, 0);
  assert.equal(failureState.analytics.waveRepairs, 0);
});
