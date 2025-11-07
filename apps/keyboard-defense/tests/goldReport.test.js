import { test } from "vitest";
import assert from "node:assert/strict";
import path from "node:path";

import { parseArgs, runGoldReport } from "../scripts/goldReport.mjs";

test("parseArgs captures defaults and overrides", () => {
  const parsed = parseArgs([
    "--timeline-out",
    "out/timeline.json",
    "--summary-out",
    "out/summary.csv",
    "--summary-csv",
    "--no-merge-passives",
    "--passive-window",
    "3",
    "--global",
    "snapshots"
  ]);
  assert.equal(parsed.timelineOut, "out/timeline.json");
  assert.equal(parsed.summaryOut, "out/summary.csv");
  assert.equal(parsed.summaryCsv, true);
  assert.equal(parsed.mergePassives, false);
  assert.equal(parsed.passiveWindow, 3);
  assert.equal(parsed.global, true);
  assert.deepEqual(parsed.targets, ["snapshots"]);
});

test("runGoldReport invokes goldTimeline then goldSummary", async () => {
  const commands = [];
  const fakeRunner = async (cmd, args) => {
    commands.push({ cmd, args });
  };
  const opts = {
    timelineOut: "tmp/timeline.json",
    summaryOut: "tmp/summary.json",
    summaryCsv: false,
    mergePassives: true,
    passiveWindow: 7,
    global: true,
    targets: ["snapshots/sample.json"]
  };
  await runGoldReport(opts, fakeRunner);
  assert.equal(commands.length, 2);
  assert(commands[0].args.includes("./scripts/goldTimeline.mjs"));
  assert(commands[0].args.includes("--merge-passives"));
  assert(commands[0].args.includes("--passive-window"));
  assert(commands[0].args.includes(path.resolve("snapshots/sample.json")));
  assert(commands[1].args.includes("./scripts/goldSummary.mjs"));
  assert(commands[1].args.includes("--global"));
  assert(commands[1].args.includes(path.resolve("tmp/timeline.json")));
});

test("runGoldReport propagates errors from runner", async () => {
  const failingRunner = async () => {
    throw new Error("boom");
  };
  await assert.rejects(
    () =>
      runGoldReport(
        {
          timelineOut: "a",
          summaryOut: "b",
          summaryCsv: false,
          mergePassives: true,
          passiveWindow: 5,
          global: false,
          targets: ["snap.json"]
        },
        failingRunner
      ),
    /boom/
  );
});
