export type SoundKey = "projectile-arrow" | "projectile-arcane" | "projectile-flame" | "impact-hit" | "impact-breach" | "upgrade";
export declare class SoundManager {
    private readonly ctx;
    private readonly masterGain;
    private enabled;
    private readonly sounds;
    private initialized;
    private volume;
    private intensity;
    constructor();
    ensureInitialized(): Promise<void>;
    play(key: SoundKey, detune?: number): void;
    setEnabled(enabled: boolean): void;
    isEnabled(): boolean;
    setVolume(volume: number): void;
    getVolume(): number;
    setIntensity(intensity: number): void;
    getIntensity(): number;
    private loadSounds;
    private createTone;
    private createNoise;
}
