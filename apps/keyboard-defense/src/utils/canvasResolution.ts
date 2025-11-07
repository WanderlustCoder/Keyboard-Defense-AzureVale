const MIN_CANVAS_WIDTH = 320;

export interface CanvasResolutionInput {
  baseWidth: number;
  baseHeight: number;
  availableWidth: number;
  devicePixelRatio?: number;
  minWidth?: number;
}

export interface CanvasResolution {
  cssWidth: number;
  cssHeight: number;
  renderWidth: number;
  renderHeight: number;
}

export function calculateCanvasResolution(input: CanvasResolutionInput): CanvasResolution {
  const {
    baseWidth,
    baseHeight,
    availableWidth,
    devicePixelRatio = 1,
    minWidth = MIN_CANVAS_WIDTH
  } = input;

  const safeWidth = Number.isFinite(availableWidth) && availableWidth > 0 ? availableWidth : baseWidth;
  const boundedCssWidth = clamp(Math.round(safeWidth), minWidth, baseWidth);
  const aspectRatio = baseHeight / baseWidth;
  const cssHeight = Math.round(boundedCssWidth * aspectRatio);
  const dpr = Math.max(1, devicePixelRatio);
  const renderWidth = Math.max(1, Math.round(boundedCssWidth * dpr));
  const renderHeight = Math.max(1, Math.round(cssHeight * dpr));

  return {
    cssWidth: boundedCssWidth,
    cssHeight,
    renderWidth,
    renderHeight
  };
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}
