import { describe, expect, it } from "vitest";
import { GameEngine } from "../src/engine/gameEngine.js";

describe("challenge modifiers (engine)", () => {
  it("applies score multipliers in practice mode only", () => {
    const practice = new GameEngine({ seed: 7 });
    practice.setMode("practice");
    practice.setChallengeModifiers({
      fog: false,
      fastSpawns: false,
      limitedMistakes: false,
      mistakeBudget: 10,
      scoreMultiplier: 1.5
    });
    const beforePractice = practice.getState().resources;
    practice.spawnEnemy({ tierId: "grunt", lane: 0, word: "a", order: 1 });
    practice.inputCharacter("a");
    const afterPractice = practice.getState().resources;
    const goldDeltaPractice = afterPractice.gold - beforePractice.gold;
    const scoreDeltaPractice = afterPractice.score - beforePractice.score;
    expect(goldDeltaPractice).toBeGreaterThan(0);
    expect(scoreDeltaPractice).toBe(Math.round(goldDeltaPractice * 1.5));

    const campaign = new GameEngine({ seed: 7 });
    campaign.setMode("campaign");
    campaign.setChallengeModifiers({
      fog: false,
      fastSpawns: false,
      limitedMistakes: false,
      mistakeBudget: 10,
      scoreMultiplier: 1.5
    });
    const beforeCampaign = campaign.getState().resources;
    campaign.spawnEnemy({ tierId: "grunt", lane: 0, word: "a", order: 1 });
    campaign.inputCharacter("a");
    const afterCampaign = campaign.getState().resources;
    const goldDeltaCampaign = afterCampaign.gold - beforeCampaign.gold;
    const scoreDeltaCampaign = afterCampaign.score - beforeCampaign.score;
    expect(goldDeltaCampaign).toBeGreaterThan(0);
    expect(scoreDeltaCampaign).toBe(goldDeltaCampaign);
  });

  it("ends the wave when the mistake budget is exceeded", () => {
    const engine = new GameEngine({ seed: 11 });
    engine.setMode("practice");
    engine.setChallengeModifiers({
      fog: false,
      fastSpawns: false,
      limitedMistakes: true,
      mistakeBudget: 1,
      scoreMultiplier: 1.2
    });
    engine.update(4);
    expect(engine.getState().wave.inCountdown).toBe(false);

    let payload = null;
    engine.events.on("challenge:mistake-limit", (event) => {
      payload = event;
    });

    engine.spawnEnemy({ tierId: "grunt", lane: 0, word: "a", order: 1 });
    engine.inputCharacter("x");
    expect(engine.getStatus()).not.toBe("defeat");
    engine.inputCharacter("y");
    expect(engine.getStatus()).toBe("defeat");
    expect(payload?.limit).toBe(1);
    expect(payload?.errors).toBe(2);
  });

  it("fast spawns advances wave time faster without changing global time", () => {
    const baseline = new GameEngine({ seed: 99 });
    baseline.setMode("practice");
    baseline.update(4);
    expect(baseline.getState().wave.inCountdown).toBe(false);

    const fast = new GameEngine({ seed: 99 });
    fast.setMode("practice");
    fast.setChallengeModifiers({
      fog: false,
      fastSpawns: true,
      limitedMistakes: false,
      mistakeBudget: 10,
      scoreMultiplier: 1
    });
    fast.update(4);
    expect(fast.getState().wave.inCountdown).toBe(false);

    const baselineState = baseline.getState();
    const fastState = fast.getState();
    const baselineWaveStart = baselineState.wave.timeInWave;
    const fastWaveStart = fastState.wave.timeInWave;
    const baselineTimeStart = baselineState.time;
    const fastTimeStart = fastState.time;

    baseline.update(1);
    fast.update(1);

    const baselineAfter = baseline.getState();
    const fastAfter = fast.getState();
    const baselineWaveDelta = baselineAfter.wave.timeInWave - baselineWaveStart;
    const fastWaveDelta = fastAfter.wave.timeInWave - fastWaveStart;
    expect(fastWaveDelta).toBeGreaterThan(baselineWaveDelta);
    expect(fastWaveDelta).toBeCloseTo(baselineWaveDelta * 1.35, 1);
    expect(fastAfter.time - fastTimeStart).toBeCloseTo(1, 4);
    expect(baselineAfter.time - baselineTimeStart).toBeCloseTo(1, 4);
  });
});
