export const PROGRESS_TRANSFER_FORMAT = "keyboard-defense-progress";
export const PROGRESS_TRANSFER_VERSION = 1;

export type ProgressTransferPayload = {
  format: typeof PROGRESS_TRANSFER_FORMAT;
  version: number;
  exportedAt: string;
  entries: Record<string, string | null>;
};

const DEFAULT_ALLOWED_PREFIXES = ["keyboard-defense:"];
const DEFAULT_ALLOWED_KEYS = ["lore.codex.unlocked"];

function normalizeStringList(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  const normalized: string[] = [];
  const seen = new Set<string>();
  for (const entry of value) {
    if (typeof entry !== "string") continue;
    const trimmed = entry.trim();
    if (!trimmed) continue;
    if (seen.has(trimmed)) continue;
    seen.add(trimmed);
    normalized.push(trimmed);
  }
  return normalized;
}

function buildAllowList(options?: { allowedPrefixes?: string[]; allowedKeys?: string[] }): {
  prefixes: string[];
  keys: Set<string>;
} {
  const prefixes = normalizeStringList(options?.allowedPrefixes);
  if (prefixes.length === 0) prefixes.push(...DEFAULT_ALLOWED_PREFIXES);
  const keys = new Set<string>(normalizeStringList(options?.allowedKeys));
  for (const key of DEFAULT_ALLOWED_KEYS) keys.add(key);
  return { prefixes, keys };
}

export function isAllowedProgressKey(
  key: string,
  options?: { allowedPrefixes?: string[]; allowedKeys?: string[] }
): boolean {
  const allow = buildAllowList(options);
  if (allow.keys.has(key)) return true;
  return allow.prefixes.some((prefix) => key.startsWith(prefix));
}

export function exportProgressTransferPayload(
  storage: Storage | null | undefined,
  options?: { allowedPrefixes?: string[]; allowedKeys?: string[] }
): ProgressTransferPayload {
  const entries: Record<string, string | null> = {};
  if (storage) {
    const allow = buildAllowList(options);
    const keys = new Set<string>();
    for (let i = 0; i < storage.length; i += 1) {
      const key = storage.key(i);
      if (!key) continue;
      if (allow.keys.has(key) || allow.prefixes.some((prefix) => key.startsWith(prefix))) {
        keys.add(key);
      }
    }
    for (const key of Array.from(keys).sort((a, b) => a.localeCompare(b))) {
      entries[key] = storage.getItem(key);
    }
  }
  return {
    format: PROGRESS_TRANSFER_FORMAT,
    version: PROGRESS_TRANSFER_VERSION,
    exportedAt: new Date().toISOString(),
    entries
  };
}

type ImportResult = {
  applied: number;
  removed: number;
  skipped: number;
  errors: string[];
};

export function importProgressTransferPayload(
  storage: Storage | null | undefined,
  payload: unknown,
  options?: { allowedPrefixes?: string[]; allowedKeys?: string[] }
): ImportResult {
  const result: ImportResult = { applied: 0, removed: 0, skipped: 0, errors: [] };
  if (!storage) {
    result.errors.push("Storage unavailable.");
    return result;
  }
  if (!payload || typeof payload !== "object") {
    result.errors.push("Invalid payload (expected an object).");
    return result;
  }
  const data = payload as Record<string, unknown>;
  if (data.format !== PROGRESS_TRANSFER_FORMAT) {
    result.errors.push("Unsupported payload format.");
    return result;
  }
  if (data.version !== PROGRESS_TRANSFER_VERSION) {
    result.errors.push("Unsupported payload version.");
    return result;
  }
  const entries = data.entries;
  if (!entries || typeof entries !== "object") {
    result.errors.push("Invalid payload entries (expected an object).");
    return result;
  }
  const allow = buildAllowList(options);
  for (const [key, value] of Object.entries(entries as Record<string, unknown>)) {
    const allowed = allow.keys.has(key) || allow.prefixes.some((prefix) => key.startsWith(prefix));
    if (!allowed) {
      result.skipped += 1;
      continue;
    }
    if (typeof value === "string") {
      try {
        storage.setItem(key, value);
        result.applied += 1;
      } catch (error) {
        result.errors.push(`Failed to write ${key}: ${String(error)}`);
      }
      continue;
    }
    if (value === null) {
      try {
        storage.removeItem(key);
        result.removed += 1;
      } catch (error) {
        result.errors.push(`Failed to remove ${key}: ${String(error)}`);
      }
      continue;
    }
    result.skipped += 1;
  }
  return result;
}
