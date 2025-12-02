import { describe, expect, test } from "vitest";
import fs from "node:fs/promises";
import path from "node:path";
import os from "node:os";

import { buildAtlas, packSprites } from "../scripts/assets/buildAtlas.mjs";

const PNG_1X1_BASE64 =
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9YwH3YsAAAAASUVORK5CYII=";

async function writePng(filePath) {
  const buffer = Buffer.from(PNG_1X1_BASE64, "base64");
  await fs.mkdir(path.dirname(filePath), { recursive: true });
  await fs.writeFile(filePath, buffer);
}

describe("buildAtlas", () => {
  test("packs sprites into rows with wrap and writes atlas JSON", async () => {
    const tmp = await fs.mkdtemp(path.join(os.tmpdir(), "atlas-test-"));
    const a = path.join(tmp, "a.png");
    const b = path.join(tmp, "b.png");
    const c = path.join(tmp, "nested", "c.png");
    await writePng(a);
    await writePng(b);
    await writePng(c);

    const outPath = path.join(tmp, "atlas.json");
    const result = await buildAtlas({
      sourceDir: tmp,
      outPath,
      atlasName: "test-atlas",
      tileSize: 32,
      maxSize: 64,
      dryRun: false
    });

    expect(result.files).toBe(3);
    const atlas = JSON.parse(await fs.readFile(outPath, "utf8"));
    expect(atlas.atlas).toBe("test-atlas");
    expect(Object.keys(atlas.frames)).toEqual(["a", "b", "c"]);
    expect(atlas.frames.a.frame).toEqual({ x: 0, y: 0, w: 32, h: 32 });
    expect(atlas.frames.b.frame).toEqual({ x: 32, y: 0, w: 32, h: 32 });
    // Third sprite wraps to next row.
    expect(atlas.frames.c.frame).toEqual({ x: 0, y: 32, w: 32, h: 32 });
  });
});

describe("packSprites", () => {
  test("wraps when exceeding max width", () => {
    const files = ["one.png", "two.png", "three.png"];
    const frames = packSprites(files, { tileSize: 50, maxSize: 100 });
    expect(frames.one.frame).toEqual({ x: 0, y: 0, w: 50, h: 50 });
    expect(frames.two.frame).toEqual({ x: 50, y: 0, w: 50, h: 50 });
    expect(frames.three.frame).toEqual({ x: 0, y: 50, w: 50, h: 50 });
  });
});
