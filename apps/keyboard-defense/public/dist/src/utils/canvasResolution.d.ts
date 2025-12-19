export interface CanvasResolutionInput {
    baseWidth: number;
    baseHeight: number;
    availableWidth: number;
    availableHeight?: number;
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
export type DprChangeCause = "media" | "simulate" | "manual";
export interface DprChangeEvent {
    previous: number;
    next: number;
    cause: DprChangeCause;
}
export interface DprListenerOptions {
    onChange: (event: DprChangeEvent) => void;
    debounceMs?: number;
    getCurrent?: () => number;
}
export interface DprListenerHandle {
    start(): void;
    stop(): void;
    simulate(dpr: number, cause?: DprChangeCause): void;
    getCurrent(): number;
}
export declare function createDprListener(options: DprListenerOptions): DprListenerHandle;
//# sourceMappingURL=canvasResolution.d.ts.map