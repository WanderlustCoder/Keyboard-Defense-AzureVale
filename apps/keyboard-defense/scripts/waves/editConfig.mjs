#!/usr/bin/env node

import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import { fileURLToPath, pathToFileURL } from "node:url";
import Ajv from "ajv";
import addFormats from "ajv-formats";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const APP_ROOT = path.resolve(__dirname, "../..");
const DEFAULT_INPUT = path.join(APP_ROOT, "config", "waves.designer.json");
const DEFAULT_OUTPUT = DEFAULT_INPUT;
const DEFAULT_SCHEMA = path.join(APP_ROOT, "schemas", "wave-config.schema.json");
const DEFAULT_CORE_CONFIG = path.join(APP_ROOT, "public", "dist", "src", "core", "config.js");

function printHelp() {
  console.log(`Wave Config Editor

Usage:
  node scripts/waves/editConfig.mjs [options]

Options:
  --input <path>          Input wave config JSON (default: ${DEFAULT_INPUT})
  --output <path>         Output path (default: same as input)
  --schema <path>         Schema path (default: ${DEFAULT_SCHEMA})
  --create-from-core      Generate config from compiled core config (no edits applied)
  --force                 Allow overwriting output file
  --set-toggle key=val    Set feature toggle (dynamicSpawns, eliteAffixes, evacuationEvents, bossMechanics)
                          repeatable. val accepts true/false/1/0
  --summarize             Print wave summary instead of writing file (still validates)
  --no-write              Skip writing output
  --help                  Show this message

Examples:
  # Validate and summarize existing designer config
  npm run wave:edit -- --summarize

  # Create a fresh designer config from core defaults
  npm run wave:edit -- --create-from-core --output config/waves.designer.json --force

  # Toggle evacuation events off and save
  npm run wave:edit -- --set-toggle evacuationEvents=false
`);
}

function parseArgs(argv) {
  const toggles = {};
  const args = {
    input: DEFAULT_INPUT,
    output: DEFAULT_OUTPUT,
    schema: DEFAULT_SCHEMA,
    createFromCore: false,
    force: false,
    summarize: false,
    write: true,
    toggles
  };
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--input":
        args.input = argv[++i] ?? args.input;
        break;
      case "--output":
        args.output = argv[++i] ?? args.output;
        break;
      case "--schema":
        args.schema = argv[++i] ?? args.schema;
        break;
      case "--create-from-core":
        args.createFromCore = true;
        break;
      case "--force":
        args.force = true;
        break;
      case "--summarize":
        args.summarize = true;
        break;
      case "--no-write":
        args.write = false;
        break;
      case "--set-toggle": {
        const raw = argv[++i] ?? "";
        const [key, value] = raw.split("=");
        if (!key || value === undefined) {
          throw new Error("--set-toggle expects key=value");
        }
        toggles[key] = parseBool(value);
        break;
      }
      case "--help":
        args.help = true;
        break;
      default:
        if (token.startsWith("-")) {
          throw new Error(`Unknown option ${token}`);
        }
    }
  }
  return args;
}

function parseBool(value) {
  const normalized = String(value).toLowerCase().trim();
  return normalized === "true" || normalized === "1" || normalized === "yes" || normalized === "on";
}

async function loadJson(file) {
  const raw = await fs.readFile(file, "utf8");
  return JSON.parse(raw);
}

async function loadSchema(schemaPath) {
  const raw = await fs.readFile(schemaPath, "utf8");
  return JSON.parse(raw);
}

function compileValidator(schema) {
  const ajv = new Ajv({ allErrors: true, strict: false });
  addFormats(ajv);
  return ajv.compile(schema);
}

async function buildFromCore(corePath = DEFAULT_CORE_CONFIG) {
  const mod = await import(pathToFileURL(corePath).href);
  const config = mod.defaultConfig ?? mod.default ?? mod.config ?? null;
  if (!config) {
    throw new Error(`Unable to load defaultConfig from ${corePath}`);
  }
  const enemyTiers = Object.keys(config.enemyTiers ?? {});
  const turretSlots = config.turretSlots?.map((slot) => ({
    id: slot.id,
    lane: slot.lane,
    unlockWave: slot.unlockWave
  }));
  const waves = (config.waves ?? []).map((wave) => ({
    id: wave.id,
    duration: wave.duration,
    rewardBonus: wave.rewardBonus ?? 0,
    spawns: wave.spawns?.map((spawn) => ({
      at: spawn.at,
      lane: spawn.lane,
      tierId: spawn.tierId,
      count: spawn.count,
      cadence: spawn.cadence,
      shield: spawn.shield,
      taunt: spawn.taunt
    })) ?? []
  }));
  return {
    featureToggles: {
      dynamicSpawns: Boolean(config.featureToggles?.dynamicSpawns),
      eliteAffixes: Boolean(config.featureToggles?.eliteAffixes),
      evacuationEvents: Boolean(config.featureToggles?.evacuationEvents),
      bossMechanics: Boolean(config.featureToggles?.bossMechanics)
    },
    enemyTiers,
    turretSlots,
    waves
  };
}

function applyToggles(config, toggles) {
  if (!config.featureToggles) {
    config.featureToggles = {};
  }
  for (const [key, value] of Object.entries(toggles)) {
    if (["dynamicSpawns", "eliteAffixes", "evacuationEvents", "bossMechanics"].includes(key)) {
      config.featureToggles[key] = Boolean(value);
    }
  }
  return config;
}

function summarize(config) {
  const lines = [];
  lines.push(`Waves: ${config.waves?.length ?? 0}`);
  for (const wave of config.waves ?? []) {
    const hazards = wave.hazards?.length ?? 0;
    const dynamic = wave.dynamicEvents?.length ?? 0;
    const evac = wave.evacuation ? "evac" : "";
    const boss = wave.boss ? "boss" : "";
    lines.push(
      ` - ${wave.id}: ${wave.spawns?.length ?? 0} spawns, hazards=${hazards}, dynamic=${dynamic}${
        evac ? ", evac" : ""
      }${boss ? ", boss" : ""}`
    );
  }
  return lines.join("\n");
}

async function ensureWritable(output, force) {
  try {
    await fs.stat(output);
    if (!force) {
      throw new Error(
        `Output ${output} already exists. Use --force to overwrite or pick a new --output`
      );
    }
  } catch (error) {
    if (error.code !== "ENOENT") {
      throw error;
    }
  }
}

async function main(argv) {
  const options = parseArgs(argv);
  if (options.help) {
    printHelp();
    return 0;
  }

  const schema = await loadSchema(options.schema);
  const validate = compileValidator(schema);

  let config;
  if (options.createFromCore) {
    config = await buildFromCore();
  } else {
    try {
      config = await loadJson(options.input);
    } catch (error) {
      throw new Error(`Failed to read input ${options.input}: ${error.message}`);
    }
  }

  applyToggles(config, options.toggles);
  const valid = validate(config);
  if (!valid) {
    console.error("Validation failed:");
    for (const err of validate.errors ?? []) {
      console.error(` - ${err.instancePath || "/"} ${err.message}`);
    }
    return 1;
  }

  if (options.summarize) {
    console.log("Wave summary:\n" + summarize(config));
  }

  if (options.write) {
    const output = options.output || options.input;
    await ensureWritable(output, options.force || options.createFromCore);
    await fs.mkdir(path.dirname(path.resolve(output)), { recursive: true });
    await fs.writeFile(output, JSON.stringify(config, null, 2), "utf8");
    console.log(`Wrote ${output}`);
  }

  return 0;
}

const isCli =
  typeof process.argv[1] === "string" &&
  fileURLToPath(import.meta.url) === path.resolve(process.argv[1]);

if (isCli) {
  main(process.argv.slice(2))
    .then((code) => {
      if (typeof code === "number") process.exit(code);
    })
    .catch((error) => {
      console.error(error instanceof Error ? error.message : error);
      process.exit(1);
    });
}

export { buildFromCore, applyToggles, summarize, loadSchema, compileValidator, parseArgs };
