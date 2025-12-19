import { describe, expect, it } from "vitest";
import { GameEngine } from "../src/engine/gameEngine.js";

describe("support boost (engine)", () => {
  it("activates, expires, and enforces cooldown", () => {
    const engine = new GameEngine({ seed: 5 });
    engine.update(6);

    expect(engine.activateSupportBoost(0, { multiplier: 1.2, duration: 3, cooldown: 5 })).toBe(true);
    let state = engine.getState();
    expect(state.supportBoost.lane).toBe(0);
    expect(state.supportBoost.remaining).toBeGreaterThan(2.9);
    expect(state.supportBoost.multiplier).toBeCloseTo(1.2);
    expect(state.supportBoost.cooldownRemaining).toBeGreaterThan(4.9);

    engine.update(1);
    state = engine.getState();
    expect(state.supportBoost.remaining).toBeGreaterThan(1.9);
    expect(state.supportBoost.cooldownRemaining).toBeGreaterThan(3.9);
    expect(engine.activateSupportBoost(0, { multiplier: 1.2, duration: 3, cooldown: 5 })).toBe(false);

    engine.update(2.2);
    state = engine.getState();
    expect(state.supportBoost.remaining).toBe(0);
    expect(state.supportBoost.lane).toBe(null);
    expect(state.supportBoost.multiplier).toBe(1);
    expect(state.supportBoost.cooldownRemaining).toBeGreaterThan(0.5);
    expect(engine.activateSupportBoost(0, { multiplier: 1.2, duration: 3, cooldown: 5 })).toBe(false);

    engine.update(3);
    state = engine.getState();
    expect(state.supportBoost.cooldownRemaining).toBe(0);
    expect(engine.activateSupportBoost(0, { multiplier: 1.2, duration: 3, cooldown: 5 })).toBe(true);
  });
});

