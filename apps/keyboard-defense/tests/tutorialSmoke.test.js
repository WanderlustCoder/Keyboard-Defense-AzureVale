import { test } from "vitest";
import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import path from "node:path";

import {
  parseArgs,
  validateMode,
  buildArtifact,
  resumeGameplay
} from "../scripts/tutorialSmoke.mjs";

const script = path.resolve("scripts", "tutorialSmoke.mjs");

function run(args) {
  return new Promise((resolve, reject) => {
    execFile("node", [script, ...args], { cwd: path.resolve(".") }, (error, stdout, stderr) => {
      if (error) {
        reject(Object.assign(error, { stdout, stderr }));
      } else {
        resolve({ stdout, stderr });
      }
    });
  });
}

test("tutorial smoke --help exits successfully", async () => {
  const { stdout } = await run(["--help"]);
  assert.match(stdout, /tutorial smoke/i);
});

test("parseArgs captures overrides", () => {
  const args = parseArgs([
    "--url",
    "http://localhost:9999",
    "--artifact",
    "out/smoke.json",
    "--mode",
    "campaign",
    "--audio-intensity",
    "75"
  ]);
  assert.equal(args.baseUrl, "http://localhost:9999");
  assert.equal(args.artifact, "out/smoke.json");
  assert.equal(args.mode, "campaign");
  assert.equal(args.audioIntensity, 0.75);
});

test("validateMode enforces allowed values", () => {
  assert.equal(validateMode("skip"), "skip");
  assert.equal(validateMode("full"), "full");
  assert.equal(validateMode("campaign"), "campaign");
  assert.throws(() => validateMode("speedrun"), /Unsupported mode/);
});

test("buildArtifact derives shield break totals", () => {
  const startedAt = "2025-01-01T00:00:00.000Z";
  const artifact = buildArtifact({
    baseUrl: "http://localhost:4173",
    mode: "full",
    startedAt,
    result: {
      success: true,
      durationMs: 1500,
      tutorialStorage: "v2",
      summaryOverlay: { accuracy: "Accuracy: 98.5%" },
      consoleLogs: [{ type: "info", text: "[tutorial] advance" }],
      stateSnapshot: {
        time: 50,
        status: "running",
        castle: { passives: [{ id: "regen", total: 1.2, delta: 0.5 }] }
      },
      analytics: {
        totalShieldBreaks: 4,
        castlePassiveUnlocks: [{ id: "regen", total: 1.2, delta: 0.5, level: 3, time: 120.5 }],
        goldEvents: [
          { gold: 200, delta: 25, timestamp: 10 },
          { gold: 260, delta: 60, timestamp: 30 },
          { gold: 310, delta: 50, timestamp: 45 }
        ],
        tutorial: {
          events: [
            { event: "start", stepId: "intro" },
            { event: "shield-broken", stepId: "shielded-enemy" }
          ]
        }
      }
    }
  });

  assert.equal(artifact.status, "success");
  assert.equal(artifact.shieldBreaks, 4);
  assert.deepEqual(artifact.summaryOverlay, { accuracy: "Accuracy: 98.5%" });
  assert.equal(artifact.baseUrl, "http://localhost:4173");
  assert.equal(artifact.startedAt, startedAt);
  assert.equal(artifact.passiveUnlockCount, 1);
  assert.deepEqual(artifact.passiveUnlocks, [
    { id: "regen", total: 1.2, delta: 0.5, level: 3, time: 120.5 }
  ]);
  assert.ok(artifact.passiveUnlockSummary?.includes("Regen"));
  assert.ok(artifact.lastPassiveUnlock?.startsWith("Regen"));
  assert.deepEqual(artifact.activeCastlePassives, [{ id: "regen", total: 1.2, delta: 0.5 }]);
  assert.equal(artifact.recentGoldEvents.length, 3);
  assert.deepEqual(artifact.recentGoldEvents[0], {
    gold: 200,
    delta: 25,
    timestamp: 10,
    timeSince: 40
  });
  assert.equal(artifact.recentGoldEvents[2].delta, 50);
});

test("buildArtifact captures audio intensity telemetry", () => {
  const artifact = buildArtifact({
    baseUrl: "http://localhost",
    mode: "full",
    startedAt: "2025-01-01T00:00:00.000Z",
    requestedAudioIntensity: 0.9,
    result: {
      success: true,
      durationMs: 2500,
      soundSettings: { soundIntensity: 1.1, soundVolume: 0.8, soundEnabled: true },
      playerSettings: { soundEnabled: true, soundVolume: 0.7, audioIntensity: 0.85 },
      audioIntensity: {
        applied: 1.2,
        history: [
          { to: 0.9, combo: 4, accuracy: 0.93, timestampMs: 5 },
          { to: 1.2, combo: 6, accuracy: 0.97, timestampMs: 10 }
        ]
      },
      analytics: {
        goldEvents: [],
        tutorial: { events: [] }
      }
    }
  });
  assert.equal(artifact.audioIntensity.requested, 0.9);
  assert.equal(artifact.audioIntensity.recorded, 1.2);
  assert.equal(artifact.audioIntensity.average, 1.05);
  assert.equal(artifact.audioIntensity.historySamples, 2);
  assert.deepEqual(artifact.settings.soundIntensity, 1.1);
  assert.deepEqual(artifact.settings.sources.live.soundIntensity, 1.1);
  assert.deepEqual(artifact.settings.sources.stored.soundIntensity, 0.85);
  assert.equal(artifact.audioIntensity.history[0].combo, 4);
  assert.equal(artifact.audioIntensity.history[1].accuracy, 0.97);
  assert.equal(artifact.flags.audioIntensity, 0.9);
});

test("buildArtifact counts shield-broken events when total missing", () => {
  const artifact = buildArtifact({
    baseUrl: "http://localhost",
    mode: "full",
    startedAt: "2025-01-01T00:00:00.000Z",
    result: {
      success: true,
      durationMs: 100,
      tutorialStorage: "v2",
      analytics: {
        tutorial: {
          events: [
            { event: "shield-broken", stepId: "shielded-enemy" },
            { event: "shield-broken", stepId: "shielded-enemy" },
            { event: "advance", stepId: "wrap-up" }
          ]
        }
      },
      consoleLogs: [],
      summaryOverlay: null,
      stateSnapshot: { time: 0.1, status: "running" }
    }
  });

  assert.equal(artifact.shieldBreaks, 2);
  assert.equal(artifact.passiveUnlockCount, 0);
  assert.deepEqual(artifact.passiveUnlocks, []);
  assert.equal(artifact.passiveUnlockSummary, null);
  assert.equal(artifact.lastPassiveUnlock, null);
  assert.deepEqual(artifact.activeCastlePassives, []);
  assert.deepEqual(artifact.recentGoldEvents, []);
});

test("resumeGameplay resumes and applies speed multiplier", async () => {
  const recorded = [];
  const previousWindow = global.window;
  global.window = {
    keyboardDefense: {
      resume: () => recorded.push(["resume"]),
      setSpeed: (multiplier) => recorded.push(["setSpeed", multiplier])
    }
  };
  try {
    const page = {
      evaluate: async (fn, args) => fn(args)
    };
    await resumeGameplay(page, { speed: 2 });
  } finally {
    global.window = previousWindow;
  }
  assert.deepEqual(recorded, [["resume"], ["setSpeed", 2]]);
});

test("resumeGameplay throws when debug API is unavailable", async () => {
  const previousWindow = global.window;
  global.window = {};
  const page = {
    evaluate: async (fn, args) => fn(args)
  };
  try {
    await assert.rejects(() => resumeGameplay(page), /debug API missing/);
  } finally {
    global.window = previousWindow;
  }
});

test("buildArtifact handles campaign result metadata", () => {
  const artifact = buildArtifact({
    baseUrl: "http://localhost:4173",
    mode: "campaign",
    startedAt: "2025-01-01T00:00:00.000Z",
    result: {
      success: true,
      durationMs: 800,
      tutorialStorage: null,
      consoleLogs: [],
      stateSnapshot: { time: 0.8, status: "running" },
      analytics: {
        enemiesDefeated: 3,
        totalDamageDealt: 450,
        metadata: { slotId: "slot-1", waveIndex: 0 }
      }
    }
  });

  assert.equal(artifact.status, "success");
  assert.equal(artifact.analytics.enemiesDefeated, 3);
  assert.equal(artifact.analytics.metadata.slotId, "slot-1");
  assert.equal(artifact.mode, "campaign");
  assert.equal(artifact.passiveUnlockCount, 0);
  assert.deepEqual(artifact.passiveUnlocks, []);
  assert.equal(artifact.passiveUnlockSummary, null);
  assert.equal(artifact.lastPassiveUnlock, null);
  assert.deepEqual(artifact.activeCastlePassives, []);
  assert.deepEqual(artifact.recentGoldEvents, []);
});
