import { TurretTargetPriority, TurretTypeId } from "../core/types.js";
export declare const PLAYER_SETTINGS_STORAGE_KEY = "keyboard-defense:player-settings";
export declare const PLAYER_SETTINGS_VERSION = 11;
export declare const TURRET_PRESET_IDS: readonly ["preset-a", "preset-b", "preset-c"];
declare const ALLOWED_TURRET_PRESET_IDS: readonly ["preset-a", "preset-b", "preset-c"];
type MaybeStorage = Pick<Storage, "getItem" | "setItem" | "removeItem"> | null | undefined;
export type TurretTargetingPreferences = Record<string, TurretTargetPriority>;
export type TurretLoadoutPresetId = (typeof ALLOWED_TURRET_PRESET_IDS)[number];
export interface TurretLoadoutSlot {
    typeId: TurretTypeId;
    level: number;
    priority?: TurretTargetPriority;
}
export interface TurretLoadoutPreset {
    id: TurretLoadoutPresetId;
    slots: Record<string, TurretLoadoutSlot>;
    savedAt: string;
}
export type TurretLoadoutPresetMap = Partial<Record<TurretLoadoutPresetId, TurretLoadoutPreset>>;
export interface PlayerSettings {
    version: number;
    soundEnabled: boolean;
    soundVolume: number;
    diagnosticsVisible: boolean;
    reducedMotionEnabled: boolean;
    checkeredBackgroundEnabled: boolean;
    readableFontEnabled: boolean;
    dyslexiaFontEnabled: boolean;
    colorblindPaletteEnabled: boolean;
    audioIntensity: number;
    telemetryEnabled: boolean;
    crystalPulseEnabled: boolean;
    hudFontScale: number;
    turretTargeting: TurretTargetingPreferences;
    turretLoadoutPresets: TurretLoadoutPresetMap;
    hudPassivesCollapsed: boolean | null;
    hudGoldEventsCollapsed: boolean | null;
    optionsPassivesCollapsed: boolean | null;
    updatedAt: string;
}
export type PlayerSettingsPatch = Partial<Omit<PlayerSettings, "version" | "updatedAt">>;
export declare const defaultPlayerSettings: PlayerSettings;
export declare function createDefaultPlayerSettings(): PlayerSettings;
export declare function readPlayerSettings(storage: MaybeStorage): PlayerSettings;
export declare function writePlayerSettings(storage: MaybeStorage, settings: PlayerSettings): void;
export declare function clearPlayerSettings(storage: MaybeStorage): void;
export declare function withPatchedPlayerSettings(current: PlayerSettings, patch: PlayerSettingsPatch): PlayerSettings;
export {};
