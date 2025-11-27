import { DiagnosticsOverlay } from "../src/ui/diagnostics.ts";
import { test } from "vitest";
import assert from "node:assert/strict";
import { parseHTML } from "linkedom";
import { GameEngine } from "../src/engine/gameEngine.ts";

const setupDiagnosticsDom = (options = {}) => {
  const { window } = parseHTML("<html><body><div id='diagnostics-overlay'></div></body></html>");
  const { document } = window;
  const container = document.getElementById("diagnostics-overlay");
  if (!container) throw new Error("Missing diagnostics container in test DOM");

  const originalGlobals = {
    document: global.document,
    window: global.window,
    HTMLElement: global.HTMLElement,
    HTMLDivElement: global.HTMLDivElement,
    HTMLButtonElement: global.HTMLButtonElement,
    Node: global.Node,
    matchMedia: global.window?.matchMedia
  };

  Object.assign(global, {
    document,
    window,
    HTMLElement: window.HTMLElement,
    HTMLDivElement: window.HTMLDivElement,
    HTMLButtonElement: window.HTMLButtonElement,
    Node: window.Node
  });

  const matchMedia =
    typeof options.matchMedia === "function"
      ? options.matchMedia
      : createMatchMediaStub(options.matchMediaState ?? {});
  window.matchMedia = matchMedia;
  global.window.matchMedia = matchMedia;

  return {
    container,
    document,
    window,
    cleanup: () => {
      if (originalGlobals.document === undefined) delete global.document;
      else global.document = originalGlobals.document;
      if (originalGlobals.window === undefined) delete global.window;
      else global.window = originalGlobals.window;
      if (originalGlobals.HTMLElement === undefined) delete global.HTMLElement;
      else global.HTMLElement = originalGlobals.HTMLElement;
      if (originalGlobals.HTMLDivElement === undefined) delete global.HTMLDivElement;
      else global.HTMLDivElement = originalGlobals.HTMLDivElement;
      if (originalGlobals.HTMLButtonElement === undefined)
        delete global.HTMLButtonElement;
      else global.HTMLButtonElement = originalGlobals.HTMLButtonElement;
      if (originalGlobals.Node === undefined) delete global.Node;
      else global.Node = originalGlobals.Node;
      if (originalGlobals.window && originalGlobals.matchMedia) {
        originalGlobals.window.matchMedia = originalGlobals.matchMedia;
      }
    }
  };
};

const createMatchMediaStub = (state = {}) => {
  const resolver =
    typeof state === "function" ? state : (query) => state[query] ?? state.default ?? false;
  return (query) => ({
    matches: Boolean(resolver(query)),
    media: query,
    addEventListener: () => {},
    removeEventListener: () => {},
    addListener: () => {},
    removeListener: () => {},
    dispatchEvent: () => false
  });
};

test("runtime metrics report wave, difficulty, and entity counts", () => {
  const engine = new GameEngine({ seed: 12, config: { waves: [] } });

  const metrics = engine.getRuntimeMetrics();
  assert.equal(metrics.wave.index, 0);
  assert.ok(metrics.difficulty.enemyHealthMultiplier >= 1);
  assert.equal(metrics.projectiles, 0);
  assert.equal(metrics.enemiesAlive, 0);
  assert.equal(metrics.damage.total, 0);
  assert.equal(metrics.damage.turret, 0);
  assert.equal(metrics.damage.typing, 0);
  assert.equal(typeof metrics.difficultyRating, "number");
  assert.ok(metrics.difficultyRating >= 0);
  assert.equal(metrics.typing.recentSampleSize, 0);
  assert.equal(metrics.typing.difficultyBias, 0);
  assert.ok(Array.isArray(metrics.turretStats));
  assert.equal(metrics.turretStats.length, 0);
  assert.equal(metrics.goldEventCount ?? 0, 0);
  assert.equal(metrics.goldDelta ?? null, null);
  assert.equal(metrics.goldEventTimestamp ?? null, null);
  const recentGoldEvents = Array.isArray(metrics.recentGoldEvents) ? metrics.recentGoldEvents : [];
  assert.equal(recentGoldEvents.length, 0);
  const passiveList = Array.isArray(metrics.castlePassives) ? metrics.castlePassives : [];
  assert.equal(passiveList.length, 0);
  const passiveCount =
    typeof metrics.passiveUnlockCount === "number" ? metrics.passiveUnlockCount : passiveList.length;
  assert.equal(passiveCount, passiveList.length);
  assert.equal(metrics.lastPassiveUnlock ?? null, null);

  engine.spawnEnemy({ tierId: "grunt", lane: 0, word: "test" });
  engine.inputCharacter("t");
  engine.grantGold(25);

  const updated = engine.getRuntimeMetrics();
  assert.equal(updated.enemiesAlive, 1);
  assert.equal(updated.typing.totalInputs, 1);
  assert.equal(updated.typing.correctInputs, 1);
  assert.ok(updated.typing.accuracy > 0.9);
  assert.ok(updated.typing.recentAccuracy > 0.9);
  assert.equal(updated.typing.recentSampleSize, 1);
  assert.equal(updated.typing.difficultyBias, 0);
  assert.equal(typeof updated.damage.total, "number");
  assert.equal(typeof updated.damage.typing, "number");
  assert.equal(typeof updated.damage.turret, "number");
  assert.equal(typeof updated.difficultyRating, "number");
  assert.ok(updated.difficultyRating >= 0);
  assert.equal(updated.turretStats.length, 0);
  const updatedEvents = Array.isArray(updated.recentGoldEvents) ? updated.recentGoldEvents : [];
  const emittedEventCount =
    typeof updated.goldEventCount === "number" ? updated.goldEventCount : updatedEvents.length;
  assert.equal(emittedEventCount, 1);
  const latestDelta = updated.goldDelta ?? updatedEvents[0]?.delta ?? null;
  assert.equal(latestDelta, 25);
  const latestTimestamp =
    typeof updated.goldEventTimestamp === "number"
      ? updated.goldEventTimestamp
      : updatedEvents[0]?.timestamp ?? null;
  assert.equal(typeof latestTimestamp, "number");
  assert.equal(updatedEvents.length, 1);
  assert.equal(updatedEvents[0].delta, 25);
});

test("DiagnosticsOverlay displays shield forecast lines", () => {
  const { container, cleanup } = setupDiagnosticsDom();
  try {
    const overlay = new DiagnosticsOverlay(container);
    overlay.applyCondensedState(false);
    overlay.applySectionPreferences({ "gold-events": false }, { silent: true });
    overlay.setVisible(true);

    overlay.update(
      {
        mode: "campaign",
      wave: { index: 0, total: 3, inCountdown: false, countdown: 0 },
      difficulty: new GameEngine().getRuntimeMetrics().difficulty,
      difficultyRating: 275,
      projectiles: 0,
      enemiesAlive: 0,
      combo: 0,
      gold: 0,
      time: 0,
      goldEventCount: 0,
      goldDelta: null,
      goldEventTimestamp: null,
      recentGoldEvents: [],
      passiveUnlockCount: 0,
      castlePassives: [],
      lastPassiveUnlock: null,
      typing: {
        accuracy: 1,
        totalInputs: 0,
        correctInputs: 0,
        errors: 0,
        recentAccuracy: 1,
        recentSampleSize: 0,
        difficultyBias: 0
      },
      damage: { turret: 0, typing: 0, total: 0 },
      turretStats: [
        { slotId: "slot-1", turretType: "arrow", level: 2, damage: 320.5, dps: 48.2 },
        { slotId: "slot-2", turretType: "flame", level: 1, damage: 210, dps: 35 }
      ]
    },
    {
      bestCombo: 4,
      breaches: 1,
      soundEnabled: true,
      soundVolume: 0.6,
      soundIntensity: 1,
      summaryCount: 0,
      totalTurretDamage: 120,
      totalTypingDamage: 45,
      totalRepairs: 2,
      totalRepairHealth: 160,
      totalRepairGold: 300,
      totalReactionTime: 5.2,
      reactionSamples: 4,
      timeToFirstTurretSeconds: 42.5,
      shieldedNow: true,
      shieldedNext: true
    }
  );

  const output = container.innerHTML;
    assert.ok(output.includes("Gold: 0 events: 0"));
    assert.ok(output.includes("Castle passives: none unlocked"));
    assert.ok(output.includes("Passive unlocks tracked: 0"));
    assert.ok(output.includes("Shielded enemies: ACTIVE"));
    assert.ok(output.includes("Wave threat rating"));
    assert.ok(output.includes("Sound: on (volume 60%, intensity 100%)"));
    assert.ok(output.includes("Session damage (turret/typing): 120 / 45"));
    assert.ok(output.includes("Castle repairs: 2"));
    assert.ok(output.includes("HP restored 160"));
    assert.ok(output.includes("Gold spent 300g"));
    assert.ok(output.includes("First turret deployed at 42.5s"));
    assert.ok(output.includes("Average reaction: 1.30s (4 samples)"));
    assert.ok(output.includes("Turret DPS breakdown:"));
    assert.ok(output.includes("slot-1"));
    assert.ok(output.includes("320.5 dmg"));
  } finally {
    cleanup();
  }
});

test("DiagnosticsOverlay lists recent gold events", () => {
  const { container, cleanup } = setupDiagnosticsDom();
  try {
    const engine = new GameEngine({ seed: 42, config: { waves: [] } });
    const baseMetrics = engine.getRuntimeMetrics();
    const overlay = new DiagnosticsOverlay(container);
    overlay.setVisible(true);
    overlay.applyCondensedState(false);
    overlay.applySectionPreferences({ "gold-events": false }, { silent: true });
    overlay.update(
      {
        ...baseMetrics,
      gold: 350,
      goldEventCount: 3,
      goldDelta: 40,
      goldEventTimestamp: 120.5,
      recentGoldEvents: [
        { gold: 350, delta: 40, timestamp: 120.5 },
        { gold: 310, delta: -20, timestamp: 95.2 },
        { gold: 330, delta: 30, timestamp: 80 }
      ],
      time: 140
    },
    undefined
  );
    const output = container.textContent ?? "";
    assert.ok(output.includes("Recent gold events:"));
    assert.ok(output.includes("+40g -> 350g @ 120.5s"));
    assert.ok(output.includes("-20g -> 310g @ 95.2s"));
  } finally {
    cleanup();
  }
});

test("DiagnosticsOverlay reports last canvas resize cause when provided", () => {
  const { container, cleanup } = setupDiagnosticsDom();
  try {
    const engine = new GameEngine({ seed: 7, config: { waves: [] } });
    const overlay = new DiagnosticsOverlay(container);
    overlay.setVisible(true);
    overlay.applyCondensedState(false);
    const metrics = engine.getRuntimeMetrics();
    overlay.update(metrics, {
      bestCombo: 0,
      breaches: 0,
      soundEnabled: true,
      soundVolume: 1,
      soundIntensity: 1,
      summaryCount: 0,
      lastCanvasResizeCause: "device-pixel-ratio"
    });
    const output = container.textContent ?? "";
    assert.ok(
      output.includes("Last canvas resize: device-pixel-ratio"),
      "expected diagnostics text to show last canvas resize cause"
    );
  } finally {
    cleanup();
  }
});

test("DiagnosticsOverlay condenses overlay on compact height", () => {
  const listeners = new Map();
  const matchState = {
    "(max-height: 540px)": true,
    "(max-width: 720px)": false
  };
  const stubMatchMedia = (query) => ({
    matches: Boolean(matchState[query]),
    media: query,
    addEventListener: (event, handler) => {
      if (event === "change") {
        listeners.set(query, handler);
      }
    },
    addListener: (handler) => {
      listeners.set(query, handler);
    },
    removeEventListener: () => {},
    removeListener: () => {}
  });
  const { container, cleanup } = setupDiagnosticsDom({ matchMedia: stubMatchMedia });
  try {
    const overlay = new DiagnosticsOverlay(container);
    overlay.setVisible(true);
    assert.equal(container.dataset.condensed, "true");
    matchState["(max-height: 540px)"] = false;
    const handler = listeners.get("(max-height: 540px)");
    handler?.({ matches: false });
    assert.equal(container.dataset.condensed, undefined);
    assert.equal(document.body.dataset.diagnosticsCondensed, undefined);
  } finally {
    cleanup();
  }
});

test("DiagnosticsOverlay collapses detailed sections when condensed", () => {
  const matchState = {
    "(max-height: 540px)": true,
    "(max-width: 720px)": false
  };
  const stubMatchMedia = (query) => ({
    matches: Boolean(matchState[query]),
    media: query,
    addEventListener: () => {},
    removeEventListener: () => {},
    addListener: () => {},
    removeListener: () => {}
  });
  const { container, cleanup } = setupDiagnosticsDom({ matchMedia: stubMatchMedia });
  const engine = new GameEngine({ seed: 7, config: { waves: [] } });
  const metrics = engine.getRuntimeMetrics();
    const overlay = new DiagnosticsOverlay(container);
    overlay.setVisible(true);
    assert.equal(container.dataset.condensed, "true");
  overlay.applySectionPreferences(
      { "gold-events": true, "castle-passives": true, "turret-dps": true },
      { silent: true }
    );
  overlay.update(
    {
      ...metrics,
      recentGoldEvents: [
        { gold: 300, delta: 50, timestamp: 10 },
        { gold: 260, delta: -20, timestamp: 5 }
      ],
      gold: 300,
      goldEventCount: 2,
      turretStats: [
        { slotId: "a1", turretType: "arrow", level: 2, damage: 250, dps: 45 },
        { slotId: "b2", turretType: "flame", level: 1, damage: 120, dps: 30 }
      ]
    },
    undefined
  );
  try {
    const collapsedOutput = container.innerHTML;
    assert.ok(collapsedOutput.includes("Recent gold events"));
    const preExpanded = collapsedOutput;
    overlay.applySectionPreferences(
      { "gold-events": false, "castle-passives": false, "turret-dps": false },
      { silent: true }
    );
    overlay.update(
      {
        ...metrics,
        recentGoldEvents: [
          { gold: 300, delta: 50, timestamp: 10 },
          { gold: 260, delta: -20, timestamp: 5 }
        ],
        gold: 300,
        goldEventCount: 2,
        turretStats: [
          { slotId: "a1", turretType: "arrow", level: 2, damage: 250, dps: 45 },
          { slotId: "b2", turretType: "flame", level: 1, damage: 120, dps: 30 }
        ]
      },
      undefined
    );
    const expandedOutput = container.innerHTML;
    assert.notEqual(preExpanded, expandedOutput);
    assert.ok(expandedOutput.includes("Recent gold events:"));
    assert.ok(expandedOutput.includes("Turret DPS breakdown:"));
  } finally {
    cleanup();
  }
});

test("DiagnosticsOverlay exposes condensed snapshot state", () => {
  const { container, cleanup } = setupDiagnosticsDom();
  try {
    const overlay = new DiagnosticsOverlay(container);
    overlay.setVisible(true);
    overlay.applyCondensedState(true);
    overlay.applySectionPreferences(
      { "gold-events": true, "castle-passives": true, "turret-dps": true },
      { silent: true }
    );
    let snapshot = overlay.getCondensedState();
    assert.equal(snapshot.condensed, true);
    assert.equal(snapshot.sectionsCollapsed, true);
    assert.equal(snapshot.collapsedSections["gold-events"], true);
    overlay.applyCondensedState(false);
    overlay.applySectionPreferences(
      { "gold-events": false, "castle-passives": false, "turret-dps": false },
      { silent: true }
    );
    snapshot = overlay.getCondensedState();
    assert.equal(snapshot.condensed, false);
    assert.equal(snapshot.sectionsCollapsed, false);
    assert.equal(snapshot.collapsedSections["gold-events"], false);
  } finally {
    cleanup();
  }
});

test("DiagnosticsOverlay records canvas transition state", () => {
  const { container, cleanup } = setupDiagnosticsDom();
  try {
    const overlay = new DiagnosticsOverlay(container);
    overlay.setCanvasTransitionState("running");
    assert.equal(container.dataset.canvasTransition, "running");
    overlay.setCanvasTransitionState("idle");
    assert.equal(container.dataset.canvasTransition, "idle");
  } finally {
    cleanup();
  }
});
