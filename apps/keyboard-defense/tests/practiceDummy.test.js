import { describe, expect, it } from "vitest";
import { GameEngine } from "../src/engine/gameEngine.js";

describe("practice dummy enemy", () => {
  it("spawns stationary target and can be cleared", () => {
    const engine = new GameEngine({ seed: 1 });
    const dummy = engine.spawnEnemy({ tierId: "dummy", lane: 1, word: "dummy", order: 99 });
    expect(dummy?.tierId).toBe("dummy");
    expect(dummy?.speed).toBe(0);
    expect(dummy?.baseSpeed).toBe(0);
    expect(dummy?.distance).toBeGreaterThan(0.5);
    expect(dummy?.damage).toBe(0);
    const removed = engine.removeEnemiesByTier("dummy");
    expect(removed).toBeGreaterThan(0);
  });
});
