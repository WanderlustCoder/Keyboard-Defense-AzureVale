#!/usr/bin/env node

import { readFile } from "node:fs/promises";
import path from "node:path";
import process from "node:process";

const DEFAULT_CATALOG = path.resolve("docs/taunts/catalog.json");
const VALID_RARITIES = new Set(["boss", "elite", "affix"]);

export function parseArgs(argv = []) {
  const options = {
    catalog: DEFAULT_CATALOG,
    help: false
  };
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--catalog":
        options.catalog = path.resolve(argv[++i] ?? DEFAULT_CATALOG);
        break;
      case "--help":
        options.help = true;
        break;
      default:
        throw new Error(`Unknown option '${token}'. Use --help for usage.`);
    }
  }
  return options;
}

export async function loadCatalog(filePath) {
  const absolute = path.resolve(filePath);
  const raw = await readFile(absolute, "utf8");
  const data = JSON.parse(raw);
  if (Array.isArray(data)) return data;
  if (Array.isArray(data.entries)) return data.entries;
  return [];
}

export function validateCatalogEntries(entries) {
  const errors = [];
  const warnings = [];
  const seenIds = new Set();
  const seenText = new Set();
  for (const entry of entries) {
    if (!entry?.id || typeof entry.id !== "string") {
      errors.push("Taunt entry missing string id.");
      continue;
    }
    if (seenIds.has(entry.id)) {
      errors.push(`Duplicate taunt id '${entry.id}'.`);
    }
    seenIds.add(entry.id);
    if (!entry.text || typeof entry.text !== "string") {
      errors.push(`Taunt '${entry.id}' is missing text.`);
    } else if (seenText.has(entry.text.trim())) {
      warnings.push(`Duplicate taunt text detected for '${entry.id}'.`);
    }
    seenText.add(entry.text?.trim() ?? "");
    if (!entry.enemyType || typeof entry.enemyType !== "string") {
      errors.push(`Taunt '${entry.id}' missing enemyType.`);
    }
    if (!VALID_RARITIES.has(entry.rarity)) {
      errors.push(
        `Taunt '${entry.id}' has invalid rarity '${entry.rarity}'. Expected ${Array.from(VALID_RARITIES).join(
          ", "
        )}.`
      );
    }
    if (!Array.isArray(entry.tags) || entry.tags.length === 0) {
      errors.push(`Taunt '${entry.id}' requires at least one tag.`);
    } else if (!entry.tags.some((tag) => tag.startsWith("episode"))) {
      warnings.push(`Taunt '${entry.id}' is missing an episode tag.`);
    }
  }
  if (entries.length === 0) {
    warnings.push("No taunt entries found.");
  }
  return { errors, warnings };
}

function printHelp() {
  console.log(`Taunt Catalog Validator

Usage:
  node scripts/taunts/validateCatalog.mjs [--catalog <path>]

Validates taunt JSON files for duplicate ids/text and required metadata. Exits
with code 1 when validation fails.`);
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
  try {
    const entries = await loadCatalog(options.catalog);
    const { errors, warnings } = validateCatalogEntries(entries);
    for (const warning of warnings) {
      console.warn(`⚠️ ${warning}`);
    }
    if (errors.length > 0) {
      for (const error of errors) {
        console.error(`❌ ${error}`);
      }
      process.exit(1);
      return;
    }
    console.log(`Taunt catalog OK (${entries.length} entries checked).`);
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
  }
}

if (
  import.meta.url === `file://${process.argv[1]}` ||
  process.argv[1]?.endsWith("validateCatalog.mjs")
) {
  await main();
}
