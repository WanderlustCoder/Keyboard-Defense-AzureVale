#!/usr/bin/env node
import fs from "node:fs/promises";
import path from "node:path";
import { createHash } from "node:crypto";
import { pathToFileURL } from "node:url";

const DEFAULT_SOURCE = "public/assets";
const DEFAULT_OUT = "public/assets/manifest.json";
const ALLOWED_EXT = new Set([".png", ".jpg", ".jpeg", ".webp", ".gif", ".svg"]);

function usage() {
  console.log(`Generate an asset manifest (images + integrity hashes) from a source directory.

Usage: node scripts/assets/generateManifest.mjs [--source <dir>] [--out <file>] [--version <value>] [--verify-only]

Options:
  --source <dir>   Directory to scan for sprite assets (default: ${DEFAULT_SOURCE})
  --out <file>     Output manifest path (default: ${DEFAULT_OUT})
  --version <val>  Version string to embed in the manifest (default: preserve existing or current ISO timestamp)
  --verify-only    Do not write; validate existing manifest integrity against current files
`);
}

function parseArgs(argv) {
  const options = {
    source: DEFAULT_SOURCE,
    out: DEFAULT_OUT,
    version: null,
    verifyOnly: false
  };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    switch (arg) {
      case "--help":
      case "-h":
        options.help = true;
        break;
      case "--source":
        options.source = argv[++i] ?? options.source;
        break;
      case "--out":
        options.out = argv[++i] ?? options.out;
        break;
      case "--version":
        options.version = argv[++i] ?? null;
        break;
      case "--verify-only":
        options.verifyOnly = true;
        break;
      default:
        if (arg.startsWith("-")) {
          throw new Error(`Unknown option ${arg}`);
        }
    }
  }
  return options;
}

async function walkFiles(dir, accumulator = []) {
  const entries = await fs.readdir(dir, { withFileTypes: true });
  for (const entry of entries) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      await walkFiles(full, accumulator);
      continue;
    }
    const ext = path.extname(entry.name).toLowerCase();
    if (!ALLOWED_EXT.has(ext)) {
      continue;
    }
    accumulator.push(full);
  }
  return accumulator;
}

function relativeKey(filePath, sourceDir) {
  const rel = path.relative(sourceDir, filePath).replace(/\\/g, "/");
  const base = path.basename(rel, path.extname(rel));
  return base;
}

async function hashFile(filePath) {
  const data = await fs.readFile(filePath);
  const hash = createHash("sha256").update(data).digest("base64");
  return `sha256-${hash}`;
}

export async function generateManifest({ sourceDir, outPath, version }) {
  const files = await walkFiles(sourceDir, []);
  const images = {};
  const integrity = {};
  for (const file of files) {
    const key = relativeKey(file, sourceDir);
    const relPath = path.relative(path.dirname(outPath), file).replace(/\\/g, "/");
    images[key] = relPath;
    integrity[key] = await hashFile(file);
  }
  let manifest = {};
  try {
    const existing = await fs.readFile(outPath, "utf8");
    manifest = JSON.parse(existing);
  } catch {
    manifest = {};
  }
  manifest.version = version ?? manifest.version ?? new Date().toISOString();
  manifest.images = images;
  manifest.integrity = integrity;
  const serialized = `${JSON.stringify(manifest, null, 2)}\n`;
  await fs.mkdir(path.dirname(outPath), { recursive: true });
  await fs.writeFile(outPath, serialized, "utf8");
  return { manifest, files: files.length };
}

export async function verifyManifest({ manifestPath }) {
  const contents = await fs.readFile(manifestPath, "utf8");
  const manifest = JSON.parse(contents);
  if (!manifest.images || !manifest.integrity) {
    throw new Error(`Manifest missing images/integrity sections (${manifestPath}).`);
  }
  let failures = 0;
  for (const [key, relPath] of Object.entries(manifest.images)) {
    const full = path.resolve(path.dirname(manifestPath), relPath);
    const expected = manifest.integrity[key] ?? null;
    const actual = await hashFile(full);
    if (expected !== actual) {
      failures += 1;
      console.error(`[verify] Mismatch for ${key}: expected ${expected ?? "<missing>"} got ${actual}`);
    }
  }
  if (failures > 0) {
    throw new Error(`Manifest integrity failed (${failures} mismatches).`);
  }
  return { ok: true, total: Object.keys(manifest.images).length };
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  if (options.help) {
    usage();
    return;
  }
  const sourceDir = path.resolve(options.source);
  const outPath = path.resolve(options.out);
  if (options.verifyOnly) {
    await verifyManifest({ sourceDir, manifestPath: outPath });
    console.log(`[manifest] Verified integrity for ${outPath}`);
    return;
  }
  const result = await generateManifest({
    sourceDir,
    outPath,
    version: options.version ?? undefined
  });
  console.log(
    `[manifest] Wrote ${outPath} (${result.files} assets, version ${result.manifest.version ?? "n/a"})`
  );
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  await main();
}
