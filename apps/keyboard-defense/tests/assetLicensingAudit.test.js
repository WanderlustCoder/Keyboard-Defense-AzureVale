import { describe, expect, test } from "vitest";

import { validateAssetLicenses } from "../scripts/assetLicensing.mjs";

describe("asset licensing manifest", () => {
  test("every shipped asset is covered by docs/asset_licensing_manifest.json", async () => {
    const summary = await validateAssetLicenses();
    expect(summary.status).toBe("pass");
    expect(summary.missing).toEqual([]);
    expect(summary.stale).toEqual([]);
    expect(summary.errors).toEqual([]);
  });
});

