import type { EliteAffixId, EliteAffixInstance } from "../core/types.js";
import type { PRNG } from "../utils/random.js";

export interface EliteAffixContext {
  tierId: string;
  waveIndex: number;
  rng: Pick<PRNG, "next" | "pick">;
  baseShield?: number;
}

export interface EliteAffixDefinition {
  id: EliteAffixId;
  label: string;
  description: string;
  effects: EliteAffixInstance["effects"];
}

const AFFIX_CATALOG: Record<EliteAffixId, EliteAffixDefinition> = {
  "slow-aura": {
    id: "slow-aura",
    label: "Frost Aura",
    description: "Turrets in this lane fire 20% slower while the elite is alive.",
    effects: { laneFireRateMultiplier: 0.8 }
  },
  armored: {
    id: "armored",
    label: "Armored",
    description: "Reduces turret damage taken by 20%, typing damage unchanged.",
    effects: { turretDamageTakenMultiplier: 0.8 }
  },
  shielded: {
    id: "shielded",
    label: "Aegis Shield",
    description: "Spawns with an extra 35 barrier HP.",
    effects: { bonusShield: 35 }
  }
};

const ELITE_TIER_OPTIONS: Record<string, EliteAffixId[]> = {
  brute: ["armored", "shielded"],
  witch: ["slow-aura", "shielded"],
  vanguard: ["armored", "slow-aura"],
  embermancer: ["slow-aura", "armored"],
  archivist: ["armored", "shielded", "slow-aura"]
};

const ELIGIBLE_TIERS = new Set(Object.keys(ELITE_TIER_OPTIONS));

function normalizeOptions(tierId: string): EliteAffixId[] {
  const options = ELITE_TIER_OPTIONS[tierId];
  if (options && options.length > 0) return options;
  return ["armored", "slow-aura"];
}

function pickAffix(context: EliteAffixContext): EliteAffixId | null {
  const waveNumber = context.waveIndex + 1;
  const chance = waveNumber >= 3 ? 0.75 : waveNumber >= 2 ? 0.55 : 0.25;
  if (context.rng.next() > chance) return null;
  const options = normalizeOptions(context.tierId);
  const filtered =
    (context.baseShield ?? 0) > 0 && options.length > 1
      ? options.filter((id) => id !== "shielded")
      : options;
  const pool = filtered.length > 0 ? filtered : options;
  try {
    return context.rng.pick(pool);
  } catch {
    return null;
  }
}

export function rollEliteAffixes(context: EliteAffixContext): EliteAffixInstance[] {
  if (!ELIGIBLE_TIERS.has(context.tierId)) {
    return [];
  }
  const picked = pickAffix(context);
  if (!picked) return [];
  const def = AFFIX_CATALOG[picked];
  if (!def) return [];
  return [
    {
      ...def,
      source: "roll"
    }
  ];
}

export function getEliteAffixCatalog(): EliteAffixDefinition[] {
  return Object.values(AFFIX_CATALOG);
}

export function isTierEligibleForAffixes(tierId: string): boolean {
  return ELIGIBLE_TIERS.has(tierId);
}
