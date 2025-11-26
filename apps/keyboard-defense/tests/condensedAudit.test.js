import { describe, expect, test } from "vitest";
import path from "node:path";
import { fileURLToPath } from "node:url";

import {
  evaluateMatrix,
  loadMatrix,
  loadSnapshots,
  runCondensedAudit
} from "../scripts/docs/condensedAudit.mjs";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const WORKSPACE_ROOT = path.resolve(__dirname, "..", "..", "..");

const MATRIX_PATH = path.join(
  WORKSPACE_ROOT,
  "docs",
  "codex_pack",
  "fixtures",
  "responsive",
  "condensed-matrix.yml"
);
const META_DIR = path.join(WORKSPACE_ROOT, "docs", "codex_pack", "fixtures", "ui-snapshot");

test("loadMatrix returns panels", async () => {
  const matrix = await loadMatrix(MATRIX_PATH);
  expect(Array.isArray(matrix.panels)).toBe(true);
  expect(matrix.panels.length).toBeGreaterThan(0);
});

test("loadSnapshots collects HUD metadata", async () => {
  const snapshots = await loadSnapshots([META_DIR]);
  expect(snapshots.size).toBeGreaterThan(0);
  expect(snapshots.has("hud-main")).toBe(true);
});

test("runCondensedAudit passes with fixtures", async () => {
  const result = await runCondensedAudit({ matrixPath: MATRIX_PATH, metaDirs: [META_DIR] });
  expect(result.ok).toBe(true);
  expect(result.checks).toBeGreaterThan(0);
});

describe("evaluateMatrix", () => {
  test("reports missing required fields", () => {
  const evaluation = evaluateMatrix(
    { panels: [{ id: "demo", requirements: [] }] },
    new Map([["demo", { id: "demo" }]])
  );
  expect(evaluation.ok).toBe(false);
  expect(evaluation.failures[0].message).toMatch(/missing required fields/i);
});

  test("reports missing snapshot", () => {
    const matrix = {
      panels: [
        {
          id: "demo-panel",
          toggleSelector: "#toggle",
          preferenceKey: "demoPref",
          requirements: [
            {
              snapshot: "missing-shot",
              breakpoint: "desktop",
              expectedState: "expanded",
              assertions: []
            }
          ]
        }
      ]
    };
  const evaluation = evaluateMatrix(matrix, new Map());
  expect(evaluation.ok).toBe(false);
  expect(evaluation.failures[0].message).toMatch(/Missing snapshot/);
});
});
