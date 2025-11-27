import { describe, it, expect } from "vitest";
import path from "node:path";

import {
  parseArgs,
  buildSummary,
  formatMarkdown
} from "../scripts/ci/assetIntegritySummary.mjs";

describe("assetIntegritySummary CLI helpers", () => {
  it("parses defaults and overrides", () => {
    const args = parseArgs(["--telemetry", "temp/telemetry.json", "--history", "temp/history.log"]);
    expect(args.telemetryPaths).toEqual([path.resolve("temp/telemetry.json")]);
    expect(args.historyPath.endsWith(path.normalize("temp/history.log"))).toBe(true);
  });

  it("builds summary + markdown", () => {
    const telemetryEntries = [
      {
        scenario: "tutorial-smoke",
        manifest: "public/assets/manifest.json",
        checked: 10,
        missingHash: 1,
        failed: 0,
        extraEntries: 0,
        strictMode: false,
        timestamp: "2025-11-21T00:00:00.000Z"
      }
    ];
    const historyEntries = [
      {
        scenario: "ci-build",
        manifest: "public/assets/manifest.json",
        checked: 12,
        missingHash: 0,
        failed: 0,
        strictMode: true,
        timestamp: "2025-11-20T00:00:00.000Z"
      }
    ];
    const summary = buildSummary({
      telemetryEntries,
      historyEntries,
      warnings: []
    });
    expect(summary.totals.runs).toBe(1);
    expect(summary.latest.scenario).toBe("tutorial-smoke");
    expect(summary.history.length).toBe(1);
    const markdown = formatMarkdown(summary);
    expect(markdown).toContain("Asset Integrity Summary");
    expect(markdown).toContain("tutorial-smoke");
    expect(markdown).toContain("History");
  });
});
