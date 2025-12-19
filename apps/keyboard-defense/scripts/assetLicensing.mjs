#!/usr/bin/env node
/**
 * Asset licensing manifest checker (Season 4 #100).
 *
 * Scans shipped asset roots (public/assets + public/fonts) and verifies every file
 * is accounted for in docs/asset_licensing_manifest.json with required metadata.
 */

import fs from "node:fs/promises";
import fsSync from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath, pathToFileURL } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const APP_ROOT = path.resolve(__dirname, "..");

const DEFAULT_MANIFEST_PATH = path.join(APP_ROOT, "docs", "asset_licensing_manifest.json");
const DEFAULT_OUT_PATH = path.join(APP_ROOT, "artifacts", "summaries", "asset-licensing.json");

const ORIGINS = new Set(["project", "third-party", "generated"]);

const DEFAULT_ROOTS = [
  path.join(APP_ROOT, "public", "assets"),
  path.join(APP_ROOT, "public", "fonts")
];

const IGNORED_BASENAMES = new Set([".ds_store", "thumbs.db", "desktop.ini"]);

function toPosix(value) {
  return String(value ?? "").replace(/\\/g, "/");
}

function normalizeRelativeAssetPath(value) {
  const raw = toPosix(value).trim();
  const stripped = raw.startsWith("./") ? raw.slice(2) : raw;
  if (!stripped || stripped.startsWith("/") || stripped.startsWith("../")) {
    return null;
  }
  if (stripped.split("/").some((part) => part === ".." || !part)) {
    return null;
  }
  return stripped;
}

function sanitizeBoolean(value) {
  return value === true || value === "1" || value === "true";
}

function parseArgs(argv) {
  const options = {
    manifest: DEFAULT_MANIFEST_PATH,
    out: DEFAULT_OUT_PATH,
    check: false,
    json: false,
    help: false
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--manifest": {
        const value = argv[++i];
        if (!value) throw new Error("Missing value for --manifest");
        options.manifest = path.isAbsolute(value) ? value : path.resolve(process.cwd(), value);
        break;
      }
      case "--out": {
        const value = argv[++i];
        if (!value) throw new Error("Missing value for --out");
        options.out = path.isAbsolute(value) ? value : path.resolve(process.cwd(), value);
        break;
      }
      case "--check":
        options.check = true;
        break;
      case "--json":
        options.json = true;
        break;
      case "--help":
      case "-h":
        options.help = true;
        break;
      default:
        if (token.startsWith("-")) {
          throw new Error(`Unknown option "${token}". Use --help for usage.`);
        }
        break;
    }
  }

  options.check = options.check || sanitizeBoolean(process.env.ASSET_LICENSES_CHECK);
  options.json = options.json || sanitizeBoolean(process.env.ASSET_LICENSES_JSON);

  return options;
}

function printHelp() {
  console.log(`Keyboard Defense asset licensing checker

Usage:
  node scripts/assetLicensing.mjs [options]

Options:
  --manifest <path>   Licensing manifest (default docs/asset_licensing_manifest.json)
  --out <path>        Write a JSON summary (default artifacts/summaries/asset-licensing.json)
  --check             Exit non-zero on failures (default false)
  --json              Print summary JSON to stdout
  --help              Show this help
`);
}

async function walkFiles(rootDir) {
  const files = [];
  if (!rootDir || !fsSync.existsSync(rootDir)) return files;

  const stack = [rootDir];
  while (stack.length > 0) {
    const current = stack.pop();
    if (!current) continue;
    const entries = await fs.readdir(current, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(current, entry.name);
      if (entry.isDirectory()) {
        stack.push(fullPath);
        continue;
      }
      if (!entry.isFile()) continue;
      const basename = entry.name.toLowerCase();
      if (IGNORED_BASENAMES.has(basename)) continue;
      files.push(fullPath);
    }
  }

  return files;
}

async function scanAssetFiles(roots = DEFAULT_ROOTS) {
  const scannedRoots = [];
  const files = [];

  for (const rootDir of roots) {
    if (!rootDir) continue;
    if (!fsSync.existsSync(rootDir)) continue;
    scannedRoots.push(rootDir);
    const entries = await walkFiles(rootDir);
    files.push(...entries);
  }

  const relativeFiles = files
    .map((filePath) => toPosix(path.relative(APP_ROOT, filePath)))
    .filter(Boolean)
    .sort((a, b) => a.localeCompare(b));

  return {
    roots: scannedRoots.map((dir) => toPosix(path.relative(APP_ROOT, dir))),
    files: relativeFiles
  };
}

async function loadLicensingManifest(filePath) {
  const raw = await fs.readFile(filePath, "utf8");
  try {
    return JSON.parse(raw);
  } catch (error) {
    throw new Error(
      `Failed to parse licensing manifest JSON (${filePath}): ${
        error instanceof Error ? error.message : String(error)
      }`
    );
  }
}

function validateEntry(entry, index) {
  const errors = [];
  const prefix = `assets[${index}]`;
  if (!entry || typeof entry !== "object") {
    return [`${prefix} must be an object`];
  }

  const normalizedPath = normalizeRelativeAssetPath(entry.path);
  if (!normalizedPath) {
    errors.push(`${prefix}.path must be a repo-relative path like "public/assets/...".`);
  }

  const kind = typeof entry.kind === "string" ? entry.kind.trim() : "";
  if (!kind) {
    errors.push(`${prefix}.kind is required (e.g., "image", "font", "data").`);
  }

  const origin = typeof entry.origin === "string" ? entry.origin.trim() : "";
  if (!ORIGINS.has(origin)) {
    errors.push(`${prefix}.origin must be one of: ${[...ORIGINS].join(", ")}.`);
  }

  if (origin === "generated") {
    const generator = typeof entry.generatedBy === "string" ? entry.generatedBy.trim() : "";
    if (!generator) {
      errors.push(`${prefix}.generatedBy is required when origin="generated".`);
    }
  }

  if (origin === "third-party") {
    const license = entry.license;
    const source = entry.source;
    const licenseName =
      license && typeof license === "object"
        ? typeof license.spdx === "string"
          ? license.spdx.trim()
          : typeof license.name === "string"
            ? license.name.trim()
            : ""
        : "";
    if (!licenseName) {
      errors.push(`${prefix}.license.spdx or ${prefix}.license.name is required for third-party assets.`);
    }
    const sourceUrl =
      source && typeof source === "object" && typeof source.url === "string"
        ? source.url.trim()
        : "";
    const author =
      source && typeof source === "object" && typeof source.author === "string"
        ? source.author.trim()
        : "";
    if (!sourceUrl && !author) {
      errors.push(`${prefix}.source.url or ${prefix}.source.author is required for third-party assets.`);
    }
  }

  return errors;
}

export async function validateAssetLicenses({
  manifestPath = DEFAULT_MANIFEST_PATH,
  roots = DEFAULT_ROOTS
} = {}) {
  const startedAt = new Date().toISOString();
  const scan = await scanAssetFiles(roots);
  const manifest = await loadLicensingManifest(manifestPath);

  const manifestEntries = Array.isArray(manifest?.assets) ? manifest.assets : null;
  if (!manifestEntries) {
    throw new Error(`Licensing manifest must contain an "assets" array (${manifestPath}).`);
  }

  const errors = [];
  const entryByPath = new Map();
  const originCounts = { project: 0, "third-party": 0, generated: 0 };

  for (const [index, entry] of manifestEntries.entries()) {
    errors.push(...validateEntry(entry, index));
    const normalizedPath = normalizeRelativeAssetPath(entry?.path);
    if (!normalizedPath) continue;
    if (entryByPath.has(normalizedPath)) {
      errors.push(`Duplicate manifest entry path: "${normalizedPath}".`);
      continue;
    }
    entryByPath.set(normalizedPath, entry);

    const origin = typeof entry.origin === "string" ? entry.origin.trim() : "";
    if (originCounts[origin] !== undefined) {
      originCounts[origin] += 1;
    }
  }

  const missing = [];
  for (const filePath of scan.files) {
    if (!entryByPath.has(filePath)) {
      missing.push(filePath);
    }
  }

  const stale = [];
  for (const entryPath of entryByPath.keys()) {
    const absolute = path.join(APP_ROOT, entryPath.split("/").join(path.sep));
    if (!fsSync.existsSync(absolute)) {
      stale.push(entryPath);
    }
  }

  const extra = [];
  const scannedSet = new Set(scan.files);
  for (const entryPath of entryByPath.keys()) {
    if (!scannedSet.has(entryPath)) {
      extra.push(entryPath);
    }
  }

  const status =
    errors.length === 0 && missing.length === 0 && stale.length === 0 ? "pass" : "fail";

  const summary = {
    status,
    startedAt,
    finishedAt: new Date().toISOString(),
    manifestPath: toPosix(path.relative(APP_ROOT, manifestPath)),
    roots: scan.roots,
    scanned: scan.files.length,
    manifestEntries: entryByPath.size,
    origins: originCounts,
    missing,
    stale,
    extra,
    errors
  };

  return summary;
}

async function writeSummary(outPath, summary) {
  if (!outPath) return null;
  const resolved = path.isAbsolute(outPath) ? outPath : path.resolve(process.cwd(), outPath);
  await fs.mkdir(path.dirname(resolved), { recursive: true });
  await fs.writeFile(resolved, JSON.stringify(summary, null, 2) + "\n", "utf8");
  return resolved;
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  if (options.help) {
    printHelp();
    return;
  }

  const summary = await validateAssetLicenses({ manifestPath: options.manifest });
  const written = await writeSummary(options.out, summary);

  const headline = `[asset-licensing] ${summary.status.toUpperCase()} - scanned ${summary.scanned}, manifest ${summary.manifestEntries}`;
  if (summary.status === "pass") {
    console.log(headline);
  } else {
    console.error(headline);
    if (summary.missing.length) {
      console.error(`[asset-licensing] Missing entries (${summary.missing.length}):`);
      for (const entry of summary.missing.slice(0, 30)) {
        console.error(`  - ${entry}`);
      }
      if (summary.missing.length > 30) {
        console.error(`  ... +${summary.missing.length - 30} more`);
      }
    }
    if (summary.stale.length) {
      console.error(`[asset-licensing] Manifest references missing files (${summary.stale.length}):`);
      for (const entry of summary.stale.slice(0, 30)) {
        console.error(`  - ${entry}`);
      }
      if (summary.stale.length > 30) {
        console.error(`  ... +${summary.stale.length - 30} more`);
      }
    }
    if (summary.errors.length) {
      console.error(`[asset-licensing] Manifest validation errors (${summary.errors.length}):`);
      for (const entry of summary.errors.slice(0, 30)) {
        console.error(`  - ${entry}`);
      }
      if (summary.errors.length > 30) {
        console.error(`  ... +${summary.errors.length - 30} more`);
      }
    }
  }

  if (written) {
    console.log(`[asset-licensing] Summary written to ${written}`);
  }
  if (options.json) {
    console.log(JSON.stringify(summary, null, 2));
  }
  if (options.check && summary.status !== "pass") {
    process.exitCode = 1;
  }
}

const entryPoint = process.argv[1];
if (typeof entryPoint === "string" && import.meta.url === pathToFileURL(entryPoint).href) {
  await main();
}

