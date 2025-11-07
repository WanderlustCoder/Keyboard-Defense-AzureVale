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
export declare function calculateCanvasResolution(input: CanvasResolutionInput): CanvasResolution;
