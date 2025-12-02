import vm from "node:vm";
import { describe, expect, it } from "vitest";
import { parseHTML } from "linkedom";
import {
  buildHtml,
  deriveTutorialMetrics
} from "../scripts/generateStaticDashboard.mjs";

describe("generateStaticDashboard", () => {
  it("derives tutorial completion metrics from tutorial payload analytics", () => {
    const sources = {
      tutorialPayload: {
        analytics: {
          attemptedRuns: 3,
          completedRuns: 2,
          skippedRuns: 1,
          assistsShown: 4,
          replayedRuns: 1
        }
      }
    };
    const metrics = deriveTutorialMetrics(sources);
    expect(metrics.attemptedRuns).toBe(3);
    expect(metrics.completedRuns).toBe(2);
    expect(metrics.skippedRuns).toBe(1);
    expect(metrics.assistsShown).toBe(4);
    expect(metrics.completionRate).toBeCloseTo(2 / 3);
  });

  it("renders completion rows in tutorial and matrix sections", () => {
    const sources = {
      tutorialPayload: {
        mode: "full",
        status: "success",
        startedAt: "2025-12-07T00:00:00.000Z",
        finishedAt: "2025-12-07T00:00:05.000Z",
        durationMs: 5000,
        analytics: {
          attemptedRuns: 2,
          completedRuns: 1,
          skippedRuns: 0,
          assistsShown: 3
        }
      },
      ciMatrix: {
        tutorialRuns: [
          {
            mode: "full",
            status: "success",
            durationMs: 5000,
            attemptedRuns: 2,
            completedRuns: 1,
            failureReason: null
          }
        ],
        aggregates: {
          tutorialDuration: { p50: 5000, p90: 5000 }
        }
      }
    };
    const payload = {
      generatedAt: "2025-12-07T00:00:00.000Z",
      sources,
      tutorialMetrics: deriveTutorialMetrics(sources)
    };
    const html = buildHtml(payload);
    const scriptMatch = html.match(/<script>([\s\S]*)<\/script>/);
    expect(scriptMatch).toBeTruthy();

    const { document, window } = parseHTML(html);
    vm.runInNewContext(scriptMatch[1], { document, window, console, Date });

    const tutorialText = document.getElementById("tutorial-content").textContent;
    expect(tutorialText).toContain("Completed runs");
    expect(tutorialText).toContain("1/2 (50.0%)");

    const matrixCell =
      document.querySelector("#matrix-section table tbody tr td:nth-child(4)")?.textContent ?? "";
    expect(matrixCell).toContain("1/2 (50.0%)");
  });
});
