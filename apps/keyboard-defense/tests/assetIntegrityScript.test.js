import { test } from "vitest";
import assert from "node:assert/strict";
import os from "node:os";
import path from "node:path";
import { promises as fs } from "node:fs";

import {
  parseArgs,
  computeIntegrityForFile,
  runAssetIntegrity
} from "../scripts/assetIntegrity.mjs";

test("parseArgs resolves defaults and flags", () => {
  const options = parseArgs([
    "--manifest",
    "./public/assets/manifest.json",
    "--assets",
    "./public/assets",
    "--check"
  ]);
  assert.equal(options.manifest.endsWith(path.normalize("public/assets/manifest.json")), true);
  assert.equal(options.assetsDir.endsWith(path.normalize("public/assets")), true);
  assert.equal(options.check, true);
});

test("computeIntegrityForFile returns sha256 base64 string", async () => {
  const tmp = await fs.mkdtemp(path.join(os.tmpdir(), "integrity-hash-"));
  try {
    const file = path.join(tmp, "sprite.svg");
    await fs.writeFile(file, "<svg>hash-me</svg>", "utf8");
    const digest = await computeIntegrityForFile(file);
    assert.equal(digest.startsWith("sha256-"), true);
    assert.match(digest, /^sha256-[A-Za-z0-9+/=]+$/);
  } finally {
    await fs.rm(tmp, { recursive: true, force: true });
  }
});

test("runAssetIntegrity updates manifest integrity map", async () => {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), "integrity-write-"));
  const assetsDir = path.join(dir, "public", "assets");
  await fs.mkdir(assetsDir, { recursive: true });
  const manifestPath = path.join(assetsDir, "manifest.json");
  const manifest = {
    version: "1",
    images: {
      hero: "hero.svg",
      foe: "foe.svg"
    }
  };
  await fs.writeFile(manifestPath, JSON.stringify(manifest, null, 2), "utf8");
  await fs.writeFile(path.join(assetsDir, "hero.svg"), "<svg>hero</svg>", "utf8");
  await fs.writeFile(path.join(assetsDir, "foe.svg"), "<svg>foe</svg>", "utf8");

  try {
    const exitCode = await runAssetIntegrity({
      manifest: manifestPath,
      assetsDir,
      check: false,
      help: false
    });
    assert.equal(exitCode, 0);
    const updated = JSON.parse(await fs.readFile(manifestPath, "utf8"));
    assert.ok(updated.integrity);
    assert.equal(Object.keys(updated.integrity).length, 2);
    assert(updated.integrity.hero.startsWith("sha256-"));
    assert(updated.integrity.foe.startsWith("sha256-"));
  } finally {
    await fs.rm(dir, { recursive: true, force: true });
  }
});

test("runAssetIntegrity --check flags mismatched hashes", async () => {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), "integrity-check-"));
  const assetsDir = path.join(dir, "assets");
  await fs.mkdir(assetsDir, { recursive: true });
  const manifestPath = path.join(assetsDir, "manifest.json");
  await fs.writeFile(
    manifestPath,
    JSON.stringify({
      images: { hero: "hero.svg" },
      integrity: { hero: "sha256-invalid" }
    }),
    "utf8"
  );
  await fs.writeFile(path.join(assetsDir, "hero.svg"), "<svg>hero</svg>", "utf8");

  try {
    const exitCode = await runAssetIntegrity({
      manifest: manifestPath,
      assetsDir,
      check: true,
      help: false
    });
    assert.equal(exitCode, 1);
  } finally {
    await fs.rm(dir, { recursive: true, force: true });
  }
});
