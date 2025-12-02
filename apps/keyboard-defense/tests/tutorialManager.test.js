import { describe, expect, test, vi } from "vitest";

import { TutorialManager } from "../public/dist/src/tutorial/tutorialManager.js";

function createHudMock() {
  const hud = {
    messages: [],
    highlights: [],
    setTutorialMessage: vi.fn((message) => {
      hud.messages.push(message);
    }),
    setWavePreviewHighlight: vi.fn((value) => {
      hud.highlights.push(value);
    }),
    setSlotTutorialLock: vi.fn(),
    clearSlotTutorialLock: vi.fn(),
    showSlotMessage: vi.fn(),
    showCastleMessage: vi.fn(),
    setPassiveHighlight: vi.fn()
  };
  return hud;
}

function createEngineMock() {
  const state = {
    enemies: [],
    turrets: [
      { id: "slot-1", lane: 1, unlocked: true, turret: null },
      { id: "slot-2", lane: 2, unlocked: true, turret: null }
    ],
    resources: { gold: 500 },
    castle: { maxHealth: 100, health: 100, passives: [] },
    analytics: { sessionBreaches: 0 },
    typing: { accuracy: 1, combo: 0 }
  };

  const recordTutorialEvent = vi.fn();
  const recordTutorialAssist = vi.fn();

  const engine = {
    config: {
      turretSlots: [
        { id: "slot-1", lane: 1, unlockWave: 0 },
        { id: "slot-2", lane: 2, unlockWave: 0 }
      ],
      turretArchetypes: {
        arrow: { levels: [{ cost: 50 }, { level: 2, cost: 75 }] },
        arcane: { levels: [{ cost: 60 }, { level: 2, cost: 90 }] }
      }
    },
    events: { emit: vi.fn() },
    recordTutorialEvent,
    recordTutorialAssist,
    getState: () => state,
    spawnEnemy: vi.fn((request) => {
      const id = `enemy-${state.enemies.length + 1}`;
      state.enemies.push({ id, ...request });
    }),
    placeTurret: vi.fn((slotId, typeId) => {
      const slot = state.turrets.find((s) => s.id === slotId);
      if (!slot) {
        return { success: false, message: "slot missing" };
      }
      const cost = engine.config.turretArchetypes[typeId]?.levels?.[0]?.cost ?? 0;
      state.resources.gold -= cost;
      slot.turret = { typeId, level: 1 };
      return { success: true };
    }),
    setTurretFiringEnabled: vi.fn(),
    grantGold: vi.fn((delta) => {
      state.resources.gold += delta;
    }),
    damageCastle: vi.fn((damage) => {
      state.castle.health -= damage;
    })
  };

  return { engine, state };
}

function buildTutorialManager(overrides = {}) {
  const hud = createHudMock();
  const { engine } = createEngineMock();
  const manager = new TutorialManager({
    engine,
    hud,
    pauseGame: vi.fn(),
    resumeGame: vi.fn(),
    onComplete: vi.fn(),
    ...overrides
  });
  return { manager, hud, engine };
}

describe("TutorialManager assist + replay/skip flows", () => {
  test("shows assist hint after typing errors and only records once per step", () => {
    const { manager, hud, engine } = buildTutorialManager();

    manager.start();
    manager.notify({ type: "ui:continue" }); // intro -> typing-basic
    expect(manager.getCurrentStepId()).toBe("typing-basic");

    for (let i = 0; i < 4; i += 1) {
      manager.notify({ type: "typing:error" });
    }
    expect(engine.recordTutorialAssist).not.toHaveBeenCalled();

    manager.notify({ type: "typing:error" });
    expect(engine.recordTutorialAssist).toHaveBeenCalledTimes(1);
    const lastMessage = hud.messages.at(-1);
    expect(lastMessage).toMatch(/Hint: Focus on the glowing letters/i);

    // Further errors should not double-record the assist for the same step.
    manager.notify({ type: "typing:error" });
    expect(engine.recordTutorialAssist).toHaveBeenCalledTimes(1);

    const assistEvent = engine.recordTutorialEvent.mock.calls.find(
      ([, event]) => event === "assist:letter-hint"
    );
    expect(assistEvent?.[0]).toBe("typing-basic");
  });

  test("skip ends the tutorial, clears HUD messaging, and fires completion callback", () => {
    const onComplete = vi.fn();
    const { manager, hud } = buildTutorialManager({ onComplete });

    manager.start();
    manager.notify({ type: "ui:continue" }); // intro -> typing-basic
    expect(manager.getCurrentStepId()).toBe("typing-basic");

    manager.skip();

    const state = manager.getState();
    expect(state.active).toBe(false);
    expect(state.currentStepIndex).toBe(manager.steps.length);
    expect(manager.getCurrentStepId()).toBeNull();
    expect(onComplete).toHaveBeenCalledTimes(1);
    expect(hud.messages.at(-1)).toBeNull();
    expect(hud.highlights.at(-1)).toBe(false);
  });

  test("reset allows replay and clears assist/error counters between runs", () => {
    const { manager, hud, engine } = buildTutorialManager();

    manager.start();
    manager.notify({ type: "ui:continue" }); // intro -> typing-basic
    for (let i = 0; i < 5; i += 1) {
      manager.notify({ type: "typing:error" });
    }
    expect(engine.recordTutorialAssist).toHaveBeenCalledTimes(1);
    expect(manager.assistHintShown).toBe(true);
    const firstRunHint = hud.messages.at(-1);
    expect(firstRunHint).toMatch(/Hint/i);

    manager.reset();
    const resetState = manager.getState();
    expect(resetState.completedSteps).toHaveLength(0);
    expect(resetState.currentStepIndex).toBe(0);
    expect(manager.assistHintShown).toBe(false);
    expect(manager.errorsInStep).toBe(0);

    manager.start();
    manager.notify({ type: "ui:continue" }); // intro -> typing-basic
    expect(manager.getCurrentStepId()).toBe("typing-basic");
    for (let i = 0; i < 5; i += 1) {
      manager.notify({ type: "typing:error" });
    }
    expect(engine.recordTutorialAssist).toHaveBeenCalledTimes(2);
    expect(hud.messages.at(-1)).toMatch(/Hint/i);
  });
});
