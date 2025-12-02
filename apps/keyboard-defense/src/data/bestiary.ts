import bestiary from "../../docs/enemies/bestiary.json" with { type: "json" };
import { type EnemyTierConfig } from "../core/config.js";

export interface EnemyBiography {
  id: string;
  name: string;
  role: string;
  danger: string;
  description: string;
  abilities: string[];
  tips: string[];
}

type BestiarySource =
  | EnemyBiography[]
  | {
      enemies?: EnemyBiography[];
    };

function normalize(source: BestiarySource): EnemyBiography[] {
  if (Array.isArray(source)) return source;
  if (Array.isArray(source?.enemies)) return source.enemies ?? [];
  return [];
}

const ENTRIES = normalize(bestiary as BestiarySource);
const MAP = new Map(ENTRIES.map((entry) => [entry.id, entry]));

export function getEnemyBiography(
  tierId: string,
  configTier?: EnemyTierConfig
): EnemyBiography {
  const fallbackName = configTier?.id ?? tierId;
  const normalizedName = fallbackName
    ? fallbackName.charAt(0).toUpperCase() + fallbackName.slice(1)
    : "Unknown";
  const existing = MAP.get(tierId);
  if (existing) {
    return existing;
  }
  return {
    id: tierId,
    name: normalizedName,
    role: "Enemy",
    danger: "Unknown",
    description: "Details on this enemy are still being gathered.",
    abilities: ["No dossier available."],
    tips: ["Face the wave and record notes to complete the dossier."]
  };
}

export function listEnemyBiographies(): EnemyBiography[] {
  return [...ENTRIES];
}
