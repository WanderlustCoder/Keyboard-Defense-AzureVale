import { test, expect } from "vitest";
import { promises as fs } from "node:fs";
import { fileURLToPath } from "node:url";
import {
  summarizeScenario,
  buildMarkdown
} from "../scripts/analytics/goldDeltaAggregator.mjs";

const FIXTURE = fileURLToPath(
  new URL("../../../docs/codex_pack/fixtures/gold-delta-aggregates/sample.analytics.json", import.meta.url)
);

test("goldDeltaAggregator summarises events per wave", async () => {
  const snapshot = JSON.parse(await fs.readFile(FIXTURE, "utf8"));
  const options = {
    warnMaxLoss: -200,
    failMinNet: -300,
    mode: "warn"
  };
  const entry = summarizeScenario(FIXTURE, snapshot, options);
  expect(entry.waves).toHaveLength(3);
  expect(entry.waves[0].gain).toBeCloseTo(60);
  expect(entry.waves[1].spend).toBeCloseTo(-50);
  expect(entry.stats.netDelta).toBe(0);
  expect(entry.alerts).toHaveLength(0);

  const summary = {
    generatedAt: "2025-11-20T00:00:00.000Z",
    mode: "warn",
    status: entry.status,
    entries: [entry]
  };
  const markdown = buildMarkdown(summary);
  expect(markdown).toContain("Gold Delta Aggregates");
  expect(markdown).toContain("Wave | Gain");
});
