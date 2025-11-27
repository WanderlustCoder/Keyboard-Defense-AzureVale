#!/usr/bin/env node
/**
 * scripts/ci/validate.mjs
 * Evaluates guard thresholds in ci/guards.yml (or .json) against CI artifacts.
 */
import fs from 'node:fs';
import path from 'node:path';

function readJSON(p) {
  if (!p || !fs.existsSync(p)) return null;
  try { return JSON.parse(fs.readFileSync(p, 'utf8')); } catch { return null; }
}
async function readGuards(p) {
  if (!fs.existsSync(p)) return null;
  const raw = fs.readFileSync(p, 'utf8');
  // Try YAML first, then JSON
  try {
    const yaml = (await import('yaml')).default;
    return yaml.parse(raw);
  } catch {
    try { return JSON.parse(raw); }
    catch { throw new Error('Failed to parse guards file as YAML or JSON'); }
  }
}

const guardsPath = fs.existsSync('ci/guards.yml') ? 'ci/guards.yml' :
                   fs.existsSync('ci/guards.json') ? 'ci/guards.json' : null;
if (!guardsPath) {
  console.warn('No ci/guards.yml or ci/guards.json found — skipping validation.');
  process.exit(0);
}

const guards = await readGuards(guardsPath);

// Load artifacts
const smoke = readJSON('artifacts/smoke/devserver-smoke-summary.ci.json')
           || readJSON('artifacts/smoke/devserver-smoke-summary.json') || {};
const monitor =
  readJSON('artifacts/monitor/dev-monitor.ci.json') ||
  readJSON('artifacts/monitor/dev-monitor.json') ||
  readJSON('monitor-artifacts/run.json') ||
  {};
const gold = readJSON('artifacts/smoke/gold-summary.ci.json')
          || readJSON('artifacts/e2e/gold-summary.ci.json') || {};
const breach = readJSON('artifacts/castle-breach.ci.json')
            || readJSON('artifacts/castle-breach.json') || {};
const shots = readJSON('artifacts/screenshots/screenshots-summary.ci.json') || {};

function pick(obj, keys, fallback=undefined) {
  for (const k of keys) if (obj && obj[k] != null) return obj[k];
  return fallback;
}

const metrics = {
  'smoke.serverReadyMs': pick(smoke, ['serverReadyMs','bootMs','readyMs'], null),
  'gold.gain.p90': gold.p90Gain ?? null,
  'gold.spend.p90': gold.p90Spend ?? null,
  'gold.rows': Array.isArray(gold.rows) ? gold.rows.length : (gold.rowCount ?? null),
  'breach.breached': breach.breached ?? null,
  'breach.timeToBreachMs': breach.timeToBreachMs ?? null,
  'screenshots.diffPixels': shots.totalDiffPixels ?? null, // wire up once diffs land
  'assets.integrityFailures': null // TODO: set from an artifact or log parser if available
};

function val(path) {
  return metrics[path] ?? null;
}

const failures = [];
const warnings = [];

function checkRule(metricPath, rule, severity='fail') {
  const v = val(metricPath);
  if (v == null) {
    warnings.push({ metricPath, rule, reason: 'MISSING', value: v });
    return;
  }
  let ok = true;
  if (rule.eq != null) ok = ok && (String(v) === String(rule.eq));
  if (rule.min != null) ok = ok && (v >= rule.min);
  if (rule.max != null) ok = ok && (v <= rule.max);
  if (!ok) {
    (severity === 'warn' ? warnings : failures).push({ metricPath, rule, value: v });
  }
}

function walkGuards(g, prefix=[]) {
  for (const [k, v] of Object.entries(g)) {
    if (v && typeof v === 'object' && !('eq' in v || 'min' in v || 'max' in v)) {
      walkGuards(v, prefix.concat(k));
    } else {
      // Treat this as a rule object
      const metricPath = prefix.concat(k).join('.');
      checkRule(metricPath, v);
    }
  }
}
walkGuards(guards);

if (warnings.length) {
  console.warn('Guard warnings:');
  for (const w of warnings) {
    console.warn(` - ${w.metricPath}: WARN (${w.reason}) value=${w.value} rule=${JSON.stringify(w.rule)}`);
  }
}
if (failures.length) {
  console.error('Guard failures:');
  for (const f of failures) {
    console.error(` - ${f.metricPath}: value=${f.value} rule=${JSON.stringify(f.rule)}`);
  }
  process.exit(1);
}

console.log('All guards passed.');
