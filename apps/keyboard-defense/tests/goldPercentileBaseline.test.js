import { describe, it, expect } from "vitest";

import {
  DEFAULT_METRICS,
  buildBaselineMap,
  buildBaselineDocument,
  buildThresholdDocument,
  formatBaselineMarkdown
} from "../scripts/ci/goldPercentileBaseline.mjs";

describe("goldPercentileBaseline CLI helpers", () => {
  it("averages scenario metrics into deterministic baselines", () => {
    const rows = [
      {
        file: "artifacts/smoke/tutorial.skip.json",
        medianGain: 50,
        p90Gain: 95,
        medianSpend: -30,
        p90Spend: -55
      },
      {
        file: "artifacts/smoke/tutorial.skip.json",
        medianGain: 70,
        p90Gain: 125,
        medianSpend: -40,
        p90Spend: -75
      },
      {
        file: "artifacts/e2e/campaign.json",
        medianGain: 65,
        p90Gain: 115,
        medianSpend: -45,
        p90Spend: -80
      }
    ];

    const baselines = buildBaselineMap(rows, DEFAULT_METRICS);
    expect(Object.keys(baselines)).toHaveLength(2);
    expect(baselines["artifacts/smoke/tutorial.skip.json"].medianGain).toBe(60);
    expect(baselines["artifacts/smoke/tutorial.skip.json"].p90Spend).toBe(-65);
    expect(baselines["artifacts/e2e/campaign.json"].medianSpend).toBe(-45);

    const baselineDoc = buildBaselineDocument(
      baselines,
      DEFAULT_METRICS,
      "2025-11-21T00:00:00.000Z"
    );
    expect(baselineDoc._meta.metrics).toEqual(DEFAULT_METRICS);
    expect(baselineDoc._meta.generatedAt).toBe("2025-11-21T00:00:00.000Z");
  });

  it("builds threshold defaults and markdown summaries", () => {
    const baselines = {
      "artifacts/smoke/tutorial.skip.json": {
        medianGain: 60,
        p90Gain: 110,
        medianSpend: -35,
        p90Spend: -65
      }
    };
    const baselineDoc = buildBaselineDocument(
      baselines,
      DEFAULT_METRICS,
      "2025-11-21T00:00:00.000Z"
    );
    const options = {
      deltaAbs: 20,
      deltaPct: 0.3,
      metricOverrides: new Map([["medianGain", { abs: 15, pct: 0.25 }]])
    };
    const thresholds = buildThresholdDocument(DEFAULT_METRICS, options, null, "2025-11-21T01:00:00.000Z");
    expect(thresholds.defaults.medianGain).toEqual({ abs: 15, pct: 0.25 });
    expect(thresholds.defaults.p90Gain).toEqual({ abs: 20, pct: 0.3 });
    expect(thresholds._meta.deltaAbs).toBe(20);

    const markdown = formatBaselineMarkdown(baselineDoc, thresholds);
    expect(markdown).toContain("## Gold Percentile Baselines");
    expect(markdown).toContain("tutorial.skip.json");
    expect(markdown).toContain("### Threshold Defaults");
    expect(markdown).toContain("medianGain");
  });
});
