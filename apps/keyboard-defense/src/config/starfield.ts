export interface StarfieldLayerConfig {
  id: string;
  count: number;
  depth: number;
  speed: number;
  direction: 1 | -1;
  depthOffset?: number;
  waveSpeedMultiplier?: number;
}

export interface StarfieldConfig {
  waveProgressSeconds: number;
  maxWaveSpeedMultiplier: number;
  waveDepthBoost: number;
  baseDepth: number;
  damageDepthBoost: number;
  maxSeverityTintBoost: number;
  tintThresholds: {
    warning: number;
    crisis: number;
  };
  tintColors: {
    calm: string;
    warning: string;
    crisis: string;
  };
  tintBlendIntensity: number;
  reducedMotion: {
    freezeParallax: boolean;
    tintOnly: boolean;
    clampWaveProgress?: number;
    clampSeverity?: number;
  };
  layers: StarfieldLayerConfig[];
}

export const defaultStarfieldConfig: StarfieldConfig = {
  waveProgressSeconds: 45,
  maxWaveSpeedMultiplier: 1.8,
  waveDepthBoost: 0.2,
  baseDepth: 1,
  damageDepthBoost: 0.4,
  maxSeverityTintBoost: 0.2,
  tintThresholds: {
    warning: 0.35,
    crisis: 0.7
  },
  tintColors: {
    calm: "#cbd5f5",
    warning: "#fbbf24",
    crisis: "#fb7185"
  },
  tintBlendIntensity: 0.65,
  layers: [
    { id: "backdrop", count: 40, depth: 0.45, speed: 0.005, direction: -1, depthOffset: -0.05, waveSpeedMultiplier: 0.6 },
    { id: "mid", count: 30, depth: 0.75, speed: 0.012, direction: -1, depthOffset: 0, waveSpeedMultiplier: 1 },
    { id: "foreground", count: 24, depth: 1.1, speed: 0.02, direction: 1, depthOffset: 0.1, waveSpeedMultiplier: 1.2 }
  ],
  reducedMotion: {
    freezeParallax: true,
    tintOnly: true,
    clampWaveProgress: 0.2,
    clampSeverity: 0.25
  }
};
