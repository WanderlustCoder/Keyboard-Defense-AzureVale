import { describe, expect, test } from "vitest";

import { resolveCastlePalette, resolveCastleVisual } from "../src/rendering/castlePalette.ts";
import { defaultConfig } from "../src/core/config.ts";

describe("castle visuals", () => {
  test("returns distinct palettes per castle level", () => {
    const level1 = resolveCastlePalette(defaultConfig, 1);
    const level2 = resolveCastlePalette(defaultConfig, 2);
    const level3 = resolveCastlePalette(defaultConfig, 3);

    expect(level1.fill).not.toBe(level2.fill);
    expect(level2.fill).not.toBe(level3.fill);
    expect(level1.accent).toMatch(/^#/);
  });

  test("falls back to defaults when level missing", () => {
    const palette = resolveCastlePalette(defaultConfig, 99);
    expect(palette.fill).toBeDefined();
    expect(palette.border).toBeDefined();
    expect(palette.accent).toBeDefined();
  });

  test("exposes sprite keys per level for renderer swaps", () => {
    const visual = resolveCastleVisual(defaultConfig, 2);
    expect(visual.spriteKey).toBe("castle-level-2");
    expect(visual.fill).toBeDefined();
  });
});
