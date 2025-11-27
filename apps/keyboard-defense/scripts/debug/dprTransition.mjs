#!/usr/bin/env node

import { promises as fs } from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

const DEFAULT_BASE_WIDTH = 960;
const DEFAULT_BASE_HEIGHT = 540;
const DEFAULT_STEPS = ["1:960:init", "1.25:900:zoom", "2:800:retina"];

function printHelp() {
  console.log(`Canvas DPR Transition Debugger

Usage:
  npm run debug:dpr-transition -- [options]
  node scripts/debug/dprTransition.mjs [options]

Options:
  --steps <spec>        Comma-separated list of transitions (format: dpr[:cssWidth[:cause]])
                        Example: --steps 1:960:init,1.5:840:pinch,1.25:880:zoom
  --fade-ms <number>    Fade duration in milliseconds (default: 180)
  --hold-ms <number>    Hold duration before cleanup (default: 70)
  --base-width <px>     Base canvas width used when cssWidth omitted (default: 960)
  --base-height <px>    Base canvas height used when cssWidth omitted (default: 540)
  --prefers-condensed   Force prefersCondensedHud to true
  --no-prefers-condensed Force prefersCondensedHud to false
  --hud-layout <mode>   Force hud layout ("stacked" or "condensed")
  --json                Print JSON payload instead of a table
  --report <path>       Write JSON payload to the provided file
  --markdown <path>     Write a Markdown summary table to the provided file
  --help                Show this message
`);
}

function parseArgs(argv) {
  const options = {
    steps: DEFAULT_STEPS,
    fadeMs: 180,
    holdMs: 70,
    baseWidth: DEFAULT_BASE_WIDTH,
    baseHeight: DEFAULT_BASE_HEIGHT,
    prefersCondensedHud: null,
    hudLayout: null,
    json: false,
    report: null,
    markdown: null,
    help: false
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--steps":
        options.steps = (argv[++i] ?? "").split(",").filter(Boolean);
        break;
      case "--fade-ms":
        options.fadeMs = Number(argv[++i] ?? options.fadeMs);
        break;
      case "--hold-ms":
        options.holdMs = Number(argv[++i] ?? options.holdMs);
        break;
      case "--base-width":
        options.baseWidth = Number(argv[++i] ?? options.baseWidth);
        break;
      case "--base-height":
        options.baseHeight = Number(argv[++i] ?? options.baseHeight);
        break;
      case "--prefers-condensed":
        options.prefersCondensedHud = true;
        break;
      case "--no-prefers-condensed":
        options.prefersCondensedHud = false;
        break;
      case "--hud-layout": {
        const layout = (argv[++i] ?? "").toLowerCase();
        if (layout === "stacked" || layout === "condensed") {
          options.hudLayout = layout;
        }
        break;
      }
      case "--json":
        options.json = true;
        break;
      case "--report":
        options.report = argv[++i] ?? null;
        break;
      case "--markdown":
        options.markdown = argv[++i] ?? null;
        break;
      case "--help":
        options.help = true;
        break;
      default:
        if (token.startsWith("-")) {
          throw new Error(`Unknown option '${token}'. Use --help for usage.`);
        }
    }
  }

  return options;
}

function parseStep(input, baseWidth) {
  const trimmed = input.trim();
  if (!trimmed) return null;
  const [dprRaw, widthRaw, cause] = trimmed.split(":");
  const dpr = Number(dprRaw);
  if (!Number.isFinite(dpr) || dpr <= 0) {
    throw new Error(`Invalid DPR value '${dprRaw}' in step '${input}'.`);
  }
  const cssWidth = widthRaw ? Number(widthRaw) : baseWidth;
  if (!Number.isFinite(cssWidth) || cssWidth <= 0) {
    throw new Error(`Invalid cssWidth '${widthRaw}' in step '${input}'.`);
  }
  return {
    dpr,
    cssWidth,
    cause: cause ?? "cli"
  };
}

function buildResolution(width, height, dpr) {
  const cssWidth = Math.max(1, Math.round(width));
  const cssHeight = Math.max(1, Math.round(height));
  const renderWidth = Math.max(1, Math.round(cssWidth * dpr));
  const renderHeight = Math.max(1, Math.round(cssHeight * dpr));
  return { cssWidth, cssHeight, renderWidth, renderHeight };
}

async function writeReport(reportPath, payload) {
  await fs.mkdir(path.dirname(path.resolve(reportPath)), { recursive: true });
  await fs.writeFile(reportPath, JSON.stringify(payload, null, 2), "utf8");
}

async function writeMarkdownReport(reportPath, payload) {
  const markdown = formatTransitionMarkdown(payload);
  await fs.mkdir(path.dirname(path.resolve(reportPath)), { recursive: true });
  await fs.writeFile(reportPath, markdown, "utf8");
}

function logTable(entries) {
  if (entries.length === 0) {
    console.log("No transitions recorded.");
    return;
  }
  console.log("| # | From DPR | To DPR | CSS (px) | Render (px) | Cause | Transition (ms) |");
  console.log("| --- | --- | --- | --- | --- | --- | --- |");
  entries.forEach((entry, index) => {
    const css = `${entry.cssWidth}×${entry.cssHeight}`;
    const render = `${entry.renderWidth}×${entry.renderHeight}`;
    console.log(
      `| ${index + 1} | ${entry.fromDpr.toFixed(2)} | ${entry.toDpr.toFixed(
        2
      )} | ${css} | ${render} | ${entry.cause} | ${entry.transitionMs} |`
    );
  });
}

function buildResolutionChangeEntry(options) {
  const {
    resolution,
    cause = "cli",
    previousDpr,
    nextDpr,
    transitionMs = 0,
    prefersCondensedHud = null,
    hudLayout = null,
    capturedAt = new Date().toISOString()
  } = options;

  return {
    capturedAt,
    cause,
    fromDpr: sanitizeDpr(previousDpr),
    toDpr: sanitizeDpr(nextDpr),
    cssWidth: clampDimension(resolution.cssWidth),
    cssHeight: clampDimension(resolution.cssHeight),
    renderWidth: clampDimension(resolution.renderWidth),
    renderHeight: clampDimension(resolution.renderHeight),
    transitionMs: Math.max(0, Math.round(Number(transitionMs) || 0)),
    prefersCondensedHud: normalizeNullableBoolean(prefersCondensedHud),
    hudLayout: normalizeHudLayout(hudLayout)
  };
}

function sanitizeDpr(value) {
  if (!Number.isFinite(value) || value <= 0) {
    return 1;
  }
  return Math.round(value * 100) / 100;
}

function clampDimension(value) {
  if (!Number.isFinite(value)) {
    return 1;
  }
  return Math.max(1, Math.round(value));
}

function normalizeNullableBoolean(value) {
  if (typeof value === "boolean") {
    return value;
  }
  return null;
}

function normalizeHudLayout(layout) {
  if (layout === "stacked" || layout === "condensed") {
    return layout;
  }
  return null;
}

function simulateDprTransitions(config = {}) {
  const baseWidth = config.baseWidth ?? DEFAULT_BASE_WIDTH;
  const baseHeight = config.baseHeight ?? DEFAULT_BASE_HEIGHT;
  const ratio = baseHeight / baseWidth;
  const fadeDuration = Math.max(0, Math.round(Number(config.fadeMs ?? 180) || 0));
  const holdDuration = Math.max(0, Math.round(Number(config.holdMs ?? 70) || 0));
  const transitionMs = fadeDuration + holdDuration;
  const now = typeof config.now === "function" ? config.now : () => new Date();

  const stepSpecs = (config.steps && config.steps.length > 0 ? config.steps : DEFAULT_STEPS).map(
    (step) => parseStep(step, baseWidth)
  );
  const validSteps = stepSpecs.filter(Boolean);
  if (validSteps.length === 0) {
    throw new Error("No valid steps provided. Use --steps to supply at least one transition.");
  }

  let previousDpr = validSteps[0]?.dpr ?? 1;
  const entries = [];
  for (const step of validSteps) {
    const cssHeight = step.cssWidth * ratio;
    const resolution = buildResolution(step.cssWidth, cssHeight, step.dpr);
    const entry = buildResolutionChangeEntry({
      resolution,
      cause: step.cause ?? "cli",
      previousDpr,
      nextDpr: step.dpr,
      transitionMs,
      prefersCondensedHud:
        typeof config.prefersCondensedHud === "boolean" ? config.prefersCondensedHud : null,
      hudLayout: config.hudLayout ?? null,
      capturedAt: now().toISOString()
    });
    entries.push(entry);
    previousDpr = step.dpr;
  }

  return {
    generatedAt: now().toISOString(),
    fadeMs: fadeDuration,
    holdMs: holdDuration,
    steps: entries
  };
}

function formatTransitionMarkdown(payload) {
  const steps = Array.isArray(payload.steps) ? payload.steps : [];
  const lines = [];
  lines.push("# Canvas DPR Transition");
  lines.push("");
  lines.push(
    `- Generated: **${payload.generatedAt ?? "n/a"}**  \n- Fade: **${payload.fadeMs ?? 0}ms**  \n- Hold: **${payload.holdMs ?? 0}ms**  \n- Steps: **${steps.length}**`
  );
  lines.push("");
  lines.push(
    "| # | Cause | From DPR | To DPR | CSS Width | Render Width | Prefers Condensed | HUD Layout | Transition (ms) |"
  );
  lines.push("| --- | --- | --- | --- | --- | --- | --- | --- | --- |");
  steps.forEach((step, index) => {
    lines.push(
      `| ${index + 1} | ${step.cause ?? "-"} | ${step.fromDpr ?? "-"} | ${step.toDpr ?? "-"} | ${step.cssWidth ?? "-"} | ${
        step.renderWidth ?? "-"
      } | ${step.prefersCondensedHud ?? "-"} | ${step.hudLayout ?? "-"} | ${step.transitionMs ?? "-"} |`
    );
  });
  return `${lines.join("\n")}\n`;
}

async function main(argv) {
  const options = parseArgs(argv);
  if (options.help) {
    printHelp();
    return 0;
  }

  const payload = simulateDprTransitions(options);

  if (options.report) {
    await writeReport(options.report, payload);
    console.log(`Report written to ${path.resolve(options.report)}`);
  }

  if (options.markdown) {
    await writeMarkdownReport(options.markdown, payload);
    console.log(`Markdown summary written to ${path.resolve(options.markdown)}`);
  }

  if (options.json) {
    console.log(JSON.stringify(payload, null, 2));
  } else {
    logTable(payload.steps);
  }

  return 0;
}

const isCliInvocation =
  typeof process.argv[1] === "string" &&
  fileURLToPath(import.meta.url) === path.resolve(process.argv[1]);

if (isCliInvocation) {
  main(process.argv.slice(2))
    .then((code) => {
      if (typeof code === "number") {
        process.exitCode = code;
      }
    })
    .catch((error) => {
      console.error(error instanceof Error ? error.message : error);
      process.exitCode = 1;
    });
}

export { parseArgs, simulateDprTransitions, formatTransitionMarkdown, DEFAULT_STEPS };
