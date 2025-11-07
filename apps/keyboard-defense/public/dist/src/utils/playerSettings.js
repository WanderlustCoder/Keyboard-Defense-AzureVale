export const PLAYER_SETTINGS_STORAGE_KEY = "keyboard-defense:player-settings";
export const PLAYER_SETTINGS_VERSION = 12;
const DEFAULT_UPDATED_AT = "1970-01-01T00:00:00.000Z";
const HUD_FONT_SCALE_MIN = 0.85;
const HUD_FONT_SCALE_MAX = 1.3;
const SOUND_VOLUME_MIN = 0;
const SOUND_VOLUME_MAX = 1;
const DEFAULT_SOUND_VOLUME = 0.8;
const AUDIO_INTENSITY_MIN = 0.5;
const AUDIO_INTENSITY_MAX = 1.5;
const DEFAULT_AUDIO_INTENSITY = 1;
const DEFAULT_PRESET_SAVED_AT = "1970-01-01T00:00:00.000Z";
const MAX_TURRET_LEVEL = 10;
export const TURRET_PRESET_IDS = ["preset-a", "preset-b", "preset-c"];
const ALLOWED_TURRET_PRESET_IDS = TURRET_PRESET_IDS;
const BASE_DEFAULT_SETTINGS = {
    version: PLAYER_SETTINGS_VERSION,
    soundEnabled: true,
    soundVolume: DEFAULT_SOUND_VOLUME,
    diagnosticsVisible: false,
    reducedMotionEnabled: false,
    checkeredBackgroundEnabled: false,
    readableFontEnabled: false,
    dyslexiaFontEnabled: false,
    colorblindPaletteEnabled: false,
    audioIntensity: DEFAULT_AUDIO_INTENSITY,
    telemetryEnabled: false,
    crystalPulseEnabled: false,
    hudFontScale: 1,
    turretTargeting: {},
    turretLoadoutPresets: Object.create(null),
    hudPassivesCollapsed: null,
    hudGoldEventsCollapsed: null,
    optionsPassivesCollapsed: null,
    updatedAt: DEFAULT_UPDATED_AT
};
export const defaultPlayerSettings = Object.freeze({
    ...BASE_DEFAULT_SETTINGS,
    turretTargeting: {},
    turretLoadoutPresets: Object.freeze({})
});
export function createDefaultPlayerSettings() {
    return {
        ...BASE_DEFAULT_SETTINGS,
        readableFontEnabled: false,
        dyslexiaFontEnabled: false,
        colorblindPaletteEnabled: false,
        telemetryEnabled: false,
        crystalPulseEnabled: false,
        hudFontScale: 1,
        turretTargeting: {},
        turretLoadoutPresets: Object.create(null)
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
        const diagnosticsVisible = typeof parsed.diagnosticsVisible === "boolean"
            ? parsed.diagnosticsVisible
            : fallback.diagnosticsVisible;
        const reducedMotionEnabled = typeof parsed.reducedMotionEnabled === "boolean"
            ? parsed.reducedMotionEnabled
            : fallback.reducedMotionEnabled;
        const checkeredBackgroundEnabled = typeof parsed.checkeredBackgroundEnabled === "boolean"
            ? parsed.checkeredBackgroundEnabled
            : fallback.checkeredBackgroundEnabled;
        const readableFontEnabled = typeof parsed.readableFontEnabled === "boolean"
            ? parsed.readableFontEnabled
            : fallback.readableFontEnabled;
        const dyslexiaFontEnabled = typeof parsed.dyslexiaFontEnabled === "boolean"
            ? parsed.dyslexiaFontEnabled
            : fallback.dyslexiaFontEnabled;
        const colorblindPaletteEnabled = typeof parsed.colorblindPaletteEnabled === "boolean"
            ? parsed.colorblindPaletteEnabled
            : fallback.colorblindPaletteEnabled;
        const audioIntensity = typeof parsed.audioIntensity === "number"
            ? normalizeAudioIntensity(parsed.audioIntensity)
            : fallback.audioIntensity;
        const telemetryEnabled = typeof parsed.telemetryEnabled === "boolean"
            ? parsed.telemetryEnabled
            : fallback.telemetryEnabled;
        const crystalPulseEnabled = typeof parsed.crystalPulseEnabled === "boolean"
            ? parsed.crystalPulseEnabled
            : fallback.crystalPulseEnabled;
        const hudFontScale = typeof parsed.hudFontScale === "number"
            ? normalizeHudFontScale(parsed.hudFontScale)
            : fallback.hudFontScale;
        const turretTargeting = normalizeTargetingMap(parsed.turretTargeting);
        const turretLoadoutPresets = normalizeLoadoutPresets(parsed.turretLoadoutPresets);
        const hudPassivesCollapsed = parseCollapsePreference(parsed.hudPassivesCollapsed);
        const hudGoldEventsCollapsed = parseCollapsePreference(parsed.hudGoldEventsCollapsed);
        const optionsPassivesCollapsed = parseCollapsePreference(parsed.optionsPassivesCollapsed);
        const updatedAt = typeof parsed.updatedAt === "string" && parsed.updatedAt.length > 0
            ? parsed.updatedAt
            : fallback.updatedAt;
        return {
            version: PLAYER_SETTINGS_VERSION,
            soundEnabled,
            soundVolume,
            diagnosticsVisible,
            reducedMotionEnabled,
            checkeredBackgroundEnabled,
            readableFontEnabled,
            dyslexiaFontEnabled,
            colorblindPaletteEnabled,
            audioIntensity,
            telemetryEnabled,
            crystalPulseEnabled,
            hudFontScale,
            turretTargeting,
            turretLoadoutPresets,
            hudPassivesCollapsed,
            hudGoldEventsCollapsed,
            optionsPassivesCollapsed,
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
        diagnosticsVisible: typeof patch.diagnosticsVisible === "boolean"
            ? patch.diagnosticsVisible
            : current.diagnosticsVisible,
        reducedMotionEnabled: typeof patch.reducedMotionEnabled === "boolean"
            ? patch.reducedMotionEnabled
            : current.reducedMotionEnabled,
        checkeredBackgroundEnabled: typeof patch.checkeredBackgroundEnabled === "boolean"
            ? patch.checkeredBackgroundEnabled
            : current.checkeredBackgroundEnabled,
        readableFontEnabled: typeof patch.readableFontEnabled === "boolean"
            ? patch.readableFontEnabled
            : current.readableFontEnabled,
        dyslexiaFontEnabled: typeof patch.dyslexiaFontEnabled === "boolean"
            ? patch.dyslexiaFontEnabled
            : current.dyslexiaFontEnabled,
        colorblindPaletteEnabled: typeof patch.colorblindPaletteEnabled === "boolean"
            ? patch.colorblindPaletteEnabled
            : current.colorblindPaletteEnabled,
        audioIntensity: typeof patch.audioIntensity === "number"
            ? normalizeAudioIntensity(patch.audioIntensity)
            : current.audioIntensity,
        telemetryEnabled: typeof patch.telemetryEnabled === "boolean"
            ? patch.telemetryEnabled
            : current.telemetryEnabled,
        crystalPulseEnabled: typeof patch.crystalPulseEnabled === "boolean"
            ? patch.crystalPulseEnabled
            : current.crystalPulseEnabled,
        hudFontScale: typeof patch.hudFontScale === "number"
            ? normalizeHudFontScale(patch.hudFontScale)
            : current.hudFontScale,
        turretTargeting: patch.turretTargeting !== undefined
            ? normalizeTargetingMap(patch.turretTargeting)
            : { ...current.turretTargeting },
        turretLoadoutPresets: patch.turretLoadoutPresets !== undefined
            ? normalizeLoadoutPresets(patch.turretLoadoutPresets)
            : cloneLoadoutPresets(current.turretLoadoutPresets),
        hudPassivesCollapsed: mergeCollapsePreference(patch.hudPassivesCollapsed, current.hudPassivesCollapsed),
        hudGoldEventsCollapsed: mergeCollapsePreference(patch.hudGoldEventsCollapsed, current.hudGoldEventsCollapsed),
        optionsPassivesCollapsed: mergeCollapsePreference(patch.optionsPassivesCollapsed, current.optionsPassivesCollapsed),
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
function normalizeHudFontScale(value) {
    if (typeof value !== "number" || !Number.isFinite(value)) {
        return 1;
    }
    const clamped = Math.min(HUD_FONT_SCALE_MAX, Math.max(HUD_FONT_SCALE_MIN, value));
    return Math.round(clamped * 100) / 100;
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
