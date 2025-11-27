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

function withEnv(overrides, callback) {
  const backup = {};
  for (const key of Object.keys(overrides)) {
    backup[key] = process.env[key];
    const value = overrides[key];
    if (typeof value === "undefined") {
      delete process.env[key];
    } else {
      process.env[key] = value;
    }
  }
  try {
    return callback();
  } finally {
    for (const [key, value] of Object.entries(backup)) {
      if (typeof value === "undefined") {
        delete process.env[key];
      } else {
        process.env[key] = value;
      }
    }
  }
}

test("parseArgs resolves defaults and flags", () => {
  const options = withEnv(
    { CI: undefined, ASSET_INTEGRITY_SCENARIO: undefined, ASSET_INTEGRITY_HISTORY: undefined },
    () =>
      parseArgs([
        "--manifest",
        "./public/assets/manifest.json",
        "--assets",
        "./public/assets",
        "--check"
      ])
  );
  assert.equal(options.manifest.endsWith(path.normalize("public/assets/manifest.json")), true);
  assert.equal(options.assetsDir.endsWith(path.normalize("public/assets")), true);
  assert.equal(options.check, true);
  assert.equal(options.scenario, "local");
  assert.equal(options.history, null);
});

test("parseArgs honors scenario/history overrides", () => {
  const options = withEnv(
    {
      CI: "1",
      ASSET_INTEGRITY_SCENARIO: "tutorial-smoke",
      ASSET_INTEGRITY_HISTORY: "./artifacts/history/asset-integrity-ci.log"
    },
    () =>
      parseArgs([
        "--manifest",
        "./public/assets/manifest.json",
        "--assets",
        "./public/assets",
        "--history",
        "./temp/history.log",
        "--scenario",
        "manual-run"
      ])
  );
  assert.equal(options.scenario, "manual-run");
  assert.equal(options.history.endsWith(path.normalize("temp/history.log")), true);
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
      help: false,
      mode: "off",
      telemetry: null,
      telemetryMarkdown: null,
      history: null,
      scenario: "unit-test"
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
  const historyPath = path.join(dir, "history", "asset-integrity.log");

  try {
    const exitCode = await runAssetIntegrity({
      manifest: manifestPath,
      assetsDir,
      check: true,
      help: false,
      mode: "soft",
      telemetry: null,
      telemetryMarkdown: null,
      history: historyPath,
      scenario: "test-suite"
    });
    assert.equal(exitCode, 1);
    const history = await fs.readFile(historyPath, "utf8");
    const lines = history.trim().split("\n");
    assert.equal(lines.length, 1);
    const entry = JSON.parse(lines[0]);
    assert.equal(entry.scenario, "test-suite");
    assert.equal(entry.failed, 1);
  } finally {
    await fs.rm(dir, { recursive: true, force: true });
  }
});
