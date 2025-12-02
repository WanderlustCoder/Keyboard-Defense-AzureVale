import { type GameConfig } from "../core/config.js";

export type CastlePalette = {
  fill: string;
  border: string;
  accent: string;
};

export function resolveCastlePalette(config: GameConfig, level: number): CastlePalette {
  const match =
    config.castleLevels.find((entry) => entry.level === level)?.visual ??
    config.castleLevels[0]?.visual;
  if (match) {
    return match;
  }
  return {
    fill: "#475569",
    border: "#1f2937",
    accent: "#22d3ee"
  };
}
