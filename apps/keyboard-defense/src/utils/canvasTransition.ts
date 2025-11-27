export interface CanvasResolutionSnapshot {
  cssWidth: number;
  cssHeight: number;
  renderWidth: number;
  renderHeight: number;
}

export interface CanvasResolutionChangeEntry extends CanvasResolutionSnapshot {
  capturedAt: string;
  cause: string;
  fromDpr: number;
  toDpr: number;
  transitionMs: number;
  prefersCondensedHud: boolean | null;
  hudLayout: "stacked" | "condensed" | null;
}

interface BuildResolutionChangeOptions {
  resolution: CanvasResolutionSnapshot;
  cause?: string;
  previousDpr: number;
  nextDpr: number;
  transitionMs?: number | null;
  prefersCondensedHud?: boolean | null;
  hudLayout?: "stacked" | "condensed" | null;
  capturedAt?: string;
}

export function buildResolutionChangeEntry(
  options: BuildResolutionChangeOptions
): CanvasResolutionChangeEntry {
  const {
    resolution,
    cause = "auto",
    previousDpr,
    nextDpr,
    transitionMs = 0,
    prefersCondensedHud = null,
    hudLayout = null,
    capturedAt = new Date().toISOString()
  } = options;

  return {
    capturedAt,
    cause,
    fromDpr: sanitizeDpr(previousDpr),
    toDpr: sanitizeDpr(nextDpr),
    cssWidth: clampDimension(resolution.cssWidth),
    cssHeight: clampDimension(resolution.cssHeight),
    renderWidth: clampDimension(resolution.renderWidth),
    renderHeight: clampDimension(resolution.renderHeight),
    transitionMs: Math.max(0, Math.round(Number(transitionMs) || 0)),
    prefersCondensedHud: normalizeNullableBoolean(prefersCondensedHud),
    hudLayout: normalizeHudLayout(hudLayout)
  };
}

function sanitizeDpr(value: number): number {
  if (!Number.isFinite(value) || value <= 0) {
    return 1;
  }
  return Math.round(value * 100) / 100;
}

function clampDimension(value: number): number {
  if (!Number.isFinite(value)) {
    return 1;
  }
  return Math.max(1, Math.round(value));
}

function normalizeNullableBoolean(value: boolean | null | undefined): boolean | null {
  if (typeof value === "boolean") {
    return value;
  }
  return null;
}

function normalizeHudLayout(
  layout: "stacked" | "condensed" | null | undefined
): "stacked" | "condensed" | null {
  if (layout === "stacked" || layout === "condensed") {
    return layout;
  }
  return null;
}

