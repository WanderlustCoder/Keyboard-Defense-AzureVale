import { describe, expect, test } from "vitest";
import fs from "node:fs/promises";
import path from "node:path";
import os from "node:os";

import {
  generateManifest,
  verifyManifest
} from "../scripts/assets/generateManifest.mjs";

const PNG_1X1_BASE64 =
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9YwH3YsAAAAASUVORK5CYII=";

async function writePng(filePath) {
  const buffer = Buffer.from(PNG_1X1_BASE64, "base64");
  await fs.mkdir(path.dirname(filePath), { recursive: true });
  await fs.writeFile(filePath, buffer);
}

describe("generateManifest", () => {
  test("creates manifest with images and integrity hashes and verifies ok", async () => {
    const tmp = await fs.mkdtemp(path.join(os.tmpdir(), "manifest-test-"));
    const spriteA = path.join(tmp, "alpha.png");
    const spriteB = path.join(tmp, "nested", "beta.png");
    await writePng(spriteA);
    await writePng(spriteB);

    const outPath = path.join(tmp, "manifest.json");
    const result = await generateManifest({
      sourceDir: tmp,
      outPath,
      version: "test-version"
    });

    expect(result.files).toBe(2);
    const manifest = JSON.parse(await fs.readFile(outPath, "utf8"));
    expect(manifest.version).toBe("test-version");
    expect(manifest.images).toEqual({
      alpha: "alpha.png",
      beta: "nested/beta.png"
    });
    expect(manifest.integrity.alpha).toMatch(/^sha256-/);
    expect(manifest.integrity.beta).toMatch(/^sha256-/);

    const verify = await verifyManifest({ manifestPath: outPath });
    expect(verify.ok).toBe(true);
    expect(verify.total).toBe(2);

    // Corrupt a sprite and expect verify to fail.
    await fs.appendFile(spriteA, Buffer.from([0]));
    await expect(() => verifyManifest({ manifestPath: outPath })).rejects.toThrow(
      /mismatches/i
    );
  });
});
