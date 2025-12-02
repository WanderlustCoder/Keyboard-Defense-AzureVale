export type AmbientProfile = "calm" | "rising" | "siege" | "dire";
export declare class SoundManager {
    private enabled;
    private initialized;
    private volume;
    private intensity;
    private ctx;
    private masterGain;
    private sounds;
    private ambientGain;
    private ambientSource;
    private ambientProfile;
    private ambientBuffers;
    constructor();
    ensureInitialized(): Promise<void>;
    play(key: string, detune?: number): void;
    setAmbientProfile(profile: AmbientProfile, options?: {
        volume?: number;
    }): void;
    stopAmbient(): void;
    setEnabled(enabled: boolean): void;
    isEnabled(): boolean;
    setVolume(volume: number): void;
    getVolume(): number;
    setIntensity(intensity: number): void;
    getIntensity(): number;
    private loadSounds;
    private loadAmbientBuffers;
    private createPad;
    private createTone;
    private createNoise;
}
//# sourceMappingURL=soundManager.d.ts.map