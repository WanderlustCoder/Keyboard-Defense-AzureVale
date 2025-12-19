export const PLAYER_SETTINGS_STORAGE_KEY = "keyboard-defense:player-settings";
export const PLAYER_SETTINGS_VERSION = 33;
const DEFAULT_UPDATED_AT = "1970-01-01T00:00:00.000Z";
const HUD_FONT_SCALE_MIN = 0.85;
const HUD_FONT_SCALE_MAX = 1.3;
const HUD_ZOOM_MIN = 0.8;
const HUD_ZOOM_MAX = 1.2;
const HUD_ZOOM_DEFAULT = 1;
const HUD_LAYOUT_DEFAULT = "right";
export const VOICE_PACK_IDS = ["mentor-classic", "mentor-calm", "mentor-arcade"];
const DEFAULT_ACCESSIBILITY_PRESET = false;
const TUTORIAL_PACING_MIN = 0.75;
const TUTORIAL_PACING_MAX = 1.25;
const DEFAULT_TUTORIAL_PACING = 1;
const SOUND_VOLUME_MIN = 0;
const SOUND_VOLUME_MAX = 1;
const DEFAULT_SOUND_VOLUME = 0.8;
const AUDIO_INTENSITY_MIN = 0.5;
const AUDIO_INTENSITY_MAX = 1.5;
const DEFAULT_AUDIO_INTENSITY = 1;
const MUSIC_LEVEL_MIN = 0;
const MUSIC_LEVEL_MAX = 1;
const DEFAULT_MUSIC_LEVEL = 0.65;
const SCREEN_SHAKE_INTENSITY_MIN = 0;
const SCREEN_SHAKE_INTENSITY_MAX = 1.2;
const DEFAULT_SCREEN_SHAKE_INTENSITY = 0.65;
const CASTLE_SKINS = new Set(["classic", "dusk", "aurora", "ember"]);
const DEFAULT_CASTLE_SKIN = "classic";
const FOCUS_OUTLINE_PRESETS = new Set(["system", "contrast", "glow"]);
const DEFAULT_FOCUS_OUTLINE = "system";
const ACCESSIBILITY_SELF_TEST_DEFAULT = {
    lastRunAt: null,
    soundConfirmed: false,
    visualConfirmed: false,
    motionConfirmed: false
};
const DEFAULT_PRESET_SAVED_AT = "1970-01-01T00:00:00.000Z";
const MAX_TURRET_LEVEL = 10;
const TEXT_SIZE_MIN = 0.9;
const TEXT_SIZE_MAX = 1.1;
const VIRTUAL_KEYBOARD_LAYOUTS = new Set(["qwerty", "qwertz", "azerty"]);
const DEFAULT_VIRTUAL_KEYBOARD_LAYOUT = "qwerty";
export const TURRET_PRESET_IDS = ["preset-a", "preset-b", "preset-c"];
const ALLOWED_TURRET_PRESET_IDS = TURRET_PRESET_IDS;
const DIAGNOSTICS_SECTION_IDS = ["gold-events", "castle-passives", "turret-dps"];
const DEFEAT_ANIMATION_MODES = new Set(["auto", "sprite", "procedural"]);
const BASE_DEFAULT_SETTINGS = {
    version: PLAYER_SETTINGS_VERSION,
    soundEnabled: true,
    soundVolume: DEFAULT_SOUND_VOLUME,
    diagnosticsVisible: false,
    latencySparklineEnabled: true,
    reducedMotionEnabled: false,
    lowGraphicsEnabled: false,
    virtualKeyboardEnabled: false,
    virtualKeyboardLayout: DEFAULT_VIRTUAL_KEYBOARD_LAYOUT,
    hapticsEnabled: false,
    textSizeScale: 1,
    checkeredBackgroundEnabled: false,
    readableFontEnabled: false,
    dyslexiaFontEnabled: false,
    dyslexiaSpacingEnabled: false,
    reducedCognitiveLoadEnabled: false,
    audioNarrationEnabled: false,
    voicePackId: "mentor-classic",
    accessibilityPresetEnabled: DEFAULT_ACCESSIBILITY_PRESET,
    tutorialPacing: DEFAULT_TUTORIAL_PACING,
    largeSubtitlesEnabled: false,
    backgroundBrightness: 1,
    colorblindPaletteEnabled: false,
    focusOutlinePreset: DEFAULT_FOCUS_OUTLINE,
    audioIntensity: DEFAULT_AUDIO_INTENSITY,
    musicEnabled: true,
    musicLevel: DEFAULT_MUSIC_LEVEL,
    screenShakeEnabled: false,
    screenShakeIntensity: DEFAULT_SCREEN_SHAKE_INTENSITY,
    telemetryEnabled: false,
    eliteAffixesEnabled: true,
    crystalPulseEnabled: false,
    accessibilitySelfTest: { ...ACCESSIBILITY_SELF_TEST_DEFAULT },
    hudZoom: HUD_ZOOM_DEFAULT,
    hudLayout: HUD_LAYOUT_DEFAULT,
    castleSkin: DEFAULT_CASTLE_SKIN,
    hudFontScale: 1,
    defeatAnimationMode: "auto",
    turretTargeting: {},
    turretLoadoutPresets: Object.create(null),
    diagnosticsSections: Object.create(null),
    diagnosticsSectionsUpdatedAt: DEFAULT_UPDATED_AT,
    hudPassivesCollapsed: null,
    hudGoldEventsCollapsed: null,
    optionsPassivesCollapsed: null,
    lastDevicePixelRatio: null,
    lastHudLayout: null,
    updatedAt: DEFAULT_UPDATED_AT
};
export const defaultPlayerSettings = Object.freeze({
    ...BASE_DEFAULT_SETTINGS,
    turretTargeting: {},
    turretLoadoutPresets: Object.freeze({}),
    diagnosticsSections: Object.freeze({}),
    accessibilitySelfTest: Object.freeze({ ...ACCESSIBILITY_SELF_TEST_DEFAULT })
});
export function createDefaultPlayerSettings() {
    return {
        ...BASE_DEFAULT_SETTINGS,
        readableFontEnabled: false,
        dyslexiaFontEnabled: false,
        dyslexiaSpacingEnabled: false,
        backgroundBrightness: 1,
        colorblindPaletteEnabled: false,
        telemetryEnabled: false,
        eliteAffixesEnabled: true,
        crystalPulseEnabled: false,
        hudFontScale: 1,
        turretTargeting: {},
        turretLoadoutPresets: Object.create(null),
        diagnosticsSections: Object.create(null),
        diagnosticsSectionsUpdatedAt: DEFAULT_UPDATED_AT,
        accessibilitySelfTest: { ...ACCESSIBILITY_SELF_TEST_DEFAULT }
    };
}
export function readPlayerSettings(storage) {
    const fallback = createDefaultPlayerSettings();
    fallback.updatedAt = new Date().toISOString();
    const raw = safeGet(storage, PLAYER_SETTINGS_STORAGE_KEY);
    if (!raw) {
        return fallback;
    }
    try {
        const parsed = JSON.parse(raw);
        if (!parsed || typeof parsed !== "object") {
            return fallback;
        }
        if (parsed.version !== PLAYER_SETTINGS_VERSION) {
            return fallback;
        }
        const soundEnabled = typeof parsed.soundEnabled === "boolean" ? parsed.soundEnabled : fallback.soundEnabled;
        const soundVolume = typeof parsed.soundVolume === "number"
            ? normalizeSoundVolume(parsed.soundVolume)
            : fallback.soundVolume;
        const latencySparklineEnabled = typeof parsed.latencySparklineEnabled === "boolean"
            ? parsed.latencySparklineEnabled
            : fallback.latencySparklineEnabled;
        const diagnosticsVisible = typeof parsed.diagnosticsVisible === "boolean"
            ? parsed.diagnosticsVisible
            : fallback.diagnosticsVisible;
        const reducedMotionEnabled = typeof parsed.reducedMotionEnabled === "boolean"
            ? parsed.reducedMotionEnabled
            : fallback.reducedMotionEnabled;
        const lowGraphicsEnabled = typeof parsed.lowGraphicsEnabled === "boolean"
            ? parsed.lowGraphicsEnabled
            : fallback.lowGraphicsEnabled;
        const checkeredBackgroundEnabled = typeof parsed.checkeredBackgroundEnabled === "boolean"
            ? parsed.checkeredBackgroundEnabled
            : fallback.checkeredBackgroundEnabled;
        const virtualKeyboardEnabled = typeof parsed.virtualKeyboardEnabled === "boolean"
            ? parsed.virtualKeyboardEnabled
            : fallback.virtualKeyboardEnabled;
        const virtualKeyboardLayout = typeof parsed.virtualKeyboardLayout === "string"
            ? normalizeVirtualKeyboardLayout(parsed.virtualKeyboardLayout)
            : fallback.virtualKeyboardLayout;
        const readableFontEnabled = typeof parsed.readableFontEnabled === "boolean"
            ? parsed.readableFontEnabled
            : fallback.readableFontEnabled;
        const dyslexiaFontEnabled = typeof parsed.dyslexiaFontEnabled === "boolean"
            ? parsed.dyslexiaFontEnabled
            : fallback.dyslexiaFontEnabled;
        const dyslexiaSpacingEnabled = typeof parsed.dyslexiaSpacingEnabled === "boolean"
            ? parsed.dyslexiaSpacingEnabled
            : fallback.dyslexiaSpacingEnabled;
        const reducedCognitiveLoadEnabled = typeof parsed.reducedCognitiveLoadEnabled === "boolean"
            ? parsed.reducedCognitiveLoadEnabled
            : fallback.reducedCognitiveLoadEnabled;
        const audioNarrationEnabled = typeof parsed.audioNarrationEnabled === "boolean"
            ? parsed.audioNarrationEnabled
            : fallback.audioNarrationEnabled;
        const voicePackId = typeof parsed.voicePackId === "string"
            ? normalizeVoicePack(parsed.voicePackId)
            : fallback.voicePackId;
        const accessibilityPresetEnabled = typeof parsed.accessibilityPresetEnabled === "boolean"
            ? parsed.accessibilityPresetEnabled
            : fallback.accessibilityPresetEnabled;
        const largeSubtitlesEnabled = typeof parsed.largeSubtitlesEnabled === "boolean"
            ? parsed.largeSubtitlesEnabled
            : fallback.largeSubtitlesEnabled;
        const backgroundBrightness = typeof parsed.backgroundBrightness === "number"
            ? parsed.backgroundBrightness
            : fallback.backgroundBrightness;
        const colorblindPaletteEnabled = typeof parsed.colorblindPaletteEnabled === "boolean"
            ? parsed.colorblindPaletteEnabled
            : fallback.colorblindPaletteEnabled;
        const focusOutlinePreset = normalizeFocusOutlinePreset(parsed.focusOutlinePreset);
        const textSizeScale = typeof parsed.textSizeScale === "number"
            ? normalizeTextSizeScale(parsed.textSizeScale)
            : fallback.textSizeScale;
        const hapticsEnabled = typeof parsed.hapticsEnabled === "boolean"
            ? parsed.hapticsEnabled
            : fallback.hapticsEnabled;
        const defeatAnimationMode = normalizeDefeatAnimationMode(parsed.defeatAnimationMode);
        const audioIntensity = typeof parsed.audioIntensity === "number"
            ? normalizeAudioIntensity(parsed.audioIntensity)
            : fallback.audioIntensity;
        const tutorialPacing = typeof parsed.tutorialPacing === "number"
            ? normalizeTutorialPacing(parsed.tutorialPacing)
            : fallback.tutorialPacing;
        const musicEnabled = typeof parsed.musicEnabled === "boolean"
            ? parsed.musicEnabled
            : fallback.musicEnabled;
        const musicLevel = typeof parsed.musicLevel === "number"
            ? normalizeMusicLevel(parsed.musicLevel)
            : fallback.musicLevel;
        const screenShakeEnabled = typeof parsed.screenShakeEnabled === "boolean"
            ? parsed.screenShakeEnabled
            : fallback.screenShakeEnabled;
        const screenShakeIntensity = typeof parsed.screenShakeIntensity === "number"
            ? normalizeScreenShakeIntensity(parsed.screenShakeIntensity)
            : fallback.screenShakeIntensity;
        const telemetryEnabled = typeof parsed.telemetryEnabled === "boolean"
            ? parsed.telemetryEnabled
            : fallback.telemetryEnabled;
        const eliteAffixesEnabled = typeof parsed.eliteAffixesEnabled === "boolean"
            ? parsed.eliteAffixesEnabled
            : fallback.eliteAffixesEnabled;
        const crystalPulseEnabled = typeof parsed.crystalPulseEnabled === "boolean"
            ? parsed.crystalPulseEnabled
            : fallback.crystalPulseEnabled;
        const hudZoom = typeof parsed.hudZoom === "number"
            ? normalizeHudZoom(parsed.hudZoom)
            : fallback.hudZoom;
        const hudLayout = typeof parsed.hudLayout === "string" ? normalizeHudLayout(parsed.hudLayout) : fallback.hudLayout;
        const castleSkin = normalizeCastleSkin(parsed.castleSkin);
        const hudFontScale = typeof parsed.hudFontScale === "number"
            ? normalizeHudFontScale(parsed.hudFontScale)
            : fallback.hudFontScale;
        const turretTargeting = normalizeTargetingMap(parsed.turretTargeting);
        const turretLoadoutPresets = normalizeLoadoutPresets(parsed.turretLoadoutPresets);
        const hudPassivesCollapsed = parseCollapsePreference(parsed.hudPassivesCollapsed);
        const hudGoldEventsCollapsed = parseCollapsePreference(parsed.hudGoldEventsCollapsed);
        const optionsPassivesCollapsed = parseCollapsePreference(parsed.optionsPassivesCollapsed);
        const lastDevicePixelRatio = normalizeDevicePixelRatioPreference(parsed.lastDevicePixelRatio);
        const lastHudLayout = normalizeHudLayoutPreference(parsed.lastHudLayout);
        const diagnosticsSections = normalizeDiagnosticsSections(parsed.diagnosticsSections);
        const diagnosticsSectionsUpdatedAt = normalizeTimestamp(parsed.diagnosticsSectionsUpdatedAt ?? DEFAULT_UPDATED_AT);
        const accessibilitySelfTest = normalizeAccessibilitySelfTest(parsed.accessibilitySelfTest);
        const updatedAt = typeof parsed.updatedAt === "string" && parsed.updatedAt.length > 0
            ? parsed.updatedAt
            : fallback.updatedAt;
        return {
            version: PLAYER_SETTINGS_VERSION,
            soundEnabled,
            soundVolume,
            latencySparklineEnabled,
            diagnosticsVisible,
            reducedMotionEnabled,
            lowGraphicsEnabled,
            virtualKeyboardEnabled,
            virtualKeyboardLayout,
            hapticsEnabled,
            textSizeScale,
            checkeredBackgroundEnabled,
            readableFontEnabled,
            dyslexiaFontEnabled,
            dyslexiaSpacingEnabled,
            reducedCognitiveLoadEnabled,
            audioNarrationEnabled,
            voicePackId,
            accessibilityPresetEnabled,
            largeSubtitlesEnabled,
            backgroundBrightness,
            colorblindPaletteEnabled,
            focusOutlinePreset,
            audioIntensity,
            tutorialPacing,
            musicEnabled,
            musicLevel,
            screenShakeEnabled,
            screenShakeIntensity,
            telemetryEnabled,
            eliteAffixesEnabled,
            crystalPulseEnabled,
            accessibilitySelfTest,
            hudZoom,
            hudLayout,
            castleSkin,
            hudFontScale,
            defeatAnimationMode,
            turretTargeting,
            turretLoadoutPresets,
            diagnosticsSections,
            diagnosticsSectionsUpdatedAt,
            hudPassivesCollapsed,
            hudGoldEventsCollapsed,
            optionsPassivesCollapsed,
            lastDevicePixelRatio,
            lastHudLayout,
            updatedAt
        };
    }
    catch {
        return fallback;
    }
}
export function writePlayerSettings(storage, settings) {
    safeSet(storage, PLAYER_SETTINGS_STORAGE_KEY, JSON.stringify(settings));
}
export function clearPlayerSettings(storage) {
    safeRemove(storage, PLAYER_SETTINGS_STORAGE_KEY);
}
export function withPatchedPlayerSettings(current, patch) {
    return {
        version: PLAYER_SETTINGS_VERSION,
        soundEnabled: typeof patch.soundEnabled === "boolean" ? patch.soundEnabled : current.soundEnabled,
        soundVolume: typeof patch.soundVolume === "number"
            ? normalizeSoundVolume(patch.soundVolume)
            : current.soundVolume,
        musicEnabled: typeof patch.musicEnabled === "boolean"
            ? patch.musicEnabled
            : current.musicEnabled,
        musicLevel: typeof patch.musicLevel === "number"
            ? normalizeMusicLevel(patch.musicLevel)
            : current.musicLevel,
        latencySparklineEnabled: typeof patch.latencySparklineEnabled === "boolean"
            ? patch.latencySparklineEnabled
            : current.latencySparklineEnabled,
        diagnosticsVisible: typeof patch.diagnosticsVisible === "boolean"
            ? patch.diagnosticsVisible
            : current.diagnosticsVisible,
        reducedMotionEnabled: typeof patch.reducedMotionEnabled === "boolean"
            ? patch.reducedMotionEnabled
            : current.reducedMotionEnabled,
        lowGraphicsEnabled: typeof patch.lowGraphicsEnabled === "boolean"
            ? patch.lowGraphicsEnabled
            : current.lowGraphicsEnabled,
        hapticsEnabled: typeof patch.hapticsEnabled === "boolean"
            ? patch.hapticsEnabled
            : current.hapticsEnabled,
        textSizeScale: typeof patch.textSizeScale === "number"
            ? normalizeTextSizeScale(patch.textSizeScale)
            : current.textSizeScale,
        virtualKeyboardEnabled: typeof patch.virtualKeyboardEnabled === "boolean"
            ? patch.virtualKeyboardEnabled
            : current.virtualKeyboardEnabled,
        virtualKeyboardLayout: typeof patch.virtualKeyboardLayout === "string"
            ? normalizeVirtualKeyboardLayout(patch.virtualKeyboardLayout)
            : current.virtualKeyboardLayout ?? DEFAULT_VIRTUAL_KEYBOARD_LAYOUT,
        checkeredBackgroundEnabled: typeof patch.checkeredBackgroundEnabled === "boolean"
            ? patch.checkeredBackgroundEnabled
            : current.checkeredBackgroundEnabled,
        readableFontEnabled: typeof patch.readableFontEnabled === "boolean"
            ? patch.readableFontEnabled
            : current.readableFontEnabled,
        dyslexiaFontEnabled: typeof patch.dyslexiaFontEnabled === "boolean"
            ? patch.dyslexiaFontEnabled
            : current.dyslexiaFontEnabled,
        dyslexiaSpacingEnabled: typeof patch.dyslexiaSpacingEnabled === "boolean"
            ? patch.dyslexiaSpacingEnabled
            : current.dyslexiaSpacingEnabled,
        reducedCognitiveLoadEnabled: typeof patch.reducedCognitiveLoadEnabled === "boolean"
            ? patch.reducedCognitiveLoadEnabled
            : current.reducedCognitiveLoadEnabled,
        audioNarrationEnabled: typeof patch.audioNarrationEnabled === "boolean"
            ? patch.audioNarrationEnabled
            : current.audioNarrationEnabled,
        voicePackId: typeof patch.voicePackId === "string"
            ? normalizeVoicePack(patch.voicePackId)
            : current.voicePackId,
        accessibilityPresetEnabled: typeof patch.accessibilityPresetEnabled === "boolean"
            ? patch.accessibilityPresetEnabled
            : current.accessibilityPresetEnabled,
        largeSubtitlesEnabled: typeof patch.largeSubtitlesEnabled === "boolean"
            ? patch.largeSubtitlesEnabled
            : current.largeSubtitlesEnabled,
        backgroundBrightness: typeof patch.backgroundBrightness === "number"
            ? patch.backgroundBrightness
            : current.backgroundBrightness,
        colorblindPaletteEnabled: typeof patch.colorblindPaletteEnabled === "boolean"
            ? patch.colorblindPaletteEnabled
            : current.colorblindPaletteEnabled,
        focusOutlinePreset: normalizeFocusOutlinePreset(patch.focusOutlinePreset !== undefined
            ? patch.focusOutlinePreset
            : current.focusOutlinePreset ?? DEFAULT_FOCUS_OUTLINE),
        audioIntensity: typeof patch.audioIntensity === "number"
            ? normalizeAudioIntensity(patch.audioIntensity)
            : current.audioIntensity,
        tutorialPacing: typeof patch.tutorialPacing === "number"
            ? normalizeTutorialPacing(patch.tutorialPacing)
            : current.tutorialPacing,
        screenShakeEnabled: typeof patch.screenShakeEnabled === "boolean"
            ? patch.screenShakeEnabled
            : current.screenShakeEnabled,
        screenShakeIntensity: typeof patch.screenShakeIntensity === "number"
            ? normalizeScreenShakeIntensity(patch.screenShakeIntensity)
            : current.screenShakeIntensity,
        telemetryEnabled: typeof patch.telemetryEnabled === "boolean"
            ? patch.telemetryEnabled
            : current.telemetryEnabled,
        eliteAffixesEnabled: typeof patch.eliteAffixesEnabled === "boolean"
            ? patch.eliteAffixesEnabled
            : current.eliteAffixesEnabled,
        crystalPulseEnabled: typeof patch.crystalPulseEnabled === "boolean"
            ? patch.crystalPulseEnabled
            : current.crystalPulseEnabled,
        hudZoom: typeof patch.hudZoom === "number"
            ? normalizeHudZoom(patch.hudZoom)
            : current.hudZoom,
        hudLayout: typeof patch.hudLayout === "string"
            ? normalizeHudLayout(patch.hudLayout)
            : current.hudLayout,
        castleSkin: typeof patch.castleSkin === "string"
            ? normalizeCastleSkin(patch.castleSkin)
            : current.castleSkin ?? DEFAULT_CASTLE_SKIN,
        hudFontScale: typeof patch.hudFontScale === "number"
            ? normalizeHudFontScale(patch.hudFontScale)
            : current.hudFontScale,
        defeatAnimationMode: typeof patch.defeatAnimationMode === "string"
            ? normalizeDefeatAnimationMode(patch.defeatAnimationMode)
            : current.defeatAnimationMode,
        accessibilitySelfTest: patch.accessibilitySelfTest !== undefined
            ? normalizeAccessibilitySelfTest({
                ...current.accessibilitySelfTest,
                ...patch.accessibilitySelfTest
            })
            : normalizeAccessibilitySelfTest(current.accessibilitySelfTest),
        turretTargeting: patch.turretTargeting !== undefined
            ? normalizeTargetingMap(patch.turretTargeting)
            : { ...current.turretTargeting },
        turretLoadoutPresets: patch.turretLoadoutPresets !== undefined
            ? normalizeLoadoutPresets(patch.turretLoadoutPresets)
            : cloneLoadoutPresets(current.turretLoadoutPresets),
        diagnosticsSections: patch.diagnosticsSections !== undefined
            ? cloneDiagnosticsSections(normalizeDiagnosticsSections(patch.diagnosticsSections))
            : cloneDiagnosticsSections(current.diagnosticsSections ?? {}),
        diagnosticsSectionsUpdatedAt: typeof patch.diagnosticsSectionsUpdatedAt === "string"
            ? normalizeTimestamp(patch.diagnosticsSectionsUpdatedAt)
            : current.diagnosticsSectionsUpdatedAt ?? DEFAULT_UPDATED_AT,
        hudPassivesCollapsed: mergeCollapsePreference(patch.hudPassivesCollapsed, current.hudPassivesCollapsed),
        hudGoldEventsCollapsed: mergeCollapsePreference(patch.hudGoldEventsCollapsed, current.hudGoldEventsCollapsed),
        optionsPassivesCollapsed: mergeCollapsePreference(patch.optionsPassivesCollapsed, current.optionsPassivesCollapsed),
        lastDevicePixelRatio: patch.lastDevicePixelRatio !== undefined
            ? normalizeDevicePixelRatioPreference(patch.lastDevicePixelRatio)
            : current.lastDevicePixelRatio ?? null,
        lastHudLayout: patch.lastHudLayout !== undefined
            ? normalizeHudLayoutPreference(patch.lastHudLayout)
            : current.lastHudLayout ?? null,
        updatedAt: new Date().toISOString()
    };
}
function safeGet(storage, key) {
    if (!storage)
        return null;
    try {
        return storage.getItem(key);
    }
    catch {
        return null;
    }
}
function safeSet(storage, key, value) {
    if (!storage)
        return;
    try {
        storage.setItem(key, value);
    }
    catch {
        /* ignore */
    }
}
function safeRemove(storage, key) {
    if (!storage)
        return;
    try {
        storage.removeItem(key);
    }
    catch {
        /* ignore */
    }
}
function normalizeTargetingMap(value) {
    if (!value || typeof value !== "object") {
        return {};
    }
    const entries = Object.entries(value);
    const next = {};
    for (const [slotId, rawPriority] of entries) {
        if (typeof rawPriority !== "string")
            continue;
        if (isValidPriority(rawPriority)) {
            next[slotId] = rawPriority;
        }
    }
    return next;
}
function isValidPriority(value) {
    return value === "first" || value === "strongest" || value === "weakest";
}
function normalizeLoadoutPresets(value) {
    if (!value || typeof value !== "object") {
        return Object.create(null);
    }
    const entries = Object.entries(value);
    const next = Object.create(null);
    for (const [rawId, rawPreset] of entries) {
        if (!isAllowedPresetId(rawId) || !rawPreset || typeof rawPreset !== "object") {
            continue;
        }
        const slots = normalizeLoadoutSlots(rawPreset.slots);
        const savedAt = normalizeTimestamp(rawPreset.savedAt ?? DEFAULT_PRESET_SAVED_AT);
        next[rawId] = {
            id: rawId,
            slots,
            savedAt
        };
    }
    return next;
}
function normalizeLoadoutSlots(value) {
    if (!value || typeof value !== "object") {
        return {};
    }
    const entries = Object.entries(value);
    const slots = {};
    for (const [slotId, rawSlot] of entries) {
        if (!isValidSlotId(slotId) || !rawSlot || typeof rawSlot !== "object") {
            continue;
        }
        const slotRecord = rawSlot;
        if (!isValidTurretTypeId(slotRecord.typeId) || !isValidTurretLevel(slotRecord.level)) {
            continue;
        }
        const priority = normalizePriority(slotRecord.priority);
        slots[slotId] = {
            typeId: slotRecord.typeId,
            level: Math.trunc(slotRecord.level),
            ...(priority ? { priority } : {})
        };
    }
    return slots;
}
function normalizePriority(value) {
    if (typeof value !== "string") {
        return undefined;
    }
    if (value === "first" || value === "strongest" || value === "weakest") {
        return value;
    }
    return undefined;
}
function normalizeTimestamp(value) {
    if (typeof value !== "string" || value.length === 0) {
        return DEFAULT_PRESET_SAVED_AT;
    }
    return value;
}
function isAllowedPresetId(value) {
    return ALLOWED_TURRET_PRESET_IDS.includes(value);
}
function isValidSlotId(value) {
    return typeof value === "string" && /^slot-\d+$/.test(value);
}
function isValidTurretTypeId(value) {
    return typeof value === "string" && value.length > 0;
}
function isValidTurretLevel(value) {
    return (typeof value === "number" &&
        Number.isFinite(value) &&
        Number.isInteger(value) &&
        value > 0 &&
        value <= MAX_TURRET_LEVEL);
}
function cloneLoadoutPresets(map) {
    const cloned = Object.create(null);
    for (const presetId of Object.keys(map)) {
        const preset = map[presetId];
        if (!preset)
            continue;
        cloned[presetId] = {
            id: preset.id,
            savedAt: preset.savedAt,
            slots: cloneLoadoutSlots(preset.slots)
        };
    }
    return cloned;
}
function cloneLoadoutSlots(slots) {
    const cloned = {};
    for (const [slotId, slot] of Object.entries(slots)) {
        cloned[slotId] = {
            typeId: slot.typeId,
            level: slot.level,
            ...(slot.priority ? { priority: slot.priority } : {})
        };
    }
    return cloned;
}
function normalizeCastleSkin(value) {
    if (typeof value !== "string") {
        return DEFAULT_CASTLE_SKIN;
    }
    const normalized = value.toLowerCase();
    return CASTLE_SKINS.has(normalized) ? normalized : DEFAULT_CASTLE_SKIN;
}
function normalizeHudZoom(value) {
    if (typeof value !== "number" || !Number.isFinite(value)) {
        return HUD_ZOOM_DEFAULT;
    }
    const clamped = Math.min(HUD_ZOOM_MAX, Math.max(HUD_ZOOM_MIN, value));
    return Math.round(clamped * 100) / 100;
}
function normalizeTutorialPacing(value) {
    if (typeof value !== "number" || !Number.isFinite(value)) {
        return DEFAULT_TUTORIAL_PACING;
    }
    const clamped = Math.min(TUTORIAL_PACING_MAX, Math.max(TUTORIAL_PACING_MIN, value));
    return Math.round(clamped * 100) / 100;
}
function normalizeHudLayout(value) {
    if (value === "left") return "left";
    return HUD_LAYOUT_DEFAULT;
}
function normalizeVirtualKeyboardLayout(value) {
    if (typeof value !== "string") {
        return DEFAULT_VIRTUAL_KEYBOARD_LAYOUT;
    }
    const normalized = value.toLowerCase();
    return VIRTUAL_KEYBOARD_LAYOUTS.has(normalized)
        ? normalized
        : DEFAULT_VIRTUAL_KEYBOARD_LAYOUT;
}
function normalizeHudFontScale(value) {
    if (typeof value !== "number" || !Number.isFinite(value)) {
        return 1;
    }
    const clamped = Math.min(HUD_FONT_SCALE_MAX, Math.max(HUD_FONT_SCALE_MIN, value));
    return Math.round(clamped * 100) / 100;
}
function normalizeDefeatAnimationMode(value) {
    if (typeof value !== "string") {
        return "auto";
    }
    const normalized = value.toLowerCase();
    return DEFEAT_ANIMATION_MODES.has(normalized) ? normalized : "auto";
}
function parseCollapsePreference(value) {
    if (typeof value === "boolean")
        return value;
    if (value === null)
        return null;
    return null;
}
function mergeCollapsePreference(patchValue, currentValue) {
    if (typeof patchValue === "boolean" || patchValue === null) {
        return patchValue;
    }
    return currentValue ?? null;
}
function normalizeDiagnosticsSections(value) {
    if (!value || typeof value !== "object") {
        return Object.create(null);
    }
    const normalized = Object.create(null);
    for (const sectionId of DIAGNOSTICS_SECTION_IDS) {
        if (typeof value[sectionId] === "boolean") {
            normalized[sectionId] = value[sectionId];
        }
    }
    return normalized;
}
function cloneDiagnosticsSections(value) {
    const clone = Object.create(null);
    if (!value || typeof value !== "object") {
        return clone;
    }
    for (const sectionId of DIAGNOSTICS_SECTION_IDS) {
        if (typeof value[sectionId] === "boolean") {
            clone[sectionId] = value[sectionId];
        }
    }
    return clone;
}
function normalizeDevicePixelRatioPreference(value) {
    if (value === null) {
        return null;
    }
    if (typeof value !== "number" || !Number.isFinite(value) || value <= 0) {
        return null;
    }
    return Math.round(value * 100) / 100;
}
function normalizeHudLayoutPreference(value) {
    if (value === null) {
        return null;
    }
    if (value === "stacked" || value === "condensed") {
        return value;
    }
    return null;
}
function normalizeFocusOutlinePreset(value) {
    if (typeof value !== "string") {
        return DEFAULT_FOCUS_OUTLINE;
    }
    const normalized = value.trim().toLowerCase();
    return FOCUS_OUTLINE_PRESETS.has(normalized) ? normalized : DEFAULT_FOCUS_OUTLINE;
}
function normalizeTextSizeScale(value) {
    if (typeof value !== "number" || !Number.isFinite(value)) {
        return 1;
    }
    const clamped = Math.min(TEXT_SIZE_MAX, Math.max(TEXT_SIZE_MIN, value));
    return Math.round(clamped * 100) / 100;
}
function normalizeSoundVolume(value) {
    if (typeof value !== "number" || !Number.isFinite(value)) {
        return DEFAULT_SOUND_VOLUME;
    }
    const clamped = Math.min(SOUND_VOLUME_MAX, Math.max(SOUND_VOLUME_MIN, value));
    return Math.round(clamped * 100) / 100;
}
function normalizeAudioIntensity(value) {
    if (typeof value !== "number" || !Number.isFinite(value)) {
        return DEFAULT_AUDIO_INTENSITY;
    }
    const clamped = Math.min(AUDIO_INTENSITY_MAX, Math.max(AUDIO_INTENSITY_MIN, value));
    return Math.round(clamped * 100) / 100;
}
function normalizeVoicePack(value) {
    if (typeof value !== "string") return "mentor-classic";
    const normalized = value.toLowerCase();
    if (normalized === "mentor-calm" || normalized === "mentor-arcade") {
        return normalized;
    }
    return "mentor-classic";
}
function normalizeMusicLevel(value) {
    if (typeof value !== "number" || !Number.isFinite(value)) {
        return DEFAULT_MUSIC_LEVEL;
    }
    const clamped = Math.min(MUSIC_LEVEL_MAX, Math.max(MUSIC_LEVEL_MIN, value));
    return Math.round(clamped * 100) / 100;
}
function normalizeScreenShakeIntensity(value) {
    if (typeof value !== "number" || !Number.isFinite(value)) {
        return DEFAULT_SCREEN_SHAKE_INTENSITY;
    }
    const clamped = Math.min(SCREEN_SHAKE_INTENSITY_MAX, Math.max(SCREEN_SHAKE_INTENSITY_MIN, value));
    return Math.round(clamped * 100) / 100;
}
function normalizeAccessibilitySelfTest(value) {
    const lastRunAt = typeof (value === null || value === void 0 ? void 0 : value.lastRunAt) === "string" && value.lastRunAt.length > 0
        ? value.lastRunAt
        : null;
    return {
        lastRunAt,
        soundConfirmed: typeof (value === null || value === void 0 ? void 0 : value.soundConfirmed) === "boolean"
            ? value.soundConfirmed
            : ACCESSIBILITY_SELF_TEST_DEFAULT.soundConfirmed,
        visualConfirmed: typeof (value === null || value === void 0 ? void 0 : value.visualConfirmed) === "boolean"
            ? value.visualConfirmed
            : ACCESSIBILITY_SELF_TEST_DEFAULT.visualConfirmed,
        motionConfirmed: typeof (value === null || value === void 0 ? void 0 : value.motionConfirmed) === "boolean"
            ? value.motionConfirmed
            : ACCESSIBILITY_SELF_TEST_DEFAULT.motionConfirmed
    };
}
