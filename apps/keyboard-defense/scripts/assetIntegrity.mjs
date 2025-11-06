#!/usr/bin/env node

import { promises as fs } from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";
import { createHash } from "node:crypto";

const DEFAULT_MANIFEST = "public/assets/manifest.json";

function printHelp() {
  console.log(`Keyboard Defense asset integrity helper

Usage:
  node scripts/assetIntegrity.mjs [options]

Options:
  --manifest <path>   Manifest JSON path (default ${DEFAULT_MANIFEST})
  --assets <dir>      Directory that contains the manifest's assets (defaults to manifest directory)
  --check             Verify existing integrity hashes instead of writing
  --help              Show this message

Description:
  Computes SHA-256 digests for every asset referenced in the manifest's images map.
  By default the script rewrites the manifest's "integrity" section with the fresh hashes.
  Run with --check to verify that the manifest already matches the computed values.`);
}

export function parseArgs(argv = []) {
  const options = {
    manifest: DEFAULT_MANIFEST,
    assetsDir: null,
    check: false,
    help: false
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--manifest": {
        const value = argv[++i];
        if (!value) {
          throw new Error("Expected path after --manifest");
        }
        options.manifest = value;
        break;
      }
      case "--assets": {
        const value = argv[++i];
        if (!value) {
          throw new Error("Expected directory after --assets");
        }
        options.assetsDir = value;
        break;
      }
      case "--check":
        options.check = true;
        break;
      case "--help":
        options.help = true;
        break;
      default:
        throw new Error(`Unknown flag: ${token}`);
    }
  }

  const resolvedManifest = path.resolve(options.manifest);
  const resolvedAssets = path.resolve(options.assetsDir ?? path.dirname(resolvedManifest));

  return {
    manifest: resolvedManifest,
    assetsDir: resolvedAssets,
    check: options.check,
    help: options.help
  };
}

export async function loadManifest(manifestPath) {
  const contents = await fs.readFile(manifestPath, "utf8");
  try {
    return JSON.parse(contents);
  } catch (error) {
    throw new Error(`Failed to parse manifest JSON (${manifestPath}): ${error.message}`);
  }
}

export async function computeIntegrityForFile(filePath) {
  const data = await fs.readFile(filePath);
  const hash = createHash("sha256").update(data).digest("base64");
  return `sha256-${hash}`;
}

export async function buildIntegrityMap(manifest, manifestPath, assetsDir) {
  if (!manifest?.images) {
    return {};
  }
  const entries = Object.entries(manifest.images);
  const map = {};

  await Promise.all(
    entries.map(async ([key, relativePath]) => {
      const assetPath = path.resolve(assetsDir, relativePath);
      try {
        const digest = await computeIntegrityForFile(assetPath);
        map[key] = digest;
      } catch (error) {
        throw new Error(
          `Failed to hash asset "${key}" (${relativePath}) referenced by ${manifestPath}: ${error.message}`
        );
      }
    })
  );

  return Object.fromEntries(
    Object.keys(map)
      .sort()
      .map((key) => [key, map[key]])
  );
}

export function diffIntegrity(existing, computed) {
  const issues = [];
  const existingKeys = new Set(Object.keys(existing ?? {}));

  for (const [key, digest] of Object.entries(computed)) {
    if (!existing || !(key in existing)) {
      issues.push(`Missing integrity entry for "${key}".`);
      continue;
    }
    existingKeys.delete(key);
    if (existing[key] !== digest) {
      issues.push(`Integrity mismatch for "${key}": expected ${digest}, found ${existing[key]}`);
    }
  }

  for (const leftover of existingKeys) {
    issues.push(`Integrity entry "${leftover}" is not referenced by manifest images.`);
  }
  return issues;
}

export async function runAssetIntegrity(options) {
  const manifest = await loadManifest(options.manifest);
  const integrity = await buildIntegrityMap(manifest, options.manifest, options.assetsDir);

  if (options.check) {
    const issues = diffIntegrity(manifest.integrity ?? {}, integrity);
    if (issues.length === 0) {
      console.log(`Integrity hashes verified for ${Object.keys(integrity).length} asset(s).`);
      return 0;
    }
    for (const issue of issues) {
      console.error(issue);
    }
    return 1;
  }

  manifest.integrity = integrity;
  await fs.writeFile(options.manifest, `${JSON.stringify(manifest, null, 2)}\n`, "utf8");
  console.log(
    `Updated manifest with ${Object.keys(integrity).length} integrity entr${
      Object.keys(integrity).length === 1 ? "y" : "ies"
    }.`
  );
  return 0;
}

async function main() {
  let parsed;
  try {
    parsed = parseArgs(process.argv.slice(2));
  } catch (error) {
    console.error(error.message);
    process.exit(1);
  }

  if (parsed.help) {
    printHelp();
    process.exit(0);
  }

  try {
    const exitCode = await runAssetIntegrity(parsed);
    process.exit(exitCode);
  } catch (error) {
    console.error(error.message);
    process.exit(1);
  }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  main();
}
