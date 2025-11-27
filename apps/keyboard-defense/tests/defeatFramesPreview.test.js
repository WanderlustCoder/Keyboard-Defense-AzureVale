import { describe, expect, it } from "vitest";

import {
  buildDefeatAnimationReport,
  formatDefeatAnimationMarkdown
} from "../scripts/defeatFramesPreview.mjs";

describe("defeatFramesPreview", () => {
  const sampleAnimations = [
    {
      id: "default",
      frames: [
        { key: "defeat-default-01", durationMs: 80, size: 72, offsetX: 0, offsetY: -4 },
        { key: "defeat-default-02", durationMs: 100, size: 92, offsetX: 1, offsetY: -2 },
        { key: "defeat-default-03", durationMs: 140, size: 104, offsetX: 0, offsetY: 0 }
      ],
      fallback: null,
      loop: false
    },
    {
      id: "brute",
      frames: [],
      fallback: "default",
      loop: false
    }
  ];

  it("summarizes animations and records warnings", () => {
    const report = buildDefeatAnimationReport({
      animations: sampleAnimations,
      source: { path: "fixtures/defeat-animations/sample.json" }
    });

    expect(report.animations).toHaveLength(2);
    const first = report.animations.find((entry) => entry.id === "brute");
    expect(first?.frameCount).toBe(0);
    expect(first?.fallback).toBe("default");
    expect(report.warnings.length).toBeGreaterThan(0);
    expect(report.totals.frames).toBe(3);
  });

  it("renders markdown output", () => {
    const report = buildDefeatAnimationReport({
      animations: sampleAnimations,
      source: { path: "fixtures/defeat-animations/sample.json" }
    });
    const markdown = formatDefeatAnimationMarkdown(report);
    expect(markdown).toContain("Defeat Animation Preview");
    expect(markdown).toContain("default");
    expect(markdown).toContain("Warnings");
  });
});
