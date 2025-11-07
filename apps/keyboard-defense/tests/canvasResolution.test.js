import { describe, it, expect } from "vitest";
import { calculateCanvasResolution } from "../dist/src/utils/canvasResolution.js";

describe("calculateCanvasResolution", () => {
  it("clamps css width to base width when larger", () => {
    const result = calculateCanvasResolution({
      baseWidth: 960,
      baseHeight: 540,
      availableWidth: 1400,
      devicePixelRatio: 1
    });
    expect(result.cssWidth).toBe(960);
    expect(result.renderWidth).toBe(960);
  });

  it("scales render size with device pixel ratio", () => {
    const result = calculateCanvasResolution({
      baseWidth: 960,
      baseHeight: 540,
      availableWidth: 600,
      devicePixelRatio: 2
    });
    expect(result.cssWidth).toBe(600);
    expect(result.renderWidth).toBe(1200);
    expect(result.cssHeight).toBe(Math.round((540 / 960) * 600));
  });

  it("respects minimum width fallback", () => {
    const result = calculateCanvasResolution({
      baseWidth: 960,
      baseHeight: 540,
      availableWidth: 100,
      devicePixelRatio: 1
    });
    expect(result.cssWidth).toBeGreaterThanOrEqual(320);
    expect(result.renderWidth).toBeGreaterThanOrEqual(320);
  });
});
