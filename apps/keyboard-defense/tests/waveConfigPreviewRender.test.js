import { describe, expect, test } from "vitest";
import path from "node:path";
import {
  renderHtml,
  summarizeConfig,
  waveSearchTokens
} from "../scripts/waves/previewConfig.mjs";

const SAMPLE_CONFIG = {
  featureToggles: {
    dynamicSpawns: true,
    eliteAffixes: false,
    evacuationEvents: true
  },
  waves: [
    {
      id: "wave-1",
      duration: 30,
      rewardBonus: 5,
      spawns: [
        { at: 0, lane: 0, tierId: "grunt", count: 2, affixes: ["aura"], cadence: 1.5 },
        { at: 5, lane: 1, tierId: "runner", count: 1 }
      ],
      hazards: [{ kind: "fog", lane: 0, time: 8, duration: 6, fireRateMultiplier: 0.8 }],
      dynamicEvents: [{ kind: "skirmish", lane: 2, time: 12 }],
      evacuation: { time: 15, lane: 2, duration: 8, word: "rescue" }
    },
    {
      id: "wave-2",
      duration: 20,
      rewardBonus: 0,
      spawns: [{ at: 2, lane: 1, tierId: "shield", count: 1, shield: 10 }],
      boss: true
    }
  ]
};

describe("wave preview rendering", () => {
  test("summarizeConfig tallies counts and lanes", () => {
    const summary = summarizeConfig(SAMPLE_CONFIG);
    expect(summary.waves).toBe(2);
    expect(summary.spawns).toBe(3);
    expect(summary.hazards).toBe(1);
    expect(summary.dynamic).toBe(1);
    expect(summary.evac).toBe(1);
    expect(summary.boss).toBe(1);
    expect(summary.lanes).toEqual(["0", "1", "2"]);
    expect(summary.featureToggles.dynamicSpawns).toBe(true);
  });

  test("waveSearchTokens captures identifiers, affixes, and evac word", () => {
    const tokens = waveSearchTokens(SAMPLE_CONFIG.waves[0]);
    expect(tokens).toContain("grunt");
    expect(tokens).toContain("aura");
    expect(tokens).toContain("rescue");
    expect(tokens).toContain("evac");
  });

  test("renderHtml emits filters, timelines, and data attributes", () => {
    const summary = summarizeConfig(SAMPLE_CONFIG);
    const html = renderHtml({
      config: SAMPLE_CONFIG,
      summary,
      paths: { configPath: path.join("tmp", "config.json"), schemaPath: path.join("tmp", "schema.json") }
    });

    expect(html).toContain('data-filter-lane="0"');
    expect(html).toContain('data-type-toggle="hazards"');
    expect(html).toContain("Feature toggles");
    expect(html).toContain("timeline");
    expect(html).toContain("data-wave-id=\"wave-1\"");
    expect(html).toContain("spawns");
    expect(html).toContain("evacuation");
  });

  test("renderHtml shows validation error block when provided", () => {
    const html = renderHtml({
      config: null,
      summary: summarizeConfig(),
      paths: { configPath: "missing.json", schemaPath: "schema.json" },
      error: new Error("boom")
    });
    expect(html).toContain("Validation failed");
    expect(html).toContain("boom");
  });
});
