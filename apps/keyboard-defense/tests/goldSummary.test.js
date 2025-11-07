import { test } from "vitest";
import assert from "node:assert/strict";
import os from "node:os";
import path from "node:path";
import { promises as fs } from "node:fs";

import {
  parseArgs,
  summarizeFileEntries,
  summarizeGoldEntries,
  runGoldSummary
} from "../scripts/goldSummary.mjs";

test("parseArgs captures csv flag and targets", () => {
  const parsed = parseArgs(["--csv", "--out", "summary.csv", "timeline.json"]);
  assert.equal(parsed.csv, true);
  assert.equal(parsed.out, "summary.csv");
  assert.deepEqual(parsed.targets, ["timeline.json"]);
});

test("summarizeFileEntries computes stats", () => {
  const summary = summarizeFileEntries("sample.json", [
    { gold: 200, delta: 30, timestamp: 10 },
    { gold: 150, delta: -50, timestamp: 20, passiveId: "armor", passiveLag: 2 },
    { gold: 190, delta: 40, timestamp: 35 }
  ]);
  assert.equal(summary.eventCount, 3);
  assert.equal(summary.netDelta, 20);
  assert.equal(summary.maxGain, 40);
  assert.equal(summary.maxSpend, -50);
  assert.equal(summary.totalPositive, 70);
  assert.equal(summary.totalNegative, 50);
  assert.equal(summary.firstTimestamp, 10);
  assert.equal(summary.lastTimestamp, 35);
  assert.equal(summary.passiveLinkedCount, 1);
  assert.equal(summary.uniquePassiveIds.length, 1);
  assert.equal(summary.maxPassiveLag, 2);
});

test("summarizeGoldEntries groups by file", () => {
  const summaries = summarizeGoldEntries([
    { file: "a.json", delta: 10, timestamp: 5 },
    { file: "a.json", delta: -5, timestamp: 10 },
    { file: "b.json", delta: 20, timestamp: 1 }
  ]);
  const fileA = summaries.find((row) => row.file.endsWith("a.json"));
  assert.equal(fileA.eventCount, 2);
  assert.equal(fileA.netDelta, 5);
});

test("runGoldSummary writes csv output", async () => {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), "gold-summary-"));
  try {
    const timeline = [
      { file: "sample", eventIndex: 0, gold: 200, delta: 10, timestamp: 5 },
      { file: "sample", eventIndex: 1, gold: 180, delta: -20, timestamp: 10 }
    ];
    const file = path.join(dir, "timeline.json");
    await fs.writeFile(file, JSON.stringify(timeline, null, 2), "utf8");
    const outPath = path.join(dir, "summary.csv");
    const exitCode = await runGoldSummary({
      csv: true,
      out: outPath,
      help: false,
      targets: [file]
    });
    assert.equal(exitCode, 0);
    const csv = await fs.readFile(outPath, "utf8");
    assert.match(csv, /file,eventCount,netDelta/);
    assert.match(csv, /sample,2,-10/);
  } finally {
    await fs.rm(dir, { recursive: true, force: true });
  }
});

test("runGoldSummary appends global summary when requested", async () => {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), "gold-summary-global-"));
  try {
    const timeline = [
      { file: "sample", eventIndex: 0, gold: 100, delta: 25, timestamp: 5 },
      { file: "sample", eventIndex: 1, gold: 60, delta: -40, timestamp: 15 }
    ];
    const file = path.join(dir, "timeline.json");
    await fs.writeFile(file, JSON.stringify(timeline, null, 2), "utf8");
    const outPath = path.join(dir, "summary.json");
    const exitCode = await runGoldSummary({
      csv: false,
      out: outPath,
      help: false,
      global: true,
      targets: [file]
    });
    assert.equal(exitCode, 0);
    const rows = JSON.parse(await fs.readFile(outPath, "utf8"));
    assert.equal(rows.length, 2);
    const globalRow = rows.find((row) => row.file === "ALL");
    assert.ok(globalRow, "expected global row");
    assert.equal(globalRow.netDelta, -15);
  } finally {
    await fs.rm(dir, { recursive: true, force: true });
  }
});
