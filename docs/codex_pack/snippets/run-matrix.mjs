#!/usr/bin/env node
/**
 * scripts/ci/run-matrix.mjs (template)
 * Runs tutorial smoke / breach drill across seeds, aggregates simple stats,
 * and writes artifacts/ci-matrix-summary.json
 *
 * NOTE: Adjust the underlying commands/flags to match your scripts.
 */
import fs from 'node:fs';
import { execFileSync } from 'node:child_process';

const args = process.argv.slice(2);
const opts = Object.fromEntries(args.map(a => {
  const [k,v='true'] = a.replace(/^--/,'').split('=');
  return [k, v];
}));

const tutorialSeeds = (opts['tutorial-seeds'] || '1,2,3').split(',').map(s => s.trim()).filter(Boolean);
const breachSeeds = (opts['breach-seeds'] || '42,77').split(',').map(s => s.trim()).filter(Boolean);

function q(values, p) {
  // simple quantile (nearest-rank)
  if (!values.length) return null;
  const sorted = [...values].sort((a,b)=>a-b);
  const idx = Math.max(0, Math.min(sorted.length-1, Math.round((p/100) * (sorted.length-1))));
  return sorted[idx];
}

const tutorialReadyMs = [];
for (const seed of tutorialSeeds) {
  try {
    // If your smoke CLI prints JSON to stdout when --json is set, capture and parse it.
    const out = execFileSync('node', ['scripts/smoke.mjs', '--ci', '--json', `--seed=${seed}`], { encoding: 'utf8' });
    const data = JSON.parse(out || '{}');
    const ms = data.serverReadyMs ?? data.bootMs ?? null;
    if (ms != null) tutorialReadyMs.push(ms);
  } catch (e) {
    console.error('[matrix] smoke failed for seed', seed, e.message);
  }
}

const breachTimes = [];
for (const seed of breachSeeds) {
  try {
    const out = execFileSync('node', ['scripts/castleBreachReplay.mjs', `--seed=${seed}`, '--no-artifact', '--max-time=20000'], { encoding: 'utf8' });
    // If castle breach prints JSON, parse it; otherwise set a placeholder via grep/regex as needed.
    // Here we assume JSON to stdout for simplicity:
    const data = JSON.parse(out || '{}');
    if (data.timeToBreachMs != null) breachTimes.push(data.timeToBreachMs);
  } catch (e) {
    console.error('[matrix] breach failed for seed', seed, e.message);
  }
}

const summary = {
  tutorialSeeds,
  breachSeeds,
  tutorialReadyMs,
  breachTimes,
  tutorialReadyMs_p50: q(tutorialReadyMs, 50),
  tutorialReadyMs_p90: q(tutorialReadyMs, 90),
  breachTimes_p50: q(breachTimes, 50),
  breachTimes_p90: q(breachTimes, 90)
};

fs.mkdirSync('artifacts', { recursive: true });
fs.writeFileSync('artifacts/ci-matrix-summary.json', JSON.stringify(summary, null, 2));
console.log(JSON.stringify(summary));
