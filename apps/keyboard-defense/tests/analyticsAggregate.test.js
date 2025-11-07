import { test } from "vitest";
import assert from "node:assert/strict";
import { promises as fs } from "node:fs";
import { execFile } from "node:child_process";
import os from "node:os";
import path from "node:path";
import { main as analyticsMain } from "../scripts/analyticsAggregate.mjs";

const cliPath = path.resolve("./scripts/analyticsAggregate.mjs");

function runCli(args, options = {}) {
  return new Promise((resolve, reject) => {
    execFile("node", [cliPath, ...args], { ...options }, (error, stdout, stderr) => {
      if (error) {
        reject(new Error(`${error.message}\n${stderr}`));
        return;
      }
      resolve(stdout.trim());
    });
  });
}

async function writeSnapshot(dir, name, snapshot) {
  const file = path.join(dir, name);
  await fs.writeFile(file, JSON.stringify(snapshot, null, 2), "utf8");
  return file;
}

test("analyticsAggregate summarizes wave data into CSV", async () => {
  const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), "analytics-test-"));
  try {
    const primary = {
      capturedAt: "2025-01-01T12:00:00.000Z",
      status: "running",
      time: 123.4,
      mode: "practice",
      wave: { index: 2, total: 5 },
      typing: { accuracy: 0.91, combo: 4 },
      resources: { gold: 240, score: 820 },
      settings: {
        soundEnabled: true,
        soundVolume: 0.65,
        soundIntensity: 1.25
      },
      telemetry: {
        available: true,
        enabled: true,
        endpoint: "https://collector.example/ingest",
        queueSize: 2,
        queue: [
          {
            type: "wave-summary",
            capturedAt: "2025-01-01T12:00:01.000Z",
            payload: { wave: 1 },
            metadata: { endpoint: "https://collector.example/ingest" }
          },
          {
            type: "wave-summary",
            capturedAt: "2025-01-01T12:00:02.000Z",
            payload: { wave: 2 },
            metadata: { endpoint: "https://collector.example/ingest" }
          }
        ]
      },
      turretStats: [
        { slotId: "slot-1", turretType: "arrow", level: 2, damage: 700, dps: 17.5 },
        { slotId: "slot-2", turretType: "flame", level: 1, damage: 580.25, dps: 10.55 }
      ],
      analytics: {
        mode: "practice",
        sessionBreaches: 3,
        sessionBestCombo: 9,
        totalDamageDealt: 2696,
        totalTurretDamage: 1900,
        totalTypingDamage: 796,
        totalShieldBreaks: 5,
        totalCastleRepairs: 4,
        totalRepairHealth: 240,
        totalRepairGold: 600,
        totalPerfectWords: 8,
        totalBonusGold: 25,
        totalCastleBonusGold: 18,
        totalReactionTime: 5.4,
        reactionSamples: 4,
        averageTotalDps: 21.87,
        averageTurretDps: 15.4,
        averageTypingDps: 6.47,
        timeToFirstTurret: 0,
        tutorial: {
          events: [],
          assistsShown: 5,
          attemptedRuns: 6,
          completedRuns: 2,
          replayedRuns: 1,
          skippedRuns: 1
        },
        castlePassiveUnlocks: [
          { id: "regen", total: 1.5, delta: 0.5, level: 3, time: 120.25 },
          { id: "gold", total: 0.15, delta: 0.05, level: 4, time: 145.5 }
        ],
        goldEvents: [
          { gold: 220, delta: 20, timestamp: 30.5 },
          { gold: 240, delta: 20, timestamp: 40.25 }
        ],
        waveSummaries: [
          {
            index: 1,
            mode: "practice",
            duration: 40,
            accuracy: 0.96,
            enemiesDefeated: 11,
            breaches: 0,
            perfectWords: 5,
            averageReaction: 1.2,
            dps: 24.5,
            goldEarned: 85,
            bonusGold: 25,
            castleBonusGold: 18,
            maxCombo: 6,
            sessionBestCombo: 9,
            shieldBreaks: 2,
            turretDamage: 700,
            typingDamage: 280,
            turretDps: 17.5,
            typingDps: 7.0,
            repairsUsed: 2,
            repairHealth: 120,
            repairGold: 300
          },
          {
            index: 2,
            mode: "practice",
            duration: 55,
            accuracy: 0.9,
            enemiesDefeated: 13,
            breaches: 1,
            perfectWords: 3,
            averageReaction: 1.35,
            dps: 31.2,
            goldEarned: 92,
            bonusGold: 0,
            castleBonusGold: 0,
            maxCombo: 5,
            sessionBestCombo: 9,
            shieldBreaks: 3,
            turretDamage: 1200,
            typingDamage: 516,
            turretDps: 21.8,
            typingDps: 9.4,
            repairsUsed: 2,
            repairHealth: 120,
            repairGold: 300
          }
        ]
      }
    };

    const secondary = {
      capturedAt: "2025-02-02T08:30:00.000Z",
      status: "victory",
      time: 321.1,
      mode: "campaign",
      wave: { index: 4, total: 6 },
      settings: {
        soundEnabled: false,
        soundVolume: 0.4,
        soundIntensity: 0.95
      },
      typing: { accuracy: 0.97, combo: 7 },
      turretStats: [],
      telemetry: {
        available: false,
        enabled: false
      },
      analytics: {
        mode: "campaign",
        sessionBreaches: 0,
        sessionBestCombo: 11,
        totalDamageDealt: 999.1,
        totalTurretDamage: 600,
        totalTypingDamage: 250,
        totalShieldBreaks: 1,
        totalCastleRepairs: 0,
        totalRepairHealth: 0,
        totalRepairGold: 0,
        totalPerfectWords: 0,
        totalBonusGold: 0,
        totalCastleBonusGold: 0,
        totalReactionTime: 0,
        reactionSamples: 0,
        averageTotalDps: 12.1,
        averageTurretDps: 7.5,
        averageTypingDps: 3.9,
        timeToFirstTurret: null,
        tutorial: {
          events: [],
          assistsShown: 2,
          attemptedRuns: 3,
          completedRuns: 1,
          replayedRuns: 0,
          skippedRuns: 0
        },
        waveSummaries: []
      }
    };

    const fileA = await writeSnapshot(tempDir, "snapshot-a.json", primary);
    const nestedDir = path.join(tempDir, "exports");
    await fs.mkdir(nestedDir);
    await writeSnapshot(nestedDir, "snapshot-b.json", secondary);

    const output = await runCli([fileA, nestedDir], { cwd: path.resolve("./") });
    const lines = output.split("\n");
    assert.equal(lines.length, 4, "expected header plus three data rows");

    const headers = lines[0].split(",");
    assert.deepEqual(headers, [
      "file",
      "capturedAt",
      "status",
      "time",
      "telemetryAvailable",
      "telemetryEnabled",
      "telemetryEndpoint",
      "telemetryQueueSize",
      "soundEnabled",
      "soundVolume",
      "soundIntensity",
      "timeToFirstTurret",
      "waveIndex",
      "waveTotal",
      "mode",
      "practiceMode",
      "turretStats",
      "summaryWave",
      "duration",
      "accuracy",
      "enemiesDefeated",
      "breaches",
      "perfectWords",
      "averageReaction",
      "dps",
      "turretDps",
      "typingDps",
      "turretDamage",
      "typingDamage",
      "shieldBreaks",
      "repairsUsed",
      "repairHealth",
      "repairGold",
      "bonusGold",
      "castleBonusGold",
      "passiveUnlockCount",
      "lastPassiveUnlock",
      "castlePassiveUnlocks",
      "goldEventsTracked",
      "lastGoldDelta",
      "lastGoldEventTime",
      "goldEarned",
      "maxCombo",
      "sessionBestCombo",
      "sessionBreaches",
      "totalDamageDealt",
      "totalTurretDamage",
      "totalTypingDamage",
      "totalShieldBreaks",
      "totalCastleRepairs",
      "totalRepairHealth",
      "totalRepairGold",
      "totalPerfectWords",
      "totalBonusGold",
      "totalCastleBonusGold",
      "totalReactionTime",
      "reactionSamples",
      "averageTotalDps",
      "averageTurretDps",
      "averageTypingDps",
      "tutorialAttempts",
      "tutorialAssists",
      "tutorialCompletions",
      "tutorialReplays",
      "tutorialSkips"
    ]);

    const toRow = (line) => {
      const parts = line.split(",");
      return headers.reduce((acc, header, index) => {
        acc[header] = parts[index] ?? "";
        return acc;
      }, {});
    };

    const firstRow = toRow(lines[1]);
    assert.ok(firstRow.file.endsWith("snapshot-a.json"));
    assert.equal(firstRow.telemetryAvailable, "true");
    assert.equal(firstRow.telemetryEnabled, "true");
    assert.equal(firstRow.telemetryEndpoint, "https://collector.example/ingest");
    assert.equal(firstRow.telemetryQueueSize, "2");
    assert.equal(firstRow.soundEnabled, "true");
    assert.equal(firstRow.soundVolume, "0.65");
    assert.equal(firstRow.soundIntensity, "1.25");
    assert.equal(firstRow.timeToFirstTurret, "0");
    assert.equal(firstRow.mode, "practice");
    assert.equal(firstRow.practiceMode, "yes");
    assert.equal(firstRow.summaryWave, "1");
    assert.equal(
      firstRow.turretStats,
      "slot-1:arrow L2 dmg=700 dps=17.5 | slot-2:flame L1 dmg=580.25 dps=10.55"
    );
    assert.equal(firstRow.accuracy, "0.96");
    assert.equal(firstRow.breaches, "0");
    assert.equal(firstRow.perfectWords, "5");
    assert.equal(firstRow.averageReaction, "1.2");
    assert.equal(firstRow.turretDps, "17.5");
    assert.equal(firstRow.turretDamage, "700");
    assert.equal(firstRow.shieldBreaks, "2");
    assert.equal(firstRow.repairsUsed, "2");
    assert.equal(firstRow.repairHealth, "120");
    assert.equal(firstRow.repairGold, "300");
    assert.equal(firstRow.bonusGold, "25");
    assert.equal(firstRow.castleBonusGold, "18");
    assert.equal(firstRow.passiveUnlockCount, "2");
    assert.ok(firstRow.lastPassiveUnlock.startsWith("Gold"));
    assert.ok(firstRow.castlePassiveUnlocks.includes("Regen"));
    assert.equal(firstRow.goldEventsTracked, "2");
    assert.equal(firstRow.lastGoldDelta, "20");
    assert.equal(firstRow.lastGoldEventTime, "40.25");
    assert.equal(firstRow.totalReactionTime, "5.4");
    assert.equal(firstRow.reactionSamples, "4");
    assert.equal(firstRow.averageTotalDps, "21.87");
    assert.equal(firstRow.averageTurretDps, "15.4");
    assert.equal(firstRow.averageTypingDps, "6.47");
    assert.equal(firstRow.totalPerfectWords, "8");
    assert.equal(firstRow.totalBonusGold, "25");
    assert.equal(firstRow.totalCastleBonusGold, "18");
    assert.equal(firstRow.tutorialAttempts, "6");
    assert.equal(firstRow.tutorialAssists, "5");
    assert.equal(firstRow.tutorialCompletions, "2");
    assert.equal(firstRow.tutorialReplays, "1");
    assert.equal(firstRow.tutorialSkips, "1");

    const thirdRow = toRow(lines[3]);
    assert.ok(thirdRow.file.endsWith("snapshot-b.json"));
    assert.equal(thirdRow.telemetryAvailable, "false");
    assert.equal(thirdRow.telemetryEnabled, "false");
    assert.equal(thirdRow.telemetryEndpoint, "");
    assert.equal(thirdRow.telemetryQueueSize, "");
    assert.equal(thirdRow.soundEnabled, "false");
    assert.equal(thirdRow.soundVolume, "0.4");
    assert.equal(thirdRow.soundIntensity, "0.95");
    assert.equal(thirdRow.timeToFirstTurret, "");
    assert.equal(thirdRow.summaryWave, "4");
    assert.equal(thirdRow.mode, "campaign");
    assert.equal(thirdRow.castleBonusGold, "");
    assert.equal(thirdRow.totalCastleBonusGold, "0");
    assert.equal(thirdRow.practiceMode, "no");
    assert.equal(thirdRow.turretStats, "");
    assert.equal(thirdRow.accuracy, "0.97");
    assert.equal(thirdRow.maxCombo, "7");
    assert.equal(thirdRow.perfectWords, "");
    assert.equal(thirdRow.averageReaction, "");
    assert.equal(thirdRow.sessionBestCombo, "11");
    assert.equal(thirdRow.sessionBreaches, "0");
    assert.equal(thirdRow.totalDamageDealt, "999.1");
    assert.equal(thirdRow.totalTurretDamage, "600");
    assert.equal(thirdRow.totalTypingDamage, "250");
    assert.equal(thirdRow.totalShieldBreaks, "1");
    assert.equal(thirdRow.totalCastleRepairs, "0");
    assert.equal(thirdRow.totalRepairHealth, "0");
    assert.equal(thirdRow.totalRepairGold, "0");
    assert.equal(thirdRow.totalPerfectWords, "0");
    assert.equal(thirdRow.totalBonusGold, "0");
    assert.equal(thirdRow.totalReactionTime, "0");
    assert.equal(thirdRow.reactionSamples, "0");
    assert.equal(thirdRow.bonusGold, "");
    assert.equal(thirdRow.averageTotalDps, "12.1");
    assert.equal(thirdRow.averageTurretDps, "7.5");
    assert.equal(thirdRow.averageTypingDps, "3.9");
    assert.equal(thirdRow.tutorialAttempts, "3");
    assert.equal(thirdRow.tutorialAssists, "2");
    assert.equal(thirdRow.tutorialCompletions, "1");
    assert.equal(thirdRow.tutorialReplays, "0");
    assert.equal(thirdRow.tutorialSkips, "0");
    assert.equal(thirdRow.passiveUnlockCount, "0");
    assert.equal(thirdRow.lastPassiveUnlock, "");
    assert.equal(thirdRow.castlePassiveUnlocks, "");
    assert.equal(thirdRow.goldEventsTracked, "0");
    assert.equal(thirdRow.lastGoldDelta, "");
    assert.equal(thirdRow.lastGoldEventTime, "");
  } finally {
    await fs.rm(tempDir, { recursive: true, force: true });
  }
});

test("analyticsAggregate exits with error when snapshots are invalid", async () => {
  const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), "analytics-invalid-"));
  try {
    const badFile = path.join(tempDir, "broken.json");
    await fs.writeFile(badFile, "{not valid json", "utf8");

    await assert.rejects(
      () => runCli([badFile], { cwd: path.resolve("./") }),
      /analyticsAggregate: no analytics data could be derived/i
    );
  } finally {
    await fs.rm(tempDir, { recursive: true, force: true });
  }
});

test("analyticsAggregate main reports usage when no inputs provided", async () => {
  const errors = [];
  const originalError = console.error;
  console.error = (...args) => {
    errors.push(args.join(" "));
  };

  try {
    const exitCode = await analyticsMain([]);
    assert.equal(exitCode, 1);
    assert.equal(errors.length > 0, true);
  } finally {
    console.error = originalError;
  }
});
