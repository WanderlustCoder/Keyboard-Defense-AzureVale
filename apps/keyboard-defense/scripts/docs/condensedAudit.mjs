#!/usr/bin/env node
/**
 * Responsive condensed audit.
 * Validates that required panels/breakpoints are backed by snapshot metadata.
 */
import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";
import YAML from "yaml";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const APP_ROOT = path.resolve(__dirname, "..", "..");
const WORKSPACE_ROOT = path.resolve(APP_ROOT, "..", "..");

const DEFAULT_MATRIX = path.resolve(
  WORKSPACE_ROOT,
  "docs",
  "codex_pack",
  "fixtures",
  "responsive",
  "condensed-matrix.yml"
);
const DEFAULT_META_DIRS = [
  path.resolve(WORKSPACE_ROOT, "docs", "codex_pack", "fixtures", "ui-snapshot"),
  path.resolve(WORKSPACE_ROOT, "artifacts", "screenshots")
];

function toArrayPath(spec) {
  if (Array.isArray(spec)) {
    return spec;
  }
  if (typeof spec === "string" && spec.trim().length > 0) {
    return spec.split(".").filter((segment) => segment.length > 0);
  }
  throw new Error(`Invalid path specification: ${JSON.stringify(spec)}`);
}

function getByPath(target, pathSpec) {
  const segments = toArrayPath(pathSpec);
  let current = target;
  for (const segment of segments) {
    if (current === null || current === undefined) {
      return undefined;
    }
    current = current[segment];
  }
  return current;
}

export function parseArgs(argv = process.argv.slice(2)) {
  const args = {
    matrixPath: DEFAULT_MATRIX,
    metaDirs: [...DEFAULT_META_DIRS],
    help: false,
    outJson: null,
    outMarkdown: null
  };
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (token === "--help" || token === "-h") {
      args.help = true;
      return args;
    }
    if (token === "--matrix") {
      const next = argv[i + 1];
      if (!next) {
        throw new Error("Missing value for --matrix.");
      }
      args.matrixPath = path.resolve(process.cwd(), next);
      i += 1;
      continue;
    }
    if (token === "--meta") {
      const next = argv[i + 1];
      if (!next) {
        throw new Error("Missing value for --meta.");
      }
      args.metaDirs.push(path.resolve(process.cwd(), next));
      i += 1;
      continue;
    }
    if (token === "--out-json") {
      const next = argv[i + 1];
      if (!next) throw new Error("Missing value for --out-json.");
      args.outJson = path.resolve(process.cwd(), next);
      i += 1;
      continue;
    }
    if (token === "--out-md" || token === "--out-markdown") {
      const next = argv[i + 1];
      if (!next) throw new Error("Missing value for --out-md.");
      args.outMarkdown = path.resolve(process.cwd(), next);
      i += 1;
      continue;
    }
    throw new Error(`Unknown argument "${token}". Use --help for usage.`);
  }
  return args;
}

export async function loadMatrix(file) {
  const raw = await fs.readFile(file, "utf8");
  const parsed = YAML.parse(raw);
  if (!parsed || typeof parsed !== "object" || !Array.isArray(parsed.panels)) {
    throw new Error("Condensed matrix must contain a panels array.");
  }
  return parsed;
}

export async function loadSnapshots(metaDirs) {
  const snapshots = new Map();
  for (const dir of metaDirs) {
    if (!dir) continue;
    let entries;
    try {
      entries = await fs.readdir(dir);
    } catch {
      continue;
    }
    for (const entry of entries) {
      if (!entry.toLowerCase().endsWith(".meta.json")) {
        continue;
      }
      const file = path.join(dir, entry);
      let data;
      try {
        const raw = await fs.readFile(file, "utf8");
        data = JSON.parse(raw);
      } catch (error) {
        console.warn(`condensedAudit: unable to parse ${file}: ${error?.message ?? error}`);
        continue;
      }
      const id = typeof data?.id === "string" ? data.id : path.basename(entry, ".meta.json");
      if (!snapshots.has(id)) {
        snapshots.set(id, { ...data, __file: file });
      }
    }
  }
  return snapshots;
}

function formatFailure(panelId, requirement, message) {
  return {
    panelId,
    snapshot: requirement?.snapshot ?? null,
    breakpoint: requirement?.breakpoint ?? null,
    message
  };
}

export function evaluateMatrix(matrix, snapshots) {
  const failures = [];
  let checks = 0;

  for (const panel of matrix.panels ?? []) {
    if (!panel.id || !panel.toggleSelector || !panel.preferenceKey) {
      failures.push(
        formatFailure(panel.id ?? "<missing>", null, "Panel entry is missing required fields.")
      );
      continue;
    }
    for (const requirement of panel.requirements ?? []) {
      const snapshot = requirement?.snapshot ? snapshots.get(requirement.snapshot) : null;
      if (!snapshot) {
        if (requirement?.optional) {
          continue;
        }
        failures.push(
          formatFailure(
            panel.id,
            requirement,
            `Missing snapshot metadata for "${requirement?.snapshot}".`
          )
        );
        continue;
      }
      for (const assertion of requirement.assertions ?? []) {
        checks += 1;
        const result = evaluateAssertion(assertion, snapshot);
        if (!result.ok) {
          const message = assertion.message
            ? `${assertion.message}: ${result.message}`
            : result.message;
          failures.push(formatFailure(panel.id, requirement, message));
        }
      }
    }
  }

  return {
    ok: failures.length === 0,
    failures,
    checks
  };
}

function evaluateAssertion(assertion, snapshot) {
  const type = assertion?.type ?? "path";
  switch (type) {
    case "badge": {
      const badges = Array.isArray(snapshot?.badges) ? snapshot.badges : [];
      if (!assertion.includes) {
        return { ok: false, message: "Badge assertion missing 'includes' value." };
      }
      const matched = badges.includes(assertion.includes);
      return matched
        ? { ok: true }
        : { ok: false, message: `Expected badge "${assertion.includes}" to be present.` };
    }
    case "path": {
      if (!assertion.path) {
        return { ok: false, message: "Path assertion missing 'path'." };
      }
      const actual = getByPath(snapshot, assertion.path);
      if ("equals" in assertion) {
        return Object.is(actual, assertion.equals)
          ? { ok: true }
          : {
            ok: false,
            message: `Value at ${JSON.stringify(assertion.path)} expected ${
              assertion.equals
            } but found ${actual}.`
          };
      }
      if (assertion.truthy) {
        return actual ? { ok: true } : { ok: false, message: `Value at ${assertion.path} is not truthy.` };
      }
      if (assertion.falsy) {
        return !actual
          ? { ok: true }
          : { ok: false, message: `Value at ${assertion.path} is not falsy.` };
      }
      return { ok: false, message: "Unsupported path assertion (provide equals/truthy/falsy)." };
    }
    default:
      return { ok: false, message: `Unsupported assertion type "${type}".` };
  }
}

export async function runCondensedAudit({ matrixPath, metaDirs }) {
  const matrix = await loadMatrix(matrixPath);
  const snapshots = await loadSnapshots(metaDirs);
  const evaluation = evaluateMatrix(matrix, snapshots);
  return { ...evaluation, panels: matrix.panels.length, snapshotsChecked: snapshots.size };
}

async function writeSummaryFiles(result, args) {
  if (!args.outJson && !args.outMarkdown) {
    return;
  }
  const summary = {
    generatedAt: new Date().toISOString(),
    ok: result.ok,
    panelsChecked: result.panels,
    snapshotsChecked: result.snapshotsChecked,
    checks: result.checks,
    failures: result.failures
  };
  if (args.outJson) {
    await fs.mkdir(path.dirname(args.outJson), { recursive: true });
    await fs.writeFile(args.outJson, JSON.stringify(summary, null, 2), "utf8");
  }
  if (args.outMarkdown) {
    await fs.mkdir(path.dirname(args.outMarkdown), { recursive: true });
    const lines = [];
    lines.push("# Responsive Condensed Audit");
    lines.push("");
    lines.push(`- Generated at: ${summary.generatedAt}`);
    lines.push(`- Status: ${summary.ok ? "PASS" : "FAIL"}`);
    lines.push(
      `- Panels checked: ${summary.panelsChecked} (snapshots scanned: ${summary.snapshotsChecked})`
    );
    lines.push(`- Checks executed: ${summary.checks}`);
    lines.push("");
    if (summary.failures.length === 0) {
      lines.push("No failures detected.");
    } else {
      lines.push("| Panel | Snapshot | Breakpoint | Detail |");
      lines.push("| --- | --- | --- | --- |");
      for (const failure of summary.failures) {
        lines.push(
          `| ${failure.panelId ?? "-"} | ${failure.snapshot ?? "-"} | ${failure.breakpoint ?? "-"} | ${failure.message} |`
        );
      }
    }
    await fs.writeFile(args.outMarkdown, lines.join("\n"), "utf8");
  }
}

function printHelp() {
  console.log("Usage:");
  console.log(
    "  node scripts/docs/condensedAudit.mjs [--matrix <file>] [--meta <dir>] [--out-json <file>] [--out-md <file>]"
  );
  console.log("Runs the responsive condensed checklist against HUD snapshot metadata.");
}

async function main() {
  let parsed;
  try {
    parsed = parseArgs();
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
    return;
  }
  if (parsed.help) {
    printHelp();
    return;
  }
  try {
    const result = await runCondensedAudit(parsed);
    await writeSummaryFiles(result, parsed);
    if (!result.ok) {
      console.error("Condensed audit failed:");
      for (const failure of result.failures) {
        const parts = [`panel="${failure.panelId ?? "<unknown>"}"`];
        if (failure.snapshot) parts.push(`snapshot="${failure.snapshot}"`);
        if (failure.breakpoint) parts.push(`breakpoint="${failure.breakpoint}"`);
        console.error(` - ${parts.join(" ")} - ${failure.message}`);
      }
      console.error(`Checks executed: ${result.checks}`);
      process.exit(1);
      return;
    }
    console.log(
      `Condensed audit passed (${result.checks} checks across ${result.panels} panels, ${result.snapshotsChecked} snapshots scanned).`
    );
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
  }
}

if (import.meta.url === `file://${process.argv[1]}` || process.argv[1]?.endsWith("condensedAudit.mjs")) {
  await main();
}
