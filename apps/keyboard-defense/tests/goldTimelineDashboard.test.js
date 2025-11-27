import { promises as fs } from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { describe, expect, it } from "vitest";

import { buildMarkdown, runDashboard } from "../scripts/ci/goldTimelineDashboard.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, "..", "..", "..");

describe("goldTimelineDashboard", () => {
  it("emits per-scenario slices with latest events", async () => {
    const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), "gold-timeline-dash-"));
    const summaryPath = path.join(tempDir, "gold-timeline.summary.json");
    const fixture = path.join(REPO_ROOT, "docs", "codex_pack", "fixtures", "gold-timeline", "smoke.json");

    const summary = await runDashboard({
      summaryPath,
      mode: "warn",
      passiveWindow: 5,
      maxSpendStreak: 200,
      minNetDelta: -250,
      targets: [fixture]
    });

    expect(summary.scenarios?.length).toBeGreaterThan(0);
    const tutorial = summary.scenarios.find((scenario) => scenario.id === "tutorial-skip");
    expect(tutorial).toBeTruthy();
    expect(tutorial?.totals?.events).toBeGreaterThan(0);
    expect(tutorial?.latestEvents?.[0]?.delta).toBe(-60);
    expect(summary.latestEvents[0].delta).toBe(-60);
    const markdown = buildMarkdown(summary);
    expect(markdown).toContain("| Scenario | Events | Net Δ |");
    expect(markdown).toContain("tutorial-skip");

    const saved = JSON.parse(await fs.readFile(summaryPath, "utf8"));
    expect(Array.isArray(saved.scenarios)).toBe(true);
    expect(saved.scenarios[0].latestEvents.length).toBeGreaterThan(0);
  });
});
