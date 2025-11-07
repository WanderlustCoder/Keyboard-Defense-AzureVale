#!/usr/bin/env node

import { spawn } from "node:child_process";
import path from "node:path";
import process from "node:process";

const DEFAULT_TIMELINE_OUT = "artifacts/gold-timeline.report.json";
const DEFAULT_SUMMARY_OUT = "artifacts/gold-summary.report.json";
const DEFAULT_PASSIVE_WINDOW = 5;
const DEFAULT_SUMMARY_PERCENTILES = "25,50,90";

function printHelp() {
  console.log(`Keyboard Defense gold report orchestrator

Usage:
  node scripts/goldReport.mjs [options] <file-or-directory> [...]

Options:
  --timeline-out <path>   Where to write the gold timeline JSON (default ${DEFAULT_TIMELINE_OUT})
  --summary-out <path>    Where to write the gold summary (JSON by default)
  --summary-csv           Emit the summary as CSV instead of JSON
  --no-merge-passives     Skip attaching passive unlock metadata to the timeline
  --passive-window <secs> Seconds to search for passive unlock near each gold event (default ${DEFAULT_PASSIVE_WINDOW})
  --global                Append an aggregate row to the summary
  --percentiles <list>    Comma-separated percentile cutlines for gain/spend stats (default ${DEFAULT_SUMMARY_PERCENTILES})
  --help                  Show this help message and exit

Description:
  Runs the gold timeline CLI followed by the gold summary CLI so you can produce both artifacts
  with a single command (useful for local dashboards or manual investigations).`);
}

export function parseArgs(argv = []) {
  const options = {
    timelineOut: DEFAULT_TIMELINE_OUT,
    summaryOut: DEFAULT_SUMMARY_OUT,
    summaryCsv: false,
    mergePassives: true,
    passiveWindow: DEFAULT_PASSIVE_WINDOW,
    global: false,
    targets: [],
    percentiles: DEFAULT_SUMMARY_PERCENTILES,
    help: false
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--timeline-out": {
        const value = argv[++i];
        if (!value) throw new Error("Expected path after --timeline-out");
        options.timelineOut = value;
        break;
      }
      case "--summary-out": {
        const value = argv[++i];
        if (!value) throw new Error("Expected path after --summary-out");
        options.summaryOut = value;
        break;
      }
      case "--summary-csv":
        options.summaryCsv = true;
        break;
      case "--no-merge-passives":
        options.mergePassives = false;
        break;
      case "--passive-window": {
        const value = Number.parseFloat(argv[++i] ?? "");
        if (!Number.isFinite(value) || value < 0) {
          throw new Error("Expected --passive-window <seconds> (non-negative number).");
        }
        options.passiveWindow = value;
        break;
      }
      case "--global":
        options.global = true;
        break;
      case "--help":
        options.help = true;
        break;
      case "--percentiles": {
        const value = argv[++i];
        if (!value) throw new Error("Expected list after --percentiles");
        options.percentiles = value;
        break;
      }
      default:
        if (token.startsWith("-")) {
          throw new Error(`Unknown option: ${token}`);
        }
        options.targets.push(token);
    }
  }

  if (!options.help && options.targets.length === 0) {
    throw new Error("Provide at least one file or directory to process.");
  }

  return options;
}

function run(command, args) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, { stdio: "inherit", shell: false });
    child.on("error", reject);
    child.on("exit", (code) => {
      if (code === 0) resolve();
      else reject(new Error(`${command} ${args.join(" ")} exited with code ${code}`));
    });
  });
}

export async function runGoldReport(options, runner = run) {
  const timelinePath = path.resolve(options.timelineOut);
  const summaryPath = path.resolve(options.summaryOut);

  const timelineArgs = ["./scripts/goldTimeline.mjs", "--out", timelinePath];
  if (options.mergePassives) {
    timelineArgs.push("--merge-passives");
    timelineArgs.push("--passive-window", String(options.passiveWindow));
  } else {
    timelineArgs.push("--passive-window", String(options.passiveWindow));
  }
  timelineArgs.push(...options.targets.map((target) => path.resolve(target)));

  await runner(process.execPath, timelineArgs);

  const summaryArgs = ["./scripts/goldSummary.mjs", "--out", summaryPath];
  if (options.summaryCsv) summaryArgs.push("--csv");
  if (options.global) summaryArgs.push("--global");
  if (options.percentiles) {
    summaryArgs.push("--percentiles", options.percentiles);
  }
  summaryArgs.push(timelinePath);

  await runner(process.execPath, summaryArgs);

  return { timelinePath, summaryPath };
}

async function main() {
  let parsed;
  try {
    parsed = parseArgs(process.argv.slice(2));
  } catch (error) {
    console.error(error.message);
    process.exit(1);
    return;
  }

  if (parsed.help) {
    printHelp();
    process.exit(0);
    return;
  }

  try {
    await runGoldReport(parsed);
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
  }
}

if (
  import.meta.url === `file://${process.argv[1]}` ||
  process.argv[1]?.endsWith("goldReport.mjs")
) {
  await main();
}
