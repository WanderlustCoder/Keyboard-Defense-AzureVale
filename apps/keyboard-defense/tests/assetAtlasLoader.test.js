import { describe, expect, test, vi, afterEach } from "vitest";

import { AssetLoader } from "../public/dist/src/assets/assetLoader.js";

const originalFetch = global.fetch;

afterEach(() => {
  global.fetch = originalFetch;
  vi.restoreAllMocks();
});

describe("asset atlas loader", () => {
  test("drawFrame uses atlas frames when loaded", async () => {
    const loader = new AssetLoader({ useAtlas: true });
    const atlasJson = {
      frames: {
        "enemy-grunt": {
          frame: { x: 0, y: 0, w: 32, h: 32 }
        }
      },
      image: "atlas.png"
    };
    global.fetch = vi.fn().mockResolvedValueOnce({
      ok: true,
      status: 200,
      json: async () => atlasJson
    });
    loader.loadAtlasImage = vi.fn().mockResolvedValue({ id: "atlas-image" });

    await loader.loadAtlas("http://game/assets/atlas.json");

    const ctx = { drawImage: vi.fn() };
    const drawn = loader.drawFrame(ctx, "enemy-grunt", 1, 2, 64, 64);

    expect(drawn).toBe(true);
    expect(ctx.drawImage).toHaveBeenCalledWith({ id: "atlas-image" }, 0, 0, 32, 32, 1, 2, 64, 64);
  });

  test("loadManifest skips atlas-backed keys", async () => {
    const loader = new AssetLoader({ integrityMode: "off" });
    loader.atlas = { image: {}, frames: { alpha: { x: 0, y: 0, w: 16, h: 16 } } };
    const manifest = {
      images: { alpha: "alpha.png", beta: "beta.png" }
    };

    const loads = [];
    global.fetch = vi.fn().mockResolvedValueOnce({
      ok: true,
      status: 200,
      json: async () => manifest
    });
    loader.loadImageElement = vi.fn(async (key, url) => {
      loads.push({ key, url });
      loader.imageCache.set(key, url);
    });

    await loader.loadManifest("http://game/assets/manifest.json", { skip: new Set(["alpha"]) });

    expect(loads.map((entry) => entry.key)).toEqual(["beta"]);
  });
});
