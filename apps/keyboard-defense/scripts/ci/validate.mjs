#!/usr/bin/env node
/**
 * Generic CI guard runner. Evaluates declarative thresholds defined in ci/guards.yml
 * against the artifacts produced by the pipeline.
 */
import fs from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";
import YAML from "yaml";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const APP_ROOT = path.resolve(__dirname, "..", "..");
const REPO_ROOT = path.resolve(APP_ROOT, "..", "..");

const RULE_KEYS = new Set([
  "eq",
  "oneOf",
  "min",
  "max",
  "severity",
  "allowMissing",
  "description"
]);

const DEFAULT_SECTION_LIST = ["smoke", "tutorial", "monitor", "gold", "screenshots", "breach"];

function printHelp() {
  console.log(`Keyboard Defense CI Guard Runner

Usage:
  node scripts/ci/validate.mjs [options]

Options:
  --config <path>        Guard configuration file (defaults to ci/guards.yml lookup).
  --mode <fail|warn|auto>
                         Failure behaviour when guards trip. "auto" fails on main, warns on PRs.
  --sections <list>      Comma-separated list of top-level sections to evaluate.
  --dry-run              Always exit 0 (useful locally) but still print failures/warnings.
  --verbose              Print passing checks.
  --help                 Show this message.

Examples:
  node scripts/ci/validate.mjs --sections smoke,monitor
  node scripts/ci/validate.mjs --dry-run --sections gold
`);
}

function parseList(value) {
  if (!value) return [];
  return value
    .split(",")
    .map((entry) => entry.trim())
    .filter(Boolean);
}

function parseArgs(argv) {
  const options = {
    config: process.env.CI_GUARD_CONFIG ?? null,
    mode: (process.env.CI_GUARD_MODE ?? "auto").toLowerCase(),
    sections: new Set(parseList(process.env.CI_GUARD_SECTIONS ?? "")),
    dryRun: process.env.CI_GUARD_DRY_RUN === "1",
    verbose: process.env.CI_GUARD_VERBOSE === "1",
    help: false
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--config":
        options.config = argv[++i] ?? null;
        break;
      case "--mode":
        options.mode = (argv[++i] ?? options.mode).toLowerCase();
        break;
      case "--sections": {
        const list = parseList(argv[++i]);
        for (const entry of list) options.sections.add(entry);
        break;
      }
      case "--dry-run":
        options.dryRun = true;
        break;
      case "--verbose":
        options.verbose = true;
        break;
      case "--help":
        options.help = true;
        break;
      default:
        throw new Error(`Unknown argument "${token}". Use --help for usage.`);
    }
  }

  return options;
}

function resolveConfigPath(preferred) {
  const candidates = [];
  if (preferred) {
    candidates.push(path.resolve(preferred));
  }
  candidates.push(
    path.resolve(APP_ROOT, "ci", "guards.yml"),
    path.resolve(APP_ROOT, "ci", "guards.yaml"),
    path.resolve(APP_ROOT, "ci", "guards.json"),
    path.resolve(REPO_ROOT, "ci", "guards.yml"),
    path.resolve(REPO_ROOT, "ci", "guards.yaml"),
    path.resolve(REPO_ROOT, "ci", "guards.json")
  );
  for (const candidate of candidates) {
    if (candidate && fs.existsSync(candidate)) {
      return candidate;
    }
  }
  return null;
}

async function loadGuards(filePath) {
  const raw = fs.readFileSync(filePath, "utf8");
  if (filePath.endsWith(".json")) {
    return JSON.parse(raw);
  }
  return YAML.parse(raw);
}

function readJson(absolutePath) {
  if (!absolutePath) return null;
  if (!fs.existsSync(absolutePath)) return null;
  try {
    return JSON.parse(fs.readFileSync(absolutePath, "utf8"));
  } catch (error) {
    console.warn(`[ci:guards] Failed to parse ${absolutePath}: ${error.message}`);
    return null;
  }
}

function loadArtifact(paths) {
  for (const relative of paths) {
    const absolute = path.resolve(APP_ROOT, relative);
    if (!fs.existsSync(absolute)) continue;
    const data = readJson(absolute);
    if (data) {
      return { data, path: absolute };
    }
  }
  return null;
}

function computeReadyMs(summary) {
  if (!summary) return null;
  if (Number.isFinite(summary.readyMs)) return summary.readyMs;
  if (Number.isFinite(summary.serverReadyMs)) return summary.serverReadyMs;
  const started = summary.startCommand?.startedAt ?? summary.startedAt;
  const readyAt = summary.server?.readyAt ?? summary.readyAt;
  if (!started || !readyAt) return null;
  const delta = Date.parse(readyAt) - Date.parse(started);
  return Number.isFinite(delta) && delta >= 0 ? delta : null;
}

function computeDurationMs(start, end) {
  if (!start || !end) return null;
  const delta = Date.parse(end) - Date.parse(start);
  return Number.isFinite(delta) && delta >= 0 ? delta : null;
}

function percentile(values, percentileValue) {
  if (!Array.isArray(values) || values.length === 0) return null;
  const sorted = [...values].sort((a, b) => a - b);
  const rank = percentileValue * (sorted.length - 1);
  const lower = Math.floor(rank);
  const upper = Math.ceil(rank);
  if (lower === upper) return sorted[lower];
  const weight = rank - lower;
  return sorted[lower] + (sorted[upper] - sorted[lower]) * weight;
}

function summarizeGold(payload) {
  if (!payload || typeof payload !== "object") return null;
  const rows = Array.isArray(payload.rows) ? payload.rows : payload.summaries;
  const rowCount = Array.isArray(rows) ? rows.length : payload.rowCount ?? null;
  const globalRow =
    Array.isArray(rows) && rows.length > 0
      ? rows.find((row) => row.file === "global") ?? rows[0]
      : null;
  const primary = globalRow ?? payload.summary ?? payload;
  const percentiles =
    Array.isArray(payload.percentiles)
      ? payload.percentiles
      : Array.isArray(payload.summaryPercentiles)
        ? payload.summaryPercentiles
        : Array.isArray(primary?.percentiles)
          ? primary.percentiles
          : null;
  return {
    rows: rowCount,
    p90Gain: primary?.p90Gain ?? null,
    p90Spend: primary?.p90Spend ?? null,
    percentiles
  };
}

function formatValue(value) {
  if (Array.isArray(value)) return `[${value.map((entry) => formatValue(entry)).join(", ")}]`;
  if (value === null || value === undefined) return "null";
  if (typeof value === "number") return Number.isFinite(value) ? value.toString() : "NaN";
  if (typeof value === "object") return JSON.stringify(value);
  return String(value);
}

function describeRule(rule) {
  const pieces = [];
  if (rule.eq !== undefined) pieces.push(`eq=${JSON.stringify(rule.eq)}`);
  if (rule.oneOf) pieces.push(`oneOf=${JSON.stringify(rule.oneOf)}`);
  if (rule.min !== undefined) pieces.push(`min=${rule.min}`);
  if (rule.max !== undefined) pieces.push(`max=${rule.max}`);
  return pieces.join(" ");
}

function collectMetrics() {
  const metrics = new Map();
  const sources = new Map();

  function setMetric(key, value, sourcePath) {
    if (value === undefined || value === null) return;
    if (typeof value === "number" && Number.isNaN(value)) return;
    metrics.set(key, value);
    if (sourcePath) sources.set(key, sourcePath);
  }

  const artifacts = {
    devSmoke: loadArtifact([
      path.join("artifacts", "smoke", "devserver-smoke-summary.ci.json"),
      path.join("artifacts", "smoke", "devserver-smoke-summary.json")
    ]),
    tutorialSummary: loadArtifact([
      path.join("artifacts", "smoke", "smoke-summary.ci.json"),
      path.join("artifacts", "smoke", "smoke-summary.json")
    ]),
    tutorialPayload: loadArtifact([
      path.join("artifacts", "smoke", "smoke-payload.json"),
      path.join("smoke-artifacts", "tutorial-smoke.ci.json"),
      path.join("smoke-artifacts", "tutorial-smoke.json")
    ]),
    monitor: loadArtifact([
      path.join("artifacts", "monitor", "dev-monitor.ci.json"),
      path.join("artifacts", "monitor", "dev-monitor.json"),
      path.join("monitor-artifacts", "run.ci.json"),
      path.join("monitor-artifacts", "run.json"),
      path.join("monitor-artifacts", "dev-monitor.json")
    ]),
    gold: loadArtifact([
      path.join("artifacts", "smoke", "gold-summary.ci.json"),
      path.join("artifacts", "e2e", "gold-summary.ci.json"),
      path.join("artifacts", "summaries", "gold-summary-report.e2e.json"),
      path.join("artifacts", "summaries", "gold-summary-report.smoke.json"),
      path.join("artifacts", "summaries", "gold-summary-report.ci.json"),
      path.join("artifacts", "smoke", "gold-summary.json"),
      path.join("artifacts", "e2e", "gold-summary.json")
    ]),
    screenshots: loadArtifact([
      path.join("artifacts", "screenshots", "screenshots-summary.ci.json"),
      path.join("artifacts", "screenshots", "screenshots-summary.json")
    ]),
    breach: loadArtifact([
      path.join("artifacts", "castle-breach.ci.json"),
      path.join("artifacts", "castle-breach.json"),
      path.join("artifacts", "summaries", "castle-breach.e2e.json")
    ]),
    perf: loadArtifact([
      path.join("artifacts", "perf", "perf-smoke-summary.ci.json"),
      path.join("artifacts", "perf", "perf-smoke-summary.json")
    ])
  };

  const readyMs = computeReadyMs(artifacts.devSmoke?.data);
  setMetric("smoke.serverReadyMs", readyMs, artifacts.devSmoke?.path);
  setMetric("smoke.status", artifacts.devSmoke?.data?.status ?? null, artifacts.devSmoke?.path);

  const tutorialStatus =
    artifacts.tutorialPayload?.data?.status ??
    artifacts.tutorialSummary?.data?.status ??
    null;
  const tutorialMode =
    artifacts.tutorialPayload?.data?.mode ?? artifacts.tutorialSummary?.data?.mode ?? null;
  setMetric("tutorial.status", tutorialStatus, artifacts.tutorialPayload?.path ?? artifacts.tutorialSummary?.path);
  setMetric("tutorial.mode", tutorialMode, artifacts.tutorialPayload?.path ?? artifacts.tutorialSummary?.path);

  if (artifacts.monitor) {
    const failureCount =
      artifacts.monitor.data.failureCount ??
      artifacts.monitor.data.failures ??
      artifacts.monitor.data.errorCount ??
      null;
    setMetric("monitor.failureCount", failureCount, artifacts.monitor.path);
    setMetric("monitor.status", artifacts.monitor.data.status ?? null, artifacts.monitor.path);
    const latencies = Array.isArray(artifacts.monitor.data.history)
      ? artifacts.monitor.data.history
          .map((entry) => Number(entry.latencyMs ?? entry.durationMs))
          .filter((value) => Number.isFinite(value))
      : [];
    const latencyP95 = latencies.length > 0 ? percentile(latencies, 0.95) : null;
    setMetric("monitor.latencyP95Ms", latencyP95, artifacts.monitor.path);
    const monitorReadyMs = computeDurationMs(
      artifacts.monitor.data.startedAt,
      artifacts.monitor.data.readyAt ?? artifacts.monitor.data.completedAt
    );
    setMetric("monitor.readyMs", monitorReadyMs, artifacts.monitor.path);
    const uptimeMs =
      artifacts.monitor.data.uptimeMs ??
      computeDurationMs(artifacts.monitor.data.startedAt, artifacts.monitor.data.completedAt);
    setMetric("monitor.uptimeMs", uptimeMs, artifacts.monitor.path);
    const lastLatency = artifacts.monitor.data.lastLatencyMs ?? latencies.at(-1) ?? null;
    setMetric("monitor.lastLatencyMs", lastLatency, artifacts.monitor.path);
    if (Array.isArray(artifacts.monitor.data.flags) && artifacts.monitor.data.flags.length > 0) {
      setMetric("monitor.flags", artifacts.monitor.data.flags, artifacts.monitor.path);
    }
  }

  if (artifacts.gold) {
    const goldStats = summarizeGold(artifacts.gold.data);
    if (goldStats) {
      setMetric("gold.rows", goldStats.rows ?? null, artifacts.gold.path);
      setMetric("gold.gain.p90", goldStats.p90Gain ?? null, artifacts.gold.path);
      setMetric("gold.spend.p90", goldStats.p90Spend ?? null, artifacts.gold.path);
      if (goldStats.percentiles) {
        setMetric("gold.percentiles", goldStats.percentiles, artifacts.gold.path);
      }
    }
  }

  if (artifacts.screenshots) {
    const entry = artifacts.screenshots;
    const captured = Array.isArray(entry.data.screenshots)
      ? entry.data.screenshots.length
      : Array.isArray(entry.data.entries)
        ? entry.data.entries.length
        : Number.isFinite(entry.data.count)
          ? entry.data.count
          : null;
    setMetric("screenshots.captured", captured, entry.path);
    setMetric("screenshots.status", entry.data.status ?? null, entry.path);
    const diffPixels =
      entry.data.totalDiffPixels ??
      (Array.isArray(entry.data.screenshots)
        ? entry.data.screenshots.reduce(
            (sum, shot) => sum + (Number(shot.diffPixels) || 0),
            0
          )
        : null);
    if (Number.isFinite(diffPixels)) {
      setMetric("screenshots.diffPixels", diffPixels, entry.path);
    }
  }

  if (artifacts.breach) {
    const entry = artifacts.breach;
    setMetric("breach.breached", entry.data.breached ?? entry.data.didBreach ?? null, entry.path);
    setMetric(
      "breach.timeToBreachMs",
      entry.data.timeToBreachMs ?? entry.data.durationMs ?? null,
      entry.path
    );
  }

  if (artifacts.perf) {
    const entry = artifacts.perf;
    const metrics = entry.data?.metrics ?? entry.data ?? {};
    setMetric("perf.status", entry.data.status ?? null, entry.path);
    setMetric("perf.durationMs", metrics.durationMs ?? null, entry.path);
    setMetric("perf.fps", metrics.fps ?? null, entry.path);
    setMetric("perf.frameMsP50", metrics.frameMs?.p50 ?? null, entry.path);
    setMetric("perf.frameMsP95", metrics.frameMs?.p95 ?? null, entry.path);
    setMetric("perf.frameMsMax", metrics.frameMs?.max ?? null, entry.path);
    setMetric("perf.longFramesOver100", metrics.longFrames?.over100 ?? null, entry.path);
    setMetric("perf.heapUsedEndMB", metrics.heapUsedMB?.end ?? null, entry.path);
    setMetric("perf.heapUsedMaxMB", metrics.heapUsedMB?.max ?? null, entry.path);
  }

  return { metrics, sources };
}

function isRuleObject(node) {
  if (!node || typeof node !== "object") return false;
  return Object.keys(node).some((key) => RULE_KEYS.has(key));
}

function normalizeSeverity(value) {
  return value === "warn" ? "warn" : "fail";
}

function valuesEqual(left, right) {
  if (Array.isArray(left) && Array.isArray(right)) {
    if (left.length !== right.length) return false;
    return left.every((value, index) => valuesEqual(value, right[index]));
  }
  return left === right;
}

function evaluateRule(metricPath, rule, metrics, sources) {
  const severity = normalizeSeverity((rule.severity ?? "fail").toLowerCase());
  const allowMissing = Boolean(rule.allowMissing);
  const value = metrics.get(metricPath);
  const source = sources.get(metricPath);
  if (value === undefined) {
    if (allowMissing) {
      return { metricPath, passed: true, skipped: true };
    }
    return {
      metricPath,
      passed: false,
      severity,
      reason: "missing",
      value: null,
      rule
    };
  }

  let ok = true;
  let reason = "";

  if (rule.eq !== undefined) {
    ok = ok && valuesEqual(value, rule.eq);
    if (!ok) reason = `expected ${JSON.stringify(rule.eq)}`;
  }
  if (ok && rule.oneOf) {
    const targetSet = new Set(
      Array.isArray(rule.oneOf) ? rule.oneOf.map((entry) => String(entry)) : [String(rule.oneOf)]
    );
    ok = targetSet.has(String(value));
    if (!ok) reason = `expected oneOf ${JSON.stringify(Array.from(targetSet))}`;
  }
  if (ok && rule.min !== undefined) {
    const numeric = Number(value);
    if (!Number.isFinite(numeric) || numeric < Number(rule.min)) {
      ok = false;
      reason = `expected >= ${rule.min}`;
    }
  }
  if (ok && rule.max !== undefined) {
    const numeric = Number(value);
    if (!Number.isFinite(numeric) || numeric > Number(rule.max)) {
      ok = false;
      reason = `expected <= ${rule.max}`;
    }
  }

  return {
    metricPath,
    value,
    rule,
    severity,
    passed: ok,
    reason: ok ? "" : reason,
    source
  };
}

function evaluateGuards(tree, options, metrics, sources) {
  const sections =
    options.sections.size > 0
      ? new Set(Array.from(options.sections).map((entry) => entry.toLowerCase()))
      : null;
  const results = [];

  function walk(node, prefix = []) {
    for (const [key, value] of Object.entries(node)) {
      const nextPath = prefix.concat(key);
      if (prefix.length === 0 && sections && !sections.has(key.toLowerCase())) {
        continue;
      }
      if (isRuleObject(value)) {
        results.push(evaluateRule(nextPath.join("."), value, metrics, sources));
      } else if (value && typeof value === "object") {
        walk(value, nextPath);
      }
    }
  }

  walk(tree, []);
  return results;
}

function isProtectedBranch() {
  const ref = process.env.GITHUB_REF ?? "";
  const baseRef = process.env.GITHUB_BASE_REF ?? "";
  if (process.env.CI_GUARD_FORCE_MAIN === "1") return true;
  if (baseRef) return false;
  return ref === "refs/heads/main";
}

function resolveMode(mode) {
  if (mode === "warn" || mode === "fail") return mode;
  return isProtectedBranch() ? "fail" : "warn";
}

function relativeSource(source) {
  if (!source) return "n/a";
  const rel = path.relative(REPO_ROOT, source);
  return rel || source;
}

async function main() {
  let options;
  try {
    options = parseArgs(process.argv.slice(2));
  } catch (error) {
    console.error(error.message);
    process.exit(1);
    return;
  }

  if (options.help) {
    printHelp();
    return;
  }

  const configPath = resolveConfigPath(options.config);
  if (!configPath) {
    console.warn("No ci/guards.yml (or .json) found. Skipping guard validation.");
    return;
  }
  const guards = await loadGuards(configPath);
  if (!guards || typeof guards !== "object") {
    console.warn(`Guard file at ${configPath} is empty. Skipping validation.`);
    return;
  }

  if (options.sections.size === 0) {
    DEFAULT_SECTION_LIST.forEach((section) => options.sections.add(section));
  }

  const { metrics, sources } = collectMetrics();
  const results = evaluateGuards(guards, options, metrics, sources);
  if (results.length === 0) {
    console.log("No guard rules matched the current section filter.");
    return;
  }

  const failures = results.filter((result) => !result.passed && result.severity === "fail");
  const warnings = results.filter((result) => !result.passed && result.severity === "warn");
  const passes = results.filter((result) => result.passed && !result.skipped);

  for (const failure of failures) {
    console.error(
      `[FAIL] ${failure.metricPath} value=${formatValue(failure.value)} rule=${describeRule(
        failure.rule
      )} source=${relativeSource(failure.source)} ${failure.reason ?? ""}`
    );
  }
  for (const warning of warnings) {
    console.warn(
      `[WARN] ${warning.metricPath} value=${formatValue(warning.value)} rule=${describeRule(
        warning.rule
      )} source=${relativeSource(warning.source)} ${warning.reason ?? ""}`
    );
  }
  if (options.verbose) {
    for (const pass of passes) {
      console.log(
        `[PASS] ${pass.metricPath} value=${formatValue(pass.value)} source=${relativeSource(
          pass.source
        )}`
      );
    }
  }

  const effectiveMode = resolveMode(options.mode);
  console.log(
    `CI Guards (${effectiveMode}${options.dryRun ? ", dry-run" : ""}): ${passes.length} pass, ${warnings.length} warn, ${failures.length} fail`
  );

  if (!options.dryRun && effectiveMode === "fail" && failures.length > 0) {
    process.exitCode = 1;
  }
}

await main();
