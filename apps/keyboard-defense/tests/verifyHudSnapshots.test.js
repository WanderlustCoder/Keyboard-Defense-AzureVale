import { test, expect } from "vitest";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  validateEntry,
  summarizeResults,
  loadMetadata
} from "../scripts/docs/verifyHudSnapshots.mjs";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../..");
const fixtureDir = path.join(repoRoot, "docs/codex_pack/fixtures/ui-snapshot");

test("validateEntry passes for codex fixture metadata", async () => {
  const file = path.join(fixtureDir, "hud-main.meta.json");
  const data = await loadMetadata(file);
  const result = validateEntry(data, file);
  expect(result.errors).toHaveLength(0);
});

test("validateEntry reports missing diagnostics collapsed sections", () => {
  const result = validateEntry(
    {
      id: "broken",
      badges: ["diagnostics:condensed"],
      uiSnapshot: {
        diagnostics: { condensed: true },
        preferences: { diagnosticsSectionsUpdatedAt: "2025-01-01T00:00:00.000Z" }
      }
    },
    "broken.meta.json"
  );
  expect(result.errors).toEqual(
    expect.arrayContaining([
      "uiSnapshot.diagnostics.collapsedSections missing or empty.",
      "uiSnapshot.preferences.diagnosticsSections missing or empty."
    ])
  );
});

test("summarizeResults groups failures", () => {
  const summary = summarizeResults([
    { file: "a", id: "a", errors: [] },
    { file: "b", id: "b", errors: ["oops"] }
  ]);
  expect(summary.total).toBe(2);
  expect(summary.failures).toHaveLength(1);
});
