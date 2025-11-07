import { test } from "vitest";
import assert from "node:assert/strict";
import os from "node:os";
import path from "node:path";
import { promises as fs } from "node:fs";

import { validateSummaryPercentiles } from "../scripts/smoke.mjs";

async function createTempSummary(data) {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), "smoke-summary-"));
  const file = path.join(dir, "summary.json");
  await fs.writeFile(file, JSON.stringify(data, null, 2), "utf8");
  return { dir, file };
}

test("validateSummaryPercentiles resolves when metadata matches", async () => {
  const { dir, file } = await createTempSummary({ percentiles: [25, 50, 90], rows: [] });
  try {
    const result = await validateSummaryPercentiles(file, [25, 50, 90]);
    assert.deepEqual(result, [25, 50, 90]);
  } finally {
    await fs.rm(dir, { recursive: true, force: true });
  }
});

test("validateSummaryPercentiles rejects when metadata missing", async () => {
  const { dir, file } = await createTempSummary({ rows: [] });
  try {
    await assert.rejects(
      () => validateSummaryPercentiles(file, [25, 50, 90]),
      /missing the percentiles metadata/
    );
  } finally {
    await fs.rm(dir, { recursive: true, force: true });
  }
});

test("validateSummaryPercentiles rejects when metadata differs", async () => {
  const { dir, file } = await createTempSummary({ percentiles: [50, 90], rows: [] });
  try {
    await assert.rejects(
      () => validateSummaryPercentiles(file, [25, 50, 90]),
      /Expected percentiles/
    );
  } finally {
    await fs.rm(dir, { recursive: true, force: true });
  }
});
