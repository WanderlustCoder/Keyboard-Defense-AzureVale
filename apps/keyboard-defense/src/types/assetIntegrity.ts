export type AssetIntegrityStatus = "pending" | "passed" | "warning" | "failed" | "skipped";

export interface AssetIntegrityFailure {
  key: string;
  type: "missing" | "mismatch" | "unreferenced" | "fetch-error";
  path?: string | null;
  expected?: string | null;
  actual?: string | null;
}

export interface AssetIntegritySummary {
  status: AssetIntegrityStatus;
  strictMode: boolean;
  scenario: string | null;
  manifest: string | null;
  manifestUrl?: string | null;
  checked: number;
  missingHash: number;
  failed: number;
  extraEntries: number;
  totalImages: number;
  durationMs: number | null;
  completedAt?: string | null;
  firstFailure?: AssetIntegrityFailure | null;
  error?: string | null;
}
