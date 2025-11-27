#!/usr/bin/env node

import { execSync } from "node:child_process";
import { promises as fs } from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";
import Ajv from "ajv";
import addFormats from "ajv-formats";

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const APP_ROOT = path.resolve(SCRIPT_DIR, "../..");
const DEFAULT_SCHEMA = path.join(APP_ROOT, "schemas/analytics.schema.json");
const DEFAULT_JSON_REPORT = path.join(APP_ROOT, "artifacts/summaries/analytics-validate.ci.json");
const DEFAULT_MD_REPORT = path.join(APP_ROOT, "artifacts/summaries/analytics-validate.ci.md");
const VALID_MODES = new Set(["fail", "warn", "info"]);

function printHelp() {
  console.log(`Analytics Schema Validator

Usage:
  node scripts/analytics/validate-schema.mjs [options] <file|directory ...>

Options:
  --schema <path>       Path to analytics.schema.json (default: ${DEFAULT_SCHEMA})
  --report <path>       JSON report output (default: ${DEFAULT_JSON_REPORT})
  --no-report           Skip writing the JSON report
  --report-md <path>    Markdown summary output (default: ${DEFAULT_MD_REPORT})
  --no-md-report        Skip writing the Markdown report
  --mode <fail|warn|info>    Control exit status when failures occur (default: fail)
  --help                Show this message`);
}

function parseArgs(argv) {
  const options = {
    schema: DEFAULT_SCHEMA,
    jsonReport: DEFAULT_JSON_REPORT,
    writeJsonReport: true,
    markdownReport: DEFAULT_MD_REPORT,
    writeMarkdownReport: true,
    mode: "fail",
    targets: [],
    help: false
  };
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--schema": {
        options.schema = argv[++i] ?? options.schema;
        break;
      }
      case "--report": {
        options.jsonReport = argv[++i] ?? options.jsonReport;
        options.writeJsonReport = true;
        break;
      }
      case "--no-report": {
        options.writeJsonReport = false;
        break;
      }
      case "--report-md": {
        options.markdownReport = argv[++i] ?? options.markdownReport;
        options.writeMarkdownReport = true;
        break;
      }
      case "--no-md-report": {
        options.writeMarkdownReport = false;
        break;
      }
      case "--mode": {
        const value = (argv[++i] ?? "").toLowerCase();
        if (!VALID_MODES.has(value)) {
          throw new Error(`--mode must be one of: ${Array.from(VALID_MODES).join(", ")}`);
        }
        options.mode = value;
        break;
      }
      case "--help": {
        options.help = true;
        break;
      }
      default:
        if (token.startsWith("-")) {
          throw new Error(`Unknown option '${token}'. Use --help for usage.`);
        }
        options.targets.push(token);
    }
  }
  return options;
}

async function collectFiles(targets) {
  const files = new Set();

  const readDirRecursive = async (dir) => {
    const entries = await fs.readdir(dir, { withFileTypes: true });
    for (const entry of entries) {
      const entryPath = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        await readDirRecursive(entryPath);
      } else if (entry.isFile() && entry.name.toLowerCase().endsWith(".json")) {
        files.add(entryPath);
      }
    }
  };

  for (const target of targets) {
    const resolved = path.resolve(target);
    let stat;
    try {
      stat = await fs.stat(resolved);
    } catch {
      continue;
    }
    if (stat.isDirectory()) {
      await readDirRecursive(resolved);
    } else if (resolved.toLowerCase().endsWith(".json")) {
      files.add(resolved);
    }
  }
  return Array.from(files);
}

async function loadSchema(schemaPath) {
  const schemaRaw = await fs.readFile(schemaPath, "utf8");
  return JSON.parse(schemaRaw);
}

function createValidator(schema) {
  const ajv = new Ajv({ allErrors: true, strict: false });
  addFormats(ajv);
  return ajv.compile(schema);
}

async function validateFile(file, validate) {
  try {
    const raw = await fs.readFile(file, "utf8");
    const data = JSON.parse(raw);
    const valid = validate(data);
    return {
      file,
      valid,
      errors: valid
        ? []
        : (validate.errors ?? []).map((error) => ({
            message: error.message,
            instancePath: error.instancePath,
            schemaPath: error.schemaPath
          }))
    };
  } catch (error) {
    return {
      file,
      valid: false,
      errors: [{ message: error?.message ?? String(error), instancePath: "", schemaPath: "" }]
    };
  }
}

function summarizeResults(results) {
  return results.reduce(
    (acc, result) => {
      acc.total += 1;
      if (result.valid) {
        acc.passed += 1;
      } else {
        acc.failed += 1;
        acc.errorCount += result.errors.length;
      }
      return acc;
    },
    { total: 0, passed: 0, failed: 0, errorCount: 0 }
  );
}

function detectGitSha() {
  try {
    const output = execSync("git rev-parse HEAD", {
      cwd: APP_ROOT,
      stdio: ["ignore", "pipe", "ignore"]
    });
    return output.toString().trim() || null;
  } catch {
    return null;
  }
}

function relativeToBase(file, baseDir = APP_ROOT) {
  return path.relative(baseDir, file) || path.basename(file);
}

function renderMarkdownReport(results, meta) {
  const { summary, generatedAt, schema, gitSha, mode, baseDir = APP_ROOT } = meta;
  const lines = [];
  lines.push("# Analytics Schema Validation");
  lines.push("");
  lines.push(`- Generated: ${generatedAt}`);
  lines.push(`- Schema: \`${schema}\``);
  lines.push(`- Mode: \`${mode}\``);
  if (gitSha) {
    lines.push(`- Git SHA: \`${gitSha}\``);
  }
  lines.push(`- Files: ${summary.total} (✅ ${summary.passed}, ❌ ${summary.failed})`);
  lines.push("");
  lines.push("| File | Result | Errors |");
  lines.push("| --- | --- | --- |");
  for (const result of results) {
    const displayPath = relativeToBase(result.file, baseDir).replace(/\|/g, "\\|");
    const status = result.valid ? "✅ Pass" : `❌ Fail (${result.errors.length})`;
    const errorText =
      result.errors.length === 0
        ? "—"
        : result.errors
            .map((error) => `${error.instancePath || "/"} ${error.message || "invalid"}`)
            .join("<br>");
    lines.push(`| ${displayPath} | ${status} | ${errorText.replace(/\|/g, "\\|")} |`);
  }
  if (summary.failed > 0) {
    lines.push("");
    lines.push("## Triage");
    lines.push(
      "Refer to `docs/analytics_schema.md` for field descriptions and bump the schema version when incompatible changes land."
    );
  }
  lines.push("");
  lines.push(
    "_Generated by `node scripts/analytics/validate-schema.mjs`_"
  );
  lines.push("");
  return lines.join("\n");
}

async function writeJsonReport(reportPath, payload) {
  await fs.mkdir(path.dirname(path.resolve(reportPath)), { recursive: true });
  await fs.writeFile(reportPath, JSON.stringify(payload, null, 2), "utf8");
}

async function writeMarkdownReport(reportPath, contents) {
  await fs.mkdir(path.dirname(path.resolve(reportPath)), { recursive: true });
  await fs.writeFile(reportPath, contents, "utf8");
}

async function main(argv) {
  const options = parseArgs(argv);
  if (options.help) {
    printHelp();
    return 0;
  }
  if (options.targets.length === 0) {
    printHelp();
    return 1;
  }

  const files = await collectFiles(options.targets);
  if (files.length === 0) {
    console.error("validate-schema: no JSON snapshots found for provided targets.");
    return 1;
  }

  const schema = await loadSchema(options.schema);
  const validate = createValidator(schema);
  const results = [];
  let hasFailures = false;
  for (const file of files) {
    const result = await validateFile(file, validate);
    if (!result.valid) {
      hasFailures = true;
    }
    results.push(result);
  }

  const generatedAt = new Date().toISOString();
  const summary = summarizeResults(results);
  const gitSha = detectGitSha();
  const targets = options.targets.map((target) => path.resolve(target));
  const basePayload = {
    generatedAt,
    schema: path.resolve(options.schema),
    mode: options.mode,
    gitSha,
    summary,
    targets
  };

  if (options.writeJsonReport && options.jsonReport) {
    await writeJsonReport(options.jsonReport, {
      ...basePayload,
      files
    });
  }

  if (options.writeMarkdownReport && options.markdownReport) {
    const markdown = renderMarkdownReport(results, {
      ...basePayload,
      baseDir: APP_ROOT
    });
    await writeMarkdownReport(options.markdownReport, markdown);
  }

  for (const result of results) {
    if (!result.valid) {
      console.error(`❌ ${result.file}`);
      for (const error of result.errors) {
        console.error(`  - ${error.instancePath || "/"} ${error.message || "invalid"}`);
      }
    } else {
      console.log(`✔ ${result.file}`);
    }
  }

  if (hasFailures && options.mode !== "fail") {
    console.warn(
      `validate-schema: ${summary.failed} file(s) failed but exiting 0 because --mode=${options.mode}`
    );
  }

  return hasFailures && options.mode === "fail" ? 1 : 0;
}

const isCliInvocation =
  typeof process.argv[1] === "string" &&
  fileURLToPath(import.meta.url) === path.resolve(process.argv[1]);

if (isCliInvocation) {
  main(process.argv.slice(2))
    .then((code) => {
      if (typeof code === "number") {
        process.exit(code);
      }
    })
    .catch((error) => {
      console.error(error instanceof Error ? error.stack ?? error.message : error);
      process.exit(1);
    });
}

export {
  collectFiles,
  loadSchema,
  createValidator,
  validateFile,
  summarizeResults,
  renderMarkdownReport
};
