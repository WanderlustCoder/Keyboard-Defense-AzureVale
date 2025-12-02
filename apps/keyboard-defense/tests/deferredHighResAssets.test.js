import { describe, expect, test, vi } from "vitest";

import { AssetLoader } from "../public/dist/src/assets/assetLoader.js";

function createFetchStub(manifests) {
  return vi.fn(async (url) => {
    const manifest = manifests[url];
    if (!manifest) {
      return { ok: false, status: 404, json: async () => ({}) };
    }
    return {
      ok: true,
      status: 200,
      json: async () => manifest
    };
  });
}

describe("deferred high-res asset loading", () => {
  test("loads low-res first, invokes ready, then retries high-res with force", async () => {
    const lowUrl = "http://game/assets/low.json";
    const highUrl = "http://game/assets/high.json";
    const fetch = createFetchStub({
      [lowUrl]: { images: { turret: "low/turret.png" } },
      [highUrl]: { images: { turret: "high/turret.png" } }
    });
    const loads = [];
    const loader = new AssetLoader({});
    loader.loadImageElement = vi.fn(async (key, src) => {
      loads.push({ key, src });
      loader.imageCache.set(key, src);
    });
    const ready = vi.fn();
    const originalFetch = global.fetch;
    global.fetch = fetch;
    try {
      await loader.loadWithTiers({ lowRes: lowUrl, highRes: highUrl, onReady: ready });
    } finally {
      global.fetch = originalFetch;
    }
    expect(ready).toHaveBeenCalledTimes(1);
    expect(loads.map((l) => l.src)).toEqual([
      "http://game/assets/low/turret.png",
      "http://game/assets/high/turret.png"
    ]);
    // Cache should hold the high-res since force reload overwrote it.
    expect(loader.imageCache.get("turret")).toBe("http://game/assets/high/turret.png");
  });

  test("high-res failure keeps low-res cached and does not throw", async () => {
    const lowUrl = "http://game/assets/low.json";
    const highUrl = "http://game/assets/high.json";
    const fetch = vi
      .fn()
      .mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => ({ images: { turret: "low/turret.png" } })
      })
      .mockRejectedValueOnce(new Error("network fail"));
    const loads = [];
    const loader = new AssetLoader({});
    loader.loadImageElement = vi.fn(async (key, src) => {
      loads.push(src);
      loader.imageCache.set(key, src);
    });
    const originalFetch = global.fetch;
    global.fetch = fetch;
    try {
      await loader.loadWithTiers({ lowRes: lowUrl, highRes: highUrl });
    } finally {
      global.fetch = originalFetch;
    }
    expect(loads).toEqual(["http://game/assets/low/turret.png"]);
    expect(loader.imageCache.get("turret")).toBe("http://game/assets/low/turret.png");
  });
});
