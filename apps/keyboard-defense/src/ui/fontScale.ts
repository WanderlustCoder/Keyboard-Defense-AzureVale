export const HUD_FONT_PRESETS = [
  { value: 0.85, label: "Small" },
  { value: 1, label: "Default" },
  { value: 1.15, label: "Large" },
  { value: 1.3, label: "Extra Large" }
] as const;

export type HudFontPreset = (typeof HUD_FONT_PRESETS)[number];

function getMinFontScale(): number {
  return HUD_FONT_PRESETS[0].value;
}

function getMaxFontScale(): number {
  return HUD_FONT_PRESETS[HUD_FONT_PRESETS.length - 1].value;
}

export function normalizeHudFontScaleValue(value: number): number {
  if (!Number.isFinite(value)) {
    return 1;
  }
  const min = getMinFontScale();
  const max = getMaxFontScale();
  const clamped = Math.min(max, Math.max(min, value));
  return Math.round(clamped * 100) / 100;
}

export function findHudFontPreset(scale: number, tolerance = 0.001): HudFontPreset | null {
  const normalized = normalizeHudFontScaleValue(scale);
  for (const preset of HUD_FONT_PRESETS) {
    if (Math.abs(preset.value - normalized) <= tolerance) {
      return preset;
    }
  }
  return null;
}

export function getNextHudFontPreset(scale: number, direction: number): HudFontPreset {
  const normalized = normalizeHudFontScaleValue(scale);
  const step = direction >= 0 ? 1 : -1;
  const currentIndex = HUD_FONT_PRESETS.findIndex(
    (preset) => Math.abs(preset.value - normalized) <= 0.001
  );
  if (currentIndex >= 0) {
    const nextIndex =
      (currentIndex + step + HUD_FONT_PRESETS.length) % HUD_FONT_PRESETS.length;
    return HUD_FONT_PRESETS[nextIndex];
  }
  const nextHigherIndex = HUD_FONT_PRESETS.findIndex((preset) => normalized < preset.value);
  if (step > 0) {
    return HUD_FONT_PRESETS[nextHigherIndex === -1 ? 0 : nextHigherIndex];
  }
  if (nextHigherIndex === -1) {
    return HUD_FONT_PRESETS[HUD_FONT_PRESETS.length - 1];
  }
  return HUD_FONT_PRESETS[Math.max(0, nextHigherIndex - 1)];
}

export function formatHudFontScale(scale: number): string {
  const normalized = normalizeHudFontScaleValue(scale);
  const preset = findHudFontPreset(normalized);
  const percent = Math.round(normalized * 100);
  if (preset) {
    return `${percent}% (${preset.label})`;
  }
  return `${percent}% (custom)`;
}
