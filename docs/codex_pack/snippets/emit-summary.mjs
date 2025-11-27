#!/usr/bin/env node
/**
 * scripts/ci/emit-summary.mjs
 * Renders a concise Markdown summary from CI artifacts to stdout.
 * Pipe into $GITHUB_STEP_SUMMARY in GitHub Actions.
 */
import fs from 'node:fs';
import path from 'node:path';

const CANDIDATES = {
  smoke: [
    'artifacts/smoke/devserver-smoke-summary.ci.json',
    'artifacts/smoke/devserver-smoke-summary.json',
  ],
  startSmoke: [
    'artifacts/monitor/start-smoke-node20.json',
    'artifacts/monitor/start-smoke-node18.json',
    'artifacts/monitor/start-smoke.ci.json',
    'artifacts/monitor/start-smoke.json'
  ],
  monitor: [
    'artifacts/monitor/dev-monitor.ci.json',
    'artifacts/monitor/dev-monitor.json',
    'monitor-artifacts/run.json',
    'monitor-artifacts/run.ci.json'
  ],
  screenshots: [
    'artifacts/screenshots/screenshots-summary.ci.json'
  ],
  gold: [
    'artifacts/smoke/gold-summary.ci.json',
    'artifacts/e2e/gold-summary.ci.json'
  ],
  breach: [
    'artifacts/castle-breach.ci.json',
    'artifacts/castle-breach.json'
  ],
  audioIntensity: [
    'artifacts/summaries/audio-intensity.ci.json',
    'artifacts/summaries/audio-intensity.json'
  ],
  condensedAudit: [
    'artifacts/summaries/condensed-audit.ci.json',
    'artifacts/summaries/condensed-audit.json'
  ]
};

function findFirst(paths) {
  for (const p of paths) {
    if (fs.existsSync(p)) return p;
  }
  return null;
}
function readJSON(p) {
  if (!p || !fs.existsSync(p)) return null;
  try { return JSON.parse(fs.readFileSync(p,'utf8')); }
  catch { return null; }
}
function mdTable(rows) {
  const head = ['Section','Metric','Value'];
  const lines = [
    `| ${head.join(' | ')} |`,
    `| ${head.map(()=> '---').join(' | ')} |`,
    ...rows.map(r => `| ${r.join(' | ')} |`)
  ];
  return lines.join('\n');
}
function linkOrDash(label, file) {
  if (!file) return '—';
  const url = file; // GitHub will auto-link artifact paths in logs; step summary can show text
  return `[\`${label}\`](${url})`;
}

const files = Object.fromEntries(Object.entries(CANDIDATES).map(([k,v]) => [k, findFirst(v)]));

const smoke = readJSON(files.smoke) || {};
const monitor = readJSON(files.monitor) || {};
const startSmoke = readJSON(files.startSmoke) || {};
const screenshots = readJSON(files.screenshots) || {};
const gold = readJSON(files.gold) || {};
const breach = readJSON(files.breach) || {};
const audio = readJSON(files.audioIntensity) || {};
const condensed = readJSON(files.condensedAudit) || {};

const rows = [];

// Smoke/dev-server
const serverReadyMs = smoke.serverReadyMs ?? smoke.bootMs ?? monitor.readyMs ?? null;
rows.push(['Dev server smoke', 'serverReadyMs', serverReadyMs ?? '—']);
rows.push(['Dev server smoke', 'url', smoke.url ?? monitor.url ?? '—']);
rows.push(['Dev server smoke', 'artifact', linkOrDash('smoke-summary', files.smoke)]);

// Gold
const pcts = Array.isArray(gold.percentiles) ? gold.percentiles.join(',') : (gold.summaryPercentiles ?? '—');
rows.push(['Gold summary', 'percentiles', pcts]);
rows.push(['Gold summary', 'medianGain', gold.medianGain ?? '—']);
rows.push(['Gold summary', 'p90Gain', gold.p90Gain ?? '—']);
rows.push(['Gold summary', 'medianSpend', gold.medianSpend ?? '—']);
rows.push(['Gold summary', 'p90Spend', gold.p90Spend ?? '—']);
rows.push(['Gold summary', 'artifact', linkOrDash('gold-summary', files.gold)]);

// Screenshots
const shotCount = Array.isArray(screenshots?.entries) ? screenshots.entries.length : (screenshots?.count ?? '-');
rows.push(['Screenshots', 'captured', shotCount]);
rows.push(['Screenshots', 'artifact', linkOrDash('screenshots-summary', files.screenshots)]);

// Audio intensity
if (files.audioIntensity) {
  rows.push(['Audio intensity', 'requested', audio?.runs?.[0]?.requestedIntensity ?? audio.requestedIntensity ?? '-']);
  rows.push(['Audio intensity', 'recorded', audio?.runs?.[0]?.recordedIntensity ?? audio.recordedIntensity ?? '-']);
  rows.push(['Audio intensity', 'driftPercent', audio?.runs?.[0]?.driftPercent ?? audio.driftPercent ?? '-']);
  rows.push(['Audio intensity', 'artifact', linkOrDash('audio-intensity', files.audioIntensity)]);
}

// Condensed audit
if (files.condensedAudit) {
  const failures = Array.isArray(condensed.failures) ? condensed.failures : [];
  const preview = failures.slice(0, 2).map((f) => `${f.panelId ?? 'panel'} (${f.snapshot ?? 'snapshot'})`).join(' / ');
  rows.push(['Condensed audit', 'status', condensed.ok === false ? 'fail' : 'pass']);
  rows.push(['Condensed audit', 'coverage', `${condensed.checks ?? '-'} checks / ${condensed.panelsChecked ?? '-' } panels`]);
  rows.push(['Condensed audit', 'issues', failures.length ? preview : '-']);
  rows.push(['Condensed audit', 'artifact', linkOrDash('condensed-audit', files.condensedAudit)]);
}

// Breach
if (files.breach) {
  rows.push(['Castle breach', 'breached', String(breach.breached ?? '—')]);
  rows.push(['Castle breach', 'timeToBreachMs', breach.timeToBreachMs ?? '—']);
  rows.push(['Castle breach', 'artifact', linkOrDash('breach', files.breach)]);
}

// Monitor
rows.push(['Monitor', 'status', monitor.status ?? '-']);
rows.push(['Monitor', 'lastLatencyMs', monitor.lastLatencyMs ?? '-']);
rows.push(['Monitor', 'uptimeMs', monitor.uptimeMs ?? '-']);
rows.push(['Monitor', 'flags', Array.isArray(monitor.flags) ? monitor.flags.join(',') || '-' : '-']);
rows.push(['Monitor', 'artifact', linkOrDash('monitor-run', files.monitor)]);

if (files.startSmoke) {
  rows.push(['Start smoke', 'status', startSmoke.status ?? '-']);
  const attempts = Array.isArray(startSmoke.attempts) ? startSmoke.attempts.length : '-';
  rows.push(['Start smoke', 'attempts', attempts]);
  rows.push(['Start smoke', 'artifact', linkOrDash('start-smoke', files.startSmoke)]);
}

// Print
console.log('### CI Summary (Codex Pack)');
console.log();
console.log(mdTable(rows));
