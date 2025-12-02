export type AssetIntegrityStatus = "pending" | "passed" | "warning" | "failed" | "skipped";
export interface AssetIntegrityFailure {
    key: string;
    type: "missing" | "mismatch" | "unreferenced" | "fetch-error";
    path?: string | null;
    expected?: string | null;
    actual?: string | null;
}
export interface AssetIntegritySummary {
    status: AssetIntegrityStatus;
    strictMode: boolean;
    scenario: string | null;
    manifest: string | null;
    manifestUrl?: string | null;
    checked: number;
    missingHash: number;
    failed: number;
    extraEntries: number;
    totalImages: number;
    durationMs: number | null;
    completedAt?: string | null;
    firstFailure?: AssetIntegrityFailure | null;
    error?: string | null;
}
export interface AssetLoaderOptions {
    integrityMode?: "soft" | "strict" | "off";
    scenario?: string;
    useAtlas?: boolean;
    atlasUrl?: string;
}
export interface DefeatAnimationFrame {
    key: string;
    durationMs: number;
    size: number;
    offsetX: number;
    offsetY: number;
}
export interface DefeatAnimationSet {
    id: string;
    frames: DefeatAnimationFrame[];
    fallback?: string | null;
    loop?: boolean;
}
export declare function toSvgDataUri(svg: string): string;
export declare class AssetLoader {
    private readonly imageCache;
    private readonly listeners;
    private readonly integrityListeners;
    private pendingLoads;
    private readonly idleResolvers;
    private integritySummary;
    private integrityMode;
    private readonly integrityScenario;
    private atlas;
    private atlasEnabled;
    private atlasUrl;
    constructor(options?: AssetLoaderOptions);
    private resolveAtlasEnabled;
    private resolveScenario;
    private resolveIntegrityMode;
    private canVerifyDigests;
    getIntegritySummary(): AssetIntegritySummary | null;
    onIntegrityUpdate(listener: (summary: AssetIntegritySummary | null) => void): () => void;
    setAtlasEnabled(enabled: boolean): void;
    loadAtlas(atlasUrl: string, options?: Record<string, unknown>): Promise<void>;
    hasAtlasFrame(key: string): boolean;
    listAtlasKeys(): string[];
    drawFrame(ctx: CanvasRenderingContext2D, key: string, dx: number, dy: number, dw?: number, dh?: number): boolean;
    loadManifest(manifestUrl: string, options?: Record<string, unknown>): Promise<void>;
    loadImages(images: Record<string, string>, options?: Record<string, unknown>): Promise<void>;
    loadImage(key: string, url: string, options?: Record<string, unknown>): Promise<void>;
    applyDefeatAnimations(definitions?: unknown): void;
    getDefeatAnimation(tierId: string): DefeatAnimationSet | null;
    hasDefeatAnimation(tierId: string): boolean;
    listDefeatAnimations(): DefeatAnimationSet[];
    getImage(key: string): CanvasImageSource | null | undefined;
    onImageLoaded(listener: (key: string) => void): () => void;
    whenIdle(): Promise<void>;
    private loadImageElement;
    private createImageInstance;
    private notifyImageLoaded;
    private flushIdleResolvers;
    private resolveUrl;
}
