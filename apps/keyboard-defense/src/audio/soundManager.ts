import {
  SFX_SAMPLE_KEYS,
  getSfxLibraryDefinition,
  type SfxLibraryDefinition,
  type SfxLibraryId,
  type SfxPatch,
  type SfxSampleKey
} from "../utils/sfxLibrary.js";
import {
  MUSIC_LAYERS,
  getMusicStemDefinition,
  resolveMusicProfileGains,
  type MusicProfile,
  type MusicStemDefinition,
  type MusicStemId,
  type MusicStemLayer,
  type MusicStemLayerSpec
} from "../utils/musicStems.js";
import {
  UI_SAMPLE_KEYS,
  getUiSchemeDefinition,
  type UiPatch,
  type UiSampleKey,
  type UiSchemeDefinition,
  type UiSchemeId
} from "../utils/uiSoundScheme.js";

const DEFAULT_VOLUME = 0.8;
const DEFAULT_MUSIC_LEVEL = 0.65;

export type AmbientProfile = "calm" | "rising" | "siege" | "dire";

interface SoundDescriptor {
  buffer: AudioBuffer;
  volume: number;
}

export class SoundManager {
  private enabled = true;
  private initialized = false;
  private volume = DEFAULT_VOLUME;
  private intensity = 1;
  private ctx: AudioContext | null;
  private masterGain: GainNode | null;
  private musicGain: GainNode | null = null;
  private sounds = new Map<string, SoundDescriptor>();
  private ambientGain: GainNode | null = null;
  private ambientSource: AudioBufferSourceNode | null = null;
  private ambientProfile: AmbientProfile | null = null;
  private ambientBuffers = new Map<AmbientProfile, AudioBuffer>();
  private stingers = new Map<string, AudioBuffer>();
  private sfxLibraryId: SfxLibraryId;
  private musicEnabled = true;
  private musicLevel = DEFAULT_MUSIC_LEVEL;
  private musicProfile: MusicProfile | null = null;
  private musicSuiteId: MusicStemId;
  private musicBuffers = new Map<MusicStemLayer, AudioBuffer>();
  private musicSources = new Map<MusicStemLayer, AudioBufferSourceNode>();
  private musicGains = new Map<MusicStemLayer, GainNode>();
  private uiSchemeId: UiSchemeId = "clarity";
  private uiSounds = new Map<string, SoundDescriptor>();

  constructor() {
    this.sfxLibraryId = "classic";
    this.musicSuiteId = "siege-suite";
    // Guard for environments without WebAudio (tests/SSR)
    const AudioCtx = (globalThis as typeof globalThis & { AudioContext?: typeof AudioContext })
      .AudioContext;
    if (!AudioCtx) {
      this.ctx = null;
      this.masterGain = null;
      return;
    }
    this.ctx = new AudioCtx();
    this.masterGain = this.ctx.createGain();
    this.masterGain.gain.value = DEFAULT_VOLUME;
    this.musicGain = this.ctx.createGain();
    this.musicGain.gain.value = this.musicEnabled ? this.musicLevel : 0;
    this.musicGain.connect(this.masterGain);
    this.masterGain.connect(this.ctx.destination);
  }

  async ensureInitialized(): Promise<void> {
    if (this.initialized || !this.ctx) {
      return;
    }
    if (this.ctx.state === "suspended") {
      await this.ctx.resume();
    }
    const library = getSfxLibraryDefinition(this.sfxLibraryId);
    this.loadSounds(library);
    this.loadUiSounds();
    this.loadAmbientBuffers();
    this.loadStingers(library);
    this.loadMusicStems();
    this.musicProfile = this.musicProfile ?? "calm";
    this.initialized = true;
  }

  play(key: string, detune = 0): void {
    if (!this.enabled || !this.initialized || !this.ctx || !this.masterGain) return;
    const descriptor = this.sounds.get(key);
    if (!descriptor) return;
    const source = this.ctx.createBufferSource();
    source.buffer = descriptor.buffer;
    source.detune.value = detune;
    const gain = this.ctx.createGain();
    const scaled = Math.max(0, Math.min(1, descriptor.volume * this.intensity));
    gain.gain.value = scaled;
    source.connect(gain);
    gain.connect(this.masterGain);
    source.start();
  }

  setAmbientProfile(profile: AmbientProfile, options: { volume?: number } = {}): void {
    if (this.musicEnabled) {
      this.setMusicProfile(profile);
      return;
    }
    if (!this.ctx || !this.masterGain) return;
    if (this.ambientProfile === profile && this.ambientSource) return;
    void this.ensureInitialized().then(() => {
      if (!this.ctx || !this.masterGain) return;
      const buffer = this.ambientBuffers.get(profile);
      if (!buffer) return;
      const FADE_MS = 650;
      const now = this.ctx.currentTime;
      if (this.ambientGain && this.ambientSource) {
        this.ambientGain.gain.cancelScheduledValues(now);
        this.ambientGain.gain.setValueAtTime(this.ambientGain.gain.value, now);
        this.ambientGain.gain.linearRampToValueAtTime(0, now + FADE_MS / 1000);
        this.ambientSource.stop(now + FADE_MS / 1000 + 0.01);
      }
      const source = this.ctx.createBufferSource();
      source.buffer = buffer;
      source.loop = true;
      const gain = this.ctx.createGain();
      const targetVolume = Math.max(
        0,
        Math.min(1, (options.volume ?? 0.4) * this.intensity)
      );
      gain.gain.value = 0;
      source.connect(gain);
      gain.connect(this.masterGain);
      source.start(now);
      gain.gain.setValueAtTime(0, now);
      gain.gain.linearRampToValueAtTime(targetVolume, now + FADE_MS / 1000);
      this.ambientSource = source;
      this.ambientGain = gain;
      this.ambientProfile = profile;
    });
  }

  stopAmbient(): void {
    this.stopMusic();
    if (!this.ctx) return;
    const now = this.ctx.currentTime;
    if (this.ambientGain) {
      this.ambientGain.gain.cancelScheduledValues(now);
      this.ambientGain.gain.setValueAtTime(this.ambientGain.gain.value, now);
      this.ambientGain.gain.linearRampToValueAtTime(0, now + 0.25);
    }
    if (this.ambientSource) {
      this.ambientSource.stop(now + 0.3);
    }
    this.ambientSource = null;
    this.ambientGain = null;
    this.ambientProfile = null;
  }

  setEnabled(enabled: boolean): void {
    this.enabled = enabled;
    const nextGain = enabled ? this.volume : 0;
    if (this.masterGain) {
      this.masterGain.gain.value = nextGain;
    }
    if (this.musicGain) {
      this.musicGain.gain.value = enabled && this.musicEnabled ? this.musicLevel : 0;
    }
    if (!enabled) {
      this.stopAmbient();
    }
  }

  isEnabled(): boolean {
    return this.enabled;
  }

  setVolume(volume: number): void {
    const clamped = Math.max(0, Math.min(1, Number.isFinite(volume) ? volume : this.volume));
    this.volume = clamped;
    if (this.enabled && this.masterGain) {
      this.masterGain.gain.value = clamped;
    }
  }

  getVolume(): number {
    return this.volume;
  }

  setIntensity(intensity: number): void {
    if (!Number.isFinite(intensity)) return;
    const clamped = Math.max(0.1, Math.min(2, intensity));
    this.intensity = Math.round(clamped * 100) / 100;
    if (this.ambientGain && this.ctx) {
      const now = this.ctx.currentTime;
      this.ambientGain.gain.cancelScheduledValues(now);
      this.ambientGain.gain.setValueAtTime(this.ambientGain.gain.value, now);
      this.ambientGain.gain.linearRampToValueAtTime(
        Math.max(0, Math.min(1, 0.4 * this.intensity)),
        now + 0.2
      );
    }
    if (this.musicProfile) {
      this.applyMusicProfile(this.musicProfile);
    }
  }

  getIntensity(): number {
    return this.intensity;
  }

  setLibrary(libraryId: SfxLibraryId): void {
    const next = getSfxLibraryDefinition(libraryId);
    const changed = this.sfxLibraryId !== next.id;
    this.sfxLibraryId = next.id;
    if (changed && this.initialized) {
      this.loadSounds(next);
      this.loadStingers(next);
    }
  }

  setUiScheme(schemeId: UiSchemeId): void {
    const next = getUiSchemeDefinition(schemeId);
    const changed = this.uiSchemeId !== next.id;
    this.uiSchemeId = next.id;
    if (changed && this.initialized) {
      this.loadUiSounds(next);
    }
  }

  setMusicEnabled(enabled: boolean): void {
    this.musicEnabled = Boolean(enabled);
    if (!this.musicEnabled) {
      this.stopMusic();
      if (this.musicGain) {
        this.musicGain.gain.value = 0;
      }
      return;
    }
    void this.ensureInitialized().then(() => {
      if (!this.ctx || !this.musicGain) return;
      this.musicGain.gain.value = this.musicLevel;
      this.restartMusicLoops();
      if (this.musicProfile) {
        this.applyMusicProfile(this.musicProfile);
      }
    });
  }

  setMusicLevel(level: number): void {
    const clamped = Math.max(0, Math.min(1, Number.isFinite(level) ? level : this.musicLevel));
    this.musicLevel = Math.round(clamped * 100) / 100;
    if (this.musicGain) {
      this.musicGain.gain.value = this.enabled && this.musicEnabled ? this.musicLevel : 0;
    }
    if (this.musicProfile) {
      this.applyMusicProfile(this.musicProfile);
    }
  }

  playUi(key: UiSampleKey): void {
    if (!this.enabled || !this.initialized || !this.ctx || !this.masterGain) return;
    const descriptor = this.uiSounds.get(key);
    if (!descriptor) return;
    const source = this.ctx.createBufferSource();
    source.buffer = descriptor.buffer;
    const gain = this.ctx.createGain();
    gain.gain.value = Math.max(0, Math.min(1, descriptor.volume * this.intensity));
    source.connect(gain);
    gain.connect(this.masterGain);
    source.start();
  }

  setMusicSuite(suiteId: MusicStemId): void {
    const definition = getMusicStemDefinition(suiteId);
    const changed = this.musicSuiteId !== definition.id;
    this.musicSuiteId = definition.id;
    if (!this.ctx) return;
    this.loadMusicStems(definition);
    if (changed) {
      this.restartMusicLoops();
      if (this.musicProfile) {
        this.applyMusicProfile(this.musicProfile);
      }
    }
  }

  setMusicProfile(profile: MusicProfile | AmbientProfile): void {
    const normalized = (profile ?? "calm") as MusicProfile;
    this.musicProfile = normalized;
    if (!this.musicEnabled) return;
    void this.ensureInitialized().then(() => {
      this.applyMusicProfile(normalized);
    });
  }

  private loadSounds(definition?: SfxLibraryDefinition): void {
    if (!this.ctx) return;
    this.sounds.clear();
    const sampleRate = this.ctx.sampleRate;
    const fallback = getSfxLibraryDefinition("classic");
    const library = definition ?? getSfxLibraryDefinition(this.sfxLibraryId);
    const patchFor = (key: SfxSampleKey) => library.patches[key] ?? fallback.patches[key];
    for (const key of SFX_SAMPLE_KEYS) {
      const descriptor = this.buildDescriptor(
        sampleRate,
        patchFor(key),
        fallback.patches[key] ?? patchFor(key)
      );
      this.sounds.set(key, descriptor);
    }
  }

  playStinger(kind: "victory" | "defeat"): void {
    if (!this.enabled || !this.initialized || !this.ctx || !this.masterGain) return;
    const buffer = this.stingers.get(kind);
    if (!buffer) return;
    const source = this.ctx.createBufferSource();
    source.buffer = buffer;
    const gain = this.ctx.createGain();
    const target = Math.max(0, Math.min(1, 0.8 * this.intensity));
    gain.gain.value = target;
    source.connect(gain);
    gain.connect(this.masterGain);
    source.start();
  }

  private loadAmbientBuffers(): void {
    if (!this.ctx) return;
    const sampleRate = this.ctx.sampleRate;
    this.ambientBuffers.set("calm", this.createPad(sampleRate, { baseFreq: 220, spread: 1.5 }));
    this.ambientBuffers.set(
      "rising",
      this.createPad(sampleRate, { baseFreq: 320, spread: 2.4, modFreq: 0.3, noise: 0.04 })
    );
    this.ambientBuffers.set(
      "siege",
      this.createPad(sampleRate, { baseFreq: 440, spread: 3.6, modFreq: 0.4, noise: 0.05 })
    );
    this.ambientBuffers.set(
      "dire",
      this.createPad(sampleRate, { baseFreq: 180, spread: 4.5, modFreq: 0.18, noise: 0.08 })
    );
  }

  private loadStingers(definition?: SfxLibraryDefinition): void {
    if (!this.ctx) return;
    const sampleRate = this.ctx.sampleRate;
    const stingers = definition?.stingers ?? { victory: 440, defeat: 196 };
    const buildChord = (root: number): AudioBuffer => {
      const duration = 1.2;
      const length = Math.floor(sampleRate * duration);
      const buffer = this.ctx!.createBuffer(1, length, sampleRate);
      const data = buffer.getChannelData(0);
      const freqs = [root, root * 1.25, root * 1.5];
      for (let i = 0; i < length; i++) {
        const t = i / sampleRate;
        const env = Math.max(0, 1 - t / duration);
        const value =
          freqs.reduce((sum, freq, idx) => {
            const detune = idx === 0 ? 0 : idx * 2;
            return sum + Math.sin(2 * Math.PI * (freq + detune) * t);
          }, 0) /
          freqs.length;
        data[i] = value * env * 0.7;
      }
      return buffer;
    };
    this.stingers.set("victory", buildChord(stingers.victory));
    this.stingers.set("defeat", buildChord(stingers.defeat));
  }

  private loadMusicStems(definition?: MusicStemDefinition): void {
    if (!this.ctx) return;
    const sampleRate = this.ctx.sampleRate;
    const suite = definition ?? getMusicStemDefinition(this.musicSuiteId);
    this.musicSuiteId = suite.id;
    this.musicBuffers.clear();
    for (const layer of MUSIC_LAYERS) {
      const spec = suite.layers[layer];
      const buffer = this.buildMusicStemBuffer(sampleRate, layer, spec);
      this.musicBuffers.set(layer, buffer);
    }
  }

  private restartMusicLoops(): void {
    if (!this.ctx || !this.musicGain) return;
    const now = this.ctx.currentTime;
    for (const source of this.musicSources.values()) {
      try {
        source.stop(now + 0.05);
      } catch {
        // ignore
      }
    }
    this.musicSources.clear();
    this.musicGains.clear();
    if (!this.musicEnabled) return;
    for (const [layer, buffer] of this.musicBuffers.entries()) {
      const source = this.ctx.createBufferSource();
      source.buffer = buffer;
      source.loop = true;
      const gain = this.ctx.createGain();
      gain.gain.value = 0;
      source.connect(gain);
      gain.connect(this.musicGain);
      source.start(now);
      this.musicSources.set(layer, source);
      this.musicGains.set(layer, gain);
    }
  }

  private applyMusicProfile(profile: MusicProfile): void {
    if (!this.ctx || !this.musicGain || !this.musicEnabled) return;
    const suite = getMusicStemDefinition(this.musicSuiteId);
    const targetGains = resolveMusicProfileGains(suite, profile);
    const now = this.ctx.currentTime;
    for (const layer of MUSIC_LAYERS) {
      const gainNode = this.musicGains.get(layer);
      if (!gainNode) continue;
      const target = Math.max(
        0,
        Math.min(1, (targetGains[layer] ?? 0) * this.musicLevel * this.intensity)
      );
      gainNode.gain.cancelScheduledValues(now);
      gainNode.gain.setValueAtTime(gainNode.gain.value, now);
      gainNode.gain.linearRampToValueAtTime(target, now + 0.35);
    }
  }

  private stopMusic(): void {
    if (!this.ctx) return;
    const now = this.ctx.currentTime;
    for (const gain of this.musicGains.values()) {
      gain.gain.cancelScheduledValues(now);
      gain.gain.setValueAtTime(gain.gain.value, now);
      gain.gain.linearRampToValueAtTime(0, now + 0.2);
    }
    for (const source of this.musicSources.values()) {
      try {
        source.stop(now + 0.25);
      } catch {
        // ignore
      }
    }
    this.musicSources.clear();
    this.musicGains.clear();
  }

  private buildMusicStemBuffer(
    sampleRate: number,
    layer: MusicStemLayer,
    spec: MusicStemLayerSpec
  ): AudioBuffer {
    if (layer === "pulse") {
      return this.createPulse(sampleRate, spec);
    }
    const baseFreq = Math.max(80, spec.baseFreq ?? 220);
    const spread = Math.max(1, spec.spread ?? 2.2);
    const modFreq = Math.max(0.05, spec.modFreq ?? 0.2);
    const noise = Math.max(0, spec.noise ?? 0.02);
    const duration = Math.max(4, spec.length ?? 5.5);
    const buffer = this.ctx!.createBuffer(1, Math.floor(sampleRate * duration), sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < buffer.length; i++) {
      const t = i / sampleRate;
      const envelope = 0.6 + 0.35 * Math.sin(2 * Math.PI * 0.05 * t);
      const mod = 0.5 * Math.sin(2 * Math.PI * modFreq * t);
      const harmonics =
        Math.sin(2 * Math.PI * baseFreq * t + mod) * 0.6 +
        Math.sin(2 * Math.PI * baseFreq * spread * t - mod) * 0.4;
      const shimmer = (Math.random() * 2 - 1) * noise;
      const weight = layer === "tension" ? 0.75 : 0.6;
      data[i] = (harmonics + shimmer) * envelope * weight;
    }
    return buffer;
  }

  private createPulse(sampleRate: number, spec: MusicStemLayerSpec): AudioBuffer {
    const duration = Math.max(4, spec.length ?? 4.5);
    const length = Math.floor(sampleRate * duration);
    const buffer = this.ctx!.createBuffer(1, length, sampleRate);
    const data = buffer.getChannelData(0);
    const every = Math.max(0.32, spec.pulseEvery ?? 0.6);
    const decay = Math.max(0.08, spec.pulseDecay ?? 0.28);
    const baseFreq = Math.max(120, spec.baseFreq ?? 420);
    const noise = Math.max(0, spec.pulseNoise ?? spec.noise ?? 0.02);
    for (let i = 0; i < length; i++) {
      const t = i / sampleRate;
      const phase = (t % every) / every;
      const env = Math.max(0, 1 - phase / decay);
      const sidechain = 0.6 + 0.35 * Math.sin(2 * Math.PI * (spec.modFreq ?? 0.35) * t);
      const tone = Math.sin(2 * Math.PI * baseFreq * t) * env;
      const texture = (Math.random() * 2 - 1) * noise * env;
      data[i] = (tone + texture) * env * sidechain * 0.9;
    }
    return buffer;
  }

  private loadUiSounds(definition?: UiSchemeDefinition): void {
    if (!this.ctx) return;
    const sampleRate = this.ctx.sampleRate;
    const fallback = getUiSchemeDefinition("clarity");
    const scheme = definition ?? getUiSchemeDefinition(this.uiSchemeId);
    const patchFor = (key: UiSampleKey) => scheme.patches[key] ?? fallback.patches[key];
    this.uiSounds.clear();
    for (const key of UI_SAMPLE_KEYS) {
      const descriptor = this.buildUiDescriptor(sampleRate, patchFor(key), fallback.patches[key]);
      this.uiSounds.set(key, descriptor);
    }
  }

  private normalizeUiPatch(patch: UiPatch | undefined, fallback: UiPatch): UiPatch {
    const base = patch ?? fallback;
    const duration = Math.max(
      0.05,
      Number.isFinite(base.duration) ? (base.duration as number) : fallback.duration
    );
    const volume = Math.max(
      0,
      Math.min(1.2, Number.isFinite(base.volume) ? (base.volume as number) : fallback.volume)
    );
    const frequency = Number.isFinite(base.frequency)
      ? (base.frequency as number)
      : fallback.frequency;
    const falloff = Number.isFinite(base.falloff) ? (base.falloff as number) : fallback.falloff;
    const mix = Number.isFinite(base.mix) ? Math.max(0, Math.min(1, base.mix as number)) : 0.2;
    return {
      ...fallback,
      ...base,
      duration,
      volume,
      frequency,
      falloff,
      mix
    };
  }

  private buildUiDescriptor(
    sampleRate: number,
    patch: UiPatch | undefined,
    fallback: UiPatch
  ): SoundDescriptor {
    const spec = this.normalizeUiPatch(patch, fallback);
    let buffer: AudioBuffer;
    if (spec.wave === "noise") {
      buffer = this.createNoise(sampleRate, spec.duration, spec.falloff ?? fallback.falloff ?? 0.1);
    } else if (spec.wave === "hybrid") {
      buffer = this.createHybrid(
        sampleRate,
        spec.duration,
        spec.frequency ?? fallback.frequency,
        spec.mix ?? 0.25,
        { rising: spec.rising, falloff: spec.falloff }
      );
    } else {
      buffer = this.createTone(
        sampleRate,
        spec.duration,
        spec.frequency ?? fallback.frequency ?? 640,
        spec.rising ?? false
      );
    }
    return { buffer, volume: spec.volume };
  }

  private createPad(
    sampleRate: number,
    options: { baseFreq: number; spread: number; modFreq?: number; noise?: number }
  ): AudioBuffer {
    const duration = 4.5;
    const length = Math.floor(sampleRate * duration);
    const buffer = this.ctx!.createBuffer(1, length, sampleRate);
    const data = buffer.getChannelData(0);
    const modFreq = options.modFreq ?? 0.2;
    const noise = options.noise ?? 0.02;
    for (let i = 0; i < length; i++) {
      const t = i / sampleRate;
      const envelope = 0.65 + 0.35 * Math.sin(2 * Math.PI * 0.05 * t);
      const mod = 0.5 * Math.sin(2 * Math.PI * modFreq * t);
      const harmonics =
        Math.sin(2 * Math.PI * options.baseFreq * t + mod) * 0.6 +
        Math.sin(2 * Math.PI * options.baseFreq * options.spread * t - mod) * 0.4;
      const shimmer = (Math.random() * 2 - 1) * noise;
      data[i] = (harmonics + shimmer) * envelope * 0.5;
    }
    return buffer;
  }

  private createTone(
    sampleRate: number,
    duration: number,
    frequency: number,
    rising = false
  ): AudioBuffer {
    const length = Math.floor(sampleRate * duration);
    const buffer = this.ctx!.createBuffer(1, length, sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < length; i++) {
      const t = i / sampleRate;
      const envelope = rising ? Math.min(1, t / duration) : 1 - t / duration;
      data[i] = Math.sin(2 * Math.PI * frequency * t) * envelope * 0.8;
    }
    return buffer;
  }

  private createHybrid(
    sampleRate: number,
    duration: number,
    frequency: number | undefined,
    noiseMix: number,
    options: { rising?: boolean; falloff?: number } = {}
  ): AudioBuffer {
    const tone = this.createTone(sampleRate, duration, frequency ?? 440, options.rising ?? false);
    const noise = this.createNoise(sampleRate, duration, options.falloff ?? 0.1);
    const buffer = this.ctx!.createBuffer(1, tone.length, sampleRate);
    const target = buffer.getChannelData(0);
    const toneData = tone.getChannelData(0);
    const noiseData = noise.getChannelData(0);
    const mix = Math.max(0, Math.min(1, noiseMix));
    for (let i = 0; i < target.length; i++) {
      target[i] = toneData[i] * (1 - mix) + noiseData[i] * mix;
    }
    return buffer;
  }

  private createNoise(sampleRate: number, duration: number, falloff = 0.1): AudioBuffer {
    const length = Math.floor(sampleRate * duration);
    const buffer = this.ctx!.createBuffer(1, length, sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < length; i++) {
      const t = i / sampleRate;
      const envelope = Math.max(0, 1 - t / (duration * (1 / falloff)));
      data[i] = (Math.random() * 2 - 1) * envelope * 0.8;
    }
    return buffer;
  }

  private normalizePatch(patch: SfxPatch | undefined, fallback: SfxPatch): SfxPatch {
    const base = patch ?? fallback;
    const duration = Math.max(
      0.08,
      Number.isFinite(base.duration) ? (base.duration as number) : fallback.duration
    );
    const volume = Math.max(
      0,
      Math.min(1.2, Number.isFinite(base.volume) ? (base.volume as number) : fallback.volume)
    );
    const frequency = Number.isFinite(base.frequency)
      ? (base.frequency as number)
      : fallback.frequency;
    const falloff = Number.isFinite(base.falloff) ? (base.falloff as number) : fallback.falloff;
    const mix = Number.isFinite(base.mix) ? Math.max(0, Math.min(1, base.mix as number)) : 0.25;
    return {
      ...fallback,
      ...base,
      duration,
      volume,
      frequency,
      falloff,
      mix
    };
  }

  private buildDescriptor(
    sampleRate: number,
    patch: SfxPatch | undefined,
    fallback: SfxPatch
  ): SoundDescriptor {
    const spec = this.normalizePatch(patch, fallback);
    let buffer: AudioBuffer;
    if (spec.wave === "noise") {
      buffer = this.createNoise(sampleRate, spec.duration, spec.falloff ?? fallback.falloff ?? 0.1);
    } else if (spec.wave === "hybrid") {
      buffer = this.createHybrid(
        sampleRate,
        spec.duration,
        spec.frequency ?? fallback.frequency,
        spec.mix ?? 0.3,
        { rising: spec.rising, falloff: spec.falloff }
      );
    } else {
      buffer = this.createTone(
        sampleRate,
        spec.duration,
        spec.frequency ?? fallback.frequency ?? 440,
        spec.rising ?? false
      );
    }
    return { buffer, volume: spec.volume };
  }
}
