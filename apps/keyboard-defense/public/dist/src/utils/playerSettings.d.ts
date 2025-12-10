import { TurretTargetPriority, TurretTypeId } from "../core/types.js";
export declare const PLAYER_SETTINGS_STORAGE_KEY = "keyboard-defense:player-settings";
export declare const PLAYER_SETTINGS_VERSION = 28;
export declare const TURRET_PRESET_IDS: readonly ["preset-a", "preset-b", "preset-c"];
declare const ALLOWED_TURRET_PRESET_IDS: readonly ["preset-a", "preset-b", "preset-c"];
export type DiagnosticsSectionId = "gold-events" | "castle-passives" | "turret-dps";
export type CastleSkinId = "classic" | "dusk" | "aurora" | "ember";
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
export type DiagnosticsSectionsPreferenceMap = Partial<Record<DiagnosticsSectionId, boolean>>;
export interface AccessibilitySelfTestState {
    lastRunAt: string | null;
    soundConfirmed: boolean;
    visualConfirmed: boolean;
    motionConfirmed: boolean;
}
export interface PlayerSettings {
    version: number;
    soundEnabled: boolean;
    soundVolume: number;
    latencySparklineEnabled: boolean;
    diagnosticsVisible: boolean;
    reducedMotionEnabled: boolean;
    lowGraphicsEnabled: boolean;
    virtualKeyboardEnabled: boolean;
    hapticsEnabled: boolean;
    textSizeScale: number;
    checkeredBackgroundEnabled: boolean;
    readableFontEnabled: boolean;
    dyslexiaFontEnabled: boolean;
    dyslexiaSpacingEnabled: boolean;
    reducedCognitiveLoadEnabled: boolean;
    backgroundBrightness: number;
    colorblindPaletteEnabled: boolean;
    audioIntensity: number;
    musicEnabled: boolean;
    musicLevel: number;
    screenShakeEnabled: boolean;
    screenShakeIntensity: number;
    telemetryEnabled: boolean;
    eliteAffixesEnabled: boolean;
    crystalPulseEnabled: boolean;
    accessibilitySelfTest: AccessibilitySelfTestState;
    hudZoom: number;
    hudLayout: "left" | "right";
    castleSkin: CastleSkinId;
    hudFontScale: number;
    defeatAnimationMode: "auto" | "sprite" | "procedural";
    turretTargeting: TurretTargetingPreferences;
    turretLoadoutPresets: TurretLoadoutPresetMap;
    diagnosticsSections: DiagnosticsSectionsPreferenceMap;
    diagnosticsSectionsUpdatedAt: string;
    hudPassivesCollapsed: boolean | null;
    hudGoldEventsCollapsed: boolean | null;
    optionsPassivesCollapsed: boolean | null;
    lastDevicePixelRatio: number | null;
    lastHudLayout: "stacked" | "condensed" | null;
    updatedAt: string;
}
export type PlayerSettingsPatch = Partial<
  Omit<PlayerSettings, "version" | "updatedAt" | "accessibilitySelfTest">
> & {
    accessibilitySelfTest?: Partial<AccessibilitySelfTestState>;
};
export declare const defaultPlayerSettings: PlayerSettings;
export declare function createDefaultPlayerSettings(): PlayerSettings;
export declare function readPlayerSettings(storage: MaybeStorage): PlayerSettings;
export declare function writePlayerSettings(storage: MaybeStorage, settings: PlayerSettings): void;
export declare function clearPlayerSettings(storage: MaybeStorage): void;
export declare function withPatchedPlayerSettings(current: PlayerSettings, patch: PlayerSettingsPatch): PlayerSettings;
export {};
