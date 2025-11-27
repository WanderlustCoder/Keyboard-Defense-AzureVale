#!/usr/bin/env node
/**
 * Traceability report generator.
 *
 * Maps backlog entries to Codex tasks/tests and emits JSON + Markdown summaries
 * so CI can prove which specs are covered by which suites.
 */
import fs from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath, pathToFileURL } from "node:url";
import YAML from "yaml";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const APP_ROOT = path.resolve(__dirname, "..", "..");
const WORKSPACE_ROOT = path.resolve(APP_ROOT, "..", "..");

const DEFAULT_OPTIONS = {
  manifest: path.resolve(WORKSPACE_ROOT, "docs", "codex_pack", "manifest.yml"),
  backlog: path.resolve(APP_ROOT, "docs", "season1_backlog.md"),
  tasksDir: path.resolve(WORKSPACE_ROOT, "docs", "codex_pack", "tasks"),
  testReport: path.resolve(APP_ROOT, "artifacts", "summaries", "vitest-summary.json"),
  outJson: path.resolve(APP_ROOT, "artifacts", "summaries", "traceability-report.json"),
  outMarkdown: path.resolve(APP_ROOT, "artifacts", "summaries", "traceability-report.md"),
  mode: "warn",
  filters: null
};

const VALID_MODES = new Set(["info", "warn", "fail"]);

export function generateTraceabilityReport(options) {
  const manifestPath = options.manifest ?? DEFAULT_OPTIONS.manifest;
  const backlogPath = options.backlog ?? DEFAULT_OPTIONS.backlog;
  const tasksDir = options.tasksDir ?? DEFAULT_OPTIONS.tasksDir;
  const testReportPath = options.testReport ?? DEFAULT_OPTIONS.testReport;
  const filters = normalizeFilters(options.filters);

  const manifest = loadManifest(manifestPath);
  const taskMeta = loadTaskMetadata(manifest, manifestPath, tasksDir);
  const backlog = parseBacklog(backlogPath);
  const testStatus = loadTestStatus(testReportPath);

  const coverage = mapCoverage({
    manifest,
    taskMeta,
    backlog,
    testStatus,
    filters
  });

  return {
    generatedAt: new Date().toISOString(),
    inputs: {
      manifest: toDisplayPath(manifestPath),
      backlog: toDisplayPath(backlogPath),
      tasksDir: toDisplayPath(tasksDir),
      testReport: toDisplayPath(testReportPath),
      filters: filters ? Array.from(filters) : [],
      mode: options.mode ?? DEFAULT_OPTIONS.mode
    },
    warnings: [
      ...coverage.warnings,
      ...(testStatus.warning ? [testStatus.warning] : [])
    ],
    stats: coverage.stats,
    backlogItems: coverage.backlogItems,
    unmappedBacklog: coverage.unmappedBacklog,
    unmappedTests: coverage.unmappedTests
  };
}

export function buildMarkdown(report) {
  const lines = [];
  lines.push("## Traceability Report");
  lines.push("");
  lines.push(`Generated at: ${report.generatedAt}`);
  if (report.inputs?.filters?.length) {
    lines.push(`Filters: ${report.inputs.filters.join(", ")}`);
  }
  if (report.warnings?.length) {
    lines.push("");
    lines.push("### Warnings");
    for (const warning of report.warnings) {
      lines.push(`- ${warning}`);
    }
  }
  lines.push("");
  lines.push(
    "| Backlog | Title | Tasks | Tests | Status |",
    "| --- | --- | --- | --- | --- |"
  );
  for (const item of report.backlogItems) {
    const taskList =
      item.tasks.length > 0
        ? item.tasks.map((task) => `\`${task.id}\` (${task.status})`).join("<br>")
        : "_none_";
    const testList =
      item.tests.length > 0
        ? item.tests
            .map((test) => {
              const label = test.description ? `${test.description} – ` : "";
              return `${label}\`${test.path}\` (${test.status})`;
            })
            .join("<br>")
        : "_none_";
    lines.push(
      `| ${item.id} | ${escapePipe(item.title)} | ${taskList} | ${testList} | ${item.coverageStatus} |`
    );
  }

  const missing = report.backlogItems.filter((item) => item.tests.length === 0);
  if (missing.length) {
    lines.push("");
    lines.push("### Backlog Items Missing Tests");
    for (const item of missing) {
      lines.push(`- ${item.id} ${item.title}`);
    }
  }

  if (report.unmappedTests?.length) {
    lines.push("");
    lines.push("### Unmapped Tests");
    for (const test of report.unmappedTests) {
      lines.push(`- \`${test.path}\` (${test.status ?? "unknown"})`);
    }
  }

  if (report.unmappedBacklog?.length) {
    lines.push("");
    lines.push("### Invalid Backlog References");
    for (const entry of report.unmappedBacklog) {
      lines.push(`- ${entry.id} referenced by ${entry.tasks.join(", ")}`);
    }
  }

  return lines.join("\n");
}

function mapCoverage({ manifest, taskMeta, backlog, testStatus, filters }) {
  const backlogEntries = new Map();
  const missingBacklog = [];
  const usedTestKeys = new Set();
  const warnings = [];

  const shouldIncludeBacklog = (id) => {
    if (!filters) return true;
    return filters.has(id);
  };

  for (const task of manifest.tasks) {
    const meta = taskMeta.get(task.id);
    if (!meta) continue;
    const refs = Array.isArray(task.backlog_refs) ? task.backlog_refs : [];
    for (const ref of refs) {
      const normalizedId = normalizeBacklogId(ref);
      if (!normalizedId) continue;
      const backlogInfo = backlog.get(normalizedId);
      if (!backlogInfo) {
        missingBacklog.push({ id: normalizedId, tasks: [task.id] });
        continue;
      }
      if (!shouldIncludeBacklog(normalizedId)) continue;
      const entry = ensureBacklogEntry(backlogEntries, normalizedId, backlogInfo);
      entry.tasks.push({
        id: task.id,
        title: meta.title ?? task.title ?? task.id,
        status: task.status ?? "todo",
        priority: task.priority ?? "P3",
        traceability: meta.traceability,
        status_note: task.status_note ?? meta.status_note ?? null
      });

      for (const traceTest of meta.traceability.tests) {
        const canonical = canonicalizePath(traceTest.path);
        if (!canonical) continue;
        const status = testStatus.map.get(canonical);
        entry.tests.push({
          path: traceTest.path,
          description: traceTest.description ?? null,
          command: traceTest.command ?? null,
          status: status?.status ?? "unknown",
          lastRun: status?.lastRun ?? testStatus.generatedAt ?? null,
          source: status?.source ?? testStatus.source ?? null
        });
        if (status) {
          usedTestKeys.add(canonical);
        }
      }
    }
  }

  if (filters) {
    for (const id of filters) {
      if (backlogEntries.has(id)) continue;
      const info = backlog.get(id);
      if (info) {
        ensureBacklogEntry(backlogEntries, id, info);
      } else {
        missingBacklog.push({ id, tasks: [] });
      }
    }
  }

  const backlogItems = Array.from(backlogEntries.values()).sort((a, b) => a.order - b.order);
  for (const item of backlogItems) {
    item.coverageStatus = evaluateCoverageStatus(item);
  }

  if (testStatus.map.size > 0 && usedTestKeys.size === 0) {
    warnings.push("Test report was provided but no tests were mapped to backlog items.");
  }

  const unmappedTests = [];
  for (const [key, status] of testStatus.map.entries()) {
    if (!usedTestKeys.has(key)) {
      unmappedTests.push({
        path: status.path,
        status: status.status ?? "unknown",
        lastRun: status.lastRun ?? testStatus.generatedAt ?? null
      });
    }
  }

  const stats = {
    totalBacklog: backlogEntries.size,
    withTests: backlogItems.filter((item) => item.tests.length > 0).length,
    missingTests: backlogItems.filter((item) => item.tests.length === 0).length,
    failing:
      backlogItems.filter((item) => item.tests.some((test) => test.status === "fail")).length,
    totalTestsMapped: usedTestKeys.size,
    totalTestsReported: testStatus.map.size,
    unmappedTests: unmappedTests.length
  };

  return {
    backlogItems,
    unmappedBacklog: mergeMissingBacklogEntries(missingBacklog),
    unmappedTests,
    warnings,
    stats
  };
}

function loadManifest(file) {
  const raw = fs.readFileSync(file, "utf8");
  const parsed = YAML.parse(raw);
  if (!parsed?.tasks) {
    throw new Error(`Manifest at ${file} is missing a tasks array.`);
  }
  return parsed;
}

function loadTaskMetadata(manifest, manifestPath, tasksDir) {
  const manifestDir = path.dirname(manifestPath);
  const meta = new Map();
  for (const task of manifest.tasks) {
    const taskPath = task.path
      ? path.resolve(manifestDir, task.path)
      : path.resolve(tasksDir, `${task.id}.md`);
    if (!fs.existsSync(taskPath)) {
      meta.set(task.id, {
        id: task.id,
        title: task.title ?? task.id,
        traceability: { tests: [], commands: [] },
        status_note: task.status_note ?? null
      });
      continue;
    }
    const frontMatter = readFrontMatter(taskPath);
    meta.set(task.id, {
      id: task.id,
      title: frontMatter.title ?? task.title ?? task.id,
      traceability: normalizeTraceability(frontMatter.traceability),
      status_note: frontMatter.status_note ?? task.status_note ?? null
    });
  }
  return meta;
}

function parseBacklog(file) {
  const raw = fs.readFileSync(file, "utf8");
  const lines = raw.split(/\r?\n/);
  const map = new Map();
  let currentSection = "Backlog";
  for (const line of lines) {
    const sectionMatch = /^\s{0,3}##\s+(.*)/.exec(line);
    if (sectionMatch) {
      currentSection = sectionMatch[1].trim();
      continue;
    }
    const itemMatch = /^\s{0,3}(\d+)\.\s+(.*)/.exec(line);
    if (itemMatch) {
      const id = `#${itemMatch[1]}`;
      if (!map.has(id)) {
        map.set(id, {
          id,
          title: itemMatch[2].trim(),
          section: currentSection,
          order: Number.parseInt(itemMatch[1], 10)
        });
      }
    }
  }
  return map;
}

function loadTestStatus(file) {
  if (!file || !fs.existsSync(file)) {
    return {
      map: new Map(),
      source: null,
      generatedAt: null,
      warning: `Test report not found at ${toDisplayPath(file)}. All statuses marked unknown.`
    };
  }
  const raw = fs.readFileSync(file, "utf8");
  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch (error) {
    return {
      map: new Map(),
      source: null,
      generatedAt: null,
      warning: `Failed to parse test report ${toDisplayPath(file)}: ${error instanceof Error ? error.message : String(error)}`
    };
  }
  const map = new Map();
  if (Array.isArray(parsed.tests)) {
    for (const entry of parsed.tests) {
      if (!entry?.path) continue;
      const canonical = canonicalizePath(entry.path);
      map.set(canonical, {
        path: normalizeWorkspaceRelative(entry.path),
        status: entry.status ?? "unknown",
        lastRun: entry.lastRun ?? parsed.generatedAt ?? null,
        source: entry.source ?? parsed.source ?? null
      });
    }
  }
  return {
    map,
    source: parsed.source ?? null,
    generatedAt: parsed.generatedAt ?? null,
    warning: null
  };
}

function readFrontMatter(file) {
  const raw = fs.readFileSync(file, "utf8");
  if (!raw.startsWith("---")) return {};
  const end = raw.indexOf("\n---", 3);
  if (end === -1) return {};
  const slice = raw.slice(3, end);
  try {
    return YAML.parse(slice) ?? {};
  } catch {
    return {};
  }
}

function normalizeTraceability(value) {
  if (!value || typeof value !== "object") {
    return { tests: [], commands: [] };
  }
  const tests = Array.isArray(value.tests)
    ? value.tests
        .map((entry) => {
          if (typeof entry === "string") {
            return { path: normalizeWorkspaceRelative(entry) };
          }
          if (entry && typeof entry === "object" && entry.path) {
            return {
              path: normalizeWorkspaceRelative(entry.path),
              description: entry.description ?? entry.name ?? null,
              command: entry.command ?? null
            };
          }
          return null;
        })
        .filter(Boolean)
    : [];
  const commands = Array.isArray(value.commands)
    ? value.commands.map((cmd) => String(cmd))
    : [];
  return { tests, commands };
}

function normalizeFilters(filters) {
  if (!filters) return null;
  const ids = new Set();
  const split = Array.isArray(filters)
    ? filters
    : String(filters)
        .split(/[, ]+/)
        .filter(Boolean);
  for (const token of split) {
    const id = normalizeBacklogId(token);
    if (id) ids.add(id);
  }
  return ids.size ? ids : null;
}

function normalizeBacklogId(ref) {
  if (typeof ref !== "string") return null;
  const trimmed = ref.trim();
  if (/^#\d+$/.test(trimmed)) return trimmed;
  if (/^\d+$/.test(trimmed)) return `#${trimmed}`;
  return null;
}

function ensureBacklogEntry(map, id, info) {
  if (!map.has(id)) {
    map.set(id, {
      id,
      title: info.title,
      section: info.section,
      order: info.order,
      tasks: [],
      tests: []
    });
  }
  return map.get(id);
}

function mergeMissingBacklogEntries(entries) {
  if (!entries.length) return [];
  const grouped = new Map();
  for (const entry of entries) {
    if (!grouped.has(entry.id)) {
      grouped.set(entry.id, new Set());
    }
    const set = grouped.get(entry.id);
    for (const task of entry.tasks) {
      set.add(task);
    }
  }
  return Array.from(grouped.entries()).map(([id, tasks]) => ({
    id,
    tasks: Array.from(tasks)
  }));
}

function evaluateCoverageStatus(item) {
  if (item.tests.length === 0) {
    return "missing-tests";
  }
  const hasFail = item.tests.some((test) => test.status === "fail");
  if (hasFail) return "failing";
  const hasUnknown = item.tests.some((test) => test.status === "unknown");
  if (hasUnknown) return "unknown";
  return "covered";
}

function canonicalizePath(value) {
  if (!value) return null;
  return normalizeWorkspaceRelative(value).toLowerCase();
}

function normalizeWorkspaceRelative(value) {
  if (!value) return value;
  const cleaned = value.replace(/\\/g, "/");
  const absolute = path.isAbsolute(cleaned)
    ? cleaned
    : path.resolve(WORKSPACE_ROOT, cleaned);
  const relative = path.relative(WORKSPACE_ROOT, absolute);
  if (relative && !relative.startsWith("..")) {
    return relative.replace(/\\/g, "/");
  }
  return cleaned.replace(/^\.\/+/, "").replace(/\\/g, "/");
}

function toDisplayPath(file) {
  if (!file) return null;
  const relative = path.relative(WORKSPACE_ROOT, file);
  if (relative && !relative.startsWith("..")) {
    return relative.replace(/\\/g, "/");
  }
  return file;
}

function escapePipe(value) {
  return String(value ?? "").replace(/\|/g, "\\|");
}

function parseArgs(argv) {
  const options = {};
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (token === "--help" || token === "-h") {
      options.help = true;
      continue;
    }
    if (!token.startsWith("--")) {
      throw new Error(`Unknown argument "${token}". Use --help for usage.`);
    }
    const key = token.slice(2);
    const next = argv[i + 1];
    switch (key) {
      case "manifest":
      case "backlog":
      case "tasks":
      case "test-report":
      case "out-json":
      case "out-md":
      case "filter":
      case "mode": {
        if (!next) throw new Error(`Missing value for --${key}`);
        options[toCamel(key)] = next;
        i += 1;
        break;
      }
      default:
        throw new Error(`Unsupported flag "--${key}". Use --help for usage.`);
    }
  }
  return options;
}

function toCamel(flag) {
  return flag.replace(/-([a-z])/g, (_, letter) => letter.toUpperCase());
}

function ensureDir(file) {
  const dir = path.dirname(file);
  fs.mkdirSync(dir, { recursive: true });
}

function printHelp() {
  console.log(`Usage:
  node scripts/ci/traceabilityReport.mjs [--manifest <file>] [--backlog <file>] [--test-report <file>] [--out-json <file>] [--out-md <file>] [--mode info|warn|fail] [--filter "#53,#71"]

Examples:
  node scripts/ci/traceabilityReport.mjs --test-report docs/codex_pack/fixtures/traceability-tests.json --out-json temp/traceability.json --out-md temp/traceability.md
`);
}

function main() {
  let args;
  try {
    args = parseArgs(process.argv.slice(2));
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
    return;
  }

  if (args.help) {
    printHelp();
    return;
  }

  const mode = args.mode ?? DEFAULT_OPTIONS.mode;
  if (!VALID_MODES.has(mode)) {
    console.error(`Invalid mode "${mode}". Expected one of: ${Array.from(VALID_MODES).join(", ")}`);
    process.exit(1);
    return;
  }

  let report;
  try {
    report = generateTraceabilityReport({
      manifest: args.manifest,
      backlog: args.backlog,
      tasksDir: args.tasks,
      testReport: args.testReport,
      mode,
      filters: args.filter
    });
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
    return;
  }

  const outJson = args.outJson ?? DEFAULT_OPTIONS.outJson;
  const outMd = args.outMd ?? DEFAULT_OPTIONS.outMarkdown;

  if (outJson) {
    ensureDir(path.resolve(outJson));
    fs.writeFileSync(path.resolve(outJson), JSON.stringify(report, null, 2));
    console.log(`Wrote JSON report to ${toDisplayPath(path.resolve(outJson))}`);
  }
  if (outMd) {
    ensureDir(path.resolve(outMd));
    fs.writeFileSync(path.resolve(outMd), buildMarkdown(report));
    console.log(`Wrote Markdown summary to ${toDisplayPath(path.resolve(outMd))}`);
  }

  if (mode === "fail" && report.backlogItems.some((item) => item.coverageStatus !== "covered")) {
    console.error("Traceability gaps detected (mode=fail).");
    process.exit(1);
  } else if (mode === "warn" && report.backlogItems.some((item) => item.coverageStatus !== "covered")) {
    console.warn("Traceability gaps detected.");
  }
}

const invokedDirectly =
  process.argv[1] &&
  pathToFileURL(path.resolve(process.argv[1])).href === import.meta.url;

if (invokedDirectly) {
  main();
}
