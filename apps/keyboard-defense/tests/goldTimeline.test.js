import { test } from "vitest";
import assert from "node:assert/strict";
import os from "node:os";
import path from "node:path";
import { promises as fs } from "node:fs";

import { parseArgs, buildGoldTimelineEntries, runGoldTimeline } from "../scripts/goldTimeline.mjs";

test("parseArgs captures csv flag and targets", () => {
  const parsed = parseArgs(["--csv", "--out", "timeline.csv", "snapshots"]);
  assert.equal(parsed.csv, true);
  assert.equal(parsed.out, "timeline.csv");
  assert.deepEqual(parsed.targets, ["snapshots"]);
});

test("buildGoldTimelineEntries normalizes events", () => {
  const snapshot = {
    capturedAt: "2025-11-08T12:00:00.000Z",
    status: "running",
    mode: "campaign",
    time: 60,
    analytics: {
      goldEvents: [
        { gold: 220, delta: 20, timestamp: 10 },
        { gold: 260, delta: 40, timestamp: 45 }
      ]
    }
  };
  const rows = buildGoldTimelineEntries(snapshot, "/tmp/file.json");
  assert.equal(rows.length, 2);
  assert.equal(rows[0].delta, 20);
  assert.equal(rows[1].timeSince, 15);
});

test("runGoldTimeline writes csv output", async () => {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), "gold-timeline-"));
  try {
    const file = path.join(dir, "snapshot.json");
    await fs.writeFile(
      file,
      JSON.stringify({
        capturedAt: "2025-11-08T00:00:00.000Z",
        analytics: {
          goldEvents: [{ gold: 200, delta: 25, timestamp: 5 }]
        }
      }),
      "utf8"
    );
    const outPath = path.join(dir, "timeline.csv");
    const exitCode = await runGoldTimeline({
      csv: true,
      out: outPath,
      help: false,
      targets: [file]
    });
    assert.equal(exitCode, 0);
    const csv = await fs.readFile(outPath, "utf8");
    assert.match(csv, /file,capturedAt,status,mode/);
    assert.match(csv, /\+?25/);
  } finally {
    await fs.rm(dir, { recursive: true, force: true });
  }
});
