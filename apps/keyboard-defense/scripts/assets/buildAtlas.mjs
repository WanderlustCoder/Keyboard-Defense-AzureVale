#!/usr/bin/env node
import fs from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";

const DEFAULT_SOURCE = "public/assets";
const DEFAULT_OUT = "public/assets/atlas.json";
const DEFAULT_TILE = 64;
const DEFAULT_MAX = 1024;
const ALLOWED_EXT = new Set([".png", ".jpg", ".jpeg", ".webp"]);

function usage() {
  console.log(`Pack sprite assets into a simple atlas JSON.

Usage: node scripts/assets/buildAtlas.mjs [--source <dir>] [--out <file>] [--atlas <name>] [--tile-size <pixels>] [--max-size <pixels>] [--dry-run]

Options:
  --source <dir>      Directory containing sprite images (default: ${DEFAULT_SOURCE})
  --out <file>        Output atlas JSON path (default: ${DEFAULT_OUT})
  --atlas <name>      Atlas name to embed (default: derived from output file)
  --tile-size <px>    Fixed tile size to allocate per sprite (default: ${DEFAULT_TILE})
  --max-size <px>     Max atlas width/height before wrapping rows (default: ${DEFAULT_MAX})
  --dry-run           Do not write; print summary only
`);
}

function parseArgs(argv) {
  const options = {
    source: DEFAULT_SOURCE,
    out: DEFAULT_OUT,
    atlas: null,
    tileSize: DEFAULT_TILE,
    maxSize: DEFAULT_MAX,
    dryRun: false
  };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    switch (arg) {
      case "-h":
      case "--help":
        options.help = true;
        break;
      case "--source":
        options.source = argv[++i] ?? options.source;
        break;
      case "--out":
        options.out = argv[++i] ?? options.out;
        break;
      case "--atlas":
        options.atlas = argv[++i] ?? null;
        break;
      case "--tile-size":
        options.tileSize = Number(argv[++i] ?? options.tileSize);
        break;
      case "--max-size":
        options.maxSize = Number(argv[++i] ?? options.maxSize);
        break;
      case "--dry-run":
        options.dryRun = true;
        break;
      default:
        if (arg.startsWith("-")) {
          throw new Error(`Unknown option ${arg}`);
        }
    }
  }
  return options;
}

async function walkSprites(dir, accumulator = []) {
  const entries = await fs.readdir(dir, { withFileTypes: true });
  for (const entry of entries) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      await walkSprites(full, accumulator);
      continue;
    }
    const ext = path.extname(entry.name).toLowerCase();
    if (!ALLOWED_EXT.has(ext)) continue;
    accumulator.push(full);
  }
  return accumulator.sort();
}

export function packSprites(files, { tileSize, maxSize }) {
  let x = 0;
  let y = 0;
  const frames = {};
  for (const file of files) {
    const key = path.basename(file, path.extname(file));
    frames[key] = {
      frame: { x, y, w: tileSize, h: tileSize }
    };
    x += tileSize;
    if (x + tileSize > maxSize) {
      x = 0;
      y += tileSize;
    }
  }
  return frames;
}

export async function buildAtlas({ sourceDir, outPath, atlasName, tileSize, maxSize, dryRun }) {
  const files = await walkSprites(sourceDir, []);
  if (files.length === 0) {
    throw new Error(`No sprite assets found under ${sourceDir}`);
  }
  const frames = packSprites(files, { tileSize, maxSize });
  const atlas = {
    atlas: atlasName ?? path.basename(outPath, path.extname(outPath)),
    version: 1,
    size: { width: maxSize, height: maxSize },
    frames
  };
  if (dryRun) {
    console.log(`[atlas] DRY RUN: ${files.length} sprites -> ${outPath}`);
    return { atlas, files: files.length };
  }
  await fs.mkdir(path.dirname(outPath), { recursive: true });
  await fs.writeFile(outPath, `${JSON.stringify(atlas, null, 2)}\n`, "utf8");
  console.log(`[atlas] Wrote ${outPath} (${files.length} sprites)`);
  return { atlas, files: files.length };
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  if (options.help) {
    usage();
    return;
  }
  const sourceDir = path.resolve(options.source);
  const outPath = path.resolve(options.out);
  const atlasName = options.atlas ?? path.basename(outPath, path.extname(outPath));
  await buildAtlas({
    sourceDir,
    outPath,
    atlasName,
    tileSize: Math.max(1, Number(options.tileSize) || DEFAULT_TILE),
    maxSize: Math.max(1, Number(options.maxSize) || DEFAULT_MAX),
    dryRun: options.dryRun
  });
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  await main();
}
