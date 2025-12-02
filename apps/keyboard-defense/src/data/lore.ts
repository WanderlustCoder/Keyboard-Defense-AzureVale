import loreCatalog from "../../docs/lore/codex.json" with { type: "json" };

export interface LoreEntry {
  id: string;
  title: string;
  summary: string;
  unlockWave: number;
  body?: string;
  tags?: string[];
}

type LoreSource =
  | LoreEntry[]
  | {
      entries: LoreEntry[];
    };

function normalize(source: LoreSource): LoreEntry[] {
  if (Array.isArray(source)) return source;
  if (Array.isArray(source.entries)) return source.entries;
  return [];
}

const entries: LoreEntry[] = normalize(loreCatalog as LoreSource).sort(
  (a, b) => (a.unlockWave ?? 0) - (b.unlockWave ?? 0)
);

const map = new Map(entries.map((entry) => [entry.id, entry]));

export const LORE_ENTRIES: LoreEntry[] = entries;

export function getLore(id: string): LoreEntry | undefined {
  return map.get(id);
}

export function listLoreForWave(waveIndex: number): LoreEntry[] {
  const wave = Math.max(1, Math.floor(waveIndex));
  return entries.filter((entry) => entry.unlockWave <= wave);
}

export function listNewLoreForWave(waveIndex: number, unlocked: Set<string>): LoreEntry[] {
  return listLoreForWave(waveIndex).filter((entry) => !unlocked.has(entry.id));
}

export function allLoreIds(): string[] {
  return entries.map((entry) => entry.id);
}
