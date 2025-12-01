import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { describe, expect, test } from "vitest";

import { parseArgs, summarizeLogs } from "../scripts/ci/runtimeLogSummary.mjs";

const write = (file, content) => fs.writeFile(file, content, "utf8");

describe("runtimeLogSummary", () => {
  test("parseArgs applies defaults and custom overrides", () => {
    const parsed = parseArgs(["--input", "logs/*.txt", "--out-json", "tmp/out.json", "--no-md"]);
    expect(parsed.inputs).toContain("logs/*.txt");
    expect(parsed.outJson).toBe("tmp/out.json");
    expect(parsed.outMarkdown).toBeNull();
  });

  test("summarizeLogs aggregates breaches, accuracy, warnings, and errors", async () => {
    const tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), "runtime-log-summary-"));
    const jsonLog = path.join(tmpDir, "events.json");
    const textLog = path.join(tmpDir, "events.log");

    await write(
      jsonLog,
      JSON.stringify([
        { accuracy: 0.91, breaches: 1 },
        { analytics: { sessionBreaches: 3, sessionAccuracy: 0.88 } }
      ])
    );

    await write(
      textLog,
      [
        "WARN: spike detected breach=2 accuracy=0.75",
        "ERROR: breach=1 accuracy=0.55",
        "info line"
      ].join("\n")
    );

    const summary = await summarizeLogs([jsonLog, textLog]);
    expect(summary.files.length).toBe(2);
    expect(summary.events).toBe(4);
    expect(summary.breaches.sum).toBe(7);
    expect(summary.breaches.max).toBe(3);
    expect(summary.accuracy.last).toBe(0.55);
    expect(summary.warnings).toBe(1);
    expect(summary.errors).toBe(1);
  });
});
