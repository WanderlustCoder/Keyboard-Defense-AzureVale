export const DROPOFF_REASON_STORAGE_KEY = "keyboard-defense:dropoff-reasons";
export const DEFAULT_DROPOFF_REASON_LIMIT = 120;

export type DropoffReasonEntry = {
  capturedAt: string;
  reasonId: string;
  mode?: string;
  waveIndex?: number;
  wavesCompleted?: number;
  breaches?: number;
  accuracy?: number;
  wpm?: number;
};

function normalizeEntry(value: unknown): DropoffReasonEntry | null {
  if (!value || typeof value !== "object") return null;
  const data = value as Record<string, unknown>;
  const reasonId = typeof data.reasonId === "string" ? data.reasonId.trim() : "";
  if (!reasonId) return null;

  const capturedAtRaw = typeof data.capturedAt === "string" ? data.capturedAt.trim() : "";
  const capturedAt = capturedAtRaw || new Date().toISOString();
  const entry: DropoffReasonEntry = { capturedAt, reasonId };

  if (typeof data.mode === "string" && data.mode.trim()) {
    entry.mode = data.mode.trim();
  }

  type NumericEntryKey = "waveIndex" | "wavesCompleted" | "breaches" | "accuracy" | "wpm";
  const numericFields: Array<[NumericEntryKey, unknown, (n: number) => number]> = [
    ["waveIndex", data.waveIndex, (n) => Math.max(0, Math.floor(n))],
    ["wavesCompleted", data.wavesCompleted, (n) => Math.max(0, Math.floor(n))],
    ["breaches", data.breaches, (n) => Math.max(0, Math.floor(n))],
    ["accuracy", data.accuracy, (n) => Math.max(0, Math.min(1, n))],
    ["wpm", data.wpm, (n) => Math.max(0, n)]
  ];

  for (const [key, raw, normalize] of numericFields) {
    if (!Number.isFinite(raw)) continue;
    entry[key] = normalize(raw as number);
  }

  return entry;
}

export function readDropoffReasons(storage: Storage | null | undefined): DropoffReasonEntry[] {
  if (!storage) return [];
  let raw;
  try {
    raw = storage.getItem(DROPOFF_REASON_STORAGE_KEY);
  } catch {
    return [];
  }
  if (!raw) return [];
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return [];
  }
  if (!Array.isArray(parsed)) return [];
  const normalized: DropoffReasonEntry[] = [];
  for (const entry of parsed) {
    const next = normalizeEntry(entry);
    if (!next) continue;
    normalized.push(next);
  }
  return normalized;
}

export function recordDropoffReason(
  storage: Storage | null | undefined,
  entry: DropoffReasonEntry,
  options?: { maxEntries?: number }
): DropoffReasonEntry[] {
  if (!storage) return [];
  const maxEntriesRaw = options?.maxEntries ?? DEFAULT_DROPOFF_REASON_LIMIT;
  const maxEntries = Number.isFinite(maxEntriesRaw)
    ? Math.max(1, Math.floor(maxEntriesRaw))
    : DEFAULT_DROPOFF_REASON_LIMIT;

  const normalizedEntry = normalizeEntry(entry);
  if (!normalizedEntry) {
    return readDropoffReasons(storage);
  }

  const current = readDropoffReasons(storage);
  const next = [normalizedEntry, ...current].slice(0, maxEntries);
  try {
    storage.setItem(DROPOFF_REASON_STORAGE_KEY, JSON.stringify(next));
  } catch {
    return current;
  }
  return next;
}
