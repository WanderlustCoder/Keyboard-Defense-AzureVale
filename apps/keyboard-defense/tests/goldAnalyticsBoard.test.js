import { describe, it, expect } from "vitest";
import {
  buildGoldAnalyticsBoard,
  formatGoldAnalyticsMarkdown
} from "../scripts/ci/goldAnalyticsBoard.mjs";

describe("goldAnalyticsBoard", () => {
  it("builds a scenario board and markdown from inline data", () => {
    const summaryData = {
      generatedAt: "2025-11-20T00:00:00.000Z",
      metrics: {
        netDelta: 175,
        avgMedianGain: 60,
        avgMedianSpend: -35,
        starfield: {
          depthAvg: 1.35,
          driftAvg: 1.15,
          waveProgressAvg: 52.5,
          castleRatioAvg: 70,
          lastTint: "#fbbf24"
        }
      },
      summaries: [
        {
          file: "artifacts/tutorial-skip.summary.json",
          scenario: "tutorial-skip",
          netDelta: 175,
          medianGain: 60,
          medianSpend: -35,
          starfieldDepth: 1.35,
          starfieldDrift: 1.15,
          starfieldWaveProgress: 52.5,
          starfieldCastleRatio: 70,
          starfieldTint: "#fbbf24"
        }
      ]
    };

    const timelineData = {
      generatedAt: "2025-11-20T00:00:01.000Z",
      thresholds: { maxSpendStreak: 5 },
      metrics: {
        netDelta: 40,
        maxSpendStreak: 2,
        latestEvents: [
          {
            delta: -60,
            gold: 120,
            timestamp: 75.2,
            file: "artifacts/tutorial-skip.timeline.json",
            mode: "tutorial-skip",
            scenario: "tutorial-skip",
            passiveId: "gold",
            passiveLevel: 1
          }
        ]
      }
    };

    const passiveData = {
      generatedAt: "2025-11-20T00:00:02.000Z",
      metrics: { maxGapSeconds: 4 },
      totals: { unlocks: 1 },
      unlocks: {
        latest: [
          {
            id: "gold",
            level: 1,
            delta: 0.05,
            time: 78.2,
            goldDelta: 1.15,
            goldLag: 0,
            file: "artifacts/tutorial-skip.passives.json",
            scenario: "tutorial-skip"
          }
        ]
      }
    };

    const guardData = {
      generatedAt: "2025-11-20T00:00:03.000Z",
      totals: { failures: 0, checked: 1 },
      files: [{ file: "artifacts/tutorial-skip.summary.json", ok: true }]
    };

    const alertsData = {
      rows: [{ scenario: "tutorial-skip", status: "pass", file: "alerts.json" }],
      totals: { failures: 0 }
    };

    const board = buildGoldAnalyticsBoard({
      summaryData,
      timelineData,
      passiveData,
      guardData,
      alertsData,
      paths: {
        summary: "artifacts/tutorial-skip.summary.json",
        timeline: "artifacts/tutorial-skip.timeline.json",
        passive: "artifacts/tutorial-skip.passives.json",
        guard: "artifacts/tutorial-skip.guard.json",
        alerts: "artifacts/tutorial-skip.alerts.json",
        outJson: "temp/gold-board.json",
        markdown: "temp/gold-board.md"
      },
      now: new Date("2025-11-20T01:00:00.000Z")
    });

    expect(board.status).toBe("pass");
    expect(board.warnings).toHaveLength(0);
    expect(board.scenarios).toHaveLength(1);

    const tutorial = board.scenarios[0];
    expect(tutorial.id).toBe("tutorial-skip");
    expect(tutorial.summary.netDelta).toBe(175);
    expect(tutorial.summary.starfield?.depth).toBe(1.35);
    expect(tutorial.summary.starfield?.wavePercent).toBe(52.5);
    expect(tutorial.timelineEvents[0].delta).toBe(-60);
    expect(tutorial.passiveUnlocks[0].id).toBe("gold");
    expect(board.guard.failures).toBe(0);
    expect(board.percentileAlerts?.failures).toBe(0);

    const markdown = formatGoldAnalyticsMarkdown(board);
    expect(markdown).toContain("Gold Analytics Board");
    expect(markdown).toContain("tutorial-skip");
    expect(markdown).toMatch(/Starfield avg depth/i);
    expect(markdown).toContain("gold-board.json");
  });
});
