import { type CastleLevelConfig } from "../core/config.js";
import { type CastlePassive } from "../core/types.js";

const EPSILON = 0.0001;

export function deriveCastlePassives(
  base: CastleLevelConfig,
  level: CastleLevelConfig
): CastlePassive[] {
  const passives: CastlePassive[] = [];

  if (level.regenPerSecond - base.regenPerSecond > EPSILON) {
    passives.push({
      id: "regen",
      total: level.regenPerSecond,
      delta: level.regenPerSecond - base.regenPerSecond
    });
  }

  if (level.armor - base.armor > EPSILON) {
    passives.push({
      id: "armor",
      total: level.armor,
      delta: level.armor - base.armor
    });
  }

  if ((level.goldBonusPercent ?? 0) - (base.goldBonusPercent ?? 0) > EPSILON) {
    passives.push({
      id: "gold",
      total: level.goldBonusPercent ?? 0,
      delta: (level.goldBonusPercent ?? 0) - (base.goldBonusPercent ?? 0)
    });
  }

  return passives;
}
