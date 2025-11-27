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
  assert.deepEqual(parsed.percentiles, [50, 90]);
});

test("parseArgs accepts custom percentiles", () => {
  const parsed = parseArgs(["--percentiles", "25, 75,90", "foo.json"]);
  assert.deepEqual(parsed.percentiles, [25, 75, 90]);
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
  assert.equal(summary.medianGain, 35);
  assert.equal(summary.p90Gain, 39);
  assert.equal(summary.medianSpend, -50);
  assert.equal(summary.p90Spend, -50);
  assert.equal(summary.gainP50, 35);
  assert.equal(summary.spendP50, -50);
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

test("summarizeFileEntries yields null percentile stats when no events", () => {
  const summary = summarizeFileEntries("empty.json", []);
  assert.equal(summary.medianGain, null);
  assert.equal(summary.p90Gain, null);
  assert.equal(summary.medianSpend, null);
  assert.equal(summary.p90Spend, null);
  assert.equal(summary.gainP50, null);
  assert.equal(summary.spendP50, null);
});

test("summarizeFileEntries tracks starfield averages and tint", () => {
  const summary = summarizeFileEntries("starfield.json", [
    { starfield: { depth: 1.2, driftMultiplier: 1.05, waveProgress: 0.4, castleHealthRatio: 0.8, tint: "#222222" } },
    { starfield: { depth: 1.5, driftMultiplier: 1.25, waveProgress: 0.65, castleHealthRatio: 0.6, tint: "#00ffcc" } },
    {}
  ]);
  assert.equal(summary.starfieldDepth, 1.35);
  assert.equal(summary.starfieldDrift, 1.15);
  assert.equal(summary.starfieldWaveProgress, 52.5);
  assert.equal(summary.starfieldCastleRatio, 70);
  assert.equal(summary.starfieldTint, "#00ffcc");
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
    assert.match(
      csv,
      /file,eventCount,netDelta,maxGain,maxSpend,totalPositive,totalNegative,firstTimestamp,lastTimestamp,passiveLinkedCount,uniquePassiveIds,gainP50,spendP50,gainP90,spendP90,medianGain,p90Gain,medianSpend,p90Spend,maxPassiveLag,starfieldDepth,starfieldDrift,starfieldTint,starfieldWaveProgress,starfieldCastleRatio,summaryPercentiles/
    );
    assert.match(csv, /sample,2,-10/);
    assert.match(csv, /summaryPercentiles/);
    assert.match(csv, /50\|90/);
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
    const payload = JSON.parse(await fs.readFile(outPath, "utf8"));
    assert.deepEqual(payload.percentiles, [50, 90]);
    const rows = payload.rows;
    assert.equal(rows.length, 2);
    const globalRow = rows.find((row) => row.file === "ALL");
    assert.ok(globalRow, "expected global row");
    assert.equal(globalRow.netDelta, -15);
    assert.equal(globalRow.medianGain, 25);
    assert.equal(globalRow.medianSpend, -40);
  } finally {
    await fs.rm(dir, { recursive: true, force: true });
  }
});

test("runGoldSummary honors custom percentiles", async () => {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), "gold-summary-pcts-"));
  try {
    const timeline = [
      { file: "sample", eventIndex: 0, gold: 100, delta: 25, timestamp: 5 },
      { file: "sample", eventIndex: 1, gold: 60, delta: -40, timestamp: 15 },
      { file: "sample", eventIndex: 2, gold: 110, delta: 50, timestamp: 30 }
    ];
    const file = path.join(dir, "timeline.json");
    await fs.writeFile(file, JSON.stringify(timeline, null, 2), "utf8");
    const outPath = path.join(dir, "summary.json");
    await runGoldSummary({
      csv: false,
      out: outPath,
      help: false,
      global: false,
      percentiles: [25, 75, 95],
      targets: [file]
    });
    const payload = JSON.parse(await fs.readFile(outPath, "utf8"));
    assert.deepEqual(payload.percentiles, [25, 75, 95]);
    const [row] = payload.rows;
    assert.equal(row.gainP25, 31.25);
    assert.equal(row.gainP75, 43.75);
    assert.equal(row.gainP95, 48.75);
    assert.equal(row.spendP25, -40);
  } finally {
    await fs.rm(dir, { recursive: true, force: true });
  }
});
