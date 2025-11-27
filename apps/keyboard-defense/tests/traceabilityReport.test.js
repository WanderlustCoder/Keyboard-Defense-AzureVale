import { describe, expect, it } from "vitest";
import path from "node:path";
import { fileURLToPath } from "node:url";

import {
  generateTraceabilityReport,
  buildMarkdown
} from "../scripts/ci/traceabilityReport.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const APP_ROOT = path.resolve(__dirname, "..");
const REPO_ROOT = path.resolve(APP_ROOT, "..", "..");

const MANIFEST = path.resolve(REPO_ROOT, "docs", "codex_pack", "manifest.yml");
const TASKS_DIR = path.resolve(REPO_ROOT, "docs", "codex_pack", "tasks");
const BACKLOG = path.resolve(APP_ROOT, "docs", "season1_backlog.md");
const TEST_FIXTURE = path.resolve(
  REPO_ROOT,
  "docs",
  "codex_pack",
  "fixtures",
  "traceability-tests.json"
);

describe("traceabilityReport", () => {
  it("maps backlog entries to tasks and tests", () => {
    const report = generateTraceabilityReport({
      manifest: MANIFEST,
      backlog: BACKLOG,
      tasksDir: TASKS_DIR,
      testReport: TEST_FIXTURE,
      filters: ["#71", "#94"]
    });
    const tutorial = report.backlogItems.find((item) => item.id === "#71");
    expect(tutorial).toBeTruthy();
    expect(tutorial.tasks.map((task) => task.id)).toContain("scenario-matrix");
    expect(tutorial.tests.length).toBeGreaterThan(0);
    expect(tutorial.coverageStatus).toBe("covered");

    const visualDiffs = report.backlogItems.find((item) => item.id === "#94");
    expect(visualDiffs).toBeTruthy();
    expect(visualDiffs.tests.some((test) => test.status === "fail")).toBe(true);
    expect(report.unmappedTests.some((test) => test.path.includes("diagnostics.test.js"))).toBe(
      true
    );
  });

  it("builds markdown summaries", () => {
    const report = generateTraceabilityReport({
      manifest: MANIFEST,
      backlog: BACKLOG,
      tasksDir: TASKS_DIR,
      testReport: TEST_FIXTURE,
      filters: ["#71"]
    });
    const markdown = buildMarkdown(report);
    expect(markdown).toContain("Traceability Report");
    expect(markdown).toContain("| #71 |");
  });
});
