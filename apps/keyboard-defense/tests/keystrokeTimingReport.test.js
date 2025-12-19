import { describe, expect, test } from "vitest";
import {
  buildKeystrokeTimingHistogram,
  buildKeystrokeTimingHistogramCsv,
  summarizeKeystrokeTimings
} from "../src/utils/keystrokeTimingReport.ts";

describe("keystrokeTimingReport", () => {
  test("summarizeKeystrokeTimings reports percentiles", () => {
    const summary = summarizeKeystrokeTimings([100, 200, 300, 400, 500]);
    expect(summary.count).toBe(5);
    expect(summary.minMs).toBe(100);
    expect(summary.maxMs).toBe(500);
    expect(summary.p50Ms).toBe(300);
    expect(summary.p90Ms).toBe(460);
  });

  test("buildKeystrokeTimingHistogram buckets samples into 50ms bins", () => {
    const { buckets, summary } = buildKeystrokeTimingHistogram(
      [10, 20, 50, 55, 999, 1000, 1200],
      { bucketMs: 50, maxMs: 1000 }
    );
    const counts = Object.fromEntries(buckets.map((bucket) => [bucket.label, bucket.count]));
    expect(counts["0-49"]).toBe(2);
    expect(counts["50-99"]).toBe(2);
    expect(counts["950-999"]).toBe(1);
    expect(counts["1000+"]).toBe(2);
    expect(summary.count).toBe(7);
  });

  test("buildKeystrokeTimingHistogramCsv emits a CSV header and rows", () => {
    const csv = buildKeystrokeTimingHistogramCsv([10, 10, 60], { bucketMs: 50, maxMs: 100 });
    const lines = csv.trim().split("\n");
    expect(lines[0]).toBe("bucket_label,bucket_start_ms,bucket_end_ms,count,pct");
    expect(lines.length).toBeGreaterThan(2);
  });
});

