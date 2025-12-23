import { type TurretTargetPriority } from "../core/types.js";

export type LaneMacroPreset = {
  id: string;
  label: string;
  description: string;
  apply: (lanes: number[]) => Record<number, TurretTargetPriority>;
};

const normalizeLanes = (lanes: number[]): number[] => {
  const unique = new Set<number>();
  for (const lane of lanes) {
    if (typeof lane === "number" && Number.isFinite(lane)) {
      unique.add(lane);
    }
  }
  return Array.from(unique).sort((a, b) => a - b);
};

export const buildLanePriorityMap = (
  lanes: number[],
  priority: TurretTargetPriority
): Record<number, TurretTargetPriority> => {
  const map: Record<number, TurretTargetPriority> = {};
  for (const lane of normalizeLanes(lanes)) {
    map[lane] = priority;
  }
  return map;
};

export const LANE_MACRO_PRESETS: LaneMacroPreset[] = [
  {
    id: "guard",
    label: "Guard",
    description: "All lanes target the first enemy.",
    apply: (lanes) => buildLanePriorityMap(lanes, "first")
  },
  {
    id: "hunter",
    label: "Hunter",
    description: "All lanes target the strongest enemy.",
    apply: (lanes) => buildLanePriorityMap(lanes, "strongest")
  },
  {
    id: "sweep",
    label: "Sweep",
    description: "All lanes clean up the weakest enemy.",
    apply: (lanes) => buildLanePriorityMap(lanes, "weakest")
  },
  {
    id: "balance",
    label: "Balance",
    description: "Lane A strongest, Lane B first, Lane C weakest.",
    apply: (lanes) => {
      const sorted = normalizeLanes(lanes);
      const pattern: TurretTargetPriority[] = [
        "strongest",
        "first",
        "weakest"
      ];
      const map: Record<number, TurretTargetPriority> = {};
      for (let index = 0; index < sorted.length; index += 1) {
        map[sorted[index]] = pattern[index % pattern.length];
      }
      return map;
    }
  }
];

export const getLaneMacroPreset = (
  id: string
): LaneMacroPreset | undefined => {
  const normalized = id.trim().toLowerCase();
  if (!normalized) return undefined;
  return LANE_MACRO_PRESETS.find((preset) => preset.id === normalized);
};
