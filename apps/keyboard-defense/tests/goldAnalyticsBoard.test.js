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
          castleRatioAvg: 55,
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
          starfieldCastleRatio: 55,
          starfieldTint: "#fbbf24"
        }
      ]
    };

    const timelineData = {
      generatedAt: "2025-11-20T00:00:01.000Z",
      thresholds: { maxSpendStreak: 5 },
      scenarios: [
        {
          id: "tutorial-skip",
          latestEvents: [
            {
              delta: 5,
              gold: 240,
              timestamp: 90,
              file: "artifacts/tutorial-skip.timeline.json",
              mode: "tutorial-skip",
              scenario: "tutorial-skip"
            },
            {
              delta: -60,
              gold: 120,
              timestamp: 75.2,
              file: "artifacts/tutorial-skip.timeline.json",
              mode: "tutorial-skip",
              scenario: "tutorial-skip",
              passiveId: "gold",
              passiveLevel: 1
            },
            {
              delta: 50,
              gold: 215,
              timestamp: 63.1,
              file: "artifacts/tutorial-skip.timeline.json",
              mode: "tutorial-skip",
              scenario: "tutorial-skip"
            },
            {
              delta: 75,
              gold: 165,
              timestamp: 46.4,
              file: "artifacts/tutorial-skip.timeline.json",
              mode: "tutorial-skip",
              scenario: "tutorial-skip"
            },
            {
              delta: 10,
              gold: 130,
              timestamp: 30.5,
              file: "artifacts/tutorial-skip.timeline.json",
              mode: "tutorial-skip",
              scenario: "tutorial-skip"
            }
          ]
        }
      ],
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
        },
        {
          delta: 50,
          gold: 215,
          timestamp: 63.1,
          file: "artifacts/tutorial-skip.timeline.json",
          mode: "tutorial-skip",
          scenario: "tutorial-skip"
        }
      ],
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
          },
          {
            delta: 50,
            gold: 215,
            timestamp: 63.1,
            file: "artifacts/tutorial-skip.timeline.json",
            mode: "tutorial-skip",
            scenario: "tutorial-skip"
          },
          {
            delta: 75,
            gold: 165,
            timestamp: 46.4,
            file: "artifacts/tutorial-skip.timeline.json",
            mode: "tutorial-skip",
            scenario: "tutorial-skip"
          },
          {
            delta: 10,
            gold: 130,
            timestamp: 30.5,
            file: "artifacts/tutorial-skip.timeline.json",
            mode: "tutorial-skip",
            scenario: "tutorial-skip"
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
      now: new Date("2025-11-20T01:00:00.000Z"),
      starfieldThresholds: { warnCastlePercent: 60, breachCastlePercent: 40 }
    });

    expect(board.status).toBe("pass");
    expect(board.warnings).toHaveLength(0);
    expect(board.scenarios).toHaveLength(1);

    const tutorial = board.scenarios[0];
    expect(tutorial.id).toBe("tutorial-skip");
    expect(tutorial.timelineEvents).toHaveLength(3);
    expect(tutorial.summary.netDelta).toBe(175);
    expect(tutorial.summary.starfield?.depth).toBe(1.35);
    expect(tutorial.summary.starfield?.wavePercent).toBe(52.5);
    expect(tutorial.summary.starfield?.severity).toBe("warn");
    expect(board.summary?.metrics?.starfield?.severity).toBe("warn");
    expect(board.thresholds?.starfield?.warnCastlePercent).toBe(60);
    expect(board.thresholds?.starfield?.breachCastlePercent).toBe(40);
    expect(tutorial.timelineEvents[0].delta).toBe(5);
    expect(tutorial.timelineSparkline).toEqual([
      { delta: 5, timestamp: 90, gold: 240 },
      { delta: -60, timestamp: 75.2, gold: 120 },
      { delta: 50, timestamp: 63.1, gold: 215 },
      { delta: 75, timestamp: 46.4, gold: 165 },
      { delta: 10, timestamp: 30.5, gold: 130 }
    ]);
    expect(tutorial.passiveUnlocks[0].id).toBe("gold");
    expect(board.guard.failures).toBe(0);
    expect(board.percentileAlerts?.failures).toBe(0);

    const markdown = formatGoldAnalyticsMarkdown(board);
    expect(markdown).toContain("Gold Analytics Board");
    expect(markdown).toContain("tutorial-skip");
    expect(markdown).toMatch(/Starfield avg depth/i);
    expect(markdown).toMatch(/\[WARN\].*depth/);
    expect(markdown).toContain("+5@90, -60@75.2, +50@63.1, +75@46.4, +10@30.5 +.-*+=+#+.");
    expect(markdown).toContain("gold-board.json");
  });
});
