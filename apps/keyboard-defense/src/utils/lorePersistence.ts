const STORAGE_KEY = "lore.codex.unlocked";

export interface LoreProgress {
  version: string;
  unlocked: string[];
}

export function readLoreProgress(storage: Storage | null | undefined, version: string): LoreProgress {
  if (!storage) {
    return { version, unlocked: [] };
  }
  try {
    const raw = storage.getItem(STORAGE_KEY);
    if (!raw) return { version, unlocked: [] };
    const parsed = JSON.parse(raw);
    if (parsed.version !== version || !Array.isArray(parsed.unlocked)) {
      return { version, unlocked: [] };
    }
    return { version, unlocked: parsed.unlocked.filter((id: unknown) => typeof id === "string") };
  } catch {
    return { version, unlocked: [] };
  }
}

export function writeLoreProgress(
  storage: Storage | null | undefined,
  unlocked: Iterable<string>,
  version: string
): void {
  if (!storage) return;
  const payload: LoreProgress = {
    version,
    unlocked: Array.from(new Set(unlocked))
  };
  try {
    storage.setItem(STORAGE_KEY, JSON.stringify(payload));
  } catch {
    // ignore persistence failures (storage full/unavailable)
  }
}
