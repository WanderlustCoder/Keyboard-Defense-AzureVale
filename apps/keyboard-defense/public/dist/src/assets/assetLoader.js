const INTEGRITY_MODES = new Set(["soft", "strict", "off"]);
const MIN_DEFEAT_FRAME_DURATION_MS = 16;
const DEFAULT_DEFEAT_FRAME_DURATION_MS = 90;
const DEFAULT_DEFEAT_FRAME_SIZE = 96;
function toBase64(buffer) {
    if (typeof Buffer !== "undefined") {
        return Buffer.from(buffer).toString("base64");
    }
    const bytes = new Uint8Array(buffer);
    let binary = "";
    for (const byte of bytes) {
        binary += String.fromCharCode(byte);
    }
    return typeof btoa === "function" ? btoa(binary) : "";
}
function nowMs() {
    if (typeof performance !== "undefined" && typeof performance.now === "function") {
        return performance.now();
    }
    return Date.now();
}
function normalizeDigest(value) {
    if (typeof value !== "string") {
        return null;
    }
    const trimmed = value.trim();
    return trimmed.length > 0 ? trimmed : null;
}
function relativePath(url, baseUrl) {
    try {
        const base = new URL(baseUrl ?? (typeof window !== "undefined" ? window.location.href : "http://localhost"));
        const resolved = new URL(url, base);
        if (base.origin === resolved.origin) {
            return resolved.pathname.replace(/^\//, "");
        }
        return resolved.href;
    }
    catch {
        return url;
    }
}
export function toSvgDataUri(svg) {
    const sanitized = svg.replace(/\s*\n\s*/g, " ").trim();
    return `data:image/svg+xml;charset=utf-8,${encodeURIComponent(sanitized)}`;
}
export class AssetLoader {
    constructor(options = {}) {
        this.imageCache = new Map();
        this.listeners = new Set();
        this.integrityListeners = new Set();
        this.pendingLoads = 0;
        this.idleResolvers = [];
        this.integritySummary = null;
        this.integrityTracker = null;
        this.atlas = null;
        this.atlasEnabled = this.resolveAtlasEnabled(options.useAtlas);
        this.atlasUrl = typeof options.atlasUrl === "string" && options.atlasUrl.trim().length > 0
            ? options.atlasUrl.trim()
            : null;
        this.integrityMode = this.resolveIntegrityMode(options.integrityMode);
        this.integrityScenario = this.resolveScenario(options.scenario);
        this.defeatAnimationSets = new Map();
        this.defeatAnimationMatches = new Map();
        this.defaultDefeatAnimationId = null;
    }
    resolveScenario(explicit) {
        if (typeof explicit === "string" && explicit.trim().length > 0) {
            return explicit.trim();
        }
        if (typeof document !== "undefined" && document.body?.dataset?.assetIntegrityScenario) {
            return document.body.dataset.assetIntegrityScenario;
        }
        if (typeof window !== "undefined" && typeof window.ASSET_INTEGRITY_SCENARIO === "string") {
            return window.ASSET_INTEGRITY_SCENARIO;
        }
        if (typeof window !== "undefined" && window.location) {
            return window.location.pathname || "runtime";
        }
        return "runtime";
    }
    resolveAtlasEnabled(explicit) {
        if (typeof explicit === "boolean") {
            return explicit;
        }
        if (typeof document !== "undefined" && document.body?.dataset?.assetAtlasEnabled) {
            return document.body.dataset.assetAtlasEnabled === "true";
        }
        if (typeof window !== "undefined" && typeof window.ASSET_ATLAS_ENABLED === "boolean") {
            return window.ASSET_ATLAS_ENABLED;
        }
        return true;
    }
    resolveIntegrityMode(explicit) {
        const candidates = [
            explicit,
            typeof document !== "undefined" ? document.body?.dataset?.assetIntegrityMode : null,
            typeof window !== "undefined" && typeof window.ASSET_INTEGRITY_MODE === "string"
                ? window.ASSET_INTEGRITY_MODE
                : null
        ];
        for (const candidate of candidates) {
            if (typeof candidate === "string") {
                const normalized = candidate.toLowerCase();
                if (INTEGRITY_MODES.has(normalized)) {
                    return normalized;
                }
            }
        }
        return "soft";
    }
    canVerifyDigests() {
        return Boolean(globalThis.crypto?.subtle?.digest);
    }
    getIntegritySummary() {
        if (!this.integritySummary) {
            return null;
        }
        return { ...this.integritySummary };
    }
    onIntegrityUpdate(listener) {
        this.integrityListeners.add(listener);
        return () => this.integrityListeners.delete(listener);
    }
    notifyIntegrityListeners() {
        if (this.integrityListeners.size === 0) {
            return;
        }
        const snapshot = this.getIntegritySummary();
        for (const listener of this.integrityListeners) {
            try {
                listener(snapshot);
            }
            catch (error) {
                console.warn("AssetLoader integrity listener error:", error);
            }
        }
    }
    createIntegrityTracker({ manifestPath, manifestUrl, totalImages, integrityMap }) {
        const summary = {
            status: "pending",
            strictMode: this.integrityMode === "strict",
            scenario: this.integrityScenario,
            manifest: manifestPath,
            manifestUrl,
            checked: 0,
            missingHash: 0,
            failed: 0,
            extraEntries: 0,
            totalImages,
            durationMs: null,
            firstFailure: null,
            error: null
        };
        const expectedEntries = {};
        if (integrityMap && typeof integrityMap === "object") {
            for (const [key, value] of Object.entries(integrityMap)) {
                const digest = normalizeDigest(value);
                if (digest) {
                    expectedEntries[key] = digest;
                }
            }
        }
        const tracker = {
            summary,
            expectedEntries,
            startedAt: nowMs(),
            recordMissing: (key, path) => {
                summary.missingHash += 1;
                if (!summary.firstFailure) {
                    summary.firstFailure = { key, type: "missing", path };
                }
            },
            recordFailure: (detail) => {
                summary.failed += 1;
                if (!summary.firstFailure) {
                    summary.firstFailure = { ...detail };
                }
            },
            recordChecked: () => {
                summary.checked += 1;
            },
            finalize: () => {
                summary.extraEntries = Object.keys(expectedEntries).length;
                summary.durationMs = Math.max(0, Math.round(nowMs() - tracker.startedAt));
                summary.completedAt = new Date().toISOString();
                if (summary.failed > 0) {
                    summary.status = "failed";
                }
                else if (summary.missingHash > 0) {
                    summary.status = "warning";
                }
                else {
                    summary.status = "passed";
                }
            }
        };
        this.integrityTracker = tracker;
        this.integritySummary = summary;
        this.notifyIntegrityListeners();
        return tracker;
    }
    finalizeIntegrityTracker(tracker) {
        if (!tracker) {
            return;
        }
        tracker.finalize();
        this.integritySummary = tracker.summary;
        this.notifyIntegrityListeners();
        const { summary } = tracker;
        if (summary.strictMode && (summary.failed > 0 || summary.missingHash > 0)) {
            const reason = summary.failed > 0 ? "digest mismatch" : "missing integrity entries";
            const error = new Error(`Asset integrity strict mode failed (${reason}).`);
            error.name = "AssetIntegrityViolation";
            throw error;
        }
    }
    markIntegritySkipped(reason, details = {}) {
        this.integrityTracker = null;
        this.integritySummary = {
            status: "skipped",
            strictMode: this.integrityMode === "strict",
            scenario: this.integrityScenario,
            manifest: details.manifest ?? null,
            manifestUrl: details.manifestUrl ?? null,
            checked: 0,
            missingHash: 0,
            failed: 0,
            extraEntries: 0,
            totalImages: details.totalImages ?? 0,
            durationMs: 0,
            firstFailure: null,
            error: reason ?? null
        };
        this.notifyIntegrityListeners();
    }
    async loadWithTiers(config) {
        const { lowRes, highRes, onReady } = config;
        await this.loadManifest(lowRes);
        onReady?.();
        if (highRes) {
            try {
                await this.loadManifest(highRes, { force: true });
            }
            catch (error) {
                console.warn("[assets] high-res manifest failed; continuing with low-res assets", error);
            }
        }
    }
    async loadManifest(manifestUrl, options = {}) {
        if (typeof fetch !== "function") {
            this.markIntegritySkipped("fetch-unavailable");
            console.warn("AssetLoader: fetch API unavailable; skipping manifest load.");
            return;
        }
        const absoluteUrl = this.resolveUrl(manifestUrl);
        const manifestPath = relativePath(absoluteUrl, typeof window !== "undefined" ? window.location.href : undefined);
        let response;
        try {
            response = await fetch(absoluteUrl, { cache: "force-cache" });
        }
        catch (error) {
            this.markIntegritySkipped("manifest-fetch-failed", { manifest: manifestPath });
            console.warn(`AssetLoader: failed to fetch manifest ${absoluteUrl}`, error);
            return;
        }
        if (!response.ok) {
            this.markIntegritySkipped(`manifest-http-${response.status}`, { manifest: manifestPath });
            console.warn(`AssetLoader: manifest responded with ${response.status} for ${absoluteUrl}`);
            return;
        }
        let manifest = null;
        try {
            manifest = (await response.json());
        }
        catch (error) {
            this.markIntegritySkipped("manifest-json-error", { manifest: manifestPath });
            console.warn(`AssetLoader: manifest ${absoluteUrl} contained invalid JSON.`, error);
            return;
        }
        if (!manifest?.images) {
            this.markIntegritySkipped("manifest-missing-images", { manifest: manifestPath });
            return;
        }
        const defeatAnimations = manifest?.defeatAnimations ?? manifest?.animations?.defeat ?? null;
        this.applyDefeatAnimations(defeatAnimations);
        const baseUrl = new URL("./", absoluteUrl).toString();
        const resolvedImages = {};
        for (const [key, relative] of Object.entries(manifest.images)) {
            if (options.skip?.has?.(key)) {
                continue;
            }
            resolvedImages[key] = this.resolveUrl(relative, baseUrl);
        }
        const integrityMap = manifest.integrity && typeof manifest.integrity === "object" ? manifest.integrity : null;
        if (this.integrityMode === "off" || !integrityMap) {
            this.markIntegritySkipped(this.integrityMode === "off" ? "mode-off" : "integrity-missing", {
                manifest: manifestPath,
                totalImages: Object.keys(resolvedImages).length,
                manifestUrl: absoluteUrl
            });
            await this.loadImages(resolvedImages, options);
            return;
        }
        if (!this.canVerifyDigests()) {
            this.markIntegritySkipped("crypto-unavailable", {
                manifest: manifestPath,
                totalImages: Object.keys(resolvedImages).length,
                manifestUrl: absoluteUrl
            });
            await this.loadImages(resolvedImages, options);
            return;
        }
        const tracker = this.createIntegrityTracker({
            manifestPath,
            manifestUrl: absoluteUrl,
            totalImages: Object.keys(resolvedImages).length,
            integrityMap
        });
        try {
            await this.loadImages(resolvedImages, Object.assign(Object.assign({}, options), { tracker, integrityMap, baseUrl }));
            this.finalizeIntegrityTracker(tracker);
        }
        catch (error) {
            tracker.summary.error = error instanceof Error ? error.message : String(error);
            this.integritySummary = tracker.summary;
            this.notifyIntegrityListeners();
            throw error;
        }
    }
    async loadImages(images, options = {}) {
        const tasks = Object.entries(images).map(([key, url]) => this.loadImage(key, url, options).then(() => ({ key, status: "fulfilled" }), (reason) => ({ key, status: "rejected", reason })));
        const results = await Promise.all(tasks);
        const failures = results.filter((result) => result.status === "rejected");
        if (failures.length > 0) {
            const failedKeys = failures.map((failure) => failure.key).join(", ");
            console.warn(`AssetLoader: failed to load ${failures.length} asset(s): ${failedKeys}`, failures);
        }
    }
    async loadImage(key, url, options = {}) {
        if (this.imageCache.has(key) && !options.force) {
            return;
        }
        if (options.force) {
            this.imageCache.delete(key);
        }
        if (options.tracker && options.integrityMap && this.integrityMode !== "off" && this.canVerifyDigests()) {
            await this.loadImageWithIntegrity(key, url, options);
            return;
        }
        await this.loadImageElement(key, url);
    }
    applyDefeatAnimations(definitions) {
        this.defeatAnimationSets.clear();
        this.defeatAnimationMatches.clear();
        this.defaultDefeatAnimationId = null;
        if (!definitions) {
            return;
        }
        const entries = [];
        if (Array.isArray(definitions)) {
            entries.push(...definitions);
        }
        else if (typeof definitions === "object") {
            for (const [id, entry] of Object.entries(definitions)) {
                if (entry && typeof entry === "object") {
                    entries.push({ id, ...entry });
                }
            }
        }
        for (const entry of entries) {
            const normalized = this.normalizeDefeatAnimationEntry(entry);
            if (!normalized) {
                continue;
            }
            this.defeatAnimationSets.set(normalized.id, normalized);
            const matches = Array.isArray(entry?.match)
                ? entry.match
                : Array.isArray(entry?.matches)
                    ? entry.matches
                    : [];
            const normalizedMatches = matches
                .map((value) => (typeof value === "string" ? value.toLowerCase() : ""))
                .filter((value) => value.length > 0);
            normalizedMatches.push(normalized.id.toLowerCase());
            for (const match of normalizedMatches) {
                this.defeatAnimationMatches.set(match, normalized.id);
            }
            if (entry?.default === true || normalized.id === "default" || !this.defaultDefeatAnimationId) {
                this.defaultDefeatAnimationId = normalized.id;
            }
        }
    }
    normalizeDefeatAnimationEntry(entry) {
        if (!entry || typeof entry !== "object") {
            return null;
        }
        const idValue = typeof entry.id === "string" && entry.id.trim().length > 0 ? entry.id.trim() : null;
        if (!idValue) {
            return null;
        }
        const framesInput = Array.isArray(entry.frames) ? entry.frames : [];
        const frames = [];
        for (const frame of framesInput) {
            const key = typeof frame?.key === "string" && frame.key.trim().length > 0
                ? frame.key.trim()
                : typeof frame?.image === "string" && frame.image.trim().length > 0
                    ? frame.image.trim()
                    : null;
            if (!key) {
                continue;
            }
            const durationMs = Number.isFinite(frame?.durationMs)
                ? Math.max(MIN_DEFEAT_FRAME_DURATION_MS, Math.round(frame.durationMs))
                : DEFAULT_DEFEAT_FRAME_DURATION_MS;
            let size = Number.isFinite(frame?.size) ? Math.max(8, Math.round(frame.size)) : null;
            if (size === null && Number.isFinite(frame?.scale)) {
                size = Math.max(8, Math.round(DEFAULT_DEFEAT_FRAME_SIZE * frame.scale));
            }
            const normalizedSize = size ?? DEFAULT_DEFEAT_FRAME_SIZE;
            const offsetX = Number.isFinite(frame?.offsetX) ? frame.offsetX : 0;
            const offsetY = Number.isFinite(frame?.offsetY) ? frame.offsetY : 0;
            frames.push({
                key,
                durationMs,
                size: normalizedSize,
                offsetX,
                offsetY
            });
        }
        const fallback = typeof entry.fallback === "string" && entry.fallback.trim().length > 0 ? entry.fallback.trim() : null;
        if (frames.length === 0 && !fallback) {
            return null;
        }
        const loop = entry.loop === true;
        return { id: idValue, frames, fallback, loop };
    }
    resolveDefeatAnimationById(id, visited = new Set()) {
        if (!id || visited.has(id)) {
            return null;
        }
        visited.add(id);
        const set = this.defeatAnimationSets.get(id);
        if (!set) {
            return null;
        }
        if (set.frames.length > 0) {
            return set;
        }
        if (set.fallback) {
            return this.resolveDefeatAnimationById(set.fallback, visited);
        }
        return null;
    }
    getDefeatAnimation(tierId) {
        const fallbackId = this.defaultDefeatAnimationId;
        if (typeof tierId !== "string" || tierId.trim().length === 0) {
            return fallbackId ? this.resolveDefeatAnimationById(fallbackId) : null;
        }
        const normalized = tierId.trim().toLowerCase();
        const animationId = this.defeatAnimationMatches.get(normalized) ?? fallbackId;
        if (!animationId) {
            return null;
        }
        return this.resolveDefeatAnimationById(animationId);
    }
    hasDefeatAnimation(tierId) {
        return Boolean(this.getDefeatAnimation(tierId));
    }
    listDefeatAnimations() {
        const animations = [];
        for (const set of this.defeatAnimationSets.values()) {
            animations.push({
                id: set.id,
                frames: set.frames.map((frame) => ({
                    key: frame.key,
                    durationMs: frame.durationMs,
                    offsetX: frame.offsetX ?? 0,
                    offsetY: frame.offsetY ?? 0,
                    size: frame.size ?? DEFAULT_DEFEAT_FRAME_SIZE
                })),
                fallback: set.fallback ?? null,
                loop: Boolean(set.loop)
            });
        }
        return animations;
    }
    async loadImageWithIntegrity(key, url, options) {
        const expectedDigest = normalizeDigest(options.integrityMap?.[key]);
        const pathLabel = relativePath(url, options.baseUrl);
        if (!expectedDigest) {
            options.tracker?.recordMissing(key, pathLabel);
            await this.loadImageElement(key, url);
            return;
        }
        delete options.tracker?.expectedEntries?.[key];
        let response;
        try {
            response = await fetch(url, { cache: "force-cache" });
        }
        catch (error) {
            options.tracker?.recordFailure({
                key,
                type: "fetch-error",
                path: pathLabel,
                expected: expectedDigest,
                actual: null
            });
            throw error;
        }
        if (!response.ok) {
            options.tracker?.recordFailure({
                key,
                type: "fetch-error",
                path: pathLabel,
                expected: expectedDigest,
                actual: null
            });
            throw new Error(`AssetLoader: HTTP ${response.status} for ${url}`);
        }
        const buffer = await response.arrayBuffer();
        const computedDigest = expectedDigest && this.canVerifyDigests()
            ? `sha256-${toBase64(await globalThis.crypto.subtle.digest("SHA-256", buffer))}`
            : null;
        if (!computedDigest) {
            options.tracker?.recordFailure({
                key,
                type: "fetch-error",
                path: pathLabel,
                expected: expectedDigest,
                actual: null
            });
        }
        else if (computedDigest !== expectedDigest) {
            options.tracker?.recordFailure({
                key,
                type: "mismatch",
                path: pathLabel,
                expected: expectedDigest,
                actual: computedDigest
            });
        }
        else {
            options.tracker?.recordChecked();
        }
        const blob = new Blob([buffer], {
            type: response.headers.get("content-type") ?? "application/octet-stream"
        });
        const objectUrl = URL.createObjectURL(blob);
        try {
            await this.loadImageElement(key, objectUrl);
        }
        finally {
            URL.revokeObjectURL(objectUrl);
        }
    }
    async loadImageElement(key, src) {
        const image = this.createImageInstance(key);
        if (!image) {
            return;
        }
        this.pendingLoads += 1;
        const promise = new Promise((resolve, reject) => {
            image.onload = () => resolve();
            image.onerror = reject;
        });
        image.src = src;
        try {
            await promise;
            this.imageCache.set(key, image);
            this.notifyImageLoaded(key);
        }
        finally {
            this.pendingLoads = Math.max(0, this.pendingLoads - 1);
            this.flushIdleResolvers();
        }
    }
    createImageInstance(key) {
        const globalScope = globalThis;
        const globalImage = globalScope.Image ?? globalScope.window?.Image;
        const ctor = typeof Image === "function" ? Image : globalImage;
        if (typeof ctor !== "function") {
            console.warn(`AssetLoader: Image constructor unavailable; skipping ${key}.`);
            return null;
        }
        return new ctor();
    }
    getImage(key) {
        const cached = this.imageCache.get(key);
        if (cached) {
            return cached;
        }
        if (this.hasAtlasFrame(key)) {
            void this.resolveAtlasImage(key);
        }
        return this.imageCache.get(key) ?? null;
    }
    onImageLoaded(listener) {
        this.listeners.add(listener);
        return () => this.listeners.delete(listener);
    }
    hasAtlasFrame(key) {
        return Boolean(this.atlas?.frames?.[key]);
    }
    listAtlasKeys() {
        if (!this.atlas?.frames) {
            return [];
        }
        return Object.keys(this.atlas.frames);
    }
    setAtlasEnabled(enabled) {
        this.atlasEnabled = Boolean(enabled);
        if (!this.atlasEnabled) {
            this.atlas = null;
        }
    }
    async loadAtlas(atlasUrl, options = {}) {
        if (!this.atlasEnabled || options.disable === true || !atlasUrl) {
            this.atlas = null;
            return;
        }
        const absoluteUrl = this.resolveUrl(atlasUrl);
        let response;
        try {
            response = await fetch(absoluteUrl, { cache: "force-cache" });
        }
        catch (error) {
            console.warn(`AssetLoader: failed to fetch atlas ${absoluteUrl}`, error);
            return;
        }
        if (!response.ok) {
            console.warn(`AssetLoader: atlas responded with ${response.status} for ${absoluteUrl}`);
            return;
        }
        let atlas;
        try {
            atlas = (await response.json());
        }
        catch (error) {
            console.warn(`AssetLoader: atlas ${absoluteUrl} contained invalid JSON.`, error);
            return;
        }
        const frames = this.normalizeAtlasFrames(atlas?.frames ?? atlas?.sprites ?? {});
        if (!frames || Object.keys(frames).length === 0) {
            console.warn(`AssetLoader: atlas ${absoluteUrl} missing frames; skipping.`);
            return;
        }
        const baseUrl = new URL("./", absoluteUrl).toString();
        const inferredImage = typeof atlas?.image === "string"
            ? atlas.image
            : typeof atlas?.meta?.image === "string"
                ? atlas.meta.image
                : this.inferAtlasImagePath(absoluteUrl, atlas?.atlas ?? null);
        const imageUrl = this.resolveUrl(inferredImage, baseUrl);
        let atlasImage = options.image ?? null;
        if (!atlasImage) {
            try {
                atlasImage = await this.loadAtlasImage(imageUrl);
            }
            catch (error) {
                console.warn(`AssetLoader: failed to load atlas image ${imageUrl}`, error);
                return;
            }
        }
        this.atlas = {
            url: absoluteUrl,
            imageUrl,
            image: atlasImage,
            frames
        };
    }
    inferAtlasImagePath(atlasJsonUrl, atlasName) {
        try {
            const url = new URL(atlasJsonUrl);
            const base = url.pathname.replace(/\.json$/i, "");
            const filename = atlasName ? `${atlasName}.png` : `${base.split("/").pop() ?? "atlas"}.png`;
            url.pathname = url.pathname.replace(/[^/]+$/, filename);
            return url.toString();
        }
        catch {
            return atlasName ? `${atlasName}.png` : atlasJsonUrl.replace(/\.json$/i, ".png");
        }
    }
    normalizeAtlasFrames(framesInput) {
        if (!framesInput || typeof framesInput !== "object") {
            return null;
        }
        const frames = {};
        for (const [key, entry] of Object.entries(framesInput)) {
            const frame = entry?.frame ?? entry;
            const x = Number(frame?.x);
            const y = Number(frame?.y);
            const w = Number(frame?.w ?? frame?.width);
            const h = Number(frame?.h ?? frame?.height);
            if ([x, y, w, h].every((value) => Number.isFinite(value))) {
                frames[key] = { x, y, w, h };
            }
        }
        return frames;
    }
    async loadAtlasImage(imageUrl) {
        const image = this.createImageInstance("atlas");
        if (!image) {
            throw new Error("AssetLoader: Image constructor unavailable for atlas.");
        }
        const promise = new Promise((resolve, reject) => {
            image.onload = () => resolve(image);
            image.onerror = reject;
        });
        image.src = imageUrl;
        return promise;
    }
    drawFrame(ctx, key, dx, dy, dw, dh) {
        const cached = this.imageCache.get(key);
        if (cached) {
            try {
                ctx.drawImage(cached, dx, dy, dw ?? cached.width ?? 0, dh ?? cached.height ?? 0);
                return true;
            }
            catch {
                return false;
            }
        }
        const frame = this.atlas?.frames?.[key];
        if (!frame || !this.atlas?.image) {
            return false;
        }
        try {
            ctx.drawImage(this.atlas.image, frame.x, frame.y, frame.w, frame.h, dx, dy, dw ?? frame.w, dh ?? frame.h);
            return true;
        }
        catch {
            return false;
        }
    }
    async resolveAtlasImage(key) {
        if (!this.atlas || !this.atlas.frames?.[key] || !this.atlas.image) {
            return null;
        }
        const frame = this.atlas.frames[key];
        if (typeof createImageBitmap === "function") {
            try {
                const bitmap = await createImageBitmap(this.atlas.image, frame.x, frame.y, frame.w, frame.h);
                this.imageCache.set(key, bitmap);
                return bitmap;
            }
            catch {
                // fall back to canvas extraction
            }
        }
        if (typeof document === "undefined") {
            return null;
        }
        const canvas = document.createElement("canvas");
        canvas.width = frame.w;
        canvas.height = frame.h;
        const ctx = canvas.getContext("2d");
        if (!ctx) {
            return null;
        }
        ctx.drawImage(this.atlas.image, frame.x, frame.y, frame.w, frame.h, 0, 0, frame.w, frame.h);
        this.imageCache.set(key, canvas);
        return canvas;
    }
    whenIdle() {
        if (this.pendingLoads === 0) {
            return Promise.resolve();
        }
        return new Promise((resolve) => {
            this.idleResolvers.push(resolve);
        });
    }
    notifyImageLoaded(key) {
        for (const listener of this.listeners) {
            try {
                listener(key);
            }
            catch (error) {
                console.warn("AssetLoader listener error:", error);
            }
        }
    }
    flushIdleResolvers() {
        if (this.pendingLoads !== 0 || this.idleResolvers.length === 0) {
            return;
        }
        const resolvers = [...this.idleResolvers];
        this.idleResolvers.length = 0;
        for (const resolve of resolvers) {
            resolve();
        }
    }
    resolveUrl(path, base) {
        const fallbackBase = typeof window !== "undefined" && window.location ? window.location.href : "http://localhost/";
        try {
            return new URL(path, base ?? fallbackBase).toString();
        }
        catch {
            return path;
        }
    }
}
