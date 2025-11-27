import { describe, expect, it } from "vitest";

import { deriveStarfieldState } from "../src/utils/starfield.js";
import { defaultStarfieldConfig } from "../src/config/starfield.js";

function createState({
  time = 10,
  timeInWave = 5,
  castleHealth = 200,
  castleMaxHealth = 250
} = {}) {
  return {
    time,
    status: "running",
    mode: "campaign",
    castle: {
      health: castleHealth,
      maxHealth: castleMaxHealth
    },
    resources: {
      gold: 0,
      score: 0
    },
    turrets: [],
    enemies: [],
    projectiles: [],
    wave: {
      index: 0,
      total: 5,
      inCountdown: false,
      countdownRemaining: 0,
      timeInWave
    },
    typing: {
      activeEnemyId: null,
      buffer: "",
      combo: 0,
      comboTimer: 0,
      comboWarning: false,
      errors: 0,
      totalInputs: 0,
      correctInputs: 0,
      accuracy: 1,
      recentInputs: [],
      recentCorrectInputs: 0,
      recentAccuracy: 1,
      dynamicDifficultyBias: 0
    },
    analytics: {}
  };
}

describe("deriveStarfieldState", () => {
  it("increases drift multiplier as wave progresses", () => {
    const early = deriveStarfieldState(
      createState({ timeInWave: 2 }),
      { config: defaultStarfieldConfig }
    );
    const late = deriveStarfieldState(
      createState({ timeInWave: 60 }),
      { config: defaultStarfieldConfig }
    );
    expect(late.driftMultiplier).toBeGreaterThanOrEqual(early.driftMultiplier);
  });

  it("tints color as castle health drops", () => {
    const healthy = deriveStarfieldState(
      createState({ castleHealth: 240, castleMaxHealth: 240 }),
      { config: defaultStarfieldConfig }
    );
    const damaged = deriveStarfieldState(
      createState({ castleHealth: 80, castleMaxHealth: 240 }),
      { config: defaultStarfieldConfig }
    );
    expect(healthy.tint).not.toBe(damaged.tint);
    expect(damaged.castleHealthRatio).toBeLessThan(healthy.castleHealthRatio);
  });

  it("reports severity and reducedMotionApplied", () => {
    const base = deriveStarfieldState(
      createState({ castleHealth: 120, castleMaxHealth: 200 }),
      { config: defaultStarfieldConfig }
    );
    expect(base.severity).toBeCloseTo(0.4, 5);
    const reduced = deriveStarfieldState(
      createState({ castleHealth: 120, castleMaxHealth: 200 }),
      { config: defaultStarfieldConfig, reducedMotion: true }
    );
    expect(reduced.reducedMotionApplied).toBe(true);
    expect(reduced.layers.every((layer) => layer.velocity === 0)).toBe(true);
  });
});
