import { test } from "vitest";
import assert from "node:assert/strict";
import os from "node:os";
import path from "node:path";
import { promises as fs } from "node:fs";

import {
  collectGoldSummaryResults,
  parseArgs,
  runGoldSummaryCheck
} from "../scripts/goldSummaryCheck.mjs";

async function makeTempFile(name, content) {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), "gold-summary-check-"));
  const file = path.join(dir, name);
  await fs.writeFile(file, content, "utf8");
  return { dir, file };
}

test("parseArgs captures default percentiles and targets", () => {
  const args = parseArgs(["artifact.json"]);
  assert.deepEqual(args.percentiles, [25, 50, 90]);
  assert.deepEqual(args.targets, ["artifact.json"]);
});

test("parseArgs applies custom percentiles", () => {
  const args = parseArgs(["--percentiles", "10,90", "artifact.json"]);
  assert.deepEqual(args.percentiles, [10, 90]);
});

test("runGoldSummaryCheck passes for JSON with matching percentiles", async () => {
  const { dir, file } = await makeTempFile(
    "summary.json",
    JSON.stringify({ percentiles: [10, 90], rows: [] }, null, 2)
  );
  try {
    await runGoldSummaryCheck({ percentiles: [10, 90], targets: [file] });
  } finally {
    await fs.rm(dir, { recursive: true, force: true });
  }
});

test("runGoldSummaryCheck fails for JSON missing metadata", async () => {
  const { dir, file } = await makeTempFile("summary.json", JSON.stringify({ rows: [] }, null, 2));
  try {
    await assert.rejects(() => runGoldSummaryCheck({ percentiles: [10, 90], targets: [file] }));
  } finally {
    await fs.rm(dir, { recursive: true, force: true });
  }
});

test("runGoldSummaryCheck passes for CSV with matching column", async () => {
  const csv = ["file,eventCount,summaryPercentiles", "sample,2,10|90", "sample2,3,10|90"].join(
    "\n"
  );
  const { dir, file } = await makeTempFile("summary.csv", csv);
  try {
    await runGoldSummaryCheck({ percentiles: [10, 90], targets: [file] });
  } finally {
    await fs.rm(dir, { recursive: true, force: true });
  }
});

test("runGoldSummaryCheck fails when CSV percentiles mismatch", async () => {
  const csv = ["file,summaryPercentiles", "sample,25|50"].join("\n");
  const { dir, file } = await makeTempFile("summary.csv", csv);
  try {
    await assert.rejects(() => runGoldSummaryCheck({ percentiles: [10, 90], targets: [file] }));
  } finally {
    await fs.rm(dir, { recursive: true, force: true });
  }
});

test("collectGoldSummaryResults returns pass/fail metadata", async () => {
  const { dir, file: goodFile } = await makeTempFile(
    "summary.json",
    JSON.stringify({ percentiles: [25, 50], rows: [] }, null, 2)
  );
  const badFile = path.join(dir, "bad.json");
  await fs.writeFile(badFile, JSON.stringify({ rows: [] }), "utf8");
  try {
    const results = await collectGoldSummaryResults([dir], [25, 50]);
    assert.equal(results.length, 2);
    const success = results.find((entry) => entry.file === goodFile);
    const failure = results.find((entry) => entry.file === badFile);
    assert.ok(success?.ok);
    assert.ok(!failure?.ok);
    assert.match(failure?.error ?? "", /missing percentiles/i);
  } finally {
    await fs.rm(dir, { recursive: true, force: true });
  }
});
