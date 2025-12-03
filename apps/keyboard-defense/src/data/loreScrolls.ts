import scrollCatalog from "../../docs/lore/scrolls.json" with { type: "json" };

export interface LoreScroll {
  id: string;
  title: string;
  summary: string;
  body: string;
  requiredLessons: number;
  tags?: string[];
}

type LoreScrollSource =
  | LoreScroll[]
  | {
      scrolls: LoreScroll[];
    };

function normalize(source: LoreScrollSource): LoreScroll[] {
  if (Array.isArray(source)) return source;
  if (Array.isArray(source.scrolls)) return source.scrolls;
  return [];
}

function clampLessons(value: number | null | undefined): number {
  if (typeof value !== "number" || !Number.isFinite(value)) return 0;
  return Math.max(0, Math.floor(value));
}

function toIdSet(ids: Iterable<string> | null | undefined): Set<string> {
  const set = new Set<string>();
  if (!ids) return set;
  for (const id of ids) {
    if (typeof id === "string") {
      set.add(id);
    }
  }
  return set;
}

const entries: LoreScroll[] = normalize(scrollCatalog as LoreScrollSource).sort((a, b) => {
  const aReq = clampLessons(a.requiredLessons);
  const bReq = clampLessons(b.requiredLessons);
  if (aReq === bReq) return a.title.localeCompare(b.title);
  return aReq - bReq;
});

const map = new Map(entries.map((entry) => [entry.id, entry]));

export const LORE_SCROLLS: LoreScroll[] = entries;

export function getLoreScroll(id: string): LoreScroll | undefined {
  return map.get(id);
}

export function listLoreScrolls(): LoreScroll[] {
  return entries;
}

export function listNewLoreScrollsForLessons(
  lessonsCompleted: number,
  unlocked: Iterable<string>
): LoreScroll[] {
  const lessonCount = clampLessons(lessonsCompleted);
  const unlockedSet = toIdSet(unlocked);
  return entries.filter(
    (entry) => lessonCount >= clampLessons(entry.requiredLessons) && !unlockedSet.has(entry.id)
  );
}

export type LoreScrollStatus = {
  scroll: LoreScroll;
  unlocked: boolean;
  progress: number;
  remaining: number;
};

export type LoreScrollProgressSummary = {
  lessonsCompleted: number;
  total: number;
  unlocked: number;
  next?: { requiredLessons: number; remaining: number; title: string } | null;
  entries: LoreScrollStatus[];
};

export function buildLoreScrollProgress(
  lessonsCompleted: number,
  unlocked: Iterable<string>
): LoreScrollProgressSummary {
  const lessonCount = clampLessons(lessonsCompleted);
  const unlockedSet = toIdSet(unlocked);
  const statuses: LoreScrollStatus[] = entries.map((scroll) => {
    const required = clampLessons(scroll.requiredLessons);
    const unlockedNow = unlockedSet.has(scroll.id) || lessonCount >= required;
    const progress = Math.min(lessonCount, required);
    const remaining = Math.max(0, required - lessonCount);
    return {
      scroll,
      unlocked: unlockedNow,
      progress,
      remaining
    };
  });
  const unlockedTotal = statuses.filter((entry) => entry.unlocked).length;
  const next = statuses.find((entry) => !entry.unlocked);
  return {
    lessonsCompleted: lessonCount,
    total: statuses.length,
    unlocked: unlockedTotal,
    next: next
      ? {
          requiredLessons: clampLessons(next.scroll.requiredLessons),
          remaining: Math.max(
            0,
            clampLessons(next.scroll.requiredLessons) - lessonCount
          ),
          title: next.scroll.title
        }
      : null,
    entries: statuses
  };
}
