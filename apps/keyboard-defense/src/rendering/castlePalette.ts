import { type GameConfig } from "../core/config.js";

export type CastlePalette = {
  fill: string;
  border: string;
  accent: string;
};

export type CastleVisual = CastlePalette & {
  spriteKey: string;
};

export function resolveCastlePalette(config: GameConfig, level: number): CastlePalette {
  return resolveCastleVisual(config, level);
}

export function resolveCastleVisual(config: GameConfig, level: number): CastleVisual {
  const fallback: CastleVisual = {
    fill: "#475569",
    border: "#1f2937",
    accent: "#22d3ee",
    spriteKey: "castle-level-1"
  };
  const levelConfig =
    config.castleLevels.find((entry) => entry.level === level) ?? config.castleLevels[0];
  if (!levelConfig) return fallback;
  const visual = levelConfig.visual ?? fallback;
  const spriteKey = levelConfig.spriteKey ?? `castle-level-${levelConfig.level}`;
  return { ...visual, spriteKey };
}
