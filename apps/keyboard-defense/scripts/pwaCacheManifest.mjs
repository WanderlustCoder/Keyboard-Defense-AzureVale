#!/usr/bin/env node

import { promises as fs } from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const APP_ROOT = path.resolve(__dirname, "..");
const DEFAULT_PUBLIC_DIR = path.join(APP_ROOT, "public");
const DEFAULT_OUT_PATH = path.join(DEFAULT_PUBLIC_DIR, "pwa-cache-manifest.json");

const FILES_ALWAYS_INCLUDED = [
  "index.html",
  "styles.css",
  "manifest.webmanifest"
];

const DIST_SRC_ROOT = path.join("dist", "src");
const DIST_DOCS_ROOT = path.join("dist", "docs");

const normalizeToUrlPath = (value) => value.split(path.sep).join("/");

async function listFiles(rootDir) {
  const results = [];
  const entries = await fs.readdir(rootDir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(rootDir, entry.name);
    if (entry.isDirectory()) {
      results.push(...(await listFiles(fullPath)));
      continue;
    }
    if (entry.isFile()) {
      results.push(fullPath);
    }
  }
  return results;
}

async function readJson(filePath) {
  const raw = await fs.readFile(filePath, "utf8");
  return JSON.parse(raw);
}

function uniqSorted(values) {
  return [...new Set(values)].sort((a, b) => a.localeCompare(b));
}

export async function buildPwaCacheManifest({ publicDir = DEFAULT_PUBLIC_DIR } = {}) {
  const urls = new Set();

  for (const entry of FILES_ALWAYS_INCLUDED) {
    urls.add(entry);
  }

  try {
    urls.add("assets/manifest.json");
    const assetManifest = await readJson(path.join(publicDir, "assets", "manifest.json"));
    const images = assetManifest?.images ?? {};
    for (const relativeAssetPath of Object.values(images)) {
      if (typeof relativeAssetPath !== "string") continue;
      const cleaned = relativeAssetPath.replace(/^[./]+/, "");
      if (!cleaned) continue;
      urls.add(`assets/${cleaned}`);
    }
  } catch {
    // asset manifest missing; best-effort for local edits
  }

  try {
    const distSrcDir = path.join(publicDir, DIST_SRC_ROOT);
    const distSrcFiles = await listFiles(distSrcDir);
    for (const filePath of distSrcFiles) {
      if (!filePath.endsWith(".js")) continue;
      const rel = path.relative(publicDir, filePath);
      urls.add(normalizeToUrlPath(rel));
    }
  } catch {
    // dist tree missing before build; allow script to run independently
  }

  try {
    const distDocsDir = path.join(publicDir, DIST_DOCS_ROOT);
    const docsFiles = await listFiles(distDocsDir);
    for (const filePath of docsFiles) {
      if (!filePath.endsWith(".json")) continue;
      const rel = path.relative(publicDir, filePath);
      urls.add(normalizeToUrlPath(rel));
    }
  } catch {
    // docs tree missing before build; allow script to run independently
  }

  try {
    const fontsDir = path.join(publicDir, "fonts");
    const fontFiles = await listFiles(fontsDir);
    for (const filePath of fontFiles) {
      const rel = path.relative(publicDir, filePath);
      urls.add(normalizeToUrlPath(rel));
    }
  } catch {
    // fonts optional
  }

  return { urls: uniqSorted([...urls]) };
}

export async function writePwaCacheManifest({
  publicDir = DEFAULT_PUBLIC_DIR,
  outPath = DEFAULT_OUT_PATH
} = {}) {
  const manifest = await buildPwaCacheManifest({ publicDir });
  const serialized = JSON.stringify(manifest, null, 2) + "\n";
  let existing = null;
  try {
    existing = await fs.readFile(outPath, "utf8");
  } catch {
    existing = null;
  }
  if (existing === serialized) {
    return manifest;
  }
  await fs.writeFile(outPath, serialized, "utf8");
  return manifest;
}

function parseArgs(argv = []) {
  const options = {
    publicDir: DEFAULT_PUBLIC_DIR,
    out: DEFAULT_OUT_PATH,
    verifyOnly: false,
    help: false
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--public":
        options.publicDir = argv[++i] ? path.resolve(argv[i]) : options.publicDir;
        break;
      case "--out":
        options.out = argv[++i] ? path.resolve(argv[i]) : options.out;
        break;
      case "--verify-only":
        options.verifyOnly = true;
        break;
      case "--help":
      case "-h":
        options.help = true;
        break;
      default:
        throw new Error(`Unknown option: ${token}`);
    }
  }

  return options;
}

function printHelp() {
  console.log(`Keyboard Defense PWA cache manifest generator

Usage:
  node scripts/pwaCacheManifest.mjs [--public <dir>] [--out <file>] [--verify-only]

Writes public/pwa-cache-manifest.json used by public/sw.js to precache the offline app shell.
`);
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    printHelp();
    process.exit(0);
  }

  if (args.verifyOnly) {
    const computed = await buildPwaCacheManifest({ publicDir: args.publicDir });
    const expected = JSON.stringify(computed, null, 2) + "\n";
    const actual = await fs.readFile(args.out, "utf8");
    if (actual !== expected) {
      console.error(
        `PWA cache manifest mismatch. Regenerate with:\n  node scripts/pwaCacheManifest.mjs --public ${args.publicDir} --out ${args.out}`
      );
      process.exit(1);
    }
    console.log("PWA cache manifest verified.");
    return;
  }

  const result = await writePwaCacheManifest({ publicDir: args.publicDir, outPath: args.out });
  console.log(`Wrote ${args.out} (${result.urls.length} cached URLs).`);
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
