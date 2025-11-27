import { describe, expect, it } from "vitest";

import {
  buildMarkdown,
  buildSummary,
  normalizeBreachPayload
} from "../scripts/ci/castleBreachSummary.mjs";

const samplePayload = {
  status: "breached",
  breach: {
    time: 12.34,
    healthAfter: 42,
    maxHealth: 100
  },
  metrics: {
    timeToBreachMs: 12340,
    castleHpStart: 100,
    castleHpEnd: 42,
    damageTaken: 58,
    turretsPlaced: 1,
    enemiesSpawned: 1
  },
  options: {
    scenario: "baseline",
    enemySpecs: [{ tierId: "brute", lane: 1 }],
    turrets: [{ slotId: "slot-1", typeId: "arrow", level: 1 }]
  },
  turretPlacements: [{ slotId: "slot-1", typeId: "arrow", level: 1 }]
};

describe("castleBreachSummary", () => {
  it("normalizes breach payloads", () => {
    const row = normalizeBreachPayload(samplePayload, "/tmp/breach.json");
    expect(row.scenario).toBe("baseline");
    expect(row.timeMs).toBe(12340);
    expect(row.turretsLabel).toContain("slot-1");
    expect(row.enemiesLabel).toContain("brute");
    expect(row.damageTaken).toBe(58);
  });

  it("builds summaries and markdown with warnings", () => {
    const row = normalizeBreachPayload(
      { ...samplePayload, status: "timeout", metrics: { ...samplePayload.metrics, damageTaken: 0 } },
      "/tmp/timeout.json"
    );
    const summary = buildSummary([row], {
      mode: "warn",
      summaryPath: "artifacts/summaries/castle.json",
      maxTimeMs: 1000,
      minDamage: 10
    });
    expect(summary.warnings.length).toBeGreaterThan(0);
    const markdown = buildMarkdown(summary);
    expect(markdown).toContain("Castle Breach Watch");
    expect(markdown).toContain("Warnings");
  });
});
