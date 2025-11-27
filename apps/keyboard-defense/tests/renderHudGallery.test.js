import { test, expect } from "vitest";
import path from "node:path";
import os from "node:os";
import { promises as fs } from "node:fs";
import { fileURLToPath } from "node:url";
import {
  loadMetadata,
  buildDoc,
  buildJsonPayload,
  verifyEntries,
  dedupeEntries
} from "../scripts/docs/renderHudGallery.mjs";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../..");
const fixtureDir = path.join(repoRoot, "docs/codex_pack/fixtures/ui-snapshot");

test("buildDoc renders table rows for fixtures", async () => {
  const files = [
    path.join(fixtureDir, "hud-main.meta.json"),
    path.join(fixtureDir, "options-overlay.meta.json")
  ];
  const entries = await loadMetadata(files);
  const doc = buildDoc(entries);
  expect(doc).toContain("hud-main");
  expect(doc).toContain("options-overlay");
});

test("buildJsonPayload mirrors entries", async () => {
  const files = [path.join(fixtureDir, "hud-main.meta.json")];
  const entries = await loadMetadata(files);
  const outputFile = path.join(repoRoot, "docs/hud_gallery.md");
  const json = buildJsonPayload(entries, outputFile);
  expect(json.shots).toHaveLength(1);
  expect(json.shots[0]).toMatchObject({
    id: "hud-main",
    summary: expect.stringContaining("HUD passives collapsed")
  });
});

test("verifyEntries flags missing shots", () => {
  const result = verifyEntries([{ id: "hud-main", badges: ["foo"], summary: "ok" }], [
    "hud-main",
    "wave-scorecard"
  ]);
  expect(result.ok).toBe(false);
  expect(result.messages).toEqual(
    expect.arrayContaining(['Missing required screenshot "wave-scorecard"'])
  );
});

test("loadMetadata captures starfield scene data", async () => {
  const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), "hud-gallery-starfield-"));
  const metaPath = path.join(tempDir, "starfield.meta.json");
  await fs.writeFile(
    metaPath,
    JSON.stringify(
      {
        id: "star-test",
        description: "Starfield breach scene",
        file: "apps/keyboard-defense/artifacts/screenshots/star-test.png",
        badges: ["viewport:default-height", "starfield:breach"],
        uiSnapshot: { compactHeight: false },
        starfieldScene: "breach"
      },
      null,
      2
    ),
    "utf8"
  );
  const entries = await loadMetadata([metaPath]);
  expect(entries[0].starfieldScene).toBe("breach");
  const doc = buildDoc(entries);
  expect(doc).toContain("| Shot | Screenshot | Starfield | Badges | Summary | UI Snapshot |");
  expect(doc).toContain("`breach`");
  const json = buildJsonPayload(entries, path.join(tempDir, "gallery.md"));
  expect(json.shots[0].starfieldScene).toBe("breach");
  await fs.rm(tempDir, { recursive: true, force: true });
});

test("dedupeEntries prefers artifact metadata and preserves all sources", () => {
  const liveMeta = path.join(
    repoRoot,
    "apps",
    "keyboard-defense",
    "artifacts",
    "screenshots",
    "hud-main.meta.json"
  );
  const fixtureMeta = path.join(
    repoRoot,
    "docs",
    "codex_pack",
    "fixtures",
    "ui-snapshot",
    "hud-main.meta.json"
  );
  const entries = dedupeEntries([
    {
      id: "hud-main",
      description: "Live capture",
      image: "apps/keyboard-defense/artifacts/screenshots/hud-main.png",
      badges: ["live"],
      summary: "Live hud",
      uiDetails: "Live hud details",
      starfieldScene: "tutorial",
      metaFile: "apps/keyboard-defense/artifacts/screenshots/hud-main.meta.json",
      metaFiles: ["apps/keyboard-defense/artifacts/screenshots/hud-main.meta.json"],
      sourceAbsolute: liveMeta
    },
    {
      id: "hud-main",
      description: "Fixture",
      image: "docs/codex_pack/fixtures/ui-snapshot/hud-main.png",
      badges: ["fixture"],
      summary: "Fixture hud",
      uiDetails: "Fixture hud details",
      starfieldScene: "tutorial",
      metaFile: "docs/codex_pack/fixtures/ui-snapshot/hud-main.meta.json",
      metaFiles: ["docs/codex_pack/fixtures/ui-snapshot/hud-main.meta.json"],
      sourceAbsolute: fixtureMeta
    }
  ]);
  expect(entries).toHaveLength(1);
  expect(entries[0].image).toBe("apps/keyboard-defense/artifacts/screenshots/hud-main.png");
  expect(entries[0].metaFiles).toEqual(
    expect.arrayContaining([
      "apps/keyboard-defense/artifacts/screenshots/hud-main.meta.json",
      "docs/codex_pack/fixtures/ui-snapshot/hud-main.meta.json"
    ])
  );
});
