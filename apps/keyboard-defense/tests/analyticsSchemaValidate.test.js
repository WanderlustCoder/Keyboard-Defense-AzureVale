import { test, expect } from "vitest";
import { fileURLToPath } from "node:url";
import path from "node:path";
import {
  collectFiles,
  loadSchema,
  createValidator,
  validateFile,
  summarizeResults,
  renderMarkdownReport
} from "../scripts/analytics/validate-schema.mjs";

const REPO_ROOT = fileURLToPath(new URL("../../..", import.meta.url));
const FIXTURE_DIR = path.join(REPO_ROOT, "docs/codex_pack/fixtures/analytics");
const VALID = path.join(FIXTURE_DIR, "valid.snapshot.json");
const INVALID = path.join(FIXTURE_DIR, "invalid.snapshot.json");
const SCHEMA_PATH = path.join(
  REPO_ROOT,
  "apps/keyboard-defense/schemas/analytics.schema.json"
);

test("validate-schema accepts valid fixture", async () => {
  const schema = await loadSchema(SCHEMA_PATH);
  const validate = createValidator(schema);
  const result = await validateFile(VALID, validate);
  expect(result.valid).toBe(true);
  expect(result.errors).toHaveLength(0);
});

test("validate-schema rejects invalid fixture", async () => {
  const schema = await loadSchema(SCHEMA_PATH);
  const validate = createValidator(schema);
  const result = await validateFile(INVALID, validate);
  expect(result.valid).toBe(false);
  expect(result.errors.length).toBeGreaterThan(0);
});

test("collectFiles discovers JSON documents", async () => {
  const files = await collectFiles([FIXTURE_DIR]);
  expect(files).toEqual(expect.arrayContaining([VALID, INVALID]));
});

test("renderMarkdownReport lists pass/fail counts", () => {
  const sampleResults = [
    { file: VALID, valid: true, errors: [] },
    {
      file: INVALID,
      valid: false,
      errors: [{ message: "required property", instancePath: "/wave", schemaPath: "#/required" }]
    }
  ];
  const summary = summarizeResults(sampleResults);
  const markdown = renderMarkdownReport(sampleResults, {
    summary,
    generatedAt: "2025-11-13T00:00:00.000Z",
    schema: SCHEMA_PATH,
    gitSha: "deadbeef",
    mode: "fail",
    baseDir: REPO_ROOT
  });
  expect(markdown).toContain("Analytics Schema Validation");
  expect(markdown).toContain("deadbeef");
  expect(markdown).toContain("❌ Fail");
  expect(markdown).toContain("/wave required property");
});
