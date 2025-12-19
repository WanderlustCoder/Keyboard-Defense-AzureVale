import { defaultConfig, type GameConfig, type DifficultyBand } from "../core/config.js";
import { EventBus } from "../core/eventBus.js";
import { type GameEvents } from "../core/events.js";
import { createInitialState, cloneState } from "../core/gameState.js";
import {
  type AnalyticsSnapshot,
  type CastlePassive,
  type CastlePassiveUnlock,
  type ComboWarningHistoryEntry,
  type DefeatBurstAnalyticsEntry,
  type DefeatBurstMode,
  type BossEventEntry,
  type EliteAffixInstance,
  type EnemyState,
  type GameMode,
  type GameState,
  type GameStatus,
  type GoldEvent,
  type StarfieldAnalyticsState,
  type TurretRuntimeStat,
  type TurretSlotState,
  type TurretTargetPriority,
  type TurretTypeId,
  type TutorialSummaryStats,
  type TypingDrillSummary,
  type WaveSpawnPreview,
  type WaveSummary
} from "../core/types.js";
import { defaultWordBank, type WordBank } from "../core/wordBank.js";
import { PRNG } from "../utils/random.js";
import { resolveCastleVisual } from "../rendering/castlePalette.js";
import { EnemySystem, type SpawnEnemyInput } from "../systems/enemySystem.js";
import { TurretSystem } from "../systems/turretSystem.js";
import { TypingSystem } from "../systems/typingSystem.js";
import { UpgradeSystem, type UpgradeResult, type RepairResult } from "../systems/upgradeSystem.js";
import { WaveSystem } from "../systems/waveSystem.js";
import { ProjectileSystem } from "../systems/projectileSystem.js";
import { type TelemetryClient } from "../telemetry/telemetryClient.js";
import { rollEliteAffixes } from "../data/eliteAffixes.js";

const MAX_WAVE_HISTORY = 100;
const MAX_GOLD_EVENTS = 200;
const MAX_COMBO_WARNING_HISTORY = 20;
const MAX_TYPING_DRILL_HISTORY = 20;
const DEFAULT_TURRET_PRIORITY: TurretTargetPriority = "first";
const DYNAMIC_EVENT_ORDER_START = 1000;
const BOSS_SEGMENT_COUNT = 3;
const BOSS_SEGMENT_SHIELD = 75;
const BOSS_ROTATION_INTERVAL = 9;
const BOSS_ROTATION_INTERVAL_PHASE2 = 6;
const BOSS_VULNERABILITY_DURATION = 3.5;
const BOSS_VULNERABILITY_MULTIPLIER = 1.35;
const BOSS_SHOCKWAVE_INTERVAL = 10;
const BOSS_SHOCKWAVE_INTERVAL_PHASE2 = 7.5;
const BOSS_SHOCKWAVE_DURATION = 3.5;
const BOSS_SHOCKWAVE_SLOW = 0.65;
const EVAC_REWARD_FALLBACK = 80;
const EVAC_PENALTY_FALLBACK = 40;
const EVAC_DYNAMIC_BUFFER = 4;
const SPAWN_SPEED_GATE_MIN = 0.85;
const FAST_SPAWNS_TIME_SCALE = 1.35;

type DynamicSpawnEvent = {
  time: number;
  lane: number;
  tierId: string;
  shield?: number;
  taunt?: string;
  order: number;
};

type LaneHazardEvent = {
  time: number;
  lane: number;
  kind: "fog" | "storm";
  duration: number;
  fireRateMultiplier?: number;
};

export interface TurretBlueprintSlot {
  typeId: TurretTypeId;
  level: number;
  priority?: TurretTargetPriority;
}

export type TurretBlueprint = Record<string, TurretBlueprintSlot>;

export interface TurretBlueprintApplyResult {
  success: boolean;
  cost: number;
  reason?: "invalid-slot" | "invalid-turret" | "locked-slot" | "insufficient-gold" | "apply-failed";
  slotId?: string;
  requiredGold?: number;
  availableGold?: number;
  appliedSlots?: string[];
  clearedSlots?: string[];
  unchangedSlots?: string[];
  message?: string;
}

export interface GameEngineOptions {
  config?: Partial<GameConfig>;
  wordBank?: WordBank;
  seed?: number;
  events?: EventBus<GameEvents>;
  telemetryClient?: TelemetryClient;
}

export interface ChallengeModifiersRuntime {
  fog: boolean;
  fastSpawns: boolean;
  limitedMistakes: boolean;
  mistakeBudget: number;
  scoreMultiplier: number;
}

export interface RuntimeMetrics {
  mode: GameMode;
  wave: {
    index: number;
    total: number;
    inCountdown: boolean;
    countdown: number;
  };
  difficulty: DifficultyBand;
  difficultyRating: number;
  projectiles: number;
  enemiesAlive: number;
  combo: number;
  gold: number;
  time: number;
  typing: {
    accuracy: number;
    totalInputs: number;
    correctInputs: number;
    errors: number;
    recentAccuracy: number;
    recentSampleSize: number;
    difficultyBias: number;
  };
  damage: {
    turret: number;
    typing: number;
    total: number;
  };
  turretStats: TurretRuntimeStat[];
  goldEventCount: number;
  goldDelta: number | null;
  goldEventTimestamp: number | null;
  recentGoldEvents: GoldEvent[];
  castlePassives: CastlePassive[];
  lastPassiveUnlock: CastlePassiveUnlock | null;
  passiveUnlockCount: number;
  castleVisual: {
    level: number;
    spriteKey: string;
    fill: string;
    border: string;
    accent: string;
  };
  defeatBursts: {
    total: number;
    perMinute: number;
    spriteUsagePct: number;
    sprite: number;
    procedural: number;
    lastEnemyType: string | null;
    lastLane: number | null;
    lastTimestamp: number | null;
    lastAgeSeconds: number | null;
    lastMode: DefeatBurstMode | null;
  };
  defeatBurstHistory: DefeatBurstAnalyticsEntry[];
  starfield?: StarfieldAnalyticsState | null;
  memory?: {
    usedMB: number;
    totalMB?: number;
    limitMB?: number;
    warning?: boolean;
  } | null;
}

export interface InputResult {
  status: "progress" | "completed" | "error" | "ignored" | "purged";
  buffer: string;
  enemyId?: string;
  expected?: string;
  received?: string;
}

export class GameEngine {
  readonly events: EventBus<GameEvents>;
  readonly config: GameConfig;

  private readonly seed: number;
  private readonly rng: PRNG;
  private readonly enemySystem: EnemySystem;
  private readonly waveSystem: WaveSystem;
  private readonly turretSystem: TurretSystem;
  private readonly projectileSystem: ProjectileSystem;
  private readonly typingSystem: TypingSystem;
  private readonly upgradeSystem: UpgradeSystem;
  private readonly telemetryClient?: TelemetryClient;
  private state: GameState;
  private readonly wordBank: WordBank;
  private lastWaveIndex: number;
  private readonly difficultyBands: DifficultyBand[];
  private currentDifficultyBand: DifficultyBand;
  private defeatBurstModeResolver: ((enemy: EnemyState) => DefeatBurstMode) | null = null;
  private spawnSpeedGateMultiplier = 1;
  private laneFocus: number | null = null;
  private dynamicEvents: DynamicSpawnEvent[] = [];
  private dynamicEventIndex = 0;
  private hazardEvents: LaneHazardEvent[] = [];
  private hazardEventIndex = 0;
  private evacuationEvent: { time: number; lane: number; duration: number; word?: string | null } | null =
    null;
  private challengeModifiers: ChallengeModifiersRuntime | null = null;
  private limitedMistakesWaveBaselineErrors = 0;
  private limitedMistakesWaveIndex: number | null = null;

  private recalculateAverageDps(): void {
    const analytics = this.state.analytics;
    const elapsed = Math.max(this.state.time, 0.0001);
    analytics.averageTurretDps = analytics.totalTurretDamage / elapsed;
    analytics.averageTypingDps = analytics.totalTypingDamage / elapsed;
    analytics.averageTotalDps = analytics.totalDamageDealt / elapsed;
  }

  private resetDynamicEvents(): void {
    this.dynamicEvents = [];
    this.dynamicEventIndex = 0;
  }

  private resetHazardEvents(): void {
    this.hazardEvents = [];
    this.hazardEventIndex = 0;
  }

  private resetEvacuationSchedule(): void {
    this.evacuationEvent = null;
    this.state.evacuation = {
      active: false,
      lane: null,
      remaining: 0,
      duration: 0,
      enemyId: null,
      word: null,
      succeeded: false,
      failed: false
    };
  }

  private buildEvacuationEventForWave(waveIndex: number, rng: PRNG): void {
    this.resetEvacuationSchedule();
    if (!this.config.featureToggles.dynamicSpawns || !this.config.featureToggles.evacuationEvents) {
      return;
    }
    const wave = this.config.waves[waveIndex];
    if (!wave || wave.duration <= 12) {
      return;
    }
    const lanes = Array.from(new Set(this.config.turretSlots.map((slot) => slot.lane))).sort(
      (a, b) => a - b
    );
    if (lanes.length === 0) return;
    const focusLane = this.getActiveLaneFocus();
    const laneChoices =
      typeof focusLane === "number" && lanes.includes(focusLane) ? [focusLane] : lanes;
    const midWindowStart = Math.max(6, wave.duration * 0.4);
    const midWindowEnd = Math.max(midWindowStart + 2, wave.duration * 0.65);
    const candidateLanes = [...laneChoices];
    for (let i = candidateLanes.length - 1; i > 0; i -= 1) {
      const j = Math.floor(rng.next() * (i + 1));
      [candidateLanes[i], candidateLanes[j]] = [candidateLanes[j], candidateLanes[i]];
    }
    const attempts = Math.max(4, candidateLanes.length * 3);
    for (let i = 0; i < attempts; i += 1) {
      const lane = candidateLanes[i % candidateLanes.length];
      const time = rng.range(midWindowStart, midWindowEnd);
      const duration = rng.range(10, 16);
      if (this.hasLaneConflict(lane, time, duration)) {
        continue;
      }
      const word = this.pickEvacuationWord(lane, waveIndex, rng);
      this.evacuationEvent = { time, lane, duration, word };
      return;
    }
  }

  private hasLaneConflict(lane: number, startTime: number, duration: number): boolean {
    const endTime = startTime + duration;
    for (const hazard of this.hazardEvents) {
      if (hazard.lane !== lane) continue;
      const hazardEnd = hazard.time + hazard.duration;
      if (hazard.time <= endTime && hazardEnd >= startTime) {
        return true;
      }
    }
    for (const event of this.dynamicEvents) {
      if (event.lane !== lane) continue;
      const dynStart = event.time;
      const dynEnd = event.time + EVAC_DYNAMIC_BUFFER;
      if (dynStart <= endTime && dynEnd >= startTime) {
        return true;
      }
    }
    return false;
  }

  private pickEvacuationWord(lane: number, waveIndex: number, rng: PRNG): string | null {
    const candidates = (this.wordBank.hard ?? []).filter((word) => word.length >= 9);
    if (candidates.length === 0) {
      return "evacuation";
    }
    try {
      return rng.pick(candidates);
    } catch {
      return candidates[0] ?? "evacuation";
    }
  }

  private createBossState(): GameState["boss"] {
    return {
      active: false,
      enemyId: null,
      tierId: null,
      lane: null,
      phase: null,
      introAnnounced: false,
      segmentIndex: 0,
      segmentTotal: BOSS_SEGMENT_COUNT,
      segmentShield: BOSS_SEGMENT_SHIELD,
      rotationInterval: BOSS_ROTATION_INTERVAL,
      rotationTimer: BOSS_ROTATION_INTERVAL,
      vulnerabilityRemaining: 0,
      vulnerabilityMultiplier: 1,
      vulnerabilityAppliesToShield: true,
      shockwaveInterval: BOSS_SHOCKWAVE_INTERVAL,
      shockwaveTimer: BOSS_SHOCKWAVE_INTERVAL,
      shockwaveDuration: BOSS_SHOCKWAVE_DURATION,
      shockwaveRemaining: 0,
      shockwaveMultiplier: 1,
      phaseShifted: false
    };
  }

  private resetBossState(): void {
    this.state.boss = this.createBossState();
  }

  private clearLaneHazards(): void {
    this.state.laneHazards = [];
  }

  private buildDynamicEventsForWave(waveIndex: number): void {
    this.resetDynamicEvents();
    this.resetHazardEvents();
    if (!this.config.featureToggles.dynamicSpawns) {
      return;
    }
    const waveConfig = this.config.waves[waveIndex];
    if (!waveConfig || waveConfig.duration <= 6) {
      return;
    }
    const lanes = Array.from(new Set(this.config.turretSlots.map((slot) => slot.lane))).sort(
      (a, b) => a - b
    );
    if (lanes.length === 0) {
      return;
    }
    const focusLane = this.getActiveLaneFocus();
    const laneChoices =
      typeof focusLane === "number" && lanes.includes(focusLane) ? [focusLane] : lanes;
    const rng = new PRNG(this.seed ^ Math.imul(waveIndex + 1, 0x9e3779b1));
    const count = Math.max(1, Math.min(3, Math.round(rng.range(1, 2.4)) + (waveIndex > 0 ? 1 : 0)));
    const events: DynamicSpawnEvent[] = [];
    let order = DYNAMIC_EVENT_ORDER_START;
    for (let i = 0; i < count; i++) {
      const timeWindowStart = 4;
      const timeWindowEnd = Math.max(timeWindowStart + 2, waveConfig.duration - 4);
      const time = rng.range(timeWindowStart, timeWindowEnd);
      const lane = rng.pick(laneChoices);
      const kind = rng.pick<"skirmish" | "gold-runner" | "shield-carrier">([
        "skirmish",
        "gold-runner",
        "shield-carrier"
      ]);
      if (kind === "shield-carrier") {
        events.push({ time, lane, tierId: "runner", shield: 35, taunt: "Shield courier inbound!", order: order++ });
      } else if (kind === "gold-runner") {
        events.push({ time, lane, tierId: "runner", taunt: "Gold courier sprinting!", order: order++ });
      } else {
        events.push({ time, lane, tierId: "grunt", order: order++ });
      }
    }
    events.sort((a, b) => a.time - b.time);
    this.dynamicEvents = events;
    this.dynamicEventIndex = 0;

    this.buildLaneHazardsForWave(waveIndex, rng);
  }

  private buildLaneHazardsForWave(waveIndex: number, rng: PRNG): void {
    this.resetHazardEvents();
    if (waveIndex < 1) return;
    if (this.config.waves[waveIndex]?.duration <= 8) return;
    const lanes = Array.from(new Set(this.config.turretSlots.map((slot) => slot.lane))).sort(
      (a, b) => a - b
    );
    if (lanes.length === 0) return;
    const focusLane = this.getActiveLaneFocus();
    const laneChoices =
      typeof focusLane === "number" && lanes.includes(focusLane) ? [focusLane] : lanes;
    const hazardCount = rng.next() > 0.55 ? 1 : 0;
    const events: LaneHazardEvent[] = [];
    for (let i = 0; i < hazardCount; i++) {
      const kind = rng.next() > 0.5 ? "storm" : "fog";
      const lane = rng.pick(laneChoices);
      const duration = kind === "storm" ? rng.range(8, 14) : rng.range(10, 18);
      const fireRateMultiplier = kind === "storm" ? 0.85 : 0.9;
      const time = rng.range(6, Math.max(8, this.config.waves[waveIndex].duration - 6));
      events.push({ time, lane, kind, duration, fireRateMultiplier });
    }
    events.sort((a, b) => a.time - b.time);
    this.hazardEvents = events;
    this.hazardEventIndex = 0;
  }

  private collectDynamicSpawnRequests(currentTime: number): Omit<SpawnEnemyInput, "difficulty">[] {
    const requests: Omit<SpawnEnemyInput, "difficulty">[] = [];
    if (!this.config.featureToggles.dynamicSpawns || this.dynamicEvents.length === 0) {
      return requests;
    }
    const focusLane = this.getActiveLaneFocus();
    while (
      this.dynamicEventIndex < this.dynamicEvents.length &&
      this.dynamicEvents[this.dynamicEventIndex].time <= currentTime
    ) {
      const event = this.dynamicEvents[this.dynamicEventIndex];
      this.dynamicEventIndex += 1;
      if (typeof focusLane === "number" && event.lane !== focusLane) {
        continue;
      }
      requests.push({
        tierId: event.tierId,
        lane: event.lane,
        shield: typeof event.shield === "number" ? { health: event.shield } : undefined,
        taunt: event.taunt,
        order: event.order
      });
    }
    return requests;
  }

  private activateLaneHazards(currentTime: number, deltaSeconds: number): void {
    if (!this.config.featureToggles.dynamicSpawns || this.hazardEvents.length === 0) {
      return;
    }
    const focusLane = this.getActiveLaneFocus();
    while (
      this.hazardEventIndex < this.hazardEvents.length &&
      this.hazardEvents[this.hazardEventIndex].time <= currentTime
    ) {
      const event = this.hazardEvents[this.hazardEventIndex];
      this.hazardEventIndex += 1;
      if (typeof focusLane === "number" && event.lane !== focusLane) {
        continue;
      }
      const existing = this.state.laneHazards.find((h) => h.lane === event.lane);
      const hazardState = {
        lane: event.lane,
        kind: event.kind,
        remaining: event.duration,
        duration: event.duration,
        fireRateMultiplier: event.fireRateMultiplier
      };
      if (existing) {
        Object.assign(existing, hazardState);
      } else {
        this.state.laneHazards.push(hazardState);
      }
      const laneLabel = ["A", "B", "C", "D", "E"][event.lane] ?? `Lane ${event.lane + 1}`;
      this.events.emit("hazard:started", {
        lane: event.lane,
        kind: event.kind,
        remaining: event.duration,
        fireRateMultiplier: event.fireRateMultiplier,
        label: `${event.kind} in ${laneLabel}`
      });
    }
    if (this.state.laneHazards.length > 0) {
      const survivors: typeof this.state.laneHazards = [];
      for (const hazard of this.state.laneHazards) {
        const remaining = hazard.remaining - deltaSeconds;
        if (remaining > 0) {
          survivors.push({ ...hazard, remaining });
        } else {
          this.events.emit("hazard:ended", { lane: hazard.lane, kind: hazard.kind });
        }
      }
      this.state.laneHazards = survivors;
    }
  }

  private isBossTier(tierId: string | undefined | null): boolean {
    return tierId === "archivist";
  }

  private recordBossEvent(type: BossEventEntry["type"], enemy?: EnemyState | null): void {
    const analytics = this.state.analytics;
    const entry: BossEventEntry = {
      type,
      time: this.state.time,
      phase: this.state.boss.phase,
      health: enemy?.health ?? null,
      shield: enemy?.shield?.current ?? null,
      lane: this.state.boss.lane
    };
    analytics.bossEvents.push(entry);
    if (analytics.bossEvents.length > 30) {
      analytics.bossEvents.splice(0, analytics.bossEvents.length - 30);
    }
  }

  private handleBossSpawn(enemy: EnemyState): void {
    if (!this.config.featureToggles.bossMechanics) return;
    if (!this.isBossTier(enemy.tierId)) return;
    const boss = this.state.boss;
    boss.active = true;
    boss.enemyId = enemy.id;
    boss.tierId = enemy.tierId;
    boss.lane = typeof enemy.lane === "number" ? enemy.lane : null;
    boss.phase = "phase-one";
    boss.introAnnounced = false;
    boss.segmentIndex = 0;
    boss.segmentTotal = BOSS_SEGMENT_COUNT;
    boss.segmentShield = BOSS_SEGMENT_SHIELD;
    boss.rotationInterval = BOSS_ROTATION_INTERVAL;
    boss.rotationTimer = Math.max(1, BOSS_ROTATION_INTERVAL / 2);
    boss.vulnerabilityRemaining = 0;
    boss.vulnerabilityMultiplier = BOSS_VULNERABILITY_MULTIPLIER;
    boss.vulnerabilityAppliesToShield = true;
    boss.shockwaveInterval = BOSS_SHOCKWAVE_INTERVAL;
    boss.shockwaveTimer = Math.max(2, BOSS_SHOCKWAVE_INTERVAL / 2);
    boss.shockwaveDuration = BOSS_SHOCKWAVE_DURATION;
    boss.shockwaveRemaining = 0;
    boss.shockwaveMultiplier = BOSS_SHOCKWAVE_SLOW;
    boss.phaseShifted = false;
    const desiredShield = Math.max(0, boss.segmentShield);
    if (desiredShield > 0) {
      enemy.shield = {
        current: desiredShield,
        max: desiredShield
      };
    }
    this.state.analytics.bossPhase = boss.phase;
    this.state.analytics.bossActive = true;
    this.state.analytics.bossLane = boss.lane;
    this.recordBossEvent("intro", enemy);
    this.events.emit("boss:intro", {
      waveIndex: this.state.wave.index,
      enemyId: enemy.id,
      lane: boss.lane,
      phase: boss.phase
    });
  }

  private rotateBossShield(enemy: EnemyState): void {
    const boss = this.state.boss;
    boss.segmentIndex = (boss.segmentIndex + 1) % Math.max(1, boss.segmentTotal);
    boss.rotationTimer = boss.rotationInterval;
    const value = Math.max(0, boss.segmentShield);
    if (value > 0) {
      enemy.shield = { current: value, max: value };
    } else {
      enemy.shield = undefined;
    }
    this.recordBossEvent("shield-rotated", enemy);
    const duration = Math.max(1.25, BOSS_VULNERABILITY_DURATION);
    boss.vulnerabilityRemaining = Math.max(boss.vulnerabilityRemaining, duration);
    this.events.emit("boss:vulnerability", {
      waveIndex: this.state.wave.index,
      enemyId: enemy.id,
      active: true,
      multiplier: boss.vulnerabilityMultiplier,
      remaining: boss.vulnerabilityRemaining
    });
    this.recordBossEvent("vulnerable-start", enemy);
  }

  private triggerBossShockwave(enemy: EnemyState | null): void {
    const boss = this.state.boss;
    boss.shockwaveTimer = boss.shockwaveInterval;
    boss.shockwaveRemaining = boss.shockwaveDuration;
    boss.shockwaveMultiplier = BOSS_SHOCKWAVE_SLOW;
    this.recordBossEvent("shockwave", enemy ?? undefined);
    this.events.emit("boss:shockwave", {
      waveIndex: this.state.wave.index,
      enemyId: enemy?.id ?? null,
      lane: boss.lane,
      multiplier: boss.shockwaveMultiplier,
      duration: boss.shockwaveDuration
    });
  }

  private handleEvacuationSpawn(enemy: EnemyState): void {
    if (!this.config.featureToggles.evacuationEvents) return;
    const evac = this.state.evacuation;
    if (!evac.active || evac.enemyId || enemy.tierId !== "evac-transport") {
      return;
    }
    evac.enemyId = enemy.id;
  }

  private completeEvacuation(success: boolean): void {
    const evac = this.state.evacuation;
    if (!evac.active) return;
    evac.active = false;
    evac.succeeded = success;
    evac.failed = !success;
    const rewardGold =
      typeof this.config.evacuation?.rewardGold === "number"
        ? Math.max(0, this.config.evacuation.rewardGold)
        : EVAC_REWARD_FALLBACK;
    const penaltyGold =
      typeof this.config.evacuation?.failPenaltyGold === "number"
        ? Math.max(0, this.config.evacuation.failPenaltyGold)
        : EVAC_PENALTY_FALLBACK;
    if (success) {
      this.state.analytics.evacuationSuccesses += 1;
      if (rewardGold > 0) {
        this.grantGold(rewardGold);
      }
      this.events.emit("evac:complete", {
        waveIndex: this.state.wave.index,
        lane: evac.lane,
        word: evac.word,
        remaining: evac.remaining
      });
    } else {
      this.state.analytics.evacuationFailures += 1;
      if (penaltyGold > 0) {
        this.grantGold(-penaltyGold);
      }
      this.events.emit("evac:fail", {
        waveIndex: this.state.wave.index,
        lane: evac.lane,
        word: evac.word
      });
    }
    this.evacuationEvent = null;
  }

  private tickEvacuation(deltaSeconds: number): void {
    const evac = this.state.evacuation;
    if (!evac.active) return;
    evac.remaining = Math.max(0, evac.remaining - deltaSeconds);
    const evacEnemyAlive =
      evac.enemyId &&
      this.state.enemies.some((enemy) => enemy.id === evac.enemyId && enemy.status === "alive");
    if (!evacEnemyAlive) {
      this.completeEvacuation(true);
      return;
    }
    if (evac.remaining <= 0) {
      this.state.enemies = this.state.enemies.filter((enemy) => enemy.id !== evac.enemyId);
      this.completeEvacuation(false);
    }
  }

  private updateBoss(deltaSeconds: number): void {
    if (!this.config.featureToggles.bossMechanics) return;
    const boss = this.state.boss;
    if (!boss.active || !boss.enemyId) {
      return;
    }
    const enemy = this.state.enemies.find(
      (entry) => entry.id === boss.enemyId && entry.status === "alive"
    );
    if (!enemy) {
      boss.active = false;
      this.state.analytics.bossActive = false;
      return;
    }

    this.state.analytics.bossPhase = boss.phase;
    this.state.analytics.bossActive = true;
    this.state.analytics.bossLane = boss.lane;

    if (!boss.introAnnounced) {
      boss.introAnnounced = true;
      this.events.emit("boss:intro", {
        waveIndex: this.state.wave.index,
        enemyId: enemy.id,
        lane: boss.lane,
        phase: boss.phase
      });
    }

    if (!boss.phaseShifted && enemy.health <= enemy.maxHealth * 0.5) {
      boss.phaseShifted = true;
      boss.phase = "phase-two";
      boss.rotationInterval = BOSS_ROTATION_INTERVAL_PHASE2;
      boss.shockwaveInterval = BOSS_SHOCKWAVE_INTERVAL_PHASE2;
      boss.rotationTimer = Math.min(boss.rotationTimer, boss.rotationInterval);
      boss.vulnerabilityRemaining = Math.max(
        boss.vulnerabilityRemaining,
        BOSS_VULNERABILITY_DURATION + 1
      );
      enemy.shield = enemy.shield
        ? { current: Math.min(enemy.shield.current, boss.segmentShield), max: boss.segmentShield }
        : undefined;
      this.recordBossEvent("phase-shift", enemy);
      this.events.emit("boss:phase", {
        waveIndex: this.state.wave.index,
        enemyId: enemy.id,
        phase: boss.phase,
        lane: boss.lane
      });
      this.events.emit("boss:vulnerability", {
        waveIndex: this.state.wave.index,
        enemyId: enemy.id,
        active: true,
        multiplier: boss.vulnerabilityMultiplier,
        remaining: boss.vulnerabilityRemaining
      });
    }

    boss.rotationTimer = Math.max(0, boss.rotationTimer - deltaSeconds);
    if (boss.rotationTimer <= 0) {
      this.rotateBossShield(enemy);
    }

    if (boss.vulnerabilityRemaining > 0) {
      boss.vulnerabilityRemaining = Math.max(0, boss.vulnerabilityRemaining - deltaSeconds);
      if (boss.vulnerabilityRemaining === 0) {
        this.recordBossEvent("vulnerable-end", enemy);
        this.events.emit("boss:vulnerability", {
          waveIndex: this.state.wave.index,
          enemyId: enemy.id,
          active: false,
          multiplier: boss.vulnerabilityMultiplier,
          remaining: 0
        });
      }
    }

    boss.shockwaveTimer = Math.max(0, boss.shockwaveTimer - deltaSeconds);
    if (boss.shockwaveTimer <= 0) {
      this.triggerBossShockwave(enemy);
    }
    if (boss.shockwaveRemaining > 0) {
      boss.shockwaveRemaining = Math.max(0, boss.shockwaveRemaining - deltaSeconds);
    }
  }

  private collectEvacuationSpawnRequest(currentTime: number): SpawnEnemyInput | null {
    if (!this.config.featureToggles.dynamicSpawns || !this.config.featureToggles.evacuationEvents) {
      return null;
    }
    if (!this.evacuationEvent || this.state.evacuation.active) {
      return null;
    }
    if (currentTime < this.evacuationEvent.time) {
      return null;
    }
    const event = this.evacuationEvent;
    const focusLane = this.getActiveLaneFocus();
    const lane = typeof focusLane === "number" ? focusLane : event.lane;
    const word = event.word ?? this.pickEvacuationWord(lane, this.state.wave.index, this.rng);
    this.state.evacuation = {
      active: true,
      lane,
      remaining: event.duration,
      duration: event.duration,
      enemyId: null,
      word,
      succeeded: false,
      failed: false
    };
    this.state.analytics.evacuationAttempts += 1;
    this.events.emit("evac:start", {
      waveIndex: this.state.wave.index,
      lane,
      word,
      duration: event.duration
    });
    return {
      tierId: "evac-transport",
      lane,
      order: DYNAMIC_EVENT_ORDER_START + 200,
      word,
      waveIndex: this.state.wave.index,
      taunt: "Civilians inbound-cover their escape!"
    };
  }

  private resolveAffixSeed(input: {
    waveIndex: number;
    order?: number;
    lane?: number;
    tierId: string;
  }): number {
    let hash = this.seed ^ Math.imul(input.waveIndex + 1, 0x9e3779b1);
    hash = Math.imul(hash ^ Math.imul((input.order ?? 0) + 11, 0x85ebca6b), 0x27d4eb2d);
    hash = Math.imul(hash ^ Math.imul((input.lane ?? 0) + 3, 0xc2b2ae35), 0x165667b1);
    for (let i = 0; i < input.tierId.length; i += 1) {
      hash ^= input.tierId.charCodeAt(i) << ((i % 4) * 8);
      hash >>>= 0;
    }
    hash >>>= 0;
    return hash === 0 ? 1 : hash;
  }

  private rollEliteAffixesForSpawn(request: SpawnEnemyInput & { waveIndex: number }): EliteAffixInstance[] {
    const baseShield =
      typeof request.shield === "number"
        ? request.shield
        : request.shield?.health ?? request.shield?.max ?? 0;
    const seed = this.resolveAffixSeed({
      waveIndex: request.waveIndex,
      order: request.order ?? 0,
      lane: request.lane,
      tierId: request.tierId
    });
    const rng = new PRNG(seed);
    return rollEliteAffixes({
      tierId: request.tierId,
      waveIndex: request.waveIndex,
      rng,
      baseShield
    });
  }

  private resolveSpawnAffixes(request: SpawnEnemyInput, waveIndex: number): EliteAffixInstance[] {
    if (Array.isArray(request.affixes)) {
      return request.affixes;
    }
    if (!this.config.featureToggles.eliteAffixes) {
      return [];
    }
    return this.rollEliteAffixesForSpawn({ ...request, waveIndex });
  }

  constructor(options: GameEngineOptions = {}) {
    this.config = {
      ...defaultConfig,
      ...options.config,
      featureToggles: {
        ...defaultConfig.featureToggles,
        ...(options.config?.featureToggles ?? {})
      }
    };
    this.events = options.events ?? new EventBus<GameEvents>();
    this.wordBank = options.wordBank ?? defaultWordBank;
    this.seed = options.seed ?? Date.now();
    this.rng = new PRNG(this.seed);
    this.state = createInitialState(this.config);
    this.state.mode = this.config.loopWaves ? "practice" : "campaign";
    this.state.analytics.mode = this.state.mode;

    this.enemySystem = new EnemySystem(this.config, this.events, this.rng, this.wordBank);
    this.turretSystem = new TurretSystem(this.config, this.events);
    this.waveSystem = new WaveSystem(this.config);
    this.projectileSystem = new ProjectileSystem(this.events, this.enemySystem);
    this.typingSystem = new TypingSystem(this.config, this.events);
    this.upgradeSystem = new UpgradeSystem(this.config, this.events, this.turretSystem);
    this.telemetryClient = options.telemetryClient;
    this.lastWaveIndex = this.state.wave.index;
    this.unlockSlotsForWave(this.lastWaveIndex);
    this.clearLaneHazards();
    this.resetDynamicEvents();
    this.resetEvacuationSchedule();
    this.resetBossState();
    this.difficultyBands = [...this.config.difficultyBands].sort((a, b) => a.fromWave - b.fromWave);
    this.currentDifficultyBand = this.resolveDifficulty(this.state.wave.index);

    this.waveSystem.setLoopWaves(Boolean(this.config.loopWaves));
    this.resetAnalytics();
    this.registerEventListeners();
    this.resetLimitedMistakesWaveBaseline();
  }

  reset(): void {
    this.state = createInitialState(this.config);
    this.state.mode = this.config.loopWaves ? "practice" : "campaign";
    this.state.analytics.mode = this.state.mode;
    this.lastWaveIndex = this.state.wave.index;
    this.unlockSlotsForWave(this.lastWaveIndex);
    this.clearLaneHazards();
    this.resetDynamicEvents();
    this.resetEvacuationSchedule();
    this.resetBossState();
    this.currentDifficultyBand = this.resolveDifficulty(this.state.wave.index);
    this.resetAnalytics();
    this.resetLimitedMistakesWaveBaseline();
  }

  getState(): GameState {
    return cloneState(this.state);
  }

  getStatus(): GameStatus {
    return this.state.status;
  }

  setChallengeModifiers(modifiers: ChallengeModifiersRuntime | null): void {
    if (!modifiers) {
      this.challengeModifiers = null;
      this.resetLimitedMistakesWaveBaseline();
      return;
    }
    const scoreMultiplierRaw = modifiers.scoreMultiplier;
    const scoreMultiplier =
      typeof scoreMultiplierRaw === "number" && Number.isFinite(scoreMultiplierRaw) && scoreMultiplierRaw >= 1
        ? scoreMultiplierRaw
        : 1;
    const mistakeBudgetRaw = modifiers.mistakeBudget;
    const mistakeBudget =
      typeof mistakeBudgetRaw === "number" && Number.isFinite(mistakeBudgetRaw)
        ? Math.max(1, Math.min(99, Math.floor(mistakeBudgetRaw)))
        : 10;
    this.challengeModifiers = {
      fog: Boolean(modifiers.fog),
      fastSpawns: Boolean(modifiers.fastSpawns),
      limitedMistakes: Boolean(modifiers.limitedMistakes),
      mistakeBudget,
      scoreMultiplier
    };
    this.resetLimitedMistakesWaveBaseline();
  }

  private resetLimitedMistakesWaveBaseline(): void {
    this.limitedMistakesWaveBaselineErrors = this.state?.typing?.errors ?? 0;
    this.limitedMistakesWaveIndex = this.state?.wave?.index ?? null;
  }

  private applyChallengeScoreMultiplier(amount: number): number {
    if (typeof amount !== "number" || !Number.isFinite(amount) || amount === 0) {
      return 0;
    }
    if (this.state.mode !== "practice") {
      return amount;
    }
    const multiplier = this.challengeModifiers?.scoreMultiplier ?? 1;
    if (typeof multiplier !== "number" || !Number.isFinite(multiplier) || multiplier <= 1.0001) {
      return amount;
    }
    const boosted = amount * multiplier;
    if (!Number.isFinite(boosted)) {
      return amount;
    }
    const rounded = Math.round(boosted);
    return Math.max(amount, rounded);
  }

  private enforceLimitedMistakesBudget(): void {
    if (this.state.mode !== "practice") {
      return;
    }
    if (this.state.wave.inCountdown) {
      return;
    }
    const challenge = this.challengeModifiers;
    if (!challenge || !challenge.limitedMistakes) {
      return;
    }
    const budget = challenge.mistakeBudget;
    if (!Number.isFinite(budget) || budget <= 0) {
      return;
    }
    const waveIndex = this.state.wave.index;
    if (this.limitedMistakesWaveIndex !== waveIndex) {
      this.resetLimitedMistakesWaveBaseline();
    }
    const totalErrors = this.state.typing.errors ?? 0;
    const errorsThisWave = Math.max(0, totalErrors - this.limitedMistakesWaveBaselineErrors);
    if (errorsThisWave <= budget) {
      return;
    }
    if (this.state.status !== "running") {
      return;
    }
    this.state.status = "defeat";
    this.events.emit("challenge:mistake-limit", {
      waveIndex,
      limit: budget,
      errors: errorsThisWave
    });
  }

  update(deltaSeconds: number): void {
    const status = this.state.status as GameStatus;
    if (status === "defeat" || status === "victory") {
      return;
    }

    const prevWaveIndex = this.state.wave.index;
    const prevInCountdown = this.state.wave.inCountdown;
    const prevStatus = this.state.status;

    this.state.time += deltaSeconds;

    const focusLane = this.getActiveLaneFocus();
    const waveDeltaSeconds =
      this.state.mode === "practice" &&
      Boolean(this.challengeModifiers?.fastSpawns) &&
      !this.state.wave.inCountdown
        ? deltaSeconds * FAST_SPAWNS_TIME_SCALE
        : deltaSeconds;
    const spawnRequestsBase = this.waveSystem.update(this.state, waveDeltaSeconds);
    const spawnRequests =
      typeof focusLane === "number"
        ? spawnRequestsBase.filter((request) => request.lane === focusLane)
        : spawnRequestsBase;
    const dynamicRequests = this.collectDynamicSpawnRequests(this.state.wave.timeInWave);
    const evacRequest = this.collectEvacuationSpawnRequest(this.state.wave.timeInWave);
    const allRequests = [...spawnRequests, ...dynamicRequests];
    if (evacRequest) {
      allRequests.push(evacRequest);
    }
    this.activateLaneHazards(this.state.wave.timeInWave, deltaSeconds);

    const baseDifficulty = this.resolveDifficulty(this.state.wave.index);
    const difficulty = this.applySpawnSpeedGate(baseDifficulty);
    this.currentDifficultyBand = difficulty;
    for (const request of allRequests) {
      const affixes = this.resolveSpawnAffixes(request, this.state.wave.index);
      const spawned = this.enemySystem.spawn(this.state, {
        ...request,
        waveIndex: this.state.wave.index,
        difficulty,
        affixes
      });
      if (spawned) {
        this.handleBossSpawn(spawned);
        this.handleEvacuationSpawn(spawned);
      }
    }

    const waveChanged = this.state.wave.index !== prevWaveIndex;
    const waveStarted =
      (prevInCountdown && !this.state.wave.inCountdown) || (waveChanged && !this.state.wave.inCountdown);

    if (waveStarted) {
      this.resetLimitedMistakesWaveBaseline();
    }

    if (prevInCountdown && !this.state.wave.inCountdown && this.state.status === "running") {
      this.buildDynamicEventsForWave(this.state.wave.index);
      const evacRng = new PRNG(this.seed ^ Math.imul(this.state.wave.index + 3, 0x517cc1b7));
      this.buildEvacuationEventForWave(this.state.wave.index, evacRng);
      this.beginWaveAnalytics(this.state.wave.index);
    }

    if (this.state.wave.index !== this.lastWaveIndex) {
      this.lastWaveIndex = this.state.wave.index;
      this.unlockSlotsForWave(this.lastWaveIndex);
      this.clearLaneHazards();
      this.resetDynamicEvents();
      this.resetEvacuationSchedule();
      this.resetBossState();
    }

    this.enemySystem.update(this.state, deltaSeconds);
    this.tickEvacuation(deltaSeconds);
    this.updateBoss(deltaSeconds);
    this.projectileSystem.update(this.state, deltaSeconds);
    this.turretSystem.update(this.state, deltaSeconds, this.projectileSystem);
    this.tickSupportBoost(deltaSeconds);
    this.tickComboTimer(deltaSeconds);

    if (waveChanged && !prevInCountdown) {
      this.finalizeWaveAnalytics(prevWaveIndex);
    }
    if (prevStatus !== "victory" && this.state.status === "victory") {
      this.finalizeWaveAnalytics(prevWaveIndex);
    }

    this.tickCastleRepairCooldown(deltaSeconds);
    this.applyCastleRegen(deltaSeconds);
    this.state.analytics.lastSnapshotTime = this.state.time;

    if (this.state.castle.health <= 0 && this.state.status !== "defeat") {
      this.state.status = "defeat";
    }
  }

  inputCharacter(character: string): InputResult {
    const status = this.state.status as GameStatus;
    if (status === "defeat" || status === "victory") {
      return { status: "ignored", buffer: this.state.typing.buffer };
    }
    const result = this.typingSystem.inputCharacter(this.state, character, this.enemySystem);
    if (result.status === "error") {
      this.enforceLimitedMistakesBudget();
    }
    return {
      status: result.status,
      buffer: result.buffer,
      enemyId: result.enemyId ?? undefined,
      expected: result.expected,
      received: result.received
    };
  }

  handleBackspace(): InputResult {
    const status = this.state.status as GameStatus;
    if (status === "defeat" || status === "victory") {
      return { status: "ignored", buffer: this.state.typing.buffer };
    }
    const result = this.typingSystem.handleBackspace(this.state);
    return {
      status: result.status,
      buffer: result.buffer,
      enemyId: result.enemyId
    };
  }

  purgeTypingBuffer(): InputResult {
    const status = this.state.status as GameStatus;
    if (status === "defeat" || status === "victory") {
      return { status: "ignored", buffer: this.state.typing.buffer };
    }
    const result = this.typingSystem.purgeBuffer(this.state);
    return {
      status: result.status,
      buffer: result.buffer
    };
  }

  recoverCombo(combo: number): void {
    const safeCombo =
      typeof combo === "number" && Number.isFinite(combo) ? Math.max(0, Math.floor(combo)) : 0;
    const typing = this.state.typing;
    typing.combo = safeCombo;
    if (safeCombo > 0) {
      typing.comboTimer = this.config.comboDecaySeconds;
      typing.comboWarning = false;
      const analytics = this.state.analytics;
      analytics.waveMaxCombo = Math.max(analytics.waveMaxCombo ?? 0, safeCombo);
      analytics.sessionBestCombo = Math.max(analytics.sessionBestCombo ?? 0, safeCombo);
    } else {
      typing.comboTimer = 0;
      typing.comboWarning = false;
    }
  }

  upgradeCastle(): UpgradeResult {
    return this.upgradeSystem.upgradeCastle(this.state);
  }

  repairCastle(): RepairResult {
    const result = this.upgradeSystem.repairCastle(this.state);
    return result;
  }

  placeTurret(slotId: string, typeId: TurretTypeId): UpgradeResult {
    const result = this.upgradeSystem.placeTurret(this.state, slotId, typeId);
    if (result.success && this.state.analytics.timeToFirstTurret === null) {
      this.state.analytics.timeToFirstTurret = this.state.time;
    }
    return result;
  }

  setTurretTargetingPriority(
    slotId: string,
    priority: TurretTargetPriority
  ): TurretTargetPriority | null {
    return this.turretSystem.setTargetingPriority(this.state, slotId, priority);
  }

  setTurretFiringEnabled(slotId: string, enabled: boolean): boolean {
    const result = this.turretSystem.setFiringEnabled(this.state, slotId, enabled);
    if (!result) {
      return false;
    }
    if (!enabled) {
      this.state.projectiles = this.state.projectiles.filter(
        (projectile) => projectile.sourceSlotId !== slotId
      );
    }
    return true;
  }

  upgradeTurret(slotId: string): UpgradeResult {
    return this.upgradeSystem.upgradeTurret(this.state, slotId);
  }

  downgradeTurret(slotId: string): UpgradeResult {
    return this.upgradeSystem.downgradeTurret(this.state, slotId);
  }

  applyTurretBlueprint(
    blueprint: TurretBlueprint,
    options: { preview?: boolean } = {}
  ): TurretBlueprintApplyResult {
    const entries = Object.entries(blueprint ?? {});
    if (entries.length === 0) {
      return { success: true, cost: 0, appliedSlots: [], clearedSlots: [], unchangedSlots: [] };
    }

    const operations: Array<{
      slotId: string;
      action: "keep" | "upgrade" | "replace";
      target: TurretBlueprintSlot;
      slot: TurretSlotState;
    }> = [];
    const targetIds = new Set<string>();
    const clearedSet = new Set<string>();
    let totalCost = 0;

    for (const [slotId, slotBlueprint] of entries) {
      targetIds.add(slotId);
      const slot = this.state.turrets.find((entry) => entry.id === slotId);
      if (!slot) {
        return {
          success: false,
          cost: 0,
          reason: "invalid-slot",
          slotId,
          message: `Turret slot "${slotId}" does not exist.`
        };
      }
      if (!slot.unlocked) {
        return {
          success: false,
          cost: 0,
          reason: "locked-slot",
          slotId,
          message: `Turret slot "${slotId}" is locked.`
        };
      }
      const archetype = this.config.turretArchetypes[slotBlueprint.typeId];
      if (!archetype) {
        return {
          success: false,
          cost: 0,
          reason: "invalid-turret",
          slotId,
          message: `Unknown turret type "${slotBlueprint.typeId}".`
        };
      }
      if (!this.hasLevelConfig(archetype.levels, slotBlueprint.level)) {
        return {
          success: false,
          cost: 0,
          reason: "invalid-turret",
          slotId,
          message: `Invalid level ${slotBlueprint.level} for turret "${slotBlueprint.typeId}".`
        };
      }

      const turret = slot.turret;
      const targetLevelCost = this.calculateTurretLevelCost(archetype.levels, slotBlueprint.level);
      let action: "keep" | "upgrade" | "replace" = "keep";
      let costContribution = 0;

      if (!turret) {
        action = "replace";
        costContribution = targetLevelCost;
        clearedSet.add(slotId);
      } else if (turret.typeId !== slotBlueprint.typeId) {
        action = "replace";
        costContribution = targetLevelCost;
        clearedSet.add(slotId);
      } else if (turret.level < slotBlueprint.level) {
        action = "upgrade";
        const currentCost = this.calculateTurretLevelCost(archetype.levels, turret.level);
        costContribution = targetLevelCost - currentCost;
      } else if (turret.level > slotBlueprint.level) {
        action = "replace";
        costContribution = targetLevelCost;
        clearedSet.add(slotId);
      } else {
        action = "keep";
      }

      if (costContribution < 0) {
        costContribution = 0;
      }

      totalCost += costContribution;
      operations.push({
        slotId,
        action,
        target: slotBlueprint,
        slot
      });
    }

    // Clear turrets not present in blueprint.
    for (const slot of this.state.turrets) {
      if (!targetIds.has(slot.id) && slot.turret) {
        clearedSet.add(slot.id);
      }
    }

    if (totalCost > this.state.resources.gold) {
      return {
        success: false,
        cost: totalCost,
        reason: "insufficient-gold",
        requiredGold: totalCost,
        availableGold: this.state.resources.gold,
        message: `Not enough gold to apply preset. Requires ${totalCost}g, have ${this.state.resources.gold}g.`
      };
    }

    const previewApplied = operations
      .filter((entry) => entry.action !== "keep")
      .map((entry) => entry.slotId);
    const previewUnchanged = operations
      .filter((entry) => entry.action === "keep")
      .map((entry) => entry.slotId);
    const previewCleared = Array.from(clearedSet);

    if (options.preview) {
      return {
        success: true,
        cost: totalCost,
        appliedSlots: previewApplied,
        clearedSlots: previewCleared,
        unchangedSlots: previewUnchanged
      };
    }

    const clearedSlots: string[] = [];
    const appliedSlots: string[] = [];
    const unchangedSlots: string[] = [];
    let spent = 0;

    // Remove turrets slated for clearing.
    for (const slotId of clearedSet) {
      const slot = this.state.turrets.find((entry) => entry.id === slotId);
      if (!slot) continue;
      if (slot.turret) {
        slot.turret = undefined;
        clearedSlots.push(slotId);
      }
    }

    for (const operation of operations) {
      const slot = this.state.turrets.find((entry) => entry.id === operation.slotId);
      if (!slot) {
        return {
          success: false,
          cost: totalCost,
          reason: "apply-failed",
          slotId: operation.slotId,
          message: `Turret slot "${operation.slotId}" is unavailable during preset apply.`
        };
      }
      const archetype = this.config.turretArchetypes[operation.target.typeId];
      if (!archetype) {
        return {
          success: false,
          cost: totalCost,
          reason: "invalid-turret",
          slotId: operation.slotId,
          message: `Unknown turret type "${operation.target.typeId}".`
        };
      }

      if (operation.action === "replace") {
        const placed = this.turretSystem.placeTurret(
          this.state,
          operation.slotId,
          operation.target.typeId
        );
        if (!placed) {
          return {
            success: false,
            cost: totalCost,
            reason: "apply-failed",
            slotId: operation.slotId,
            message: `Failed to place turret in slot "${operation.slotId}".`
          };
        }
        spent += this.safeGetLevelCost(archetype.levels, 1);
        for (let level = 2; level <= operation.target.level; level++) {
          const upgraded = this.turretSystem.upgradeTurret(this.state, operation.slotId);
          if (!upgraded) {
            return {
              success: false,
              cost: totalCost,
              reason: "apply-failed",
              slotId: operation.slotId,
              message: `Failed to upgrade turret in slot "${operation.slotId}" to level ${level}.`
            };
          }
          spent += this.safeGetLevelCost(archetype.levels, level);
        }
        appliedSlots.push(operation.slotId);
      } else if (operation.action === "upgrade") {
        const currentLevel = slot.turret?.level ?? 1;
        for (let level = currentLevel + 1; level <= operation.target.level; level++) {
          const upgraded = this.turretSystem.upgradeTurret(this.state, operation.slotId);
          if (!upgraded) {
            return {
              success: false,
              cost: totalCost,
              reason: "apply-failed",
              slotId: operation.slotId,
              message: `Upgrade failed for slot "${operation.slotId}" at level ${level}.`
            };
          }
          spent += this.safeGetLevelCost(archetype.levels, level);
        }
        appliedSlots.push(operation.slotId);
      } else {
        unchangedSlots.push(operation.slotId);
      }

      const desiredPriority = operation.target.priority ?? DEFAULT_TURRET_PRIORITY;
      if (slot.targetingPriority !== desiredPriority) {
        this.turretSystem.setTargetingPriority(this.state, operation.slotId, desiredPriority);
      }
    }

    for (const slot of this.state.turrets) {
      if (!targetIds.has(slot.id) && slot.targetingPriority !== DEFAULT_TURRET_PRIORITY) {
        this.turretSystem.setTargetingPriority(this.state, slot.id, DEFAULT_TURRET_PRIORITY);
      }
    }

    if (spent !== totalCost) {
      spent = totalCost;
    }

    const before = this.state.resources.gold;
    const after = Math.max(0, before - spent);
    this.state.resources.gold = after;
    this.events.emit("resources:gold", {
      gold: after,
      delta: after - before,
      timestamp: this.state.time
    });

    return {
      success: true,
      cost: spent,
      appliedSlots,
      clearedSlots,
      unchangedSlots
    };
  }

  private calculateTurretLevelCost(
    levels: Array<{ level: number; cost: number }>,
    level: number
  ): number {
    if (level <= 0) {
      return 0;
    }
    return levels
      .filter((entry) => entry.level >= 1 && entry.level <= level)
      .reduce((total, entry) => total + Math.max(0, entry.cost ?? 0), 0);
  }

  private safeGetLevelCost(levels: Array<{ level: number; cost: number }>, level: number): number {
    const match = levels.find((entry) => entry.level === level);
    return Math.max(0, match?.cost ?? 0);
  }

  private hasLevelConfig(levels: Array<{ level: number }>, level: number): boolean {
    return levels.some((entry) => entry.level === level);
  }

  recordTutorialEvent(stepId: string | null, event: string, timeInStep: number): void {
    const tutorial = this.state.analytics.tutorial;
    if (event === "start") {
      tutorial.attemptedRuns += 1;
    }
    const log = tutorial.events;
    log.push({
      stepId,
      event,
      atTime: this.state.time,
      timeInStep
    });
    const overflow = log.length - 64;
    if (overflow > 0) {
      log.splice(0, overflow);
    }
    this.telemetryClient?.track("tutorial-event", {
      stepId,
      event,
      timeInStep,
      time: this.state.time
    });
  }

  recordTutorialAssist(): void {
    this.state.analytics.tutorial.assistsShown += 1;
    this.telemetryClient?.track("tutorial-assist", {
      time: this.state.time,
      assistsShown: this.state.analytics.tutorial.assistsShown
    });
  }

  recordTutorialSummary(summary: TutorialSummaryStats, options: { replayed: boolean }): void {
    const tutorial = this.state.analytics.tutorial;
    tutorial.lastSummary = {
      accuracy: summary.accuracy,
      bestCombo: summary.bestCombo,
      breaches: summary.breaches,
      gold: summary.gold,
      completedAt: this.state.time,
      replayed: options.replayed
    };
    tutorial.completedRuns += 1;
    if (options.replayed) {
      tutorial.replayedRuns += 1;
    }
    this.telemetryClient?.track("tutorial-summary", {
      summary,
      replayed: options.replayed,
      completedAt: tutorial.lastSummary.completedAt
    });
  }

  recordTutorialSkip(): void {
    this.state.analytics.tutorial.skippedRuns += 1;
    this.telemetryClient?.track("tutorial-skip", {
      time: this.state.time,
      skippedRuns: this.state.analytics.tutorial.skippedRuns
    });
  }

  grantGold(amount: number): void {
    if (!Number.isFinite(amount)) return;
    if (amount === 0) return;
    const baseline = this.state.resources.gold;
    const nextGold = Math.max(0, baseline + amount);
    const delta = nextGold - baseline;
    this.state.resources.gold = nextGold;
    const timestamp = this.state.time;
    this.events.emit("resources:gold", {
      gold: this.state.resources.gold,
      delta,
      timestamp
    });
    const analytics = this.state.analytics;
    const entry: GoldEvent = { gold: this.state.resources.gold, delta, timestamp };
    analytics.goldEvents.push(entry);
    if (analytics.goldEvents.length > MAX_GOLD_EVENTS) {
      analytics.goldEvents.splice(0, analytics.goldEvents.length - MAX_GOLD_EVENTS);
    }
  }

  stripEnemyShield(enemyId: string): boolean {
    const enemy = this.state.enemies.find((entry) => entry.id === enemyId);
    if (!enemy || !enemy.shield || enemy.shield.current <= 0) {
      return false;
    }
    const shieldValue = enemy.shield.current;
    this.enemySystem.damageEnemy(this.state, enemyId, shieldValue, "turret");
    const target = this.state.enemies.find((entry) => entry.id === enemyId);
    return !target || !target.shield || target.shield.current <= 0;
  }

  spawnEnemy(request: SpawnEnemyInput): EnemyState | null {
    const baseDifficulty =
      request.difficulty ?? this.resolveDifficulty(request.waveIndex ?? this.state.wave.index);
    const difficulty = this.applySpawnSpeedGate(baseDifficulty);
    this.currentDifficultyBand = difficulty;
    const waveIndex = request.waveIndex ?? this.state.wave.index;
    const affixes = this.resolveSpawnAffixes(request, waveIndex);
    const enemy = this.enemySystem.spawn(this.state, { ...request, waveIndex, difficulty, affixes });
    if (enemy) {
      this.handleBossSpawn(enemy);
    }
    return enemy;
  }

  removeEnemiesByTier(tierId: string): number {
    const before = this.state.enemies.length;
    this.state.enemies = this.state.enemies.filter((enemy) => enemy.tierId !== tierId);
    return before - this.state.enemies.length;
  }

  damageCastle(amount: number): void {
    const mitigated = Math.max(1, amount - this.state.castle.armor);
    this.state.castle.health = Math.max(0, this.state.castle.health - mitigated);
    this.events.emit("castle:damaged", {
      amount: mitigated,
      health: this.state.castle.health
    });
    if (this.state.castle.health <= 0) {
      this.state.status = "defeat";
    }
  }

  unlockSlotsForWave(index: number): void {
    this.turretSystem.unlockSlotsByWave(this.state, index);
  }

  setLoopWaves(loop: boolean): void {
    this.config.loopWaves = loop;
    this.waveSystem.setLoopWaves(loop);
  }

  isLoopingWaves(): boolean {
    return Boolean(this.config.loopWaves);
  }

  setMode(mode: GameMode): void {
    this.state.mode = mode;
    this.state.analytics.mode = mode;
  }

  setLaneFocus(lane: number | null): void {
    if (lane === null || lane === undefined) {
      this.laneFocus = null;
      return;
    }
    if (typeof lane !== "number" || !Number.isFinite(lane) || !Number.isInteger(lane)) {
      this.laneFocus = null;
      return;
    }
    const lanes = new Set(this.config.turretSlots.map((slot) => slot.lane));
    if (!lanes.has(lane)) {
      this.laneFocus = null;
      return;
    }
    this.laneFocus = lane;
  }

  getLaneFocus(): number | null {
    return this.laneFocus;
  }

  activateSupportBoost(
    lane: number,
    options: { duration?: number; multiplier?: number; cooldown?: number } = {}
  ): boolean {
    if (this.state.status !== "running") {
      return false;
    }
    if (this.state.wave.inCountdown) {
      return false;
    }
    if (typeof lane !== "number" || !Number.isFinite(lane) || !Number.isInteger(lane)) {
      return false;
    }
    const lanes = new Set(this.config.turretSlots.map((slot) => slot.lane));
    if (!lanes.has(lane)) {
      return false;
    }
    const boost = this.state.supportBoost;
    if (boost.cooldownRemaining > 0) {
      return false;
    }
    const durationRaw = options.duration ?? 3.5;
    const duration =
      typeof durationRaw === "number" && Number.isFinite(durationRaw)
        ? Math.max(1, Math.min(10, durationRaw))
        : 3.5;
    const multiplierRaw = options.multiplier ?? 1.12;
    const multiplier =
      typeof multiplierRaw === "number" && Number.isFinite(multiplierRaw)
        ? Math.max(1, Math.min(2, multiplierRaw))
        : 1.12;
    const cooldownRaw = options.cooldown ?? 18;
    const cooldown =
      typeof cooldownRaw === "number" && Number.isFinite(cooldownRaw)
        ? Math.max(1, Math.min(60, cooldownRaw))
        : 18;
    boost.lane = lane;
    boost.remaining = duration;
    boost.duration = duration;
    boost.multiplier = multiplier;
    boost.cooldownRemaining = cooldown;
    this.events.emit("support:boost", { lane, duration, multiplier, cooldown });
    return true;
  }

  private getActiveLaneFocus(): number | null {
    if (this.state.mode !== "practice") {
      return null;
    }
    return typeof this.laneFocus === "number" ? this.laneFocus : null;
  }

  setStarfieldAnalytics(state: StarfieldAnalyticsState | null): void {
    if (!state) {
      this.state.analytics.starfield = null;
      return;
    }
    this.state.analytics.starfield = {
      driftMultiplier: state.driftMultiplier,
      depth: state.depth,
      tint: state.tint,
      waveProgress: state.waveProgress,
      castleHealthRatio: state.castleHealthRatio,
      severity: state.severity,
      reducedMotionApplied: state.reducedMotionApplied,
      layers: Array.isArray(state.layers)
        ? state.layers.map((layer) => ({
            id: layer.id,
            velocity: layer.velocity,
            direction: layer.direction,
            depth: layer.depth,
            baseDepth: layer.baseDepth,
            depthOffset: layer.depthOffset
          }))
        : []
    };
  }

  setDefeatBurstModeResolver(
    resolver: ((enemy: EnemyState) => DefeatBurstMode) | null
  ): void {
    this.defeatBurstModeResolver = resolver ?? null;
  }

  getMode(): GameMode {
    return this.state.mode;
  }

  getCurrentDifficultyBand(): DifficultyBand {
    return this.currentDifficultyBand;
  }

  setSpawnSpeedGateMultiplier(multiplier: number): void {
    if (typeof multiplier !== "number" || !Number.isFinite(multiplier)) {
      this.spawnSpeedGateMultiplier = 1;
      return;
    }
    this.spawnSpeedGateMultiplier = Math.max(SPAWN_SPEED_GATE_MIN, Math.min(1, multiplier));
  }

  getSpawnSpeedGateMultiplier(): number {
    return this.spawnSpeedGateMultiplier;
  }

  private applySpawnSpeedGate(difficulty: DifficultyBand): DifficultyBand {
    const gate = this.spawnSpeedGateMultiplier;
    if (!Number.isFinite(gate) || Math.abs(gate - 1) < 0.0001) {
      return difficulty;
    }
    const baseSpeed = difficulty.enemySpeedMultiplier ?? 1;
    const gatedSpeed = baseSpeed * gate;
    if (!Number.isFinite(gatedSpeed) || Math.abs(gatedSpeed - baseSpeed) < 0.0001) {
      return difficulty;
    }
    return {
      ...difficulty,
      enemySpeedMultiplier: gatedSpeed
    };
  }

  getRuntimeMetrics(): RuntimeMetrics {
    const currentDifficulty = this.currentDifficultyBand;
    const difficultyRating = this.calculateWaveThreat(this.state.wave.index, currentDifficulty);
    const waveDuration = Math.max(0.001, this.state.wave.timeInWave);
    const breakdown = this.state.analytics.waveTurretDamageBySlot;
    const turretStats: TurretRuntimeStat[] = this.state.turrets
      .filter((slot) => slot.unlocked && slot.turret)
      .map((slot) => {
        const damage = breakdown[slot.id] ?? 0;
        const dps = !this.state.wave.inCountdown && waveDuration > 0 ? damage / waveDuration : 0;
        return {
          slotId: slot.id,
          turretType: slot.turret?.typeId ?? null,
          level: slot.turret?.level ?? null,
          damage,
          dps
        };
      })
      .sort((a, b) => b.damage - a.damage);
    const goldEvents = this.state.analytics.goldEvents ?? [];
    const lastGoldEvent = goldEvents.length > 0 ? goldEvents[goldEvents.length - 1] : null;
    const recentGoldEvents = goldEvents.slice(-3).map((event) => ({ ...event }));
    const castlePassives = Array.isArray(this.state.castle.passives)
      ? this.state.castle.passives.map((passive) => ({ ...passive }))
      : [];
    const passiveUnlocks = this.state.analytics.castlePassiveUnlocks ?? [];
    const lastPassiveUnlock =
      passiveUnlocks.length > 0 ? { ...passiveUnlocks[passiveUnlocks.length - 1] } : null;
    const castleVisual = resolveCastleVisual(this.config, this.state.castle.level);
    const defeatBurstState = this.state.analytics.defeatBurst ?? {
      total: 0,
      sprite: 0,
      procedural: 0,
      lastEnemyType: null,
      lastLane: null,
      lastTimestamp: null,
      lastMode: null,
      history: []
    };
    const elapsedMinutes = this.state.time > 0 ? Math.max(this.state.time / 60, 0) : 0;
    const perMinute =
      elapsedMinutes > 0 ? defeatBurstState.total / elapsedMinutes : defeatBurstState.total > 0 ? Infinity : 0;
    const totalBursts = Math.max(1, defeatBurstState.total);
    const spriteUsagePct = (defeatBurstState.sprite / totalBursts) * 100;
    const lastAgeSeconds =
      defeatBurstState.lastTimestamp !== null
        ? Math.max(0, this.state.time - defeatBurstState.lastTimestamp)
        : null;
    const defeatBurstHistory = defeatBurstState.history.slice(-10).map((entry) => ({ ...entry }));
    const starfieldAnalytics = this.state.analytics.starfield
      ? structuredClone(this.state.analytics.starfield)
      : null;
    return {
      mode: this.state.mode,
      wave: {
        index: this.state.wave.index,
        total: this.state.wave.total,
        inCountdown: this.state.wave.inCountdown,
        countdown: this.state.wave.countdownRemaining
      },
      difficulty: currentDifficulty,
      difficultyRating,
      projectiles: this.state.projectiles.length,
      enemiesAlive: this.state.enemies.filter((enemy) => enemy.status === "alive").length,
      combo: this.state.typing.combo,
      gold: Math.floor(this.state.resources.gold),
      time: this.state.time,
      typing: {
        accuracy: this.state.typing.accuracy,
        totalInputs: this.state.typing.totalInputs,
        correctInputs: this.state.typing.correctInputs,
        errors: this.state.typing.errors,
        recentAccuracy: this.state.typing.recentAccuracy,
        recentSampleSize: this.state.typing.recentInputs.length,
        difficultyBias: this.state.typing.dynamicDifficultyBias
      },
      damage: {
        turret: this.state.analytics.waveTurretDamage,
        typing: this.state.analytics.waveTypingDamage,
        total: this.state.analytics.waveTurretDamage + this.state.analytics.waveTypingDamage
      },
      turretStats,
      goldEventCount: goldEvents.length,
      goldDelta: lastGoldEvent ? lastGoldEvent.delta : null,
      goldEventTimestamp: lastGoldEvent ? lastGoldEvent.timestamp : null,
      recentGoldEvents,
      castlePassives,
      lastPassiveUnlock,
      passiveUnlockCount: passiveUnlocks.length,
      castleVisual: {
        level: this.state.castle.level,
        spriteKey: castleVisual.spriteKey,
        fill: castleVisual.fill,
        border: castleVisual.border,
        accent: castleVisual.accent
      },
      defeatBursts: {
        total: defeatBurstState.total,
        perMinute: Number.isFinite(perMinute) ? perMinute : 0,
        spriteUsagePct: Number.isFinite(spriteUsagePct) ? spriteUsagePct : 0,
        sprite: defeatBurstState.sprite,
        procedural: defeatBurstState.procedural,
        lastEnemyType: defeatBurstState.lastEnemyType ?? null,
        lastLane: defeatBurstState.lastLane ?? null,
        lastTimestamp: defeatBurstState.lastTimestamp ?? null,
        lastAgeSeconds,
        lastMode: defeatBurstState.lastMode ?? null
      },
      starfield: starfieldAnalytics,
      defeatBurstHistory
    };
  }

  getAnalyticsSnapshot(): AnalyticsSnapshot {
    this.recalculateAverageDps();
    const analyticsClone = structuredClone(this.state.analytics);
    analyticsClone.mode = this.state.mode;
    const runtimeMetrics = this.getRuntimeMetrics();
    return {
      capturedAt: new Date().toISOString(),
      time: this.state.time,
      status: this.state.status,
      mode: this.state.mode,
      wave: structuredClone(this.state.wave),
      typing: structuredClone(this.state.typing),
      resources: structuredClone(this.state.resources),
      analytics: analyticsClone,
      turretStats: runtimeMetrics.turretStats.map((stat) => ({
        slotId: stat.slotId,
        turretType: stat.turretType,
        level: stat.level,
        damage: stat.damage,
        dps: stat.dps
      }))
    };
  }

  recordTypingDrill(summary: TypingDrillSummary): TypingDrillSummary {
    const normalized: TypingDrillSummary = {
      ...summary,
      elapsedMs: Math.max(0, summary.elapsedMs ?? 0),
      accuracy: Math.max(0, Math.min(1, summary.accuracy ?? 0)),
      bestCombo: Math.max(0, summary.bestCombo ?? 0),
      words: Math.max(0, summary.words ?? 0),
      errors: Math.max(0, summary.errors ?? 0),
      wpm: Math.max(0, summary.wpm ?? 0),
      timestamp: Number.isFinite(summary.timestamp) ? summary.timestamp : Date.now()
    };
    const drills = this.state.analytics.typingDrills;
    drills.push(normalized);
    if (drills.length > MAX_TYPING_DRILL_HISTORY) {
      drills.splice(0, drills.length - MAX_TYPING_DRILL_HISTORY);
    }
    this.events.emit("analytics:typing-drill", normalized);
    return normalized;
  }

  getUpcomingSpawns(limit = 6): WaveSpawnPreview[] {
    const focusLane = this.getActiveLaneFocus();
    let previews: WaveSpawnPreview[] = [];
    if (typeof focusLane === "number") {
      const maxSearch = 200;
      let searchLimit = Math.max(limit, 12);
      while (searchLimit <= maxSearch) {
        const previewsBase = this.waveSystem.getUpcomingSpawns(this.state, searchLimit);
        previews = previewsBase.filter((entry) => entry.lane === focusLane);
        if (previews.length >= limit || previewsBase.length < searchLimit) {
          break;
        }
        if (searchLimit >= maxSearch) {
          break;
        }
        searchLimit = Math.min(maxSearch, searchLimit * 2);
      }
    } else {
      previews = this.waveSystem.getUpcomingSpawns(this.state, limit);
    }
    const dynamicPreviews: WaveSpawnPreview[] = [];
    if (this.config.featureToggles.dynamicSpawns && this.dynamicEvents.length > 0) {
      const waveTime = this.state.wave.inCountdown ? 0 : this.state.wave.timeInWave;
      const countdown = this.state.wave.inCountdown ? this.state.wave.countdownRemaining : 0;
      for (let i = this.dynamicEventIndex; i < this.dynamicEvents.length; i++) {
        const event = this.dynamicEvents[i];
        if (typeof focusLane === "number" && event.lane !== focusLane) {
          continue;
        }
        const timeUntil = this.state.wave.inCountdown
          ? countdown + event.time
          : Math.max(0, event.time - waveTime);
        dynamicPreviews.push({
          waveIndex: this.state.wave.index,
          lane: event.lane,
          tierId: event.tierId,
          timeUntil,
          scheduledTime: event.time,
          isNextWave: false,
          order: event.order
        });
      }
    }
    const all = [...previews, ...dynamicPreviews].map((entry) => {
      const withBoss = { ...entry, isBoss: this.isBossTier(entry.tierId) };
      if (!this.config.featureToggles.eliteAffixes) {
        return withBoss;
      }
      const affixes = this.resolveSpawnAffixes(
        entry as unknown as SpawnEnemyInput,
        entry.waveIndex ?? this.state.wave.index
      );
      return { ...withBoss, affixes };
    });
    all.sort((a, b) => a.timeUntil - b.timeUntil);
    return all.slice(0, limit);
  }

  resetAnalytics(): void {
    this.state.analytics.waveSummaries = [];
    this.state.analytics.waveHistory = [];
    this.state.analytics.sessionBreaches = 0;
    this.state.analytics.sessionBestCombo = this.state.typing.combo;
    this.state.analytics.mode = this.state.mode;
    this.state.analytics.totalDamageDealt = 0;
    this.state.analytics.totalTypingDamage = 0;
    this.state.analytics.totalTurretDamage = 0;
    this.state.analytics.totalShieldBreaks = 0;
    this.state.analytics.totalCastleRepairs = 0;
    this.state.analytics.totalRepairHealth = 0;
    this.state.analytics.totalRepairGold = 0;
    this.state.analytics.totalPerfectWords = 0;
    this.state.analytics.totalBonusGold = 0;
    this.state.analytics.totalCastleBonusGold = 0;
    this.state.analytics.totalReactionTime = 0;
    this.state.analytics.reactionSamples = 0;
    this.state.analytics.taunt = {
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
    };
    this.state.analytics.defeatBurst = {
      total: 0,
      sprite: 0,
      procedural: 0,
      lastEnemyType: null,
      lastLane: null,
      lastTimestamp: null,
      lastMode: null,
      history: []
    };
    this.state.analytics.evacuationAttempts = 0;
    this.state.analytics.evacuationSuccesses = 0;
    this.state.analytics.evacuationFailures = 0;
    this.state.analytics.bossEvents = [];
    this.state.analytics.bossPhase = null;
    this.state.analytics.bossActive = false;
    this.state.analytics.bossLane = null;
    this.state.analytics.averageTotalDps = 0;
    this.state.analytics.averageTurretDps = 0;
    this.state.analytics.averageTypingDps = 0;
    this.state.analytics.timeToFirstTurret = null;
    this.state.analytics.waveTurretDamageBySlot = {};
    this.state.analytics.typingDrills = [];
    this.resetPerWaveAnalytics(this.state.wave.inCountdown ? null : this.state.wave.index);
    this.recalculateAverageDps();
  }

  private beginWaveAnalytics(waveIndex: number): void {
    if (this.state.analytics.activeWaveIndex === waveIndex) {
      return;
    }
    this.resetPerWaveAnalytics(waveIndex);
  }

  private finalizeWaveAnalytics(completedWaveIndex: number): void {
    const analytics = this.state.analytics;
    if (analytics.activeWaveIndex === null) {
      return;
    }
    const duration = Math.max(0, this.state.time - analytics.waveStartTime);
    const inputsDelta = this.state.typing.totalInputs - analytics.startTotalInputs;
    const correctDelta = this.state.typing.correctInputs - analytics.startCorrectInputs;
    const accuracy = inputsDelta > 0 ? correctDelta / inputsDelta : 1;
    const perfectWords = analytics.wavePerfectWords;
    let bonusGold = 0;
    const bonusConfig = this.config.perfectWordBonus;
    if (
      bonusConfig &&
      typeof bonusConfig.threshold === "number" &&
      typeof bonusConfig.gold === "number" &&
      perfectWords >= bonusConfig.threshold &&
      bonusConfig.gold > 0
    ) {
      bonusGold = bonusConfig.gold;
      this.grantGold(bonusGold);
      this.state.resources.score += this.applyChallengeScoreMultiplier(bonusGold);
      analytics.totalBonusGold += bonusGold;
      analytics.waveBonusGold = bonusGold;
      this.events.emit("wave:bonus", {
        waveIndex: completedWaveIndex,
        type: "perfect-words",
        count: perfectWords,
        gold: bonusGold
      });
    } else {
      analytics.waveBonusGold = 0;
    }
    const goldEarned = this.state.resources.gold - analytics.startGold;
    const maxCombo = Math.max(0, analytics.waveMaxCombo - analytics.waveComboBaseline);
    const typingDamage = analytics.waveTypingDamage;
    const turretDamage = analytics.waveTurretDamage;
    const totalDamage = typingDamage + turretDamage;
    const turretDps = duration > 0 ? turretDamage / duration : turretDamage;
    const typingDps = duration > 0 ? typingDamage / duration : typingDamage;
    const totalDps = duration > 0 ? totalDamage / duration : totalDamage;
    const averageReaction =
      analytics.waveReactionSamples > 0
        ? analytics.waveReactionTime / analytics.waveReactionSamples
        : 0;
    const bossEvents = analytics.bossEvents ?? [];
    const bossPhase = analytics.bossPhase ?? null;
    const bossActive = analytics.bossActive ?? false;
    const bossLane = analytics.bossLane ?? null;
    analytics.totalDamageDealt = totalDamage;
    const castleBonusGold = analytics.waveCastleBonusGold;
    const summary: WaveSummary = {
      index: completedWaveIndex,
      mode: this.state.mode,
      duration,
      accuracy,
      enemiesDefeated: analytics.enemiesDefeated,
      breaches: analytics.breaches,
      perfectWords,
      dps: totalDps,
      goldEarned,
      bonusGold,
      castleBonusGold,
      maxCombo,
      sessionBestCombo: analytics.sessionBestCombo,
      turretDamage,
      typingDamage,
      turretDps,
      typingDps,
      shieldBreaks: analytics.waveShieldBreaks,
      repairsUsed: analytics.waveRepairs,
      repairHealth: analytics.waveRepairHealth,
      repairGold: analytics.waveRepairGold,
      averageReaction,
      bossEvents,
      bossPhase,
      bossActive,
      bossLane
    };
    analytics.waveSummaries.push(summary);
    if (analytics.waveSummaries.length > 12) {
      analytics.waveSummaries.shift();
    }
    analytics.waveHistory.push(summary);
    if (analytics.waveHistory.length > MAX_WAVE_HISTORY) {
      analytics.waveHistory.shift();
    }
    this.recalculateAverageDps();
    this.telemetryClient?.track("wave-summary", {
      summary,
      averages: {
        total: analytics.averageTotalDps,
        turret: analytics.averageTurretDps,
        typing: analytics.averageTypingDps
      },
      waveHistorySize: analytics.waveHistory.length
    });
    analytics.activeWaveIndex = null;
    this.resetPerWaveAnalytics(null);
    this.events.emit("analytics:wave-summary", summary);
  }

  private resetPerWaveAnalytics(activeWaveIndex: number | null): void {
    const analytics = this.state.analytics;
    analytics.activeWaveIndex = activeWaveIndex;
    analytics.waveStartTime = this.state.time;
    analytics.lastSnapshotTime = this.state.time;
    analytics.mode = this.state.mode;
    analytics.totalDamageDealt = 0;
    analytics.waveTypingDamage = 0;
    analytics.waveTurretDamage = 0;
    analytics.waveTurretDamageBySlot = {};
    analytics.waveRepairs = 0;
    analytics.waveRepairHealth = 0;
    analytics.waveRepairGold = 0;
    analytics.wavePerfectWords = 0;
    analytics.waveBonusGold = 0;
    analytics.waveCastleBonusGold = 0;
    analytics.waveReactionTime = 0;
    analytics.waveReactionSamples = 0;
    analytics.evacuationAttempts = 0;
    analytics.evacuationSuccesses = 0;
    analytics.evacuationFailures = 0;
    analytics.enemiesDefeated = 0;
    analytics.breaches = 0;
    analytics.bossEvents = [];
    analytics.bossPhase = null;
    analytics.bossActive = false;
    analytics.bossLane = null;
    analytics.startGold = this.state.resources.gold;
    analytics.startTotalInputs = this.state.typing.totalInputs;
    analytics.startCorrectInputs = this.state.typing.correctInputs;
    analytics.waveComboBaseline = this.state.typing.combo;
    analytics.waveMaxCombo = this.state.typing.combo;
  }

  private registerEventListeners(): void {
    this.events.on("enemy:defeated", ({ enemy, reward }) => {
      const waveConfig = this.config.waves[enemy.waveIndex] ?? null;
      const waveBonus = waveConfig?.rewardBonus ?? 0;
      const baseReward = reward + waveBonus;
      const castleBonusPercent = Math.max(0, this.state.castle.goldBonusPercent ?? 0);
      const castleBonus = Math.round(baseReward * castleBonusPercent);
      const totalGold = baseReward + castleBonus;
      this.grantGold(totalGold);
      this.state.resources.score += this.applyChallengeScoreMultiplier(totalGold);
      if (castleBonus > 0) {
        this.state.analytics.totalCastleBonusGold += castleBonus;
        this.state.analytics.waveCastleBonusGold += castleBonus;
      }
      this.typingSystem.releaseEnemy(this.state, enemy.id);
      this.state.analytics.enemiesDefeated += 1;
      this.recordDefeatBurst(enemy);
      if (this.state.boss.active && enemy.id === this.state.boss.enemyId) {
        this.recordBossEvent("defeated", enemy);
        this.state.analytics.bossActive = false;
        this.resetBossState();
      }
      if (this.state.evacuation.active && enemy.id === this.state.evacuation.enemyId) {
        this.completeEvacuation(true);
      }
    });

    this.events.on("enemy:escaped", ({ enemy }) => {
      this.state.analytics.breaches += 1;
      this.state.analytics.sessionBreaches += 1;
      this.damageCastle(enemy.damage);
      this.typingSystem.releaseEnemy(this.state, enemy.id);
      if (this.state.boss.active && enemy.id === this.state.boss.enemyId) {
        this.recordBossEvent("despawned", enemy);
        this.state.analytics.bossActive = false;
        this.resetBossState();
      }
      if (this.state.evacuation.active && enemy.id === this.state.evacuation.enemyId) {
        this.completeEvacuation(false);
      }
    });

    this.events.on("castle:repaired", ({ amount, cost }) => {
      const analytics = this.state.analytics;
      analytics.totalCastleRepairs += 1;
      analytics.totalRepairHealth += amount;
      analytics.totalRepairGold += cost;
      analytics.waveRepairs += 1;
      analytics.waveRepairHealth += amount;
      analytics.waveRepairGold += cost;
    });
  }

  private recordDefeatBurst(enemy: EnemyState): void {
    const analytics = this.state.analytics;
    if (!analytics.defeatBurst) {
      analytics.defeatBurst = {
        total: 0,
        sprite: 0,
        procedural: 0,
        lastEnemyType: null,
        lastLane: null,
        lastTimestamp: null,
        lastMode: null,
        history: []
      };
    }
    const burst = analytics.defeatBurst;
    const mode =
      this.defeatBurstModeResolver?.(enemy) === "sprite" ? "sprite" : "procedural";
    burst.total += 1;
    if (mode === "sprite") {
      burst.sprite += 1;
    } else {
      burst.procedural += 1;
    }
    burst.lastEnemyType = enemy.tierId ?? null;
    burst.lastLane = typeof enemy.lane === "number" ? enemy.lane : null;
    burst.lastTimestamp = this.state.time;
    burst.lastMode = mode;
    burst.history.push({
      enemyType: burst.lastEnemyType,
      lane: burst.lastLane,
      timestamp: this.state.time,
      mode
    });
    const maxHistory = 50;
    if (burst.history.length > maxHistory) {
      burst.history.splice(0, burst.history.length - maxHistory);
    }
    this.events.emit("combat:defeat-burst", { enemy, mode });
  }

  private applyCastleRegen(dt: number): void {
    if (this.state.castle.health <= 0) return;
    if (this.state.castle.health >= this.state.castle.maxHealth) return;
    this.state.castle.health = Math.min(
      this.state.castle.maxHealth,
      this.state.castle.health + this.state.castle.regenPerSecond * dt
    );
  }

  private tickComboTimer(dt: number): void {
    const typing = this.state.typing;
    if (typing.combo <= 0) {
      if (typing.comboTimer !== 0) {
        typing.comboTimer = 0;
      }
      if (typing.comboWarning) {
        this.finalizeComboWarning(typing.combo);
      }
      typing.comboWarning = false;
      this.updateComboWarningBaseline();
      return;
    }

    const remaining = Math.max(0, typing.comboTimer - dt);
    typing.comboTimer = remaining;
    if (remaining <= 0) {
      if (typing.comboWarning) {
        this.finalizeComboWarning(0);
      }
      typing.combo = 0;
      typing.comboTimer = 0;
      typing.comboWarning = false;
      this.updateComboWarningBaseline();
      return;
    }

    const warningThreshold = Math.max(0, this.config.comboWarningSeconds);
    const wasWarning = typing.comboWarning;
    typing.comboWarning = remaining <= warningThreshold;
    if (!wasWarning && typing.comboWarning) {
      this.startComboWarning();
    } else if (wasWarning && !typing.comboWarning) {
      this.finalizeComboWarning(typing.combo);
    }

    if (!typing.comboWarning) {
      this.updateComboWarningBaseline();
    }
  }

  private tickSupportBoost(dt: number): void {
    const boost = this.state.supportBoost;
    if (!boost) {
      return;
    }
    if (boost.cooldownRemaining > 0) {
      boost.cooldownRemaining = Math.max(0, boost.cooldownRemaining - dt);
    }
    if (boost.remaining <= 0) {
      boost.remaining = 0;
      return;
    }
    boost.remaining = Math.max(0, boost.remaining - dt);
    if (boost.remaining <= 0) {
      boost.lane = null;
      boost.duration = 0;
      boost.multiplier = 1;
    }
  }

  private startComboWarning(): void {
    const comboWarning = this.state.analytics.comboWarning;
    const currentAccuracy = this.getComboWarningAccuracy();
    const baseline =
      Number.isFinite(comboWarning.baselineAccuracy) && comboWarning.baselineAccuracy >= 0
        ? comboWarning.baselineAccuracy
        : currentAccuracy;
    const deltaPercent = this.roundValue((currentAccuracy - baseline) * 100, 2);
    comboWarning.active = {
      startedAt: this.state.time,
      comboBefore: this.state.typing.combo,
      baselineAccuracy: baseline,
      accuracy: currentAccuracy,
      deltaPercent,
      waveIndex: this.state.wave.index
    };
  }

  private finalizeComboWarning(comboAfter: number): void {
    const comboWarning = this.state.analytics.comboWarning;
    const active = comboWarning.active;
    if (!active) {
      return;
    }
    const durationMs = Math.max(0, (this.state.time - active.startedAt) * 1000);
    const entry: ComboWarningHistoryEntry = {
      timestamp: active.startedAt,
      waveIndex: active.waveIndex,
      comboBefore: active.comboBefore,
      comboAfter,
      accuracy: this.roundValue(active.accuracy, 4),
      baselineAccuracy: this.roundValue(active.baselineAccuracy, 4),
      deltaPercent: this.roundValue(active.deltaPercent, 2),
      durationMs
    };
    comboWarning.history.push(entry);
    if (comboWarning.history.length > MAX_COMBO_WARNING_HISTORY) {
      comboWarning.history.shift();
    }
    comboWarning.count += 1;
    comboWarning.deltaSum += entry.deltaPercent;
    comboWarning.deltaMin =
      comboWarning.deltaMin === null
        ? entry.deltaPercent
        : Math.min(comboWarning.deltaMin, entry.deltaPercent);
    comboWarning.deltaMax =
      comboWarning.deltaMax === null
        ? entry.deltaPercent
        : Math.max(comboWarning.deltaMax, entry.deltaPercent);
    const previousTimestamp = comboWarning.lastTimestamp;
    comboWarning.lastTimestamp = this.state.time;
    comboWarning.lastDelta = entry.deltaPercent;
    comboWarning.active = null;
    const timeSinceLastWarningMs =
      previousTimestamp === null
        ? null
        : Math.max(0, (this.state.time - previousTimestamp) * 1000);
    this.telemetryClient?.track("combat.comboWarningDelta", {
      timestamp: entry.timestamp,
      waveIndex: entry.waveIndex,
      comboBefore: entry.comboBefore,
      comboAfter,
      deltaPercent: entry.deltaPercent,
      accuracyPercent: this.roundValue(entry.accuracy * 100, 2),
      baselineAccuracyPercent: this.roundValue(entry.baselineAccuracy * 100, 2),
      durationMs,
      timeSinceLastWarningMs
    });
  }

  private updateComboWarningBaseline(): void {
    const accuracy = this.state.typing.accuracy;
    if (!Number.isFinite(accuracy)) {
      return;
    }
    this.state.analytics.comboWarning.baselineAccuracy = Math.max(0, Math.min(1, accuracy));
  }

  private getComboWarningAccuracy(): number {
    const accuracy = this.state.typing.accuracy;
    if (!Number.isFinite(accuracy)) {
      return Math.max(0, Math.min(1, this.state.analytics.comboWarning.baselineAccuracy));
    }
    return Math.max(0, Math.min(1, accuracy));
  }

  private roundValue(value: number, precision = 2): number {
    if (!Number.isFinite(value)) {
      return 0;
    }
    const factor = 10 ** precision;
    return Math.round(value * factor) / factor;
  }

  private tickCastleRepairCooldown(dt: number): void {
    const castle = this.state.castle;
    if (castle.repairCooldownRemaining > 0) {
      castle.repairCooldownRemaining = Math.max(0, castle.repairCooldownRemaining - dt);
    }
  }

  private calculateWaveThreat(waveIndex: number, difficulty: DifficultyBand): number {
    const waveConfig = this.config.waves[waveIndex];
    if (!waveConfig) {
      return 0;
    }
    const healthMultiplier = difficulty.enemyHealthMultiplier ?? 1;
    const speedMultiplier = difficulty.enemySpeedMultiplier ?? 1;
    const rewardMultiplier = difficulty.rewardMultiplier ?? 1;
    let total = 0;
    for (const spawn of waveConfig.spawns) {
      const tier = this.config.enemyTiers[spawn.tierId];
      if (!tier) continue;
      const count = Math.max(1, spawn.count ?? 1);
      const healthScore = tier.health * healthMultiplier * 0.6;
      const damageScore = tier.damage * 35;
      const speedScore = tier.speed * speedMultiplier * 12;
      const shieldScore = (spawn.shield ?? 0) * 0.5;
      total += (healthScore + damageScore + speedScore + shieldScore) * count;
    }
    total += (waveConfig.rewardBonus ?? 0) * 5 * rewardMultiplier;
    return Math.round(total);
  }

  private resolveDifficulty(waveIndex: number): DifficultyBand {
    let selected = this.difficultyBands[0];
    for (const band of this.difficultyBands) {
      if (waveIndex >= band.fromWave) {
        selected = band;
      } else {
        break;
      }
    }
    return selected;
  }
}
