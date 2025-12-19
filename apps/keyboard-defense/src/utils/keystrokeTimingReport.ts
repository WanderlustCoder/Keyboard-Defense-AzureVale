export type KeystrokeTimingBucket = {
  label: string;
  startMs: number;
  endMs: number | null;
  count: number;
  pct: number;
};

export type KeystrokeTimingSummary = {
  count: number;
  minMs: number | null;
  maxMs: number | null;
  p50Ms: number | null;
  p90Ms: number | null;
  p99Ms: number | null;
};

const DEFAULT_BUCKET_MS = 50;
const DEFAULT_MAX_MS = 1000;

function clampPositiveInteger(value: unknown, fallback: number): number {
  if (typeof value !== "number" || !Number.isFinite(value)) return fallback;
  return Math.max(1, Math.floor(value));
}

function normalizeSamples(samples: number[]): number[] {
  if (!Array.isArray(samples)) return [];
  const normalized: number[] = [];
  for (const sample of samples) {
    if (typeof sample !== "number" || !Number.isFinite(sample) || sample < 0) continue;
    normalized.push(sample);
  }
  return normalized;
}

function quantile(sorted: number[], q: number): number | null {
  if (!sorted.length) return null;
  const clampedQ = Math.max(0, Math.min(1, q));
  const position = (sorted.length - 1) * clampedQ;
  const base = Math.floor(position);
  const remainder = position - base;
  const lower = sorted[base];
  const upper = sorted[Math.min(sorted.length - 1, base + 1)];
  return lower + remainder * (upper - lower);
}

export function summarizeKeystrokeTimings(
  samples: number[]
): KeystrokeTimingSummary {
  const normalized = normalizeSamples(samples);
  if (normalized.length === 0) {
    return { count: 0, minMs: null, maxMs: null, p50Ms: null, p90Ms: null, p99Ms: null };
  }
  const sorted = normalized.slice().sort((a, b) => a - b);
  return {
    count: sorted.length,
    minMs: sorted[0] ?? null,
    maxMs: sorted[sorted.length - 1] ?? null,
    p50Ms: quantile(sorted, 0.5),
    p90Ms: quantile(sorted, 0.9),
    p99Ms: quantile(sorted, 0.99)
  };
}

export function buildKeystrokeTimingHistogram(
  samples: number[],
  options?: { bucketMs?: number; maxMs?: number }
): { summary: KeystrokeTimingSummary; buckets: KeystrokeTimingBucket[] } {
  const bucketMs = clampPositiveInteger(options?.bucketMs, DEFAULT_BUCKET_MS);
  const maxMs = clampPositiveInteger(options?.maxMs, DEFAULT_MAX_MS);

  const normalized = normalizeSamples(samples);
  const summary = summarizeKeystrokeTimings(normalized);
  const buckets: KeystrokeTimingBucket[] = [];
  for (let start = 0; start < maxMs; start += bucketMs) {
    const end = Math.min(maxMs, start + bucketMs);
    const label = end > start ? `${start}-${end - 1}` : `${start}`;
    buckets.push({ label, startMs: start, endMs: end, count: 0, pct: 0 });
  }
  buckets.push({ label: `${maxMs}+`, startMs: maxMs, endMs: null, count: 0, pct: 0 });

  for (const sample of normalized) {
    const idx = sample >= maxMs ? buckets.length - 1 : Math.floor(sample / bucketMs);
    const target = buckets[idx];
    if (!target) continue;
    target.count += 1;
  }

  const total = normalized.length;
  for (const bucket of buckets) {
    bucket.pct = total > 0 ? bucket.count / total : 0;
  }

  return { summary, buckets };
}

export function buildKeystrokeTimingHistogramCsv(
  samples: number[],
  options?: { bucketMs?: number; maxMs?: number }
): string {
  const histogram = buildKeystrokeTimingHistogram(samples, options);
  const lines = ["bucket_label,bucket_start_ms,bucket_end_ms,count,pct"];
  for (const bucket of histogram.buckets) {
    const end = bucket.endMs === null ? "" : bucket.endMs.toString();
    lines.push(
      [bucket.label, bucket.startMs.toString(), end, bucket.count.toString(), bucket.pct.toFixed(4)].join(
        ","
      )
    );
  }
  return lines.join("\n");
}
