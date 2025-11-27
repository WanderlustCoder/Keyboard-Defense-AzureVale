import rawCatalog from "../../docs/taunts/catalog.json" with { type: "json" };

export type TauntRarity = "boss" | "elite" | "affix";

export interface TauntEntry {
  id: string;
  enemyType: string;
  rarity: TauntRarity;
  text: string;
  tags: string[];
  voiceLineId?: string;
}

type CatalogFile =
  | {
      entries: TauntEntry[];
    }
  | TauntEntry[];

function normalizeCatalog(source: CatalogFile): TauntEntry[] {
  if (Array.isArray(source)) {
    return source;
  }
  if (Array.isArray(source.entries)) {
    return source.entries;
  }
  return [];
}

const catalog: TauntEntry[] = normalizeCatalog(rawCatalog as CatalogFile);
const tauntMap = new Map<string, TauntEntry>();
for (const entry of catalog) {
  tauntMap.set(entry.id, entry);
}

export const TAUNT_CATALOG: TauntEntry[] = catalog;

export function getTauntEntry(id: string): TauntEntry | undefined {
  return tauntMap.get(id);
}

export function getTauntText(id: string, fallback?: string): string {
  const entry = tauntMap.get(id);
  if (entry && typeof entry.text === "string" && entry.text.trim().length > 0) {
    return entry.text;
  }
  return fallback ?? `[[${id}]]`;
}
