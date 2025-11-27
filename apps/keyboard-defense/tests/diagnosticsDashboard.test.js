import { test, expect } from "vitest";
import { promises as fs } from "node:fs";
import { fileURLToPath } from "node:url";
import {
  summarizeSnapshot,
  buildMarkdown
} from "../scripts/ci/diagnosticsDashboard.mjs";

const FIXTURE_ANALYTICS = fileURLToPath(
  new URL(
    "../../../docs/codex_pack/fixtures/diagnostics-dashboard/sample.analytics.json",
    import.meta.url
  )
);

test("diagnosticsDashboard summarises gold/passive telemetry", async () => {
  const raw = await fs.readFile(FIXTURE_ANALYTICS, "utf8");
  const snapshot = JSON.parse(raw);
  const options = {
    warnMaxNegativeDelta: -250,
    failPassiveLag: 300,
    recentEventCount: 3,
    mode: "warn"
  };
  const entry = summarizeSnapshot("sample.analytics.json", snapshot, options);
  expect(entry.gold.totalEvents).toBe(5);
  expect(entry.gold.latestEvents).toHaveLength(3);
  expect(entry.passives.timeline).toHaveLength(2);
  expect(entry.alerts).toHaveLength(0);

  const summary = {
    generatedAt: "2025-11-20T00:00:00.000Z",
    mode: "warn",
    status: entry.status,
    entries: [entry]
  };
  const markdown = buildMarkdown(summary);
  expect(markdown).toContain("Diagnostics Dashboard");
  expect(markdown).toContain("Gold Delta");
  expect(markdown).toContain("Passive Unlock Timeline");
  expect(markdown).toContain("sample.analytics");
});
