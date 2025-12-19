import { describe, expect, it } from "vitest";
import { GameEngine } from "../src/engine/gameEngine.js";

describe("typo recovery (engine)", () => {
  it("restores combo and refreshes the decay timer", () => {
    const engine = new GameEngine({ seed: 41 });
    engine.setMode("practice");
    engine.update(4);

    engine.spawnEnemy({ tierId: "grunt", lane: 0, word: "a", order: 1 });
    engine.inputCharacter("a");
    expect(engine.getState().typing.combo).toBe(1);

    engine.recoverCombo(7.8);
    const state = engine.getState();
    expect(state.typing.combo).toBe(7);
    expect(state.typing.comboTimer).toBe(engine.config.comboDecaySeconds);
    expect(state.typing.comboWarning).toBe(false);
    expect(state.analytics.waveMaxCombo).toBeGreaterThanOrEqual(7);
    expect(state.analytics.sessionBestCombo).toBeGreaterThanOrEqual(7);
  });

  it("clears combo metadata when recovering to zero", () => {
    const engine = new GameEngine({ seed: 17 });
    engine.setMode("practice");
    engine.update(4);
    engine.recoverCombo(3);
    engine.recoverCombo(0);
    const state = engine.getState();
    expect(state.typing.combo).toBe(0);
    expect(state.typing.comboTimer).toBe(0);
    expect(state.typing.comboWarning).toBe(false);
  });

  it("does not reduce best combo analytics", () => {
    const engine = new GameEngine({ seed: 23 });
    engine.setMode("practice");
    engine.update(4);

    engine.recoverCombo(5);
    engine.recoverCombo(2);

    const state = engine.getState();
    expect(state.analytics.sessionBestCombo).toBe(5);
    expect(state.analytics.waveMaxCombo).toBe(5);
  });
});

