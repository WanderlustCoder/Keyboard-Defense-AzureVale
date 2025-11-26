import { test } from "vitest";
import assert from "node:assert/strict";
import { promises as fs } from "node:fs";
import { execFile } from "node:child_process";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { main as analyticsMain } from "../scripts/analyticsAggregate.mjs";

const cliPath = fileURLToPath(new URL("../scripts/analyticsAggregate.mjs", import.meta.url));

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
      assetIntegrity: {
        status: "warning",
        strictMode: false,
        scenario: "tutorial-smoke",
        manifest: "public/assets/manifest.json",
        checked: 9,
        missingHash: 1,
        failed: 0,
        totalImages: 10,
        firstFailure: {
          path: "sprites/enemy-brute.png",
          key: "enemy-brute",
          type: "missing"
        }
      },
      ui: {
        compactHeight: true,
        tutorialBanner: { condensed: true, expanded: false },
        hud: {
          passivesCollapsed: true,
          goldEventsCollapsed: false,
          prefersCondensedLists: true,
          layout: "condensed"
        },
        options: { passivesCollapsed: true },
        resolution: {
          cssWidth: 840,
          cssHeight: 472,
          renderWidth: 1260,
          renderHeight: 708,
          devicePixelRatio: 1.5,
          hudLayout: "condensed",
          lastResizeCause: "device-pixel-ratio"
        },
        resolutionChanges: [
          {
            cause: "init",
            fromDpr: 1,
            toDpr: 1,
            cssWidth: 960,
            cssHeight: 540,
            renderWidth: 960,
            renderHeight: 540
          },
          {
            cause: "pinch",
            fromDpr: 1,
            toDpr: 1.5,
            cssWidth: 840,
            cssHeight: 472,
            renderWidth: 1260,
            renderHeight: 708
          }
        ],
        diagnostics: {
          condensed: true,
          sectionsCollapsed: true,
          collapsedSections: { "gold-events": true, "turret-dps": false },
          lastUpdatedAt: "2025-01-01T11:59:59.000Z"
        },
        preferences: {
          hudPassivesCollapsed: true,
          hudGoldEventsCollapsed: false,
          optionsPassivesCollapsed: true,
          diagnosticsSections: { "gold-events": true, "turret-dps": false },
          diagnosticsSectionsUpdatedAt: "2025-01-01T11:59:59.000Z",
          devicePixelRatio: 1.5,
          hudLayout: "condensed"
        }
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
        audioIntensityHistory: [
          { to: 1, combo: 4, accuracy: 0.94 },
          { to: 1.2, combo: 6, accuracy: 0.96 }
        ],
        comboWarning: {
          active: null,
          baselineAccuracy: 0.93,
          lastTimestamp: 200.5,
          lastDelta: -4.5,
          deltaMin: -5.5,
          deltaMax: -2.4,
          deltaSum: -9,
          count: 2,
          history: [
            {
              timestamp: 110.4,
              waveIndex: 1,
              comboBefore: 9,
              comboAfter: 2,
              accuracy: 0.9,
              baselineAccuracy: 0.95,
              deltaPercent: -5,
              durationMs: 720
            },
            {
              timestamp: 180.9,
              waveIndex: 2,
              comboBefore: 6,
              comboAfter: 0,
              accuracy: 0.88,
              baselineAccuracy: 0.94,
              deltaPercent: -4,
              durationMs: 640
            }
          ]
        },
        taunt: {
          active: true,
          id: "brute_intro",
          text: "I'll crack your walls!",
          enemyType: "brute",
          lane: 1,
          waveIndex: 2,
          timestampMs: 118.5,
          countPerWave: { 2: 1 },
          uniqueLines: ["I'll crack your walls!"],
          history: [
        {
          id: "brute_intro",
          text: "I'll crack your walls!",
          enemyType: "brute",
          lane: 1,
          waveIndex: 2,
          timestamp: 118.5
        }
      ]
    },
        defeatBurst: {
          total: 12,
          sprite: 3,
          procedural: 9,
          lastEnemyType: "brute",
          lastLane: 1,
          lastTimestamp: 118.5,
          lastMode: "procedural",
          history: [
            { enemyType: "brute", lane: 1, timestamp: 118.5, mode: "procedural" },
            { enemyType: "witch", lane: 0, timestamp: 120.1, mode: "procedural" }
          ]
        },
        starfield: {
          driftMultiplier: 1.4,
          depth: 1.35,
          tint: "#fbbf24",
          waveProgress: 0.66,
          castleHealthRatio: 0.72,
          layers: [
            { id: "backdrop", velocity: 0.005, direction: -1, depth: 0.45 },
            { id: "mid", velocity: 0.012, direction: -1, depth: 0.75 },
            { id: "foreground", velocity: 0.02, direction: 1, depth: 1.1 }
          ]
        },
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
        waveSummaries: [],
        taunt: {
          active: false,
          id: null,
          text: null,
          enemyType: null,
          lane: null,
          waveIndex: null,
          timestampMs: null,
          countPerWave: {},
          uniqueLines: [],
          history: []
        },
        defeatBurst: {
          total: 0,
          sprite: 0,
          procedural: 0,
          lastEnemyType: null,
          lastLane: null,
          lastTimestamp: null,
          lastMode: null,
          history: []
        }
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
      "assetIntegrityStatus",
      "assetIntegrityStrict",
      "assetIntegrityScenario",
      "assetIntegrityManifest",
      "assetIntegrityChecked",
      "assetIntegrityMissing",
      "assetIntegrityFailed",
      "assetIntegrityTotal",
      "assetIntegrityFirstFailure",
      "time",
      "telemetryAvailable",
      "telemetryEnabled",
    "telemetryEndpoint",
    "telemetryQueueSize",
    "soundEnabled",
    "soundVolume",
    "soundIntensity",
    "uiCompactHeight",
    "uiTutorialCondensed",
    "uiTutorialExpanded",
    "uiHudPassivesCollapsed",
    "uiHudGoldEventsCollapsed",
    "uiHudPrefersCondensed",
    "uiHudLayout",
    "uiOptionsPassivesCollapsed",
    "uiResolutionCssWidth",
    "uiResolutionCssHeight",
      "uiResolutionRenderWidth",
      "uiResolutionRenderHeight",
      "uiResolutionDevicePixelRatio",
      "uiResolutionLastCause",
      "uiResolutionHudLayout",
    "uiResolutionChangeCount",
    "uiResolutionChanges",
    "uiDiagnosticsCondensed",
    "uiDiagnosticsSectionsCollapsed",
    "uiDiagnosticsCollapsedSections",
    "uiDiagnosticsLastUpdatedAt",
    "uiPrefHudPassivesCollapsed",
    "uiPrefHudGoldEventsCollapsed",
    "uiPrefOptionsPassivesCollapsed",
    "uiPrefDiagnosticsSections",
    "uiPrefDiagnosticsSectionsUpdatedAt",
    "uiPrefDevicePixelRatio",
    "uiPrefHudLayout",
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
      "tauntActive",
      "tauntText",
      "tauntEnemyType",
      "tauntWaveIndex",
      "tauntLane",
      "tauntTimestamp",
      "tauntId",
      "tauntCountPerWave",
      "tauntUniqueLines",
      "defeatBurstCount",
      "defeatBurstSpriteCount",
      "defeatBurstProceduralCount",
      "defeatBurstPerMinute",
      "defeatBurstSpritePct",
      "defeatBurstLastEnemyType",
      "defeatBurstLastLane",
      "defeatBurstLastMode",
    "defeatBurstLastTimestamp",
    "defeatBurstHistory",
    "starfieldDepth",
    "starfieldDrift",
    "starfieldTint",
    "starfieldWaveProgress",
    "starfieldCastleRatio",
    "starfieldLayers",
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
      "tutorialSkips",
      "comboWarningCount",
      "comboWarningDeltaLast",
      "comboWarningDeltaAvg",
      "comboWarningDeltaMin",
      "comboWarningDeltaMax",
      "comboWarningHistory",
      "audioIntensitySamples",
      "audioIntensityAvg",
      "audioIntensityDelta",
      "audioIntensityComboCorrelation",
      "audioIntensityAccuracyCorrelation"
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
    assert.equal(firstRow.assetIntegrityStatus, "warning");
    assert.equal(firstRow.assetIntegrityStrict, "false");
    assert.equal(firstRow.assetIntegrityScenario, "tutorial-smoke");
    assert.equal(firstRow.assetIntegrityManifest, "public/assets/manifest.json");
    assert.equal(firstRow.assetIntegrityChecked, "9");
    assert.equal(firstRow.assetIntegrityMissing, "1");
    assert.equal(firstRow.assetIntegrityFailed, "0");
    assert.equal(firstRow.assetIntegrityTotal, "10");
    assert.equal(firstRow.assetIntegrityFirstFailure, "sprites/enemy-brute.png (enemy-brute) [missing]");
    assert.equal(firstRow.telemetryAvailable, "true");
    assert.equal(firstRow.telemetryEnabled, "true");
    assert.equal(firstRow.telemetryEndpoint, "https://collector.example/ingest");
    assert.equal(firstRow.telemetryQueueSize, "2");
    assert.equal(firstRow.soundEnabled, "true");
    assert.equal(firstRow.soundVolume, "0.65");
    assert.equal(firstRow.soundIntensity, "1.25");
    assert.equal(firstRow.uiCompactHeight, "true");
    assert.equal(firstRow.uiTutorialCondensed, "true");
    assert.equal(firstRow.uiTutorialExpanded, "false");
    assert.equal(firstRow.uiHudLayout, "condensed");
    assert.equal(firstRow.uiOptionsPassivesCollapsed, "true");
    assert.equal(firstRow.uiResolutionCssWidth, "840");
    assert.equal(firstRow.uiResolutionCssHeight, "472");
    assert.equal(firstRow.uiResolutionRenderWidth, "1260");
    assert.equal(firstRow.uiResolutionRenderHeight, "708");
    assert.equal(firstRow.uiResolutionDevicePixelRatio, "1.5");
    assert.equal(firstRow.uiResolutionLastCause, "device-pixel-ratio");
    assert.equal(firstRow.uiResolutionHudLayout, "condensed");
    assert.equal(firstRow.uiResolutionChangeCount, "2");
    assert.equal(
      firstRow.uiResolutionChanges,
      "init:1->1 (960->960) | pinch:1->1.5 (840->1260)"
    );
    assert.equal(firstRow.uiDiagnosticsCondensed, "true");
    assert.equal(firstRow.uiDiagnosticsSectionsCollapsed, "true");
    assert.equal(
      firstRow.uiDiagnosticsCollapsedSections,
      "gold-events:collapsed | turret-dps:expanded"
    );
    assert.equal(firstRow.uiDiagnosticsLastUpdatedAt, "2025-01-01T11:59:59.000Z");
    assert.equal(firstRow.uiPrefHudPassivesCollapsed, "true");
    assert.equal(firstRow.uiPrefHudGoldEventsCollapsed, "false");
    assert.equal(firstRow.uiPrefOptionsPassivesCollapsed, "true");
    assert.equal(
      firstRow.uiPrefDiagnosticsSections,
      "gold-events:collapsed | turret-dps:expanded"
    );
    assert.equal(
      firstRow.uiPrefDiagnosticsSectionsUpdatedAt,
      "2025-01-01T11:59:59.000Z"
    );
    assert.equal(firstRow.uiPrefDevicePixelRatio, "1.5");
    assert.equal(firstRow.uiPrefHudLayout, "condensed");
    assert.equal(firstRow.uiHudPassivesCollapsed, "true");
    assert.equal(firstRow.uiHudGoldEventsCollapsed, "false");
    assert.equal(firstRow.uiHudPrefersCondensed, "true");
    assert.equal(firstRow.uiOptionsPassivesCollapsed, "true");
    assert.equal(firstRow.uiDiagnosticsCondensed, "true");
    assert.equal(firstRow.uiDiagnosticsSectionsCollapsed, "true");
    assert.equal(firstRow.uiPrefHudPassivesCollapsed, "true");
    assert.equal(firstRow.uiPrefHudGoldEventsCollapsed, "false");
    assert.equal(firstRow.uiPrefOptionsPassivesCollapsed, "true");
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
    assert.equal(firstRow.starfieldDepth, "1.35");
    assert.equal(firstRow.starfieldDrift, "1.4");
    assert.equal(firstRow.starfieldTint, "#fbbf24");
    assert.equal(firstRow.starfieldWaveProgress, "66");
    assert.equal(firstRow.starfieldCastleRatio, "72");
    assert.equal(firstRow.starfieldLayers, "backdrop:0.005← | mid:0.012← | foreground:0.02→");
    assert.equal(firstRow.passiveUnlockCount, "2");
    assert.ok(firstRow.lastPassiveUnlock.startsWith("Gold"));
    assert.ok(firstRow.castlePassiveUnlocks.includes("Regen"));
    assert.equal(firstRow.goldEventsTracked, "2");
    assert.equal(firstRow.lastGoldDelta, "20");
    assert.equal(firstRow.lastGoldEventTime, "40.25");
    assert.equal(firstRow.tauntActive, "true");
    assert.equal(firstRow.tauntText, "I'll crack your walls!");
    assert.equal(firstRow.tauntEnemyType, "brute");
    assert.equal(firstRow.tauntWaveIndex, "2");
    assert.equal(firstRow.tauntLane, "1");
    assert.equal(firstRow.tauntTimestamp, "118.5");
    assert.equal(firstRow.tauntId, "brute_intro");
    assert.equal(firstRow.tauntCountPerWave, "W2:1");
    assert.equal(firstRow.tauntUniqueLines, "I'll crack your walls!");
    assert.equal(firstRow.defeatBurstCount, "12");
    assert.equal(firstRow.defeatBurstSpriteCount, "3");
    assert.equal(firstRow.defeatBurstProceduralCount, "9");
    assert.equal(firstRow.defeatBurstPerMinute, "5.83");
    assert.equal(firstRow.defeatBurstSpritePct, "25");
    assert.equal(firstRow.defeatBurstLastEnemyType, "brute");
    assert.equal(firstRow.defeatBurstLastLane, "1");
    assert.equal(firstRow.defeatBurstLastMode, "procedural");
    assert.equal(firstRow.defeatBurstLastTimestamp, "118.5");
    assert.match(firstRow.defeatBurstHistory, /brute@L1:procedural/);
    assert.equal(firstRow.starfieldDepth, "1.35");
    assert.equal(firstRow.starfieldDrift, "1.4");
    assert.equal(firstRow.starfieldTint, "#fbbf24");
    assert.equal(firstRow.starfieldWaveProgress, "66");
    assert.equal(firstRow.starfieldCastleRatio, "72");
    assert.match(firstRow.starfieldLayers, /backdrop:0\.005/);
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
    assert.equal(firstRow.comboWarningCount, "2");
    assert.equal(firstRow.comboWarningDeltaLast, "-4.5");
    assert.equal(firstRow.comboWarningDeltaAvg, "-4.5");
    assert.equal(firstRow.comboWarningDeltaMin, "-5.5");
    assert.equal(firstRow.comboWarningDeltaMax, "-2.4");
    assert.ok(firstRow.comboWarningHistory.includes("W1"));
    assert.equal(firstRow.audioIntensitySamples, "2");
    assert.equal(firstRow.audioIntensityAvg, "1.1");
    assert.equal(firstRow.audioIntensityDelta, "0.2");
    assert.equal(firstRow.audioIntensityComboCorrelation, "1");
    assert.equal(firstRow.audioIntensityAccuracyCorrelation, "1");

    const secondRow = toRow(lines[2]);
    assert.ok(secondRow.file.endsWith("snapshot-a.json"));
    assert.equal(secondRow.uiCompactHeight, "true");
    assert.equal(secondRow.uiTutorialCondensed, "true");
    assert.equal(secondRow.uiTutorialExpanded, "false");
    assert.equal(secondRow.uiHudPassivesCollapsed, "true");
    assert.equal(secondRow.uiHudGoldEventsCollapsed, "false");
    assert.equal(secondRow.uiHudPrefersCondensed, "true");
    assert.equal(secondRow.uiHudLayout, "condensed");
    assert.equal(secondRow.uiOptionsPassivesCollapsed, "true");
    assert.equal(secondRow.uiResolutionCssWidth, "840");
    assert.equal(secondRow.uiResolutionCssHeight, "472");
    assert.equal(secondRow.uiResolutionRenderWidth, "1260");
    assert.equal(secondRow.uiResolutionRenderHeight, "708");
    assert.equal(secondRow.uiResolutionDevicePixelRatio, "1.5");
    assert.equal(secondRow.uiResolutionLastCause, "device-pixel-ratio");
    assert.equal(secondRow.uiResolutionHudLayout, "condensed");
    assert.equal(secondRow.uiResolutionChangeCount, "2");
    assert.equal(
      secondRow.uiResolutionChanges,
      "init:1->1 (960->960) | pinch:1->1.5 (840->1260)"
    );
    assert.equal(secondRow.uiDiagnosticsCondensed, "true");
    assert.equal(secondRow.uiDiagnosticsSectionsCollapsed, "true");
    assert.equal(
      secondRow.uiDiagnosticsCollapsedSections,
      "gold-events:collapsed | turret-dps:expanded"
    );
    assert.equal(secondRow.uiDiagnosticsLastUpdatedAt, "2025-01-01T11:59:59.000Z");
    assert.equal(secondRow.uiPrefHudPassivesCollapsed, "true");
    assert.equal(secondRow.uiPrefHudGoldEventsCollapsed, "false");
    assert.equal(secondRow.uiPrefOptionsPassivesCollapsed, "true");
    assert.equal(
      secondRow.uiPrefDiagnosticsSections,
      "gold-events:collapsed | turret-dps:expanded"
    );
    assert.equal(
      secondRow.uiPrefDiagnosticsSectionsUpdatedAt,
      "2025-01-01T11:59:59.000Z"
    );
    assert.equal(secondRow.uiPrefDevicePixelRatio, "1.5");
    assert.equal(secondRow.uiPrefHudLayout, "condensed");

    const thirdRow = toRow(lines[3]);
    assert.ok(thirdRow.file.endsWith("snapshot-b.json"));
    assert.equal(thirdRow.telemetryAvailable, "false");
    assert.equal(thirdRow.telemetryEnabled, "false");
    assert.equal(thirdRow.telemetryEndpoint, "");
    assert.equal(thirdRow.telemetryQueueSize, "");
    assert.equal(thirdRow.soundEnabled, "false");
    assert.equal(thirdRow.soundVolume, "0.4");
    assert.equal(thirdRow.soundIntensity, "0.95");
    assert.equal(thirdRow.tauntActive, "false");
    assert.equal(thirdRow.tauntText, "");
    assert.equal(thirdRow.uiCompactHeight, "");
    assert.equal(thirdRow.uiTutorialCondensed, "");
    assert.equal(thirdRow.uiTutorialExpanded, "");
    assert.equal(thirdRow.uiOptionsPassivesCollapsed, "");
    assert.equal(thirdRow.uiDiagnosticsCondensed, "");
    assert.equal(thirdRow.uiDiagnosticsSectionsCollapsed, "");
    assert.equal(thirdRow.uiDiagnosticsCollapsedSections, "");
    assert.equal(thirdRow.uiDiagnosticsLastUpdatedAt, "");
    assert.equal(thirdRow.uiPrefHudPassivesCollapsed, "");
    assert.equal(thirdRow.uiPrefHudGoldEventsCollapsed, "");
    assert.equal(thirdRow.uiPrefOptionsPassivesCollapsed, "");
    assert.equal(thirdRow.uiPrefDiagnosticsSections, "");
    assert.equal(thirdRow.uiPrefDiagnosticsSectionsUpdatedAt, "");
    assert.equal(thirdRow.uiHudPassivesCollapsed, "");
    assert.equal(thirdRow.uiHudGoldEventsCollapsed, "");
    assert.equal(thirdRow.uiHudPrefersCondensed, "");
    assert.equal(thirdRow.uiHudLayout, "");
    assert.equal(thirdRow.uiResolutionCssWidth, "");
    assert.equal(thirdRow.uiResolutionCssHeight, "");
    assert.equal(thirdRow.uiResolutionRenderWidth, "");
    assert.equal(thirdRow.uiResolutionRenderHeight, "");
    assert.equal(thirdRow.uiResolutionDevicePixelRatio, "");
    assert.equal(thirdRow.uiResolutionLastCause, "");
    assert.equal(thirdRow.uiResolutionHudLayout, "");
    assert.equal(thirdRow.uiResolutionChangeCount, "");
    assert.equal(thirdRow.uiResolutionChanges, "");
    assert.equal(thirdRow.uiOptionsPassivesCollapsed, "");
    assert.equal(thirdRow.uiDiagnosticsCondensed, "");
    assert.equal(thirdRow.uiDiagnosticsSectionsCollapsed, "");
    assert.equal(thirdRow.uiPrefHudPassivesCollapsed, "");
    assert.equal(thirdRow.uiPrefHudGoldEventsCollapsed, "");
    assert.equal(thirdRow.uiPrefOptionsPassivesCollapsed, "");
    assert.equal(thirdRow.uiPrefDevicePixelRatio, "");
    assert.equal(thirdRow.uiPrefHudLayout, "");
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
    assert.equal(thirdRow.comboWarningCount, "");
    assert.equal(thirdRow.comboWarningDeltaLast, "");
    assert.equal(thirdRow.comboWarningDeltaAvg, "");
    assert.equal(thirdRow.comboWarningDeltaMin, "");
    assert.equal(thirdRow.comboWarningDeltaMax, "");
    assert.equal(thirdRow.comboWarningHistory, "");
    assert.equal(thirdRow.audioIntensitySamples, "");
    assert.equal(thirdRow.audioIntensityAvg, "0.95");
    assert.equal(thirdRow.audioIntensityDelta, "");
    assert.equal(thirdRow.audioIntensityComboCorrelation, "");
    assert.equal(thirdRow.audioIntensityAccuracyCorrelation, "");
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

test("analyticsAggregate writes passive summary artifacts", async () => {
  const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), "analytics-passive-"));
  try {
    const snapshot = {
      capturedAt: "2025-02-02T10:00:00.000Z",
      status: "success",
      mode: "campaign",
      wave: { index: 4 },
      analytics: {
        castlePassiveUnlocks: [
          { id: "regen", level: 2, time: 32.5, total: 1.4, delta: 0.4 },
          { id: "gold", level: 1, time: 65.1, total: 0.1, delta: 0.05 }
        ]
      }
    };
    const snapshotPath = await writeSnapshot(tempDir, "passives.json", snapshot);
    const jsonOut = path.join(tempDir, "passive-summary.json");
    const csvOut = path.join(tempDir, "passive-summary.csv");
    const mdOut = path.join(tempDir, "passive-summary.md");

    const exitCode = await analyticsMain([
      "--passive-summary",
      jsonOut,
      "--passive-summary-csv",
      csvOut,
      "--passive-summary-md",
      mdOut,
      snapshotPath
    ]);

    assert.equal(exitCode, 0);

    const summary = JSON.parse(await fs.readFile(jsonOut, "utf8"));
    assert.equal(summary.stats.unlockCount, 2);
    assert.equal(summary.stats.fileCount, 1);
    assert.equal(summary.entries[0].passiveId, "regen");
    assert.equal(summary.entries[1].passiveId, "gold");

    const csv = await fs.readFile(csvOut, "utf8");
    assert.match(csv, /passiveId/);
    assert.match(csv, /regen/);

    const markdown = await fs.readFile(mdOut, "utf8");
    assert.match(markdown, /Passive Unlock Summary/);
    assert.match(markdown, /Total unlocks: \*\*2\*\*/);
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
