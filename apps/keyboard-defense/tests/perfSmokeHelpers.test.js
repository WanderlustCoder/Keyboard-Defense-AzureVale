import { test } from "vitest";
import assert from "node:assert/strict";

import { parseArgs, summarizeFrames } from "../scripts/ci/perfSmoke.mjs";

test("parseArgs selects CI artifact naming", () => {
  const local = parseArgs([]);
  assert.equal(local.ci, false);
  assert.ok(local.artifact.endsWith("perf-smoke-summary.json"));

  const ci = parseArgs(["--ci"]);
  assert.equal(ci.ci, true);
  assert.ok(ci.artifact.endsWith("perf-smoke-summary.ci.json"));
});

test("parseArgs parses numeric flags and word lists", () => {
  const options = parseArgs([
    "--duration",
    "5000",
    "--delay",
    "12",
    "--cpu-throttle",
    "3",
    "--spawn",
    "7",
    "--words",
    "a,b, c"
  ]);

  assert.equal(options.durationMs, 5000);
  assert.equal(options.delayMs, 12);
  assert.equal(options.cpuThrottle, 3);
  assert.equal(options.spawnCount, 7);
  assert.deepEqual(options.words, ["a", "b", "c"]);
});

test("parseArgs clamps cpu throttle to at least 1", () => {
  const options = parseArgs(["--cpu-throttle", "0"]);
  assert.equal(options.cpuThrottle, 1);
});

test("summarizeFrames reports fps and long-frame buckets", () => {
  const deltas = new Array(60).fill(16.67);
  const summary = summarizeFrames(deltas, 1000);

  assert.equal(summary.frames, 60);
  assert.ok(summary.fps !== null && Math.abs(summary.fps - 60) < 1);
  assert.equal(summary.longFrames.over50, 0);
  assert.equal(summary.longFrames.over100, 0);
});

test("summarizeFrames filters invalid samples and handles missing duration", () => {
  const summary = summarizeFrames([16, Number.NaN, -1, 50], null);
  assert.equal(summary.frames, 2);
  assert.equal(summary.fps, null);
  assert.equal(summary.longFrames.over50, 1);
});

