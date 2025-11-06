import { test } from "vitest";
import assert from "node:assert/strict";
import { promises as fs } from "node:fs";
import os from "node:os";
import path from "node:path";
import { execFile } from "node:child_process";

import {
  parseArgs,
  buildTimelineEntries,
  runPassiveTimeline
} from "../scripts/passiveTimeline.mjs";

const cliPath = path.resolve("scripts", "passiveTimeline.mjs");

function runCli(args, options = {}) {
  return new Promise((resolve, reject) => {
    execFile("node", [cliPath, ...args], options, (error, stdout, stderr) => {
      if (error) {
        reject(Object.assign(error, { stdout, stderr }));
      } else {
        resolve({ stdout, stderr });
      }
    });
  });
}

test("parseArgs captures flags and targets", () => {
  const args = parseArgs(["--csv", "--out", "out/file.csv", "snapshot.json"]);
  assert.equal(args.csv, true);
  assert.equal(args.out, "out/file.csv");
  assert.deepEqual(args.targets, ["snapshot.json"]);
});

test("buildTimelineEntries maps snapshot unlocks", () => {
  const snapshot = {
    capturedAt: "2025-11-07T00:00:00.000Z",
    status: "victory",
    mode: "campaign",
    wave: { index: 4 },
    analytics: {
      castlePassiveUnlocks: [
        { id: "regen", level: 2, time: 45.2, total: 1.2, delta: 0.4 },
        { id: "gold", level: 3, time: 80.5, total: 0.15, delta: 0.05 }
      ]
    }
  };
  const entries = buildTimelineEntries(snapshot, "/tmp/snap.json");
  assert.equal(entries.length, 2);
  assert.equal(entries[0].id, "regen");
  assert.equal(entries[0].level, 2);
  assert.equal(entries[0].unlockIndex, 0);
  assert.equal(entries[1].id, "gold");
  assert.equal(entries[1].unlockIndex, 1);
  assert.equal(entries[1].mode, "campaign");
  assert.equal(entries[1].file, "/tmp/snap.json");
});

test("runPassiveTimeline writes csv output", async () => {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), "passive-timeline-"));
  try {
    const file = path.join(dir, "snapshot.json");
    const snapshot = {
      capturedAt: "2025-11-07T12:00:00.000Z",
      status: "running",
      analytics: {
        castlePassiveUnlocks: [{ id: "armor", level: 3, time: 120.5, total: 2, delta: 1 }]
      }
    };
    await fs.writeFile(file, JSON.stringify(snapshot), "utf8");
    const outPath = path.join(dir, "timeline.csv");
    const exitCode = await runPassiveTimeline({
      csv: true,
      out: outPath,
      help: false,
      targets: [file]
    });
    assert.equal(exitCode, 0);
    const csv = await fs.readFile(outPath, "utf8");
    assert.match(csv, /file,capturedAt,status/);
    assert.match(csv, /armor/);
  } finally {
    await fs.rm(dir, { recursive: true, force: true });
  }
});

test("CLI emits JSON by default", async () => {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), "passive-cli-"));
  try {
    const file = path.join(dir, "snapshot.json");
    await fs.writeFile(
      file,
      JSON.stringify({
        analytics: {
          castlePassiveUnlocks: [{ id: "regen", total: 1, delta: 0.5, time: 10 }]
        }
      }),
      "utf8"
    );
    const { stdout } = await runCli([file], { cwd: path.resolve("./") });
    const payload = JSON.parse(stdout);
    assert.equal(payload.unlockCount, 1);
    assert.equal(payload.entries[0].id, "regen");
  } finally {
    await fs.rm(dir, { recursive: true, force: true });
  }
});
