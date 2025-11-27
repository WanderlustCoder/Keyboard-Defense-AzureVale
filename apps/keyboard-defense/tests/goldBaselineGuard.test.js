import { describe, it, expect } from "vitest";
import { runBaselineGuard } from "../scripts/ci/goldBaselineGuard.mjs";

describe("goldBaselineGuard", () => {
  it("reports missing baselines and returns a report", async () => {
    const timelinePath = "temp/baseline-guard.timeline.json";
    const baselinePath = "temp/baseline-guard.baseline.json";
    const outJson = "temp/baseline-guard.report.json";

    const timeline = {
      scenarios: [
        { id: "tutorial-skip" },
        { id: "campaign" }
      ]
    };
    const baseline = {
      "artifacts/smoke/tutorial.skip.json": {}
    };

    const fs = await import("node:fs/promises");
    await fs.mkdir("temp", { recursive: true });
    await fs.writeFile(timelinePath, JSON.stringify(timeline));
    await fs.writeFile(baselinePath, JSON.stringify(baseline));

    const report = await runBaselineGuard({
      timelinePath,
      baselinePath,
      outJson,
      mode: "warn"
    });

    expect(report.totals.scenarios).toBe(2);
    expect(report.totals.baselineEntries).toBe(1);
    expect(report.missing).toContain("campaign");
    expect(report.missing).not.toContain("tutorial-skip");
  });
});
