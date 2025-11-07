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

function parseArgs(argv) {
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

async function generateGoldTimeline(inputPath, artifactDir, summary, ciMode) {
  const outputName = ciMode ? "gold-timeline.ci.json" : "gold-timeline.json";
  const destination = path.join(artifactDir, outputName);
  summary.commands.push(
    `${process.execPath} ./scripts/goldTimeline.mjs --merge-passives --passive-window 8 --out ${destination} ${inputPath}`
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
        destination,
        inputPath
      ],
      {
        shell: false
      }
    );
    summary.goldTimeline = destination;
  } catch (error) {
    summary.status = summary.status === "failed" ? summary.status : "warning";
    summary.goldTimelineError = error instanceof Error ? error.message : String(error);
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
    await generateGoldTimeline(smokeArtifactPath, artifactDir, summary, opts.ci);
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

await main();
