#!/usr/bin/env node

import { promises as fs } from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";
import { createHash } from "node:crypto";

const DEFAULT_MANIFEST = "public/assets/manifest.json";
const DEFAULT_TELEMETRY_PATH = path.resolve("artifacts", "summaries", "asset-integrity.json");
const DEFAULT_TELEMETRY_MD_PATH = path.resolve("artifacts", "summaries", "asset-integrity.md");
const DEFAULT_HISTORY_PATH = path.resolve("artifacts", "history", "asset-integrity.log");
const DEFAULT_SCENARIO_CI = "ci-build";
const DEFAULT_SCENARIO_LOCAL = "local";
const MODES = new Set(["soft", "strict", "off"]);

function printHelp() {
  console.log(`Keyboard Defense asset integrity helper

Usage:
  node scripts/assetIntegrity.mjs [options]

Options:
  --manifest <path>   Manifest JSON path (default ${DEFAULT_MANIFEST})
  --assets <dir>      Directory that contains the manifest's assets (defaults to manifest directory)
  --check             Verify existing integrity hashes instead of writing
  --mode <mode>       Integrity mode: soft (default), strict, or off (skip verification failures)
  --scenario <name>   Scenario label for telemetry (default "ci-build" when CI=1, otherwise "local")
  --telemetry <file>  Write telemetry JSON describing the integrity run (default in CI)
  --telemetry-md <file>
                      Markdown summary output (default alongside telemetry JSON when CI=1)
  --history <file>    Append telemetry rows to a newline-delimited log (default artifacts/history/asset-integrity.log in CI)
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
    help: false,
    mode: null,
    telemetry: undefined,
    telemetryMarkdown: undefined,
    scenario: null,
    history: undefined
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
      case "--mode": {
        const value = argv[++i];
        if (!value) {
          throw new Error("Expected value after --mode");
        }
        options.mode = value;
        break;
      }
      case "--telemetry": {
        const value = argv[++i];
        if (!value) {
          throw new Error("Expected value after --telemetry");
        }
        options.telemetry = value;
        break;
      }
      case "--telemetry-md": {
        const value = argv[++i];
        if (!value) {
          throw new Error("Expected value after --telemetry-md");
        }
        options.telemetryMarkdown = value;
        break;
      }
      case "--history": {
        const value = argv[++i];
        if (!value) {
          throw new Error("Expected value after --history");
        }
        options.history = value;
        break;
      }
      case "--scenario": {
        const value = argv[++i];
        if (!value) {
          throw new Error("Expected value after --scenario");
        }
        options.scenario = value;
        break;
      }
      case "--help":
        options.help = true;
        break;
      default:
        throw new Error(`Unknown flag: ${token}`);
    }
  }

  const resolvedManifest = path.resolve(options.manifest);
  const resolvedAssets = path.resolve(options.assetsDir ?? path.dirname(resolvedManifest));

  const envMode = process.env.ASSET_INTEGRITY_MODE;
  const resolvedMode =
    (options.mode ?? envMode ?? (options.check ? "soft" : "off")).toLowerCase();
  if (!MODES.has(resolvedMode)) {
    throw new Error(`Unsupported integrity mode "${resolvedMode}". Use soft, strict, or off.`);
  }

  const telemetryPathRaw =
    options.telemetry ??
    process.env.ASSET_INTEGRITY_SUMMARY ??
    (process.env.CI ? DEFAULT_TELEMETRY_PATH : null);
  const telemetryMarkdownRaw =
    options.telemetryMarkdown ??
    process.env.ASSET_INTEGRITY_SUMMARY_MD ??
    (process.env.CI ? DEFAULT_TELEMETRY_MD_PATH : null);
  const historyPathRaw =
    options.history ??
    process.env.ASSET_INTEGRITY_HISTORY ??
    (process.env.CI ? DEFAULT_HISTORY_PATH : null);

  const resolveOptionalPath = (target) => (target ? path.resolve(target) : null);

  const scenario =
    options.scenario ??
    process.env.ASSET_INTEGRITY_SCENARIO ??
    (process.env.CI ? DEFAULT_SCENARIO_CI : DEFAULT_SCENARIO_LOCAL);

  return {
    manifest: resolvedManifest,
    assetsDir: resolvedAssets,
    check: options.check,
    help: options.help,
    mode: resolvedMode,
    telemetry: resolveOptionalPath(telemetryPathRaw),
    telemetryMarkdown: resolveOptionalPath(telemetryMarkdownRaw),
    history: resolveOptionalPath(historyPathRaw),
    scenario
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
  const startedAt = Date.now();
  const manifest = await loadManifest(options.manifest);
  const integrity = await buildIntegrityMap(manifest, options.manifest, options.assetsDir);
  const summary = summarizeIntegrity({
    manifest,
    manifestPath: options.manifest,
    computed: integrity,
    existing: manifest.integrity ?? {},
    durationMs: Date.now() - startedAt,
    scenario: options.scenario,
    mode: options.mode
  });

  if (options.telemetry || options.telemetryMarkdown) {
    await writeTelemetry(summary, options.telemetry, options.telemetryMarkdown);
  }
  if (options.history) {
    await appendHistory(summary, options.history);
  }

  const issuesDetected =
    summary.failed > 0 || summary.missingHash > 0 || summary.extraEntries > 0;
  if (options.check) {
    if (issuesDetected) {
      logIntegrityIssues(summary);
    } else {
      console.log(
        `Integrity hashes verified for ${summary.checked} asset(s) in ${summary.durationMs} ms.`
      );
    }
  }

  if (!options.check) {
    manifest.integrity = integrity;
    await fs.writeFile(options.manifest, `${JSON.stringify(manifest, null, 2)}\n`, "utf8");
    console.log(
      `Updated manifest with ${Object.keys(integrity).length} integrity entr${
        Object.keys(integrity).length === 1 ? "y" : "ies"
      }.`
    );
    return 0;
  }

  const strictMode = options.mode === "strict";
  if (!issuesDetected) {
    return 0;
  }

  if (strictMode) {
    return 1;
  }
  // Soft mode: mismatches always fail, missing hashes or extras fail as well to preserve previous behavior.
  return 1;
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

function summarizeIntegrity({
  manifest,
  manifestPath,
  computed,
  existing,
  durationMs,
  scenario,
  mode
}) {
  const stats = {
    checked: 0,
    missingHash: 0,
    failed: 0,
    extraEntries: 0,
    firstFailure: null
  };
  const failures = [];
  const existingEntries = { ...existing };
  const images = manifest.images ?? {};

  for (const [key, digest] of Object.entries(computed)) {
    const current = existingEntries[key];
    if (!current) {
      stats.missingHash += 1;
      failures.push({
        key,
        type: "missing",
        path: images[key] ?? null
      });
    } else if (current !== digest) {
      stats.failed += 1;
      failures.push({
        key,
        type: "mismatch",
        path: images[key] ?? null,
        expected: digest,
        actual: current
      });
    } else {
      stats.checked += 1;
    }
    delete existingEntries[key];
  }

  const leftoverKeys = Object.keys(existingEntries);
  stats.extraEntries = leftoverKeys.length;
  if (leftoverKeys.length > 0) {
    failures.push({
      key: leftoverKeys[0],
      type: "unreferenced",
      path: null,
      expected: null,
      actual: existingEntries[leftoverKeys[0]]
    });
  }

  stats.firstFailure = failures.length > 0 ? failures[0] : null;

  return {
    scenario,
    mode,
    strictMode: mode === "strict",
    manifest: path.relative(process.cwd(), manifestPath),
    checked: stats.checked,
    missingHash: stats.missingHash,
    failed: stats.failed,
    extraEntries: stats.extraEntries,
    totalImages: Object.keys(computed).length,
    durationMs,
    timestamp: new Date().toISOString(),
    firstFailure: stats.firstFailure
  };
}

async function writeTelemetry(summary, jsonPath, markdownPath) {
  if (jsonPath) {
    await fs.mkdir(path.dirname(jsonPath), { recursive: true });
    await fs.writeFile(jsonPath, JSON.stringify(summary, null, 2), "utf8");
    console.log(`Asset integrity telemetry written to ${jsonPath}`);
  }
  if (markdownPath) {
    const lines = [];
    lines.push(`Scenario: ${summary.scenario}`);
    lines.push(`Manifest: ${summary.manifest}`);
    lines.push(`Checked: ${summary.checked}`);
    lines.push(`Missing hash: ${summary.missingHash}`);
    lines.push(`Failed: ${summary.failed}`);
    lines.push(`Extra entries: ${summary.extraEntries}`);
    lines.push(`Strict mode: ${summary.strictMode ? "yes" : "no"}`);
    if (summary.firstFailure) {
      const failure = summary.firstFailure;
      const location = failure.path ? `${failure.key} (${failure.path})` : failure.key;
      lines.push(`First failure: ${location} [${failure.type}]`);
      if (failure.expected || failure.actual) {
        lines.push(`  expected: ${failure.expected ?? "-"}`);
        lines.push(`  actual: ${failure.actual ?? "-"}`);
      }
    }
    lines.push(`Duration: ${summary.durationMs} ms`);
    lines.push(`Timestamp: ${summary.timestamp}`);
    await fs.mkdir(path.dirname(markdownPath), { recursive: true });
    await fs.writeFile(markdownPath, `${lines.join("\n")}\n`, "utf8");
    console.log(`Asset integrity Markdown summary written to ${markdownPath}`);
  }
}

async function appendHistory(summary, historyPath) {
  if (!historyPath) return;
  await fs.mkdir(path.dirname(historyPath), { recursive: true });
  await fs.appendFile(historyPath, `${JSON.stringify(summary)}\n`, "utf8");
  console.log(`Asset integrity history appended to ${historyPath}`);
}

function logIntegrityIssues(summary) {
  const parts = [];
  if (summary.failed > 0) {
    parts.push(`${summary.failed} mismatched digest(s)`);
  }
  if (summary.missingHash > 0) {
    parts.push(`${summary.missingHash} missing hash entr${summary.missingHash === 1 ? "y" : "ies"}`);
  }
  if (summary.extraEntries > 0) {
    parts.push(`${summary.extraEntries} unreferenced integrity entr${summary.extraEntries === 1 ? "y" : "ies"}`);
  }
  console.error(
    `Asset integrity check failed: ${parts.join(", ")}. See telemetry for details.`
  );
}
