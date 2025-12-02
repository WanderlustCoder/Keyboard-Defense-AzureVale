import { describe, expect, test } from "vitest";
import { EnemySystem } from "../src/systems/enemySystem.js";
import { EventBus } from "../src/core/eventBus.js";
import { defaultConfig } from "../src/core/config.ts";
import { PRNG } from "../public/dist/src/utils/random.js";

const baseState = {
  wave: { index: 0 },
  typing: { dynamicDifficultyBias: 0 }
};

describe("wave-specific word banks", () => {
  test("merges wave 2 shield vocabulary into buckets", () => {
    const system = new EnemySystem(defaultConfig, new EventBus(), new PRNG("wave-words"));
    const tier = defaultConfig.enemyTiers["brute"];
    const buckets = system.buildWordBuckets(tier, 0, 1);
    expect(buckets.easy).toContain("plate");
    expect(buckets.medium).toContain("barrier");
    expect(buckets.hard).toContain("unyield");
  });

  test("merges wave 3 boss vocabulary into buckets and picks a themed word", () => {
    const system = new EnemySystem(defaultConfig, new EventBus(), new PRNG("wave-boss"));
    const tier = defaultConfig.enemyTiers["archivist"];
    const waveState = { ...baseState, wave: { index: 2 } };
    const word = system.pickWord(waveState, tier, defaultConfig.difficultyBands[2], 1);
    const buckets = system.buildWordBuckets(tier, 1, 2);
    expect(buckets.medium).toContain("archive");
    expect(buckets.hard).toContain("archivist");
    expect(word.length).toBeGreaterThan(0);
  });
});
