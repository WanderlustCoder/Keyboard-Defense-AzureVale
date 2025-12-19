export const ERROR_CLUSTER_STORAGE_KEY = "keyboard-defense:error-clusters";
export const ERROR_CLUSTER_VERSION = "v1";

const MAX_HISTORY = 180;
const MAX_AGE_MS = 1000 * 60 * 60 * 24 * 7;

export type ErrorClusterEntry = {
  expected: string;
  received: string;
  timestamp: number;
};

export type ErrorClusterProgress = {
  version: string;
  history: ErrorClusterEntry[];
  updatedAt: string;
};

type NormalizedKey = string & { __kind: "normalized-key" };

function normalizeKey(value: unknown): NormalizedKey | null {
  if (typeof value !== "string" || value.length !== 1) return null;
  const normalized = value.toLowerCase();
  if (!/^[a-z]$/.test(normalized)) return null;
  return normalized as NormalizedKey;
}

function normalizeTimestamp(value: unknown, fallback: number): number {
  const candidate =
    typeof value === "number" && Number.isFinite(value) ? value : Number(fallback);
  if (!Number.isFinite(candidate)) return fallback;
  return Math.max(0, Math.floor(candidate));
}

function normalizeEntry(raw: unknown): ErrorClusterEntry | null {
  if (!raw || typeof raw !== "object") return null;
  const data = raw as Record<string, unknown>;
  const expected = normalizeKey(data.expected);
  const received = normalizeKey(data.received);
  if (!expected || !received) return null;
  const timestamp = normalizeTimestamp(data.timestamp, Date.now());
  return { expected, received, timestamp };
}

function pruneHistory(history: ErrorClusterEntry[], nowMs: number): ErrorClusterEntry[] {
  const cutoff = nowMs - MAX_AGE_MS;
  const fresh = history.filter((entry) => entry.timestamp >= cutoff);
  if (fresh.length <= MAX_HISTORY) return fresh;
  return fresh.slice(fresh.length - MAX_HISTORY);
}

const DEFAULT_PROGRESS: ErrorClusterProgress = {
  version: ERROR_CLUSTER_VERSION,
  history: [],
  updatedAt: new Date().toISOString()
};

export function readErrorClusterProgress(storage: Storage | null | undefined): ErrorClusterProgress {
  if (!storage) return { ...DEFAULT_PROGRESS };
  try {
    const raw = storage.getItem(ERROR_CLUSTER_STORAGE_KEY);
    if (!raw) return { ...DEFAULT_PROGRESS };
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== "object") return { ...DEFAULT_PROGRESS };
    if (parsed.version !== ERROR_CLUSTER_VERSION) return { ...DEFAULT_PROGRESS };
    const history: ErrorClusterEntry[] = [];
    if (Array.isArray(parsed.history)) {
      for (const item of parsed.history) {
        const normalized = normalizeEntry(item);
        if (normalized) {
          history.push(normalized);
        }
      }
    }
    const nowMs = Date.now();
    const pruned = pruneHistory(history, nowMs);
    const updatedAt =
      typeof parsed.updatedAt === "string" && parsed.updatedAt.length > 0
        ? parsed.updatedAt
        : new Date().toISOString();
    return {
      version: ERROR_CLUSTER_VERSION,
      history: pruned,
      updatedAt
    };
  } catch {
    return { ...DEFAULT_PROGRESS };
  }
}

export function writeErrorClusterProgress(
  storage: Storage | null | undefined,
  progress: ErrorClusterProgress
): void {
  if (!storage) return;
  const nowMs = Date.now();
  const normalized: ErrorClusterProgress = {
    version: ERROR_CLUSTER_VERSION,
    history: pruneHistory(progress.history ?? [], nowMs),
    updatedAt: progress.updatedAt ?? new Date().toISOString()
  };
  try {
    storage.setItem(ERROR_CLUSTER_STORAGE_KEY, JSON.stringify(normalized));
  } catch {
    // ignore persistence failures
  }
}

export function recordErrorClusterEntry(
  progress: ErrorClusterProgress,
  entry: { expected: string | null | undefined; received: string | null | undefined; timestamp?: number }
): ErrorClusterProgress {
  const expected = normalizeKey(entry.expected);
  const received = normalizeKey(entry.received);
  if (!expected || !received) {
    return progress;
  }
  const nowMs = Date.now();
  const timestamp = normalizeTimestamp(entry.timestamp, nowMs);
  const nextHistory = [...(progress.history ?? []), { expected, received, timestamp }];
  return {
    version: ERROR_CLUSTER_VERSION,
    history: pruneHistory(nextHistory, nowMs),
    updatedAt: new Date().toISOString()
  };
}

export function getTopExpectedKeys(
  progress: ErrorClusterProgress,
  options: { nowMs?: number; windowMs?: number; limit?: number } = {}
): Array<{ key: string; count: number }> {
  const nowMs = Number.isFinite(options.nowMs) ? (options.nowMs as number) : Date.now();
  const windowMs =
    typeof options.windowMs === "number" && Number.isFinite(options.windowMs) && options.windowMs > 0
      ? options.windowMs
      : 1000 * 60 * 10;
  const limit =
    typeof options.limit === "number" && Number.isFinite(options.limit) && options.limit > 0
      ? Math.floor(options.limit)
      : 3;
  const cutoff = nowMs - windowMs;
  const counts = new Map<string, number>();
  for (const entry of progress.history ?? []) {
    if (entry.timestamp < cutoff) continue;
    counts.set(entry.expected, (counts.get(entry.expected) ?? 0) + 1);
  }
  const sorted = [...counts.entries()]
    .map(([key, count]) => ({ key, count }))
    .sort((a, b) => b.count - a.count || a.key.localeCompare(b.key));
  return sorted.slice(0, limit);
}

