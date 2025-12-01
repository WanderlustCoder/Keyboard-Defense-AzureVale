import { describe, it, expect } from "vitest";
import path from "node:path";
import { fileURLToPath } from "node:url";

import {
  parseArgs,
  collectTelemetryEvents,
  summarizeTelemetry,
  formatMarkdown
} from "../scripts/ci/typingDrillTelemetrySummary.mjs";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

describe("typingDrillTelemetrySummary", () => {
  it("parses defaults and telemetry overrides", () => {
    const parsed = parseArgs(["--telemetry", "temp/telemetry.json", "--recent", "5"]);
    expect(parsed.telemetryPaths[0].endsWith(path.normalize("temp/telemetry.json"))).toBe(true);
    expect(parsed.recent).toBe(5);
  });

  it("collects telemetry events from fixtures", async () => {
    const fixture = path.resolve(
      __dirname,
      "../../../docs/codex_pack/fixtures/telemetry/typing-drill-quickstart.json"
    );
    const { events, warnings } = await collectTelemetryEvents([fixture]);
    expect(warnings.length).toBe(0);
    expect(events.length).toBe(6);
    expect(events.filter((entry) => entry.event === "ui.typingDrill.menuQuickstart").length).toBe(
      2
    );
  });

  it("summarizes quickstarts and builds markdown", () => {
    const events = [
      {
        event: "ui.typingDrill.menuQuickstart",
        payload: { mode: "burst", hadRecommendation: true, reason: "accuracyDip" },
        timestamp: 1000
      },
      {
        event: "typing-drill.started",
        payload: { mode: "burst", source: "menu" },
        timestamp: 1100
      },
      {
        event: "typing-drill.started",
        payload: { mode: "endurance", source: "cta" },
        timestamp: 1200
      },
      {
        event: "ui.typingDrill.menuQuickstart",
        payload: { mode: "burst", hadRecommendation: false, reason: "fallback" },
        timestamp: 2000
      },
      {
        event: "typing-drill.started",
        payload: { mode: "burst", source: "menu" },
        timestamp: 2100
      }
    ];
    const summary = summarizeTelemetry(events, { recentLimit: 3 });
    expect(summary.totals.drillStarts).toBe(3);
    expect(summary.menuQuickstart.count).toBe(2);
    expect(summary.menuQuickstart.recommended).toBe(1);
    expect(summary.menuQuickstart.menuStartShare).toBeCloseTo(1);
    expect(summary.menuQuickstart.recommendedRate).toBeCloseTo(0.5);
    expect(summary.menuQuickstart.fallbackRate).toBeCloseTo(0.5);
    const markdown = formatMarkdown(summary);
    expect(markdown).toContain("Menu quickstarts: 2");
    expect(markdown).toContain("| Timestamp | Mode | Recommendation | Reason |");
  });
});
