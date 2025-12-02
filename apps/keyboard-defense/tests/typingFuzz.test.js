import { test } from "vitest";
import assert from "node:assert/strict";

import { defaultConfig } from "../src/core/config.ts";
import { TypingSystem } from "../public/dist/src/systems/typingSystem.js";

function createTestState() {
  return {
    time: 0,
    typing: {
      buffer: "",
      activeEnemyId: null,
      errors: 0,
      combo: 0,
      comboTimer: 0,
      comboWarning: false,
      totalInputs: 0,
      correctInputs: 0,
      recentInputs: [],
      recentCorrectInputs: 0,
      recentAccuracy: 1,
      dynamicDifficultyBias: 0
    },
    enemies: [
      {
        id: "enemy-1",
        word: "arcane",
        typed: 0,
        distance: 1,
        status: "alive",
        maxHealth: 50,
        health: 50,
        lane: 0,
        spawnedAt: 0
      }
    ],
    analytics: {
      waveReactionTime: 0,
      waveReactionSamples: 0,
      totalReactionTime: 0,
      reactionSamples: 0,
      waveTypingDamage: 0,
      wavePerfectWords: 0,
      totalPerfectWords: 0,
      waveMaxCombo: 0,
      sessionBestCombo: 0,
      totalTypingDamage: 0,
      totalDamageDealt: 0
    }
  };
}

const fakeEvents = {
  emitted: [],
  emit(event, payload) {
    this.emitted.push({ event, payload });
  }
};

const fakeEnemySystem = {
  damageEnemy(_state, _enemyId, _damage) {
    return { damage: _damage };
  }
};

test("TypingSystem ignores invalid characters and leaves buffer untouched", () => {
  const typing = new TypingSystem(defaultConfig, fakeEvents);
  const state = createTestState();
  const invalidInputs = ["1", "%", " ", "\n", "\t", "", "AA", "é", "7", "#"];

  for (const char of invalidInputs) {
    const result = typing.inputCharacter(state, char, fakeEnemySystem);
    assert.equal(result.status, "ignored");
    assert.equal(state.typing.buffer, "");
  }

  assert.equal(state.typing.totalInputs, 0, "invalid inputs should not increment counters");
});

test("TypingSystem withstands mixed random input without overflowing buffer", () => {
  const typing = new TypingSystem(defaultConfig, fakeEvents);
  const state = createTestState();
  const inputs = ["a", "r", "c", "x", "!", "n", "e", "backspace", " ", "z", "\n", "b"];

  for (let i = 0; i < 50; i += 1) {
    const char = inputs[i % inputs.length];
    if (char === "backspace") {
      typing.handleBackspace(state);
      continue;
    }
    const result = typing.inputCharacter(state, char, fakeEnemySystem);
    assert.ok(
      state.typing.buffer.length <= state.enemies[0].word.length,
      "buffer should never exceed active word length"
    );
    assert.ok(["progress", "completed", "error", "ignored"].includes(result.status));
    state.time += 0.1;
  }

  assert.ok(
    state.typing.buffer.length <= state.enemies[0].word.length,
    "final buffer should be bounded by word length"
  );
});

test("TypingSystem purgeBuffer safely resets active enemy and combo", () => {
  const typing = new TypingSystem(defaultConfig, fakeEvents);
  const state = createTestState();

  typing.inputCharacter(state, "a", fakeEnemySystem);
  typing.inputCharacter(state, "r", fakeEnemySystem);
  assert.ok(state.typing.buffer.length > 0);
  state.typing.combo = 2;

  const result = typing.purgeBuffer(state);
  assert.equal(result.status, "purged");
  assert.equal(state.typing.buffer, "");
  assert.equal(state.typing.activeEnemyId, null);
  assert.equal(state.typing.combo, 1, "purge should apply minor combo penalty when active");
});
