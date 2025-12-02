import seasonRoadmap from "../../docs/roadmap/season1.json" with { type: "json" };

export type RoadmapCategory = "story" | "systems" | "challenge" | "lore";

export interface RoadmapRequirement {
  tutorialComplete?: boolean;
  wave?: number;
  castleLevel?: number;
  loreEntries?: number;
}

export interface RoadmapEntry {
  id: string;
  title: string;
  phase?: string;
  type: RoadmapCategory;
  milestone: string;
  summary: string;
  reward?: string;
  requires?: RoadmapRequirement;
}

export interface RoadmapContext {
  tutorialCompleted: boolean;
  currentWave: number;
  completedWaves: number;
  totalWaves: number;
  castleLevel: number;
  loreUnlocked: number;
}

export type RoadmapStatus = "done" | "active" | "upcoming" | "locked";

export interface RoadmapEntryState extends RoadmapEntry {
  status: RoadmapStatus;
  completionRatio: number;
  progressLabel: string;
  blockers: string[];
}

interface RoadmapFile {
  season?: string;
  theme?: string;
  items?: RoadmapEntry[];
}

type RoadmapSource = RoadmapFile | { items?: RoadmapEntry[] } | RoadmapEntry[];

function normalizeEntries(source: RoadmapSource): RoadmapEntry[] {
  if (Array.isArray(source)) {
    return source;
  }
  if (Array.isArray((source as RoadmapFile).items)) {
    return (source as RoadmapFile).items ?? [];
  }
  return [];
}

const RAW_ENTRIES = normalizeEntries(seasonRoadmap as RoadmapSource);

const ALLOWED_TYPES: RoadmapCategory[] = ["story", "systems", "challenge", "lore"];

function normalizeType(type: string | undefined): RoadmapCategory {
  if (type && ALLOWED_TYPES.includes(type as RoadmapCategory)) {
    return type as RoadmapCategory;
  }
  return "story";
}

const ENTRIES: RoadmapEntry[] = RAW_ENTRIES.map((entry) => ({
  ...entry,
  type: normalizeType(entry.type),
  milestone: entry.milestone ?? entry.title ?? "Milestone",
  summary: entry.summary ?? ""
}));

export const SEASON_ROADMAP = {
  season: (seasonRoadmap as RoadmapFile).season ?? "Season Roadmap",
  theme: (seasonRoadmap as RoadmapFile).theme ?? "",
  items: ENTRIES
};

function clampWave(value: number | undefined, fallback: number): number {
  if (!Number.isFinite(value ?? Number.NaN)) return fallback;
  return Math.max(1, Math.floor(value ?? fallback));
}

function clampNonNegative(value: number | undefined, fallback = 0): number {
  if (!Number.isFinite(value ?? Number.NaN)) return fallback;
  return Math.max(0, Math.floor(value ?? fallback));
}

function clampPositive(value: number | undefined, fallback = 1): number {
  if (!Number.isFinite(value ?? Number.NaN)) return fallback;
  return Math.max(1, Math.floor(value ?? fallback));
}

function buildRequirementLabels(
  requires: RoadmapRequirement | undefined,
  context: RoadmapContext
): {
  completionRatio: number;
  blockers: string[];
  labels: string[];
  status: RoadmapStatus;
} {
  if (!requires || Object.keys(requires).length === 0) {
    return { completionRatio: 1, blockers: [], labels: ["Ready any time"], status: "done" };
  }
  const parts: Array<{
    satisfied: boolean;
    label: string;
    blocker: string;
    kind: keyof RoadmapRequirement;
    target?: number;
    near?: boolean;
  }> = [];

  if (requires.tutorialComplete) {
    const satisfied = Boolean(context.tutorialCompleted);
    parts.push({
      satisfied,
      label: satisfied ? "Tutorial complete" : "Finish tutorial",
      blocker: "Finish tutorial to unlock",
      kind: "tutorialComplete",
      near: !satisfied
    });
  }

  if (requires.wave !== undefined) {
    const targetWave = clampWave(requires.wave, 1);
    const satisfied = context.completedWaves >= targetWave;
    parts.push({
      satisfied,
      label: `Wave ${Math.min(targetWave, context.totalWaves)} of ${context.totalWaves}`,
      blocker: `Clear wave ${targetWave}`,
      kind: "wave",
      target: targetWave,
      near: !satisfied && context.currentWave >= targetWave
    });
  }

  if (requires.castleLevel !== undefined) {
    const targetLevel = clampPositive(requires.castleLevel, 1);
    const satisfied = context.castleLevel >= targetLevel;
    parts.push({
      satisfied,
      label: `Castle Lv. ${context.castleLevel}/${targetLevel}`,
      blocker: `Upgrade castle to level ${targetLevel}`,
      kind: "castleLevel",
      target: targetLevel,
      near: !satisfied && context.castleLevel + 1 >= targetLevel
    });
  }

  if (requires.loreEntries !== undefined) {
    const targetLore = clampPositive(requires.loreEntries, 1);
    const satisfied = context.loreUnlocked >= targetLore;
    parts.push({
      satisfied,
      label: `${Math.min(context.loreUnlocked, targetLore)}/${targetLore} codex`,
      blocker: `Unlock ${targetLore} lore entries`,
      kind: "loreEntries",
      target: targetLore,
      near: !satisfied && context.loreUnlocked + 1 >= targetLore
    });
  }

  const completionRatio =
    parts.length === 0 ? 1 : parts.filter((part) => part.satisfied).length / parts.length;
  const blockers = parts.filter((part) => !part.satisfied).map((part) => part.blocker);
  const labels = parts.map((part) => part.label);
  const tutorialBlocked = parts.some(
    (part) => part.kind === "tutorialComplete" && !part.satisfied
  );
  const hasTutorialRequirement = parts.some((part) => part.kind === "tutorialComplete");
  let status: RoadmapStatus = "upcoming";
  if (completionRatio >= 1) {
    status = "done";
  } else if (tutorialBlocked && hasTutorialRequirement && parts.length > 1) {
    status = "locked";
  } else if (
    tutorialBlocked ||
    parts.some((part) => !part.satisfied && part.near) ||
    parts.every((part) => part.satisfied || part.kind !== "wave")
  ) {
    status = "active";
  }

  return { completionRatio, blockers, labels, status };
}

export function listSeasonRoadmapEntries(): RoadmapEntry[] {
  return [...ENTRIES];
}

export function evaluateRoadmap(
  context: Partial<RoadmapContext>
): { entries: RoadmapEntryState[]; completed: number; total: number; activeId: string | null } {
  const normalized: RoadmapContext = {
    tutorialCompleted: Boolean(context.tutorialCompleted),
    currentWave: clampWave(context.currentWave ?? 1, 1),
    completedWaves: clampNonNegative(context.completedWaves ?? 0, 0),
    totalWaves: clampPositive(context.totalWaves ?? 3, 3),
    castleLevel: clampPositive(context.castleLevel ?? 1, 1),
    loreUnlocked: clampNonNegative(context.loreUnlocked ?? 0, 0)
  };
  normalized.totalWaves = Math.max(
    normalized.totalWaves,
    normalized.currentWave,
    normalized.completedWaves || 0
  );

  const states: RoadmapEntryState[] = ENTRIES.map((entry) => {
    const requirementState = buildRequirementLabels(entry.requires, normalized);
    const status = requirementState.status;
    const progressLabel = requirementState.labels.join(" • ");
    return {
      ...entry,
      status,
      completionRatio: requirementState.completionRatio,
      progressLabel,
      blockers: requirementState.blockers
    };
  });

  const completed = states.filter((entry) => entry.status === "done").length;
  const total = states.length;
  const activeId =
    states.find((entry) => entry.status === "active")?.id ??
    states.find((entry) => entry.status !== "done")?.id ??
    null;

  return { entries: states, completed, total, activeId };
}
