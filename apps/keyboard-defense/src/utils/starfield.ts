import { defaultStarfieldConfig, type StarfieldConfig } from "../config/starfield.js";
import { type GameState } from "../core/types.js";

export interface StarfieldLayerState {
  id: string;
  velocity: number;
  scroll: number;
  depth: number;
  direction: 1 | -1;
  baseDepth: number;
}

export interface StarfieldParallaxState {
  waveProgress: number;
  castleHealthRatio: number;
  severity: number;
  driftMultiplier: number;
  depth: number;
  tint: string;
  reducedMotionApplied: boolean;
  layers: StarfieldLayerState[];
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}

function hexToRgb(hex: string): { r: number; g: number; b: number } | null {
  const normalized = hex.replace("#", "");
  if (normalized.length !== 6) return null;
  const bigint = Number.parseInt(normalized, 16);
  if (Number.isNaN(bigint)) return null;
  const r = (bigint >> 16) & 255;
  const g = (bigint >> 8) & 255;
  const b = bigint & 255;
  return { r, g, b };
}

function rgbToHex(r: number, g: number, b: number): string {
  const toHex = (value: number) => value.toString(16).padStart(2, "0");
  return `#${toHex(clamp(Math.round(r), 0, 255))}${toHex(clamp(Math.round(g), 0, 255))}${toHex(
    clamp(Math.round(b), 0, 255)
  )}`;
}

function mixHexColors(a: string, b: string, ratio: number): string {
  const start = hexToRgb(a);
  const end = hexToRgb(b);
  if (!start || !end) {
    return a;
  }
  const t = clamp(ratio, 0, 1);
  const r = start.r + (end.r - start.r) * t;
  const g = start.g + (end.g - start.g) * t;
  const bVal = start.b + (end.b - start.b) * t;
  return rgbToHex(r, g, bVal);
}

function resolveTintColor(
  severity: number,
  config: StarfieldConfig
): string {
  const { calm, warning, crisis } = config.tintColors;
  const warningThreshold = clamp(config.tintThresholds.warning, 0.05, 0.95);
  const crisisThreshold = clamp(config.tintThresholds.crisis, warningThreshold + 0.05, 0.99);
  if (severity <= warningThreshold) {
    const localRatio = severity / warningThreshold;
    return mixHexColors(calm, warning, localRatio);
  }
  if (severity >= crisisThreshold) {
    const localRatio = clamp((severity - crisisThreshold) / (1 - crisisThreshold), 0, 1);
    return mixHexColors(warning, crisis, localRatio);
  }
  const normalized = clamp((severity - warningThreshold) / (crisisThreshold - warningThreshold), 0, 1);
  return mixHexColors(warning, crisis, normalized);
}

export function deriveStarfieldState(
  state: GameState,
  options: {
    config?: StarfieldConfig;
    reducedMotion?: boolean;
    severityOverride?: number;
    waveProgressOverride?: number;
  } = {}
): StarfieldParallaxState {
  const config = options.config ?? defaultStarfieldConfig;
  const reducedMotion = Boolean(options.reducedMotion);
  let waveProgress =
    typeof options.waveProgressOverride === "number"
      ? clamp(options.waveProgressOverride, 0, 1)
      : clamp(state.wave.timeInWave / Math.max(1, config.waveProgressSeconds), 0, 1);
  let castleHealthRatio = clamp(state.castle.health / Math.max(1, state.castle.maxHealth), 0, 1);
  let severity =
    typeof options.severityOverride === "number"
      ? clamp(options.severityOverride, 0, 1)
      : clamp(1 - castleHealthRatio, 0, 1);
  if (reducedMotion) {
    const clampWave = config.reducedMotion.clampWaveProgress;
    const clampSeverity = config.reducedMotion.clampSeverity;
    if (typeof clampWave === "number") {
      waveProgress = Math.min(waveProgress, clamp(clampWave, 0, 1));
    }
    if (typeof clampSeverity === "number") {
      severity = Math.min(severity, clamp(clampSeverity, 0, 1));
      castleHealthRatio = clamp(1 - severity, 0, 1);
    }
  }
  const driftMultiplier =
    config.maxWaveSpeedMultiplier <= 1
      ? 1
      : 1 + waveProgress * (config.maxWaveSpeedMultiplier - 1);
  const depth =
    config.baseDepth +
    severity * config.damageDepthBoost +
    waveProgress * config.waveDepthBoost;
  const tint = resolveTintColor(
    severity * (config.tintBlendIntensity + config.maxSeverityTintBoost),
    config
  );

  const layers: StarfieldLayerState[] = config.layers.map((layer) => {
    const baseVelocity = layer.speed * driftMultiplier * (layer.waveSpeedMultiplier ?? 1);
    const velocity =
      reducedMotion && config.reducedMotion.freezeParallax ? 0 : baseVelocity;
    const scrollBase = velocity === 0 ? 0 : (state.time * velocity * layer.direction) % 1;
    const scroll = ((scrollBase % 1) + 1) % 1;
    return {
      id: layer.id,
      velocity,
      scroll,
      depth: layer.depth + (layer.depthOffset ?? 0),
      baseDepth: layer.depth,
      direction: layer.direction
    };
  });

  return {
    waveProgress,
    castleHealthRatio,
    severity,
    driftMultiplier,
    depth,
    tint,
    reducedMotionApplied: reducedMotion && config.reducedMotion.freezeParallax,
    layers
  };
}
