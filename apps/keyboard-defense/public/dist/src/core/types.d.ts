export type GameStatus = "preparing" | "running" | "victory" | "defeat";
export type Vector2 = {
    x: number;
    y: number;
};
export type EnemyStatus = "alive" | "defeated" | "escaped";
export type EnemyEffect = {
    kind: "slow";
    multiplier: number;
    remaining: number;
} | {
    kind: "burn";
    dps: number;
    remaining: number;
};
export type EliteAffixId = "slow-aura" | "shielded" | "armored";
export type LaneHazardKind = "fog" | "storm";
export interface LaneHazardState {
    lane: number;
    kind: LaneHazardKind;
    remaining: number;
    duration: number;
    fireRateMultiplier?: number;
}
export interface EvacuationState {
    active: boolean;
    lane: number | null;
    remaining: number;
    duration: number;
    enemyId: string | null;
    word: string | null;
    succeeded: boolean;
    failed: boolean;
}
export type BossPhase = "intro" | "phase-one" | "phase-two" | "finale";
export type BossEventType = "intro" | "phase-shift" | "shield-rotated" | "vulnerable-start" | "vulnerable-end" | "shockwave" | "defeated" | "despawned";
export interface BossRuntimeState {
    active: boolean;
    enemyId: string | null;
    tierId: string | null;
    lane: number | null;
    phase: BossPhase | null;
    introAnnounced: boolean;
    segmentIndex: number;
    segmentTotal: number;
    segmentShield: number;
    rotationInterval: number;
    rotationTimer: number;
    vulnerabilityRemaining: number;
    vulnerabilityMultiplier: number;
    vulnerabilityAppliesToShield: boolean;
    shockwaveInterval: number;
    shockwaveTimer: number;
    shockwaveDuration: number;
    shockwaveRemaining: number;
    shockwaveMultiplier: number;
    phaseShifted: boolean;
}
export interface BossEventEntry {
    type: BossEventType;
    time: number;
    phase: BossPhase | null;
    health: number | null;
    shield: number | null;
    lane: number | null;
}
export interface EliteAffixEffects {
    laneFireRateMultiplier?: number;
    turretDamageTakenMultiplier?: number;
    bonusShield?: number;
}
export interface EliteAffixInstance {
    id: EliteAffixId;
    label: string;
    description: string;
    source?: "roll" | "scripted";
    effects: EliteAffixEffects;
}
export type GameMode = "campaign" | "practice";
export interface EnemyState {
    id: string;
    tierId: string;
    word: string;
    typed: number;
    typingErrors?: number;
    firstInputAt?: number;
    maxHealth: number;
    health: number;
    shield?: {
        current: number;
        max: number;
    };
    speed: number;
    baseSpeed: number;
    distance: number;
    lane: number;
    damage: number;
    reward: number;
    status: EnemyStatus;
    effects: EnemyEffect[];
    spawnedAt: number;
    waveIndex: number;
    affixes?: EliteAffixInstance[];
    turretDamageTakenMultiplier?: number;
    laneFireRateMultiplier?: number;
    taunt?: string;
    tauntId?: string | null;
}
export interface TurretState {
    slotId: string;
    typeId: TurretTypeId;
    level: number;
    cooldown: number;
    firingDisabled?: boolean;
}
export type TurretTargetPriority = "first" | "strongest" | "weakest";
export interface TurretRuntimeStat {
    slotId: string;
    turretType: TurretTypeId | null;
    level: number | null;
    damage: number;
    dps: number;
}
export interface TurretSlotState {
    id: string;
    lane: number;
    unlocked: boolean;
    position: Vector2;
    targetingPriority: TurretTargetPriority;
    turret?: TurretState;
}
export type CastlePassiveId = "regen" | "armor" | "gold";
export interface CastlePassive {
    id: CastlePassiveId;
    total: number;
    delta: number;
}
export interface GoldEvent {
    gold: number;
    delta: number;
    timestamp: number;
}
export interface TauntAnalyticsEntry {
    id: string | null;
    text: string;
    enemyType: string | null;
    lane: number | null;
    waveIndex: number | null;
    timestamp: number;
}
export interface TauntAnalyticsState {
    active: boolean;
    id: string | null;
    text: string | null;
    enemyType: string | null;
    lane: number | null;
    waveIndex: number | null;
    timestampMs: number | null;
    countPerWave: Record<number, number>;
    uniqueLines: string[];
    history: TauntAnalyticsEntry[];
}
export type DefeatBurstMode = "sprite" | "procedural";
export type DefeatAnimationPreference = "auto" | "sprite" | "procedural";
export interface DefeatBurstAnalyticsEntry {
    timestamp: number;
    enemyType: string | null;
    lane: number | null;
    mode: DefeatBurstMode;
}
export interface DefeatBurstAnalyticsState {
    total: number;
    sprite: number;
    procedural: number;
    lastEnemyType: string | null;
    lastLane: number | null;
    lastTimestamp: number | null;
    lastMode: DefeatBurstMode | null;
    history: DefeatBurstAnalyticsEntry[];
}
export interface StarfieldLayerAnalyticsState {
    id: string;
    velocity: number;
    direction: 1 | -1;
    depth: number;
    baseDepth: number;
    depthOffset?: number;
}
export interface StarfieldAnalyticsState {
    driftMultiplier: number;
    depth: number;
    tint: string;
    waveProgress: number;
    castleHealthRatio: number;
    severity: number;
    reducedMotionApplied: boolean;
    layers: StarfieldLayerAnalyticsState[];
}
export interface CastlePassiveUnlock {
    id: CastlePassiveId;
    total: number;
    delta: number;
    level: number;
    time: number;
}
export interface CastleState {
    level: number;
    maxHealth: number;
    health: number;
    armor: number;
    regenPerSecond: number;
    nextUpgradeCost: number | null;
    repairCooldownRemaining: number;
    goldBonusPercent: number;
    passives: CastlePassive[];
}
export interface GameResources {
    gold: number;
    score: number;
}
export interface WaveRuntimeState {
    index: number;
    total: number;
    inCountdown: boolean;
    countdownRemaining: number;
    timeInWave: number;
}
export interface TypingState {
    activeEnemyId: string | null;
    buffer: string;
    combo: number;
    comboTimer: number;
    comboWarning: boolean;
    errors: number;
    totalInputs: number;
    correctInputs: number;
    accuracy: number;
    recentInputs: number[];
    recentCorrectInputs: number;
    recentAccuracy: number;
    dynamicDifficultyBias: number;
    lastInputChar?: string | null;
    lastInputAtMs?: number | null;
}
export type TypingDrillMode = "burst" | "endurance" | "precision";
export type TypingDrillSource = "menu" | "options" | "cta" | "practice" | "debug" | (string & Record<string, never>);
export interface TypingDrillSummary {
    mode: TypingDrillMode;
    source: TypingDrillSource;
    elapsedMs: number;
    accuracy: number;
    bestCombo: number;
    words: number;
    errors: number;
    wpm: number;
    timestamp: number;
}
export interface ComboWarningHistoryEntry {
    timestamp: number;
    waveIndex: number;
    comboBefore: number;
    comboAfter: number;
    accuracy: number;
    baselineAccuracy: number;
    deltaPercent: number;
    durationMs: number;
}
export interface ComboWarningAnalyticsState {
    active: {
        startedAt: number;
        comboBefore: number;
        baselineAccuracy: number;
        accuracy: number;
        deltaPercent: number;
        waveIndex: number;
    } | null;
    baselineAccuracy: number;
    lastTimestamp: number | null;
    lastDelta: number | null;
    deltaMin: number | null;
    deltaMax: number | null;
    deltaSum: number;
    count: number;
    history: ComboWarningHistoryEntry[];
}
export interface TutorialAnalyticsEvent {
    stepId: string | null;
    event: string;
    atTime: number;
    timeInStep: number;
}
export interface TutorialSummaryStats {
    accuracy: number;
    bestCombo: number;
    breaches: number;
    gold: number;
}
export interface TutorialAnalyticsState {
    events: TutorialAnalyticsEvent[];
    assistsShown: number;
    attemptedRuns: number;
    completedRuns: number;
    replayedRuns: number;
    skippedRuns: number;
    lastSummary?: TutorialSummaryStats & {
        completedAt: number;
        replayed: boolean;
    };
}
export type ProjectileKind = "arrow" | "arcane" | "flame" | "crystal";
export type ProjectileEffect = {
    kind: "slow";
    value: number;
    duration: number;
} | {
    kind: "burn";
    value: number;
    duration: number;
};
export interface ProjectileState {
    id: string;
    kind: ProjectileKind;
    lane: number;
    position: number;
    speed: number;
    damage: number;
    targetId: string;
    sourceSlotId: string;
    effect?: ProjectileEffect;
    shieldBonus?: number;
}
export interface GameState {
    time: number;
    status: GameStatus;
    mode: GameMode;
    castle: CastleState;
    resources: GameResources;
    turrets: TurretSlotState[];
    enemies: EnemyState[];
    projectiles: ProjectileState[];
    laneHazards: LaneHazardState[];
    evacuation: EvacuationState;
    boss: BossRuntimeState;
    wave: WaveRuntimeState;
    typing: TypingState;
    analytics: GameAnalyticsState;
}
export type TurretTypeId = "arrow" | "arcane" | "flame" | "crystal";
export interface GameAnalyticsState {
    activeWaveIndex: number | null;
    waveStartTime: number;
    lastSnapshotTime: number;
    mode: GameMode;
    totalDamageDealt: number;
    totalTypingDamage: number;
    totalTurretDamage: number;
    totalShieldBreaks: number;
    totalCastleRepairs: number;
    totalRepairHealth: number;
    totalRepairGold: number;
    totalPerfectWords: number;
    totalBonusGold: number;
    totalCastleBonusGold: number;
    totalReactionTime: number;
    reactionSamples: number;
    enemiesDefeated: number;
    breaches: number;
    sessionBreaches: number;
    startGold: number;
    startTotalInputs: number;
    startCorrectInputs: number;
    waveSummaries: WaveSummary[];
    waveHistory: WaveSummary[];
    waveMaxCombo: number;
    waveShieldBreaks: number;
    waveComboBaseline: number;
    waveRepairs: number;
    waveRepairHealth: number;
    waveRepairGold: number;
    wavePerfectWords: number;
    waveBonusGold: number;
    waveCastleBonusGold: number;
    waveReactionTime: number;
    waveReactionSamples: number;
    sessionBestCombo: number;
    waveTypingDamage: number;
    waveTurretDamage: number;
    waveTurretDamageBySlot: Record<string, number>;
    averageTotalDps: number;
    averageTurretDps: number;
    averageTypingDps: number;
    timeToFirstTurret: number | null;
    castlePassiveUnlocks: CastlePassiveUnlock[];
    goldEvents: GoldEvent[];
    taunt: TauntAnalyticsState;
    defeatBurst: DefeatBurstAnalyticsState;
    evacuationAttempts: number;
    evacuationSuccesses: number;
    evacuationFailures: number;
    bossEvents: BossEventEntry[];
    bossPhase: BossPhase | null;
    bossActive: boolean;
    bossLane: number | null;
    tutorial: TutorialAnalyticsState;
    comboWarning: ComboWarningAnalyticsState;
    starfield: StarfieldAnalyticsState | null;
    typingDrills: TypingDrillSummary[];
}
export interface WaveSummary {
    index: number;
    mode: GameMode;
    duration: number;
    accuracy: number;
    enemiesDefeated: number;
    breaches: number;
    perfectWords: number;
    dps: number;
    goldEarned: number;
    bonusGold: number;
    castleBonusGold: number;
    maxCombo: number;
    sessionBestCombo: number;
    turretDamage: number;
    typingDamage: number;
    turretDps: number;
    typingDps: number;
    shieldBreaks: number;
    repairsUsed: number;
    repairHealth: number;
    repairGold: number;
    averageReaction: number;
    bossEvents?: BossEventEntry[];
    bossPhase?: BossPhase | null;
    bossActive?: boolean;
    bossLane?: number | null;
}
export interface WaveSpawnPreview {
    waveIndex: number;
    lane: number;
    tierId: string;
    timeUntil: number;
    scheduledTime: number;
    isNextWave: boolean;
    order: number;
    affixes?: EliteAffixInstance[];
    shield?: number;
    word?: string;
    isBoss?: boolean;
}
export interface AnalyticsUiSnapshot {
    compactHeight: boolean | null;
    tutorialBanner: {
        condensed: boolean;
        expanded: boolean;
    };
    hud: {
        passivesCollapsed: boolean | null;
        goldEventsCollapsed: boolean | null;
        prefersCondensedLists: boolean | null;
    };
    options: {
        passivesCollapsed: boolean | null;
    };
    diagnostics: {
        condensed: boolean | null;
        sectionsCollapsed: boolean | null;
    };
    preferences: {
        hudPassivesCollapsed: boolean | null;
        hudGoldEventsCollapsed: boolean | null;
        optionsPassivesCollapsed: boolean | null;
    };
}
export interface AnalyticsSnapshot {
    capturedAt: string;
    time: number;
    status: GameStatus;
    mode: GameMode;
    wave: WaveRuntimeState;
    typing: TypingState;
    resources: GameResources;
    analytics: GameAnalyticsState;
    settings?: {
        soundEnabled: boolean;
        soundVolume: number;
        soundIntensity: number;
    };
    ui?: AnalyticsUiSnapshot;
    turretStats?: TurretRuntimeStat[];
}
//# sourceMappingURL=types.d.ts.map