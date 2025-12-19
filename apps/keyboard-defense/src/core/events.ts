import {
  type CastlePassive,
  type EnemyState,
  type GameState,
  type StarfieldAnalyticsState,
  type ProjectileState,
  type TurretSlotState,
  type TurretTargetPriority,
  type WaveSummary,
  type DefeatBurstMode,
  type TypingDrillSummary,
  type BossPhase
} from "./types.js";

export interface GameEvents extends Record<string, unknown> {
  "enemy:spawned": EnemyState;
  "enemy:defeated": { enemy: EnemyState; by: "typing" | "turret"; reward: number };
  "enemy:escaped": { enemy: EnemyState };
  "enemy:shield-broken": { enemy: EnemyState };
  "castle:damaged": { amount: number; health: number };
  "castle:upgraded": { level: number };
  "castle:repaired": { amount: number; health: number; cost: number };
  "castle:passive-unlocked": { passive: CastlePassive };
  "turret:placed": TurretSlotState;
  "turret:upgraded": TurretSlotState;
  "turret:downgraded": TurretSlotState;
  "turret:targeting": { slotId: string; priority: TurretTargetPriority };
  "resources:gold": { gold: number; delta: number; timestamp?: number };
  "typing:progress": { enemyId: string; progress: number; buffer: string };
  "typing:error": {
    enemyId: string | null;
    expected: string | null;
    received: string;
    totalErrors: number;
  };
  "typing:perfect-word": { enemyId: string; word: string };
  "projectile:fired": ProjectileState;
  "projectile:impact": { projectile: ProjectileState; enemyId: string | null };
  "wave:bonus": { waveIndex: number; type: "perfect-words"; count: number; gold: number };
  "analytics:wave-summary": WaveSummary;
  "analytics:typing-drill": TypingDrillSummary;
  "challenge:mistake-limit": { waveIndex: number; limit: number; errors: number };
  "state:snapshot": GameState;
  "tutorial:event": { stepId: string | null; event: string; timeInStep: number };
  "combat:defeat-burst": { enemy: EnemyState; mode: DefeatBurstMode };
  "visual:starfield-state": StarfieldAnalyticsState;
  "boss:intro": { waveIndex: number; enemyId: string | null; lane: number | null; phase: BossPhase };
  "boss:phase": { waveIndex: number; enemyId: string | null; phase: BossPhase; lane: number | null };
  "boss:shield-rotated": {
    waveIndex: number;
    enemyId: string;
    shield: number;
    segmentIndex: number;
    totalSegments: number;
  };
  "boss:vulnerability": {
    waveIndex: number;
    enemyId: string;
    active: boolean;
    multiplier: number;
    remaining: number;
  };
  "boss:shockwave": { waveIndex: number; enemyId: string | null; lane: number | null; multiplier: number; duration: number };
  "evac:start": { waveIndex: number; lane: number | null; word: string | null; duration: number };
  "evac:complete": { waveIndex: number; lane: number | null; word: string | null; remaining: number };
  "evac:fail": { waveIndex: number; lane: number | null; word: string | null };
}
