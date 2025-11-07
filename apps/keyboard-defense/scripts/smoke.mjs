#!/usr/bin/env node
/**
 * Smoke test orchestrator.
 * Calls the tutorial smoke CLI in skip mode and stores a run artifact.
 */

import { spawn } from "node:child_process";
import { mkdir, writeFile, readFile } from "node:fs/promises";
import path from "node:path";
import process from "node:process";

const startedAt = new Date().toISOString();
const DASHBOARD_PERCENTILES = [25, 50, 90];
const DASHBOARD_PERCENTILES_ARG = DASHBOARD_PERCENTILES.join(",");
const DASHBOARD_PERCENTILES = "25,50,90";

export function parseArgs(argv) {
  const opts = { ci: false, mode: "skip" };
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (token === "--ci") {
      opts.ci = true;
    } else if (token === "--mode") {
      const next = argv[i + 1];
      if (next) {
        opts.mode = next;
        i += 1;
      }
    }
  }
  return opts;
}

async function run(command, args, options = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      stdio: "inherit",
      shell: options.shell ?? process.platform === "win32",
      ...options
    });
    child.on("error", reject);
    child.on("exit", (code) => {
      if (code === 0) resolve();
      else reject(new Error(`${command} ${args.join(" ")} exited with code ${code}`));
    });
  });
}

export async function validateSummaryPercentiles(summaryPath, expected) {
  let payload;
  try {
    const content = await readFile(summaryPath, "utf8");
    payload = JSON.parse(content);
  } catch (error) {
    throw new Error(
      `Failed to parse gold summary at ${summaryPath}: ${
        error instanceof Error ? error.message : String(error)
      }`
    );
  }
  if (!payload || typeof payload !== "object" || !Array.isArray(payload.percentiles)) {
    throw new Error(`Gold summary at ${summaryPath} is missing the percentiles metadata.`);
  }
  const normalized = payload.percentiles.map((value) => Number(value));
  const mismatch =
    normalized.length !== expected.length ||
    normalized.some((value, index) => value !== expected[index]);
  if (mismatch) {
    throw new Error(
      `Expected percentiles ${expected.join(",")} but found ${normalized.join(",")} in ${summaryPath}.`
    );
  }
  return normalized;
}

async function generateGoldEconomyArtifacts(inputPath, artifactDir, summary, ciMode) {
  const timelineName = ciMode ? "gold-timeline.ci.json" : "gold-timeline.json";
  const timelinePath = path.join(artifactDir, timelineName);
  summary.commands.push(
    `${process.execPath} ./scripts/goldTimeline.mjs --merge-passives --passive-window 8 --out ${timelinePath} ${inputPath}`
  );
  try {
    await run(
      process.execPath,
      [
        "./scripts/goldTimeline.mjs",
        "--merge-passives",
        "--passive-window",
        "8",
        "--out",
        timelinePath,
        inputPath
      ],
      {
        shell: false
      }
    );
    summary.goldTimeline = timelinePath;
  } catch (error) {
    summary.status = summary.status === "failed" ? summary.status : "warning";
    summary.goldTimelineError = error instanceof Error ? error.message : String(error);
    return;
  }

  const summaryName = ciMode ? "gold-summary.ci.json" : "gold-summary.json";
  const summaryPath = path.join(artifactDir, summaryName);
  summary.commands.push(
    `${process.execPath} ./scripts/goldSummary.mjs --global --percentiles ${DASHBOARD_PERCENTILES_ARG} --out ${summaryPath} ${timelinePath}`
  );
  try {
    await run(
      process.execPath,
      [
        "./scripts/goldSummary.mjs",
        "--global",
        "--percentiles",
        DASHBOARD_PERCENTILES_ARG,
        "--out",
        summaryPath,
        timelinePath
      ],
      { shell: false }
    );
    summary.goldSummary = summaryPath;
    if (path.extname(summaryPath).toLowerCase() === ".json") {
      await validateSummaryPercentiles(summaryPath, DASHBOARD_PERCENTILES);
    }
  } catch (error) {
    summary.status = summary.status === "failed" ? summary.status : "warning";
    summary.goldSummaryError = error instanceof Error ? error.message : String(error);
  }
}

async function main() {
  const opts = parseArgs(process.argv.slice(2));
  const artifactDir = path.resolve("artifacts", "smoke");
  await mkdir(artifactDir, { recursive: true });

  const summary = {
    status: "success",
    startedAt,
    finishedAt: null,
    mode: opts.mode,
    artifact: null,
    commands: []
  };

  const smokeArtifactPath = path.resolve("smoke-artifacts", "tutorial-smoke.json");
  let serverStarted = false;

  try {
    summary.commands.push(`${process.execPath} ./scripts/startMonitored.mjs`);
    await run(process.execPath, ["./scripts/startMonitored.mjs"], { shell: false });
    serverStarted = true;

    summary.commands.push(`${process.execPath} ./scripts/tutorialSmoke.mjs --mode ${opts.mode}`);
    await run(process.execPath, ["./scripts/tutorialSmoke.mjs", "--mode", opts.mode], {
      shell: false
    });
    summary.artifact = smokeArtifactPath;
    await generateGoldEconomyArtifacts(smokeArtifactPath, artifactDir, summary, opts.ci);
    if (opts.ci) {
      try {
        const payload = await readFile(smokeArtifactPath, "utf8");
        await writeFile(path.join(artifactDir, "smoke-payload.json"), payload, "utf8");
      } catch (readError) {
        summary.status = "warning";
        summary.note = "Smoke run succeeded but artifact could not be copied.";
        summary.error = readError instanceof Error ? readError.message : String(readError);
      }
    }
  } catch (error) {
    summary.status = "failed";
    summary.error = error instanceof Error ? error.message : String(error);
  } finally {
    if (serverStarted) {
      summary.commands.push(`${process.execPath} ./scripts/devServer.mjs stop`);
      try {
        await run(process.execPath, ["./scripts/devServer.mjs", "stop"], { shell: false });
      } catch (stopError) {
        summary.status = summary.status === "failed" ? summary.status : "warning";
        summary.stopError = stopError instanceof Error ? stopError.message : String(stopError);
      }
    }

    summary.finishedAt = new Date().toISOString();
    const summaryPath = path.join(
      artifactDir,
      opts.ci ? "smoke-summary.ci.json" : "smoke-summary.json"
    );
    await writeFile(summaryPath, JSON.stringify(summary, null, 2), "utf8");
    if (summary.status === "failed") {
      process.exitCode = 1;
    }
  }
}

if (
  import.meta.url === `file://${process.argv[1]}` ||
  process.argv[1]?.endsWith("smoke.mjs")
) {
  await main();
}
