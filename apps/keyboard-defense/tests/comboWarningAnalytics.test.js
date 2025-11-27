import assert from "node:assert/strict";
import { test } from "vitest";

import { GameEngine } from "../src/engine/gameEngine.ts";

function createTelemetryStub() {
  const events = [];
  return {
    track: (event, payload) => {
      events.push({ event, payload });
    },
    getEvents: () => events
  };
}

test("GameEngine records combo warning accuracy deltas and telemetry events", () => {
  const telemetry = createTelemetryStub();
  const engine = new GameEngine({ seed: 7, config: { waves: [] }, telemetryClient: telemetry });
  const typing = engine.state.typing;
  typing.combo = 6;
  typing.comboTimer = 2;
  typing.accuracy = 0.95;

  // Prime the baseline accuracy while no warning is active.
  engine.tickComboTimer(0);

  // Trigger the warning by dropping accuracy and advancing time.
  typing.accuracy = 0.9;
  engine.tickComboTimer(0.7);

  // Let the combo expire to finalize the warning entry.
  typing.accuracy = 0.82;
  engine.tickComboTimer(1.4);

  const comboWarning = engine.state.analytics.comboWarning;
  assert.equal(comboWarning.count, 1);
  assert.equal(comboWarning.history.length, 1);
  const entry = comboWarning.history[0];
  assert.equal(entry.comboBefore, 6);
  assert.equal(entry.comboAfter, 0);
  assert.ok(entry.deltaPercent < 0);
  assert.equal(entry.waveIndex, 0);
  assert.ok(entry.durationMs >= 0);
  assert.equal(comboWarning.lastDelta, entry.deltaPercent);
  assert.equal(comboWarning.deltaMin, entry.deltaPercent);
  assert.equal(comboWarning.deltaMax, entry.deltaPercent);
  assert.equal(comboWarning.deltaSum, entry.deltaPercent);

  const events = telemetry.getEvents();
  assert.equal(events.length, 1);
  const payload = events[0];
  assert.equal(payload.event, "combat.comboWarningDelta");
  assert.equal(payload.payload.comboBefore, 6);
  assert.equal(payload.payload.comboAfter, 0);
  assert.equal(payload.payload.waveIndex, 0);
  assert.equal(payload.payload.deltaPercent, entry.deltaPercent);
});
