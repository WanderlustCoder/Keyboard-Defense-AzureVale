import { type TurretTypeId } from "./types.js";
import { getTauntText } from "../data/taunts.js";

export interface DifficultyBand {
  fromWave: number;
  wordWeights: {
    easy: number;
    medium: number;
    hard: number;
  };
  enemyHealthMultiplier: number;
  enemySpeedMultiplier: number;
  rewardMultiplier: number;
}

export interface FeatureToggles {
  tutorials: boolean;
  campaignMap: boolean;
  dynamicDifficulty: boolean;
  dynamicSpawns: boolean;
  evacuationEvents: boolean;
  bossMechanics: boolean;
  eliteAffixes: boolean;
  analyticsExport: boolean;
  telemetry: boolean;
  crystalPulse: boolean;
  turretDowngrade: boolean;
  starfieldParallax: boolean;
  assetAtlas: boolean;
}

export interface CastleRepairConfig {
  cost: number;
  healAmount: number;
  cooldownSeconds: number;
}

export interface CastleLevelConfig {
  level: number;
  maxHealth: number;
  regenPerSecond: number;
  armor: number;
  upgradeCost: number | null;
  unlockSlots: number;
  goldBonusPercent: number;
  spriteKey?: string;
  visual?: {
    fill: string;
    border: string;
    accent: string;
  };
}

type TurretLevelEffectKind = "slow" | "burn";

export interface TurretLevelConfig {
  level: number;
  damage: number;
  fireRate: number;
  range: number;
  cost: number;
  splashRadius?: number;
  effect?: {
    kind: TurretLevelEffectKind;
    value: number;
    duration: number;
  };
  shieldBonus?: number;
}

export interface TurretArchetypeConfig {
  id: TurretTypeId;
  name: string;
  description: string;
  flavor?: string;
  levels: TurretLevelConfig[];
  affinityMultipliers?: Record<string, number>;
}

export interface EnemyTierConfig {
  id: string;
  wordLength: [number, number];
  health: number;
  speed: number;
  damage: number;
  reward: number;
  taunt?: string;
  taunts?: string[];
}

export interface WaveSpawnConfig {
  at: number;
  lane: number;
  tierId: string;
  count: number;
  cadence: number;
  shield?: number;
  taunt?: string;
}

export interface WaveConfig {
  id: string;
  duration: number;
  rewardBonus: number;
  spawns: WaveSpawnConfig[];
}

export interface TurretSlotConfig {
  id: string;
  lane: number;
  position: { x: number; y: number };
  unlockWave: number;
}

export interface GameConfig {
  prepCountdownSeconds: number;
  typingDamageMultiplier: number;
  comboDecaySeconds: number;
  comboWarningSeconds: number;
  burnTickRate: number;
  loopWaves: boolean;
  perfectWordBonus: {
    threshold: number;
    gold: number;
  };
  difficultyBands: DifficultyBand[];
  featureToggles: FeatureToggles;
  castleRepair: CastleRepairConfig;
  castleLevels: CastleLevelConfig[];
  turretArchetypes: Record<TurretTypeId, TurretArchetypeConfig>;
  enemyTiers: Record<string, EnemyTierConfig>;
  waves: WaveConfig[];
  turretSlots: TurretSlotConfig[];
}

export const defaultConfig: GameConfig = {
  prepCountdownSeconds: 3,
  typingDamageMultiplier: 1.25,
  comboDecaySeconds: 4.5,
  comboWarningSeconds: 1.5,
  burnTickRate: 0.3,
  loopWaves: false,
  perfectWordBonus: {
    threshold: 5,
    gold: 25
  },
  difficultyBands: [
    {
      fromWave: 0,
      wordWeights: { easy: 0.7, medium: 0.25, hard: 0.05 },
      enemyHealthMultiplier: 1,
      enemySpeedMultiplier: 1,
      rewardMultiplier: 1
    },
    {
      fromWave: 1,
      wordWeights: { easy: 0.45, medium: 0.4, hard: 0.15 },
      enemyHealthMultiplier: 1.1,
      enemySpeedMultiplier: 1.05,
      rewardMultiplier: 1.1
    },
    {
      fromWave: 2,
      wordWeights: { easy: 0.25, medium: 0.45, hard: 0.3 },
      enemyHealthMultiplier: 1.22,
      enemySpeedMultiplier: 1.1,
      rewardMultiplier: 1.2
    },
    {
      fromWave: 3,
      wordWeights: { easy: 0.1, medium: 0.35, hard: 0.55 },
      enemyHealthMultiplier: 1.35,
      enemySpeedMultiplier: 1.18,
      rewardMultiplier: 1.35
    }
  ],
  featureToggles: {
    tutorials: true,
    campaignMap: false,
    dynamicDifficulty: false,
    dynamicSpawns: true,
    evacuationEvents: true,
    bossMechanics: true,
    eliteAffixes: true,
    analyticsExport: true,
    telemetry: false,
    crystalPulse: false,
    turretDowngrade: false,
    starfieldParallax: true,
    assetAtlas: false
  },
  castleRepair: {
    cost: 150,
    healAmount: 80,
    cooldownSeconds: 25
  },
  castleLevels: [
    {
      level: 1,
      maxHealth: 100,
      regenPerSecond: 1.5,
      armor: 0,
      upgradeCost: 180,
      unlockSlots: 2,
      goldBonusPercent: 0,
      spriteKey: "castle-level-1",
      visual: { fill: "#475569", border: "#1f2937", accent: "#22d3ee" }
    },
    {
      level: 2,
      maxHealth: 150,
      regenPerSecond: 2.2,
      armor: 1,
      upgradeCost: 320,
      unlockSlots: 3,
      goldBonusPercent: 0.05,
      spriteKey: "castle-level-2",
      visual: { fill: "#4338ca", border: "#1e1b4b", accent: "#a5b4fc" }
    },
    {
      level: 3,
      maxHealth: 210,
      regenPerSecond: 2.8,
      armor: 2,
      upgradeCost: 450,
      unlockSlots: 4,
      goldBonusPercent: 0.08,
      spriteKey: "castle-level-3",
      visual: { fill: "#2563eb", border: "#0f172a", accent: "#7dd3fc" }
    },
    {
      level: 4,
      maxHealth: 280,
      regenPerSecond: 3.3,
      armor: 3,
      upgradeCost: null,
      unlockSlots: 5,
      goldBonusPercent: 0.12,
      spriteKey: "castle-level-4",
      visual: { fill: "#0ea5e9", border: "#0b1120", accent: "#38bdf8" }
    }
  ],
  turretArchetypes: {
    arrow: {
      id: "arrow",
      name: "Arrow Tower",
      description: "High single-target damage with fast reload.",
      flavor: "Reliable fletching tower that snaps to runners before they touch the gate.",
      levels: [
        { level: 1, damage: 16, fireRate: 1.4, range: 0.45, cost: 120 },
        { level: 2, damage: 22, fireRate: 1.6, range: 0.5, cost: 180 },
        { level: 3, damage: 30, fireRate: 1.8, range: 0.55, cost: 240 }
      ],
      affinityMultipliers: {
        runner: 1.25,
        witch: 1.1,
        brute: 0.9
      }
    },
    arcane: {
      id: "arcane",
      name: "Arcane Focus",
      description: "Channels beams that slow enemies while dealing damage.",
      flavor: "Prismatic focus that tethers foes in slowing beams; excels at bullying witches.",
      levels: [
        {
          level: 1,
          damage: 10,
          fireRate: 1.2,
          range: 0.5,
          cost: 140,
          effect: { kind: "slow", value: 0.7, duration: 1.8 }
        },
        {
          level: 2,
          damage: 14,
          fireRate: 1.4,
          range: 0.55,
          cost: 210,
          effect: { kind: "slow", value: 0.6, duration: 2.2 }
        },
        {
          level: 3,
          damage: 18,
          fireRate: 1.6,
          range: 0.6,
          cost: 270,
          effect: { kind: "slow", value: 0.5, duration: 2.6 }
        }
      ],
      affinityMultipliers: {
        witch: 1.2,
        brute: 1.1,
        runner: 0.9
      }
    },
    flame: {
      id: "flame",
      name: "Flame Thrower",
      description: "Low upfront damage but applies sustained burning.",
      flavor: "Alchemist’s rig that drenches lanes in fire, ideal for bruisers that linger.",
      levels: [
        {
          level: 1,
          damage: 6,
          fireRate: 1.0,
          range: 0.4,
          cost: 150,
          effect: { kind: "burn", value: 4, duration: 3 }
        },
        {
          level: 2,
          damage: 8,
          fireRate: 1.1,
          range: 0.45,
          cost: 220,
          effect: { kind: "burn", value: 6, duration: 3.2 }
        },
        {
          level: 3,
          damage: 11,
          fireRate: 1.2,
          range: 0.5,
          cost: 280,
          effect: { kind: "burn", value: 8, duration: 3.5 }
        }
      ],
      affinityMultipliers: {
        brute: 1.3,
        grunt: 1.05,
        witch: 0.85
      }
    },
    crystal: {
      id: "crystal",
      name: "Crystal Pulse",
      description: "Fires concentrated pulses that shatter shields with bonus damage.",
      flavor: "Shard engine tuned to crack barriers and stagger elites with concussive pulses.",
      levels: [
        {
          level: 1,
          damage: 9,
          fireRate: 0.9,
          range: 0.6,
          cost: 180,
          shieldBonus: 24
        },
        {
          level: 2,
          damage: 12,
          fireRate: 1.0,
          range: 0.65,
          cost: 260,
          shieldBonus: 32
        },
        {
          level: 3,
          damage: 16,
          fireRate: 1.05,
          range: 0.7,
          cost: 340,
          shieldBonus: 40
        }
      ],
      affinityMultipliers: {
        witch: 1.2,
        brute: 1.15
      }
    }
  },
  enemyTiers: {
    dummy: {
      id: "dummy",
      wordLength: [5, 6],
      health: 500,
      speed: 0,
      damage: 0,
      reward: 0,
      taunt: "Training construct deployed."
    },
    grunt: { id: "grunt", wordLength: [3, 4], health: 30, speed: 0.05, damage: 12, reward: 18 },
    runner: { id: "runner", wordLength: [3, 5], health: 24, speed: 0.075, damage: 14, reward: 20 },
    brute: {
      id: "brute",
      wordLength: [5, 7],
      health: 60,
      speed: 0.035,
      damage: 22,
      reward: 30,
      taunts: [
        "A brute bellows, daring your turrets to stop it.",
        "Brute roar: \"I'll pulp those gates!\"",
        getTauntText("affix_shield_overcharge"),
        getTauntText("affix_berserker_crescendo")
      ]
    },
    witch: {
      id: "witch",
      wordLength: [6, 8],
      health: 52,
      speed: 0.04,
      damage: 26,
      reward: 36,
      taunts: [
        "The witch cackles: \"Your defenses crumble under my hexes.\"",
        "Shieldweaver whispers, \"Your castle will soon slumber.\"",
        getTauntText("affix_frost_aegis")
      ]
    },
    vanguard: {
      id: "vanguard",
      wordLength: [6, 8],
      health: 95,
      speed: 0.038,
      damage: 30,
      reward: 48,
      taunts: [getTauntText("elite_vanguard_lancer")]
    },
    embermancer: {
      id: "embermancer",
      wordLength: [6, 9],
      health: 80,
      speed: 0.042,
      damage: 32,
      reward: 54,
      taunts: [getTauntText("elite_embermancer")]
    },
    "evac-transport": {
      id: "evac-transport",
      wordLength: [9, 14],
      health: 110,
      speed: 0.045,
      damage: 0,
      reward: 60,
      taunt: "Civilians boarding—keep them safe!"
    },
    archivist: {
      id: "archivist",
      wordLength: [7, 9],
      health: 220,
      speed: 0.028,
      damage: 42,
      reward: 125,
      taunts: [
        getTauntText("boss_archivist_intro"),
        getTauntText("boss_archivist_phase2"),
        getTauntText("boss_archivist_finale")
      ]
    }
  },
  waves: [
    {
      id: "wave-1",
      duration: 28,
      rewardBonus: 0,
      spawns: [
        { at: 2, lane: 0, tierId: "grunt", count: 3, cadence: 1.7 },
        { at: 6, lane: 1, tierId: "grunt", count: 3, cadence: 1.7 },
        { at: 9, lane: 2, tierId: "runner", count: 2, cadence: 2.1 },
        { at: 14, lane: 0, tierId: "runner", count: 2, cadence: 2 }
      ]
    },
    {
      id: "wave-2",
      duration: 32,
      rewardBonus: 8,
      spawns: [
        { at: 1.5, lane: 1, tierId: "runner", count: 3, cadence: 1.5 },
        { at: 4.5, lane: 0, tierId: "grunt", count: 5, cadence: 1.5 },
        { at: 9, lane: 2, tierId: "runner", count: 3, cadence: 1.8 },
        {
          at: 13,
          lane: 0,
          tierId: "brute",
          count: 2,
          cadence: 4,
          shield: 25,
          taunt: "Shielded brutes roar down lane A!"
        },
        { at: 18, lane: 2, tierId: "grunt", count: 3, cadence: 1.9 }
        ,
        {
          at: 21,
          lane: 1,
          tierId: "brute",
          count: 1,
          cadence: 0,
          shield: 60,
          taunt: getTauntText("affix_shield_overcharge")
        }
      ]
    },
    {
      id: "wave-3",
      duration: 52,
      rewardBonus: 22,
      spawns: [
        { at: 2, lane: 1, tierId: "runner", count: 4, cadence: 1.4 },
        {
          at: 6,
          lane: 0,
          tierId: "witch",
          count: 2,
          cadence: 4.5,
          shield: 45,
          taunt: "Witches weave shielding hexes over lane A!"
        },
        { at: 11, lane: 2, tierId: "runner", count: 3, cadence: 1.6, taunt: getTauntText("affix_berserker_crescendo") },
        {
          at: 16,
          lane: 2,
          tierId: "brute",
          count: 2,
          cadence: 3.5,
          taunt: "Brutes pound toward lane C!"
        },
        { at: 20, lane: 1, tierId: "grunt", count: 4, cadence: 1.6 },
        {
          at: 24,
          lane: 0,
          tierId: "witch",
          count: 2,
          cadence: 4,
          taunt: getTauntText("affix_frost_aegis")
        },
        {
          at: 30,
          lane: 1,
          tierId: "vanguard",
          count: 2,
          cadence: 4,
          taunt: getTauntText("elite_vanguard_lancer")
        },
        {
          at: 36,
          lane: 2,
          tierId: "embermancer",
          count: 1,
          cadence: 0,
          taunt: getTauntText("elite_embermancer")
        },
        {
          at: 42,
          lane: 1,
          tierId: "archivist",
          count: 1,
          cadence: 0,
          shield: 90,
          taunt: getTauntText("boss_archivist_intro")
        }
      ]
    }
  ],
  turretSlots: [
    { id: "slot-1", lane: 0, position: { x: 0.15, y: 0.25 }, unlockWave: 0 },
    { id: "slot-2", lane: 1, position: { x: 0.15, y: 0.5 }, unlockWave: 0 },
    { id: "slot-3", lane: 2, position: { x: 0.15, y: 0.75 }, unlockWave: 1 },
    { id: "slot-4", lane: 1, position: { x: 0.25, y: 0.4 }, unlockWave: 2 },
    { id: "slot-5", lane: 0, position: { x: 0.22, y: 0.65 }, unlockWave: 3 }
  ]
};
