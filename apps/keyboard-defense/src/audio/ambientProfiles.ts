import { type AmbientProfile } from "./soundManager.js";

export function selectAmbientProfile(
  waveIndex: number | null | undefined,
  totalWaves: number | null | undefined,
  castleHealthRatio: number | null | undefined
): AmbientProfile {
  const totalValid = Number.isFinite(totalWaves ?? NaN) && (totalWaves ?? 0) > 0;
  const total = totalValid ? Math.max(1, Math.floor(totalWaves ?? 1)) : 0;
  const current = Math.max(0, Math.floor(waveIndex ?? 0));
  const progress = total > 0 ? Math.min(1, Math.max(0, (current + 1) / total)) : 0;
  const health = Number.isFinite(castleHealthRatio ?? NaN) ? castleHealthRatio ?? 1 : 1;
  if (health <= 0.35) return "dire";
  if (progress >= 0.8) return "siege";
  if (progress >= 0.45) return "rising";
  return "calm";
}
