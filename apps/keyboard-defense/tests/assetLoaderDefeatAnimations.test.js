import { describe, expect, it } from "vitest";

import { AssetLoader } from "../public/dist/src/assets/assetLoader.js";

describe("AssetLoader defeat animation support", () => {
  it("registers defeat animations and resolves matches with fallbacks", () => {
    const loader = new AssetLoader();
    loader.applyDefeatAnimations([
      {
        id: "default",
        match: ["grunt", "runner"],
        frames: [
          { key: "defeat-grunt-1", durationMs: 90, size: 64, offsetX: 0, offsetY: 0 },
          { key: "defeat-grunt-2", durationMs: 110, size: 72, offsetX: 2, offsetY: -4 }
        ],
        default: true
      },
      {
        id: "brute",
        match: ["brute"],
        fallback: "default",
        frames: []
      }
    ]);

    expect(loader.hasDefeatAnimation("grunt")).toBe(true);
    expect(loader.hasDefeatAnimation("runner")).toBe(true);
    expect(loader.hasDefeatAnimation("witch")).toBe(true);

    const gruntAnimation = loader.getDefeatAnimation("grunt");
    expect(gruntAnimation?.frames).toHaveLength(2);
    expect(gruntAnimation?.frames[0].key).toBe("defeat-grunt-1");

    const bruteAnimation = loader.getDefeatAnimation("brute");
    expect(bruteAnimation?.frames).toHaveLength(2);
    expect(bruteAnimation?.frames[1].durationMs).toBe(110);

    loader.applyDefeatAnimations(null);
    expect(loader.hasDefeatAnimation("grunt")).toBe(false);
  });
});
