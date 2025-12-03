import { deriveCastlePassives } from "../utils/castlePassives.js";
export function createInitialState(config) {
    const castleLevel = config.castleLevels[0];
    const initialSlots = config.turretSlots.map((slot) => ({
        id: slot.id,
        lane: slot.lane,
        position: slot.position,
        unlocked: false,
        targetingPriority: "first"
    }));
    for (let i = 0; i < castleLevel.unlockSlots; i++) {
        if (initialSlots[i]) {
            initialSlots[i].unlocked = true;
        }
    }
    return {
        time: 0,
        status: "preparing",
        mode: "campaign",
        castle: {
            level: castleLevel.level,
            maxHealth: castleLevel.maxHealth,
            health: castleLevel.maxHealth,
            armor: castleLevel.armor,
            regenPerSecond: castleLevel.regenPerSecond,
            nextUpgradeCost: castleLevel.upgradeCost,
            repairCooldownRemaining: 0,
            goldBonusPercent: castleLevel.goldBonusPercent ?? 0,
            passives: deriveCastlePassives(config.castleLevels[0], castleLevel)
        },
        resources: {
            gold: 200,
            score: 0
        },
        turrets: initialSlots,
        enemies: [],
        projectiles: [],
        laneHazards: [],
        evacuation: {
            active: false,
            lane: null,
            remaining: 0,
            duration: 0,
            enemyId: null,
            word: null,
            succeeded: false,
            failed: false
        },
        boss: {
            active: false,
            enemyId: null,
            tierId: null,
            lane: null,
            phase: null,
            introAnnounced: false,
            segmentIndex: 0,
            segmentTotal: 3,
            segmentShield: 75,
            rotationInterval: 9,
            rotationTimer: 9,
            vulnerabilityRemaining: 0,
            vulnerabilityMultiplier: 1.35,
            vulnerabilityAppliesToShield: true,
            shockwaveInterval: 10,
            shockwaveTimer: 10,
            shockwaveDuration: 3.5,
            shockwaveRemaining: 0,
            shockwaveMultiplier: 0.65,
            phaseShifted: false
        },
        wave: {
            index: 0,
            total: config.waves.length,
            inCountdown: true,
            countdownRemaining: config.prepCountdownSeconds,
            timeInWave: 0
        },
        typing: {
            activeEnemyId: null,
            buffer: "",
            combo: 0,
            comboTimer: 0,
            comboWarning: false,
            errors: 0,
            totalInputs: 0,
            correctInputs: 0,
            accuracy: 1,
            recentInputs: [],
            recentCorrectInputs: 0,
            recentAccuracy: 1,
            dynamicDifficultyBias: 0,
            lastInputChar: null,
            lastInputAtMs: null
        },
        analytics: {
            activeWaveIndex: null,
            waveStartTime: 0,
            lastSnapshotTime: 0,
            mode: "campaign",
            totalDamageDealt: 0,
            totalTypingDamage: 0,
            totalTurretDamage: 0,
            totalShieldBreaks: 0,
            totalCastleRepairs: 0,
            totalRepairHealth: 0,
            totalRepairGold: 0,
            totalPerfectWords: 0,
            totalBonusGold: 0,
            totalCastleBonusGold: 0,
            totalReactionTime: 0,
            reactionSamples: 0,
            evacuationAttempts: 0,
            evacuationSuccesses: 0,
            evacuationFailures: 0,
            enemiesDefeated: 0,
            breaches: 0,
            sessionBreaches: 0,
            startGold: 200,
            startTotalInputs: 0,
            startCorrectInputs: 0,
            waveSummaries: [],
            waveHistory: [],
            waveMaxCombo: 0,
            waveShieldBreaks: 0,
            waveRepairs: 0,
            waveRepairHealth: 0,
            waveRepairGold: 0,
            wavePerfectWords: 0,
            waveBonusGold: 0,
            waveCastleBonusGold: 0,
            waveReactionTime: 0,
            waveReactionSamples: 0,
            waveComboBaseline: 0,
            sessionBestCombo: 0,
            waveTypingDamage: 0,
            waveTurretDamage: 0,
            waveTurretDamageBySlot: {},
            averageTotalDps: 0,
            averageTurretDps: 0,
            averageTypingDps: 0,
            timeToFirstTurret: null,
            castlePassiveUnlocks: [],
            goldEvents: [],
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
            },
            bossEvents: [],
            bossPhase: null,
            bossActive: false,
            bossLane: null,
            starfield: null,
            comboWarning: {
                active: null,
                baselineAccuracy: 1,
                lastTimestamp: null,
                lastDelta: null,
                deltaMin: null,
                deltaMax: null,
                deltaSum: 0,
                count: 0,
                history: []
            },
            tutorial: {
                events: [],
                assistsShown: 0,
                attemptedRuns: 0,
                completedRuns: 0,
                replayedRuns: 0,
                skippedRuns: 0
            },
            typingDrills: []
        }
    };
}
export function cloneState(state) {
    return structuredClone(state);
}
