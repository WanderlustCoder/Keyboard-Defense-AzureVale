export type FocusOutlinePreset = "system" | "contrast" | "glow";

export const FOCUS_OUTLINE_PRESETS: FocusOutlinePreset[] = ["system", "contrast", "glow"];

const PRESET_LABELS: Record<FocusOutlinePreset, string> = {
  system: "Match UI colors",
  contrast: "High contrast",
  glow: "Glow halo"
};

const PRESET_DESCRIPTIONS: Record<FocusOutlinePreset, string> = {
  system: "Keep each panel's native focus color and offset.",
  contrast: "Thicker amber outline with a dark halo for maximum legibility.",
  glow: "Soft cyan ring with a secondary glow for clearer keyboard focus."
};

export function normalizeFocusOutlinePreset(value: unknown): FocusOutlinePreset {
  return value === "contrast" || value === "glow" ? value : "system";
}

export function getFocusOutlineLabel(preset: FocusOutlinePreset): string {
  return PRESET_LABELS[normalizeFocusOutlinePreset(preset)];
}

export function describeFocusOutlinePreset(preset: FocusOutlinePreset): string {
  return PRESET_DESCRIPTIONS[normalizeFocusOutlinePreset(preset)];
}
