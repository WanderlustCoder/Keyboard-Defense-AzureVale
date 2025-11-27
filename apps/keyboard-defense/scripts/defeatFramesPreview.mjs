#!/usr/bin/env node

import { promises as fs } from "node:fs";
import path from "node:path";
import process from "node:process";

import { AssetLoader } from "../public/dist/src/assets/assetLoader.js";

const DEFAULT_MANIFEST_PATH = "public/assets/manifest.json";
const DEFAULT_OUT_JSON = "artifacts/summaries/defeat-animations-preview.json";
const DEFAULT_OUT_MARKDOWN = "artifacts/summaries/defeat-animations-preview.md";
const VALID_MODES = new Set(["fail", "warn", "info"]);

function printHelp() {
  console.log(`Defeat Frames Preview

Usage:
  node scripts/defeatFramesPreview.mjs [options]

Options:
  --manifest <path>    Asset manifest containing a "defeatAnimations" block (default: ${DEFAULT_MANIFEST_PATH})
  --animations <path>  Standalone defeat animation JSON file (array or { defeatAnimations: [...] })
  --out-json <path>    JSON output path (default: ${DEFAULT_OUT_JSON})
  --markdown <path>    Markdown output path (default: ${DEFAULT_OUT_MARKDOWN})
  --mode <fail|warn|info>  Failure behaviour when warnings exist (default: warn)
  --help               Show this message
`);
}

function parseArgs(argv) {
  const options = {
    manifestPath: process.env.DEFEAT_PREVIEW_MANIFEST ?? DEFAULT_MANIFEST_PATH,
    animationsPath: process.env.DEFEAT_PREVIEW_ANIMATIONS ?? null,
    outJson: process.env.DEFEAT_PREVIEW_JSON ?? DEFAULT_OUT_JSON,
    markdown: process.env.DEFEAT_PREVIEW_MARKDOWN ?? DEFAULT_OUT_MARKDOWN,
    mode: (process.env.DEFEAT_PREVIEW_MODE ?? "warn").toLowerCase(),
    help: false
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--manifest":
        options.manifestPath = argv[++i] ?? options.manifestPath;
        break;
      case "--animations":
        options.animationsPath = argv[++i] ?? options.animationsPath;
        break;
      case "--out-json":
        options.outJson = argv[++i] ?? options.outJson;
        break;
      case "--markdown":
        options.markdown = argv[++i] ?? options.markdown;
        break;
      case "--mode":
        options.mode = (argv[++i] ?? options.mode).toLowerCase();
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

  if (!VALID_MODES.has(options.mode)) {
    throw new Error(
      `Invalid mode '${options.mode}'. Choose one of: ${Array.from(VALID_MODES).join(", ")}`
    );
  }

  if (!options.manifestPath && !options.animationsPath) {
    throw new Error("Provide --manifest <path> or --animations <path> so defeat animations can be parsed.");
  }

  return options;
}

async function readJsonFile(filePath) {
  const absolute = path.resolve(filePath);
  const raw = await fs.readFile(absolute, "utf8");
  try {
    return JSON.parse(raw);
  } catch (error) {
    throw new Error(`Failed to parse JSON from ${filePath}: ${error instanceof Error ? error.message : String(error)}`);
  }
}

async function loadDefeatAnimationDefinitions({ manifestPath, animationsPath }) {
  if (animationsPath) {
    const data = await readJsonFile(animationsPath);
    const definitions = extractDefeatAnimationsBlock(data);
    if (!definitions) {
      throw new Error(`File ${animationsPath} did not contain a defeat animation block.`);
    }
    return { definitions, source: { kind: "animations", path: animationsPath } };
  }

  if (manifestPath) {
    try {
      const manifest = await readJsonFile(manifestPath);
      const definitions = extractDefeatAnimationsBlock(manifest);
      if (!definitions) {
        throw new Error(`Manifest ${manifestPath} did not expose "defeatAnimations".`);
      }
      return { definitions, source: { kind: "manifest", path: manifestPath } };
    } catch (error) {
      if (error && error.code === "ENOENT") {
        throw new Error(
          `Manifest ${manifestPath} not found. Provide --animations <file> or adjust --manifest.`
        );
      }
      throw error;
    }
  }

  throw new Error("No manifest or animations path could be resolved.");
}

function extractDefeatAnimationsBlock(data) {
  if (!data || typeof data !== "object") return null;
  if (Array.isArray(data)) {
    return data;
  }
  if (Array.isArray(data.defeatAnimations)) {
    return data.defeatAnimations;
  }
  if (data.animations && Array.isArray(data.animations.defeat)) {
    return data.animations.defeat;
  }
  if (Array.isArray(data.animations?.defeatAnimations)) {
    return data.animations.defeatAnimations;
  }
  return null;
}

export function buildDefeatAnimationReport({ animations, source, warnings: initialWarnings = [] }) {
  const warnings = Array.isArray(initialWarnings) ? [...initialWarnings] : [];
  const rows = animations.map((animation) => {
    const frames = Array.isArray(animation.frames) ? animation.frames : [];
    const totalDurationMs = frames.reduce((sum, frame) => sum + Number(frame.durationMs ?? 0), 0);
    const minSize = frames.reduce(
      (min, frame) => Math.min(min, Number.isFinite(frame.size) ? frame.size : min),
      Number.POSITIVE_INFINITY
    );
    const maxSize = frames.reduce(
      (max, frame) => Math.max(max, Number.isFinite(frame.size) ? frame.size : max),
      Number.NEGATIVE_INFINITY
    );
    const minSizeValue = Number.isFinite(minSize) ? minSize : null;
    const maxSizeValue = Number.isFinite(maxSize) ? maxSize : null;
    const offsetsUsed = frames.some(
      (frame) => Number(frame.offsetX ?? 0) !== 0 || Number(frame.offsetY ?? 0) !== 0
    );
    if (frames.length === 0) {
      warnings.push(
        `Animation '${animation.id}' does not define any frames${animation.fallback ? ` (falls back to ${animation.fallback})` : ""}.`
      );
    }
    if (frames.length > 0 && totalDurationMs < 250) {
      warnings.push(
        `Animation '${animation.id}' total duration ${totalDurationMs}ms is very short; confirm easing/duration are correct.`
      );
    }
    return {
      id: animation.id,
      frameCount: frames.length,
      totalDurationMs,
      averageFrameDurationMs: frames.length > 0 ? totalDurationMs / frames.length : 0,
      minSize: minSizeValue,
      maxSize: maxSizeValue,
      loop: Boolean(animation.loop),
      fallback: animation.fallback ?? null,
      offsetsUsed
    };
  });

  rows.sort((a, b) => a.id.localeCompare(b.id));

  return {
    generatedAt: new Date().toISOString(),
    source: source ?? null,
    totals: {
      animations: rows.length,
      frames: rows.reduce((sum, row) => sum + row.frameCount, 0),
      warnings: warnings.length
    },
    animations: rows,
    warnings,
    status: warnings.length > 0 ? "warn" : "pass"
  };
}

export function formatDefeatAnimationMarkdown(report) {
  const lines = [];
  lines.push("## Defeat Animation Preview");
  lines.push(`Generated: ${report.generatedAt ?? "n/a"}`);
  lines.push(`Status: ${report.status === "pass" ? "✅ Pass" : "⚠️ Warn"}`);
  const sourcePath = report.source?.path ?? "n/a";
  lines.push(`Source: ${sourcePath}`);
  lines.push("");

  if (report.animations.length > 0) {
    lines.push("| Animation | Frames | Duration (ms) | Avg Frame (ms) | Size Range | Loop | Fallback | Offsets |");
    lines.push("| --- | --- | --- | --- | --- | --- | --- | --- |");
    for (const animation of report.animations) {
      const sizeRange =
        typeof animation.minSize === "number" && typeof animation.maxSize === "number"
          ? `${animation.minSize}–${animation.maxSize}`
          : "n/a";
      const avgDuration = animation.frameCount > 0 ? animation.averageFrameDurationMs.toFixed(1) : "0";
      lines.push(
        `| ${animation.id} | ${animation.frameCount} | ${animation.totalDurationMs.toFixed(1)} | ${avgDuration} | ${sizeRange} | ${animation.loop ? "♻️" : "-"} | ${animation.fallback ?? "-"} | ${
          animation.offsetsUsed ? "🎯" : "-"
        } |`
      );
    }
    lines.push("");
  } else {
    lines.push("_No animations detected._");
    lines.push("");
  }

  lines.push("### Warnings");
  if (report.warnings.length === 0) {
    lines.push("_None_");
  } else {
    for (const warning of report.warnings) {
      lines.push(`- ${warning}`);
    }
  }

  return lines.join("\n");
}

async function writeFileEnsuringDir(targetPath, contents) {
  const absolute = path.resolve(targetPath);
  await fs.mkdir(path.dirname(absolute), { recursive: true });
  await fs.writeFile(absolute, contents);
}

async function main() {
  let options;
  try {
    options = parseArgs(process.argv.slice(2));
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
    return;
  }

  if (options.help) {
    printHelp();
    return;
  }

  let definitions;
  let sourceMeta;
  try {
    const result = await loadDefeatAnimationDefinitions({
      manifestPath: options.manifestPath,
      animationsPath: options.animationsPath
    });
    definitions = result.definitions;
    sourceMeta = result.source;
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
    return;
  }

  const loader = new AssetLoader();
  loader.applyDefeatAnimations(definitions);
  const animations = loader.listDefeatAnimations();
  const report = buildDefeatAnimationReport({ animations, source: sourceMeta });

  await writeFileEnsuringDir(options.outJson, `${JSON.stringify(report, null, 2)}\n`);
  const markdown = formatDefeatAnimationMarkdown(report);
  await writeFileEnsuringDir(options.markdown, `${markdown}\n`);

  if (report.warnings.length > 0 && options.mode === "fail") {
    throw new Error(`${report.warnings.length} defeat animation warning(s) detected. See ${options.outJson}.`);
  }
  if (report.warnings.length > 0 && options.mode === "warn") {
    console.warn(`${report.warnings.length} warning(s) emitted. See ${options.outJson}.`);
  }
}

if (
  import.meta.url === `file://${process.argv[1]}` ||
  process.argv[1]?.endsWith("defeatFramesPreview.mjs")
) {
  main().catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
  });
}
