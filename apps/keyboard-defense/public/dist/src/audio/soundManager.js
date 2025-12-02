const DEFAULT_VOLUME = 0.8;
export class SoundManager {
    enabled = true;
    initialized = false;
    volume = DEFAULT_VOLUME;
    intensity = 1;
    ctx;
    masterGain;
    sounds = new Map();
    ambientGain = null;
    ambientSource = null;
    ambientProfile = null;
    ambientBuffers = new Map();
    stingers = new Map();
    constructor() {
        // Guard for environments without WebAudio (tests/SSR)
        const AudioCtx = globalThis
            .AudioContext;
        if (!AudioCtx) {
            this.ctx = null;
            this.masterGain = null;
            return;
        }
        this.ctx = new AudioCtx();
        this.masterGain = this.ctx.createGain();
        this.masterGain.gain.value = DEFAULT_VOLUME;
        this.masterGain.connect(this.ctx.destination);
    }
    async ensureInitialized() {
        if (this.initialized || !this.ctx) {
            return;
        }
        if (this.ctx.state === "suspended") {
            await this.ctx.resume();
        }
        this.loadSounds();
        this.loadAmbientBuffers();
        this.loadStingers();
        this.initialized = true;
    }
    play(key, detune = 0) {
        if (!this.enabled || !this.initialized || !this.ctx || !this.masterGain)
            return;
        const descriptor = this.sounds.get(key);
        if (!descriptor)
            return;
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
    setAmbientProfile(profile, options = {}) {
        if (!this.ctx || !this.masterGain)
            return;
        if (this.ambientProfile === profile && this.ambientSource)
            return;
        void this.ensureInitialized().then(() => {
            if (!this.ctx || !this.masterGain)
                return;
            const buffer = this.ambientBuffers.get(profile);
            if (!buffer)
                return;
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
            const targetVolume = Math.max(0, Math.min(1, (options.volume ?? 0.4) * this.intensity));
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
    stopAmbient() {
        if (!this.ctx)
            return;
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
    setEnabled(enabled) {
        this.enabled = enabled;
        const nextGain = enabled ? this.volume : 0;
        if (this.masterGain) {
            this.masterGain.gain.value = nextGain;
        }
        if (!enabled) {
            this.stopAmbient();
        }
    }
    isEnabled() {
        return this.enabled;
    }
    setVolume(volume) {
        const clamped = Math.max(0, Math.min(1, Number.isFinite(volume) ? volume : this.volume));
        this.volume = clamped;
        if (this.enabled && this.masterGain) {
            this.masterGain.gain.value = clamped;
        }
    }
    getVolume() {
        return this.volume;
    }
    setIntensity(intensity) {
        if (!Number.isFinite(intensity))
            return;
        const clamped = Math.max(0.1, Math.min(2, intensity));
        this.intensity = Math.round(clamped * 100) / 100;
        if (this.ambientGain && this.ctx) {
            const now = this.ctx.currentTime;
            this.ambientGain.gain.cancelScheduledValues(now);
            this.ambientGain.gain.setValueAtTime(this.ambientGain.gain.value, now);
            this.ambientGain.gain.linearRampToValueAtTime(Math.max(0, Math.min(1, 0.4 * this.intensity)), now + 0.2);
        }
    }
    getIntensity() {
        return this.intensity;
    }
    loadSounds() {
        if (!this.ctx)
            return;
        const sampleRate = this.ctx.sampleRate;
        this.sounds.set("projectile-arrow", {
            buffer: this.createTone(sampleRate, 0.18, 880),
            volume: 0.6
        });
        this.sounds.set("projectile-arcane", {
            buffer: this.createTone(sampleRate, 0.22, 1320),
            volume: 0.55
        });
        this.sounds.set("projectile-flame", {
            buffer: this.createNoise(sampleRate, 0.25, 0.05),
            volume: 0.7
        });
        this.sounds.set("impact-hit", {
            buffer: this.createTone(sampleRate, 0.15, 520),
            volume: 0.8
        });
        this.sounds.set("impact-breach", {
            buffer: this.createNoise(sampleRate, 0.3, 0.12),
            volume: 1
        });
        this.sounds.set("upgrade", {
            buffer: this.createTone(sampleRate, 0.35, 960, true),
            volume: 0.8
        });
    }
    playStinger(kind) {
        if (!this.enabled || !this.initialized || !this.ctx || !this.masterGain)
            return;
        const buffer = this.stingers.get(kind);
        if (!buffer)
            return;
        const source = this.ctx.createBufferSource();
        source.buffer = buffer;
        const gain = this.ctx.createGain();
        const target = Math.max(0, Math.min(1, 0.8 * this.intensity));
        gain.gain.value = target;
        source.connect(gain);
        gain.connect(this.masterGain);
        source.start();
    }
    loadAmbientBuffers() {
        if (!this.ctx)
            return;
        const sampleRate = this.ctx.sampleRate;
        this.ambientBuffers.set("calm", this.createPad(sampleRate, { baseFreq: 220, spread: 1.5 }));
        this.ambientBuffers.set("rising", this.createPad(sampleRate, { baseFreq: 320, spread: 2.4, modFreq: 0.3, noise: 0.04 }));
        this.ambientBuffers.set("siege", this.createPad(sampleRate, { baseFreq: 440, spread: 3.6, modFreq: 0.4, noise: 0.05 }));
        this.ambientBuffers.set("dire", this.createPad(sampleRate, { baseFreq: 180, spread: 4.5, modFreq: 0.18, noise: 0.08 }));
    }
    loadStingers() {
        if (!this.ctx)
            return;
        const sampleRate = this.ctx.sampleRate;
        const buildChord = (root) => {
            const duration = 1.2;
            const length = Math.floor(sampleRate * duration);
            const buffer = this.ctx.createBuffer(1, length, sampleRate);
            const data = buffer.getChannelData(0);
            const freqs = [root, root * 1.25, root * 1.5];
            for (let i = 0; i < length; i++) {
                const t = i / sampleRate;
                const env = Math.max(0, 1 - t / duration);
                const value = freqs.reduce((sum, freq, idx) => {
                    const detune = idx === 0 ? 0 : idx * 2;
                    return sum + Math.sin(2 * Math.PI * (freq + detune) * t);
                }, 0) /
                    freqs.length;
                data[i] = value * env * 0.7;
            }
            return buffer;
        };
        this.stingers.set("victory", buildChord(440));
        this.stingers.set("defeat", buildChord(196));
    }
    createPad(sampleRate, options) {
        const duration = 4.5;
        const length = Math.floor(sampleRate * duration);
        const buffer = this.ctx.createBuffer(1, length, sampleRate);
        const data = buffer.getChannelData(0);
        const modFreq = options.modFreq ?? 0.2;
        const noise = options.noise ?? 0.02;
        for (let i = 0; i < length; i++) {
            const t = i / sampleRate;
            const envelope = 0.65 + 0.35 * Math.sin(2 * Math.PI * 0.05 * t);
            const mod = 0.5 * Math.sin(2 * Math.PI * modFreq * t);
            const harmonics = Math.sin(2 * Math.PI * options.baseFreq * t + mod) * 0.6 +
                Math.sin(2 * Math.PI * options.baseFreq * options.spread * t - mod) * 0.4;
            const shimmer = (Math.random() * 2 - 1) * noise;
            data[i] = (harmonics + shimmer) * envelope * 0.5;
        }
        return buffer;
    }
    createTone(sampleRate, duration, frequency, rising = false) {
        const length = Math.floor(sampleRate * duration);
        const buffer = this.ctx.createBuffer(1, length, sampleRate);
        const data = buffer.getChannelData(0);
        for (let i = 0; i < length; i++) {
            const t = i / sampleRate;
            const envelope = rising ? Math.min(1, t / duration) : 1 - t / duration;
            data[i] = Math.sin(2 * Math.PI * frequency * t) * envelope * 0.8;
        }
        return buffer;
    }
    createNoise(sampleRate, duration, falloff = 0.1) {
        const length = Math.floor(sampleRate * duration);
        const buffer = this.ctx.createBuffer(1, length, sampleRate);
        const data = buffer.getChannelData(0);
        for (let i = 0; i < length; i++) {
            const t = i / sampleRate;
            const envelope = Math.max(0, 1 - t / (duration * (1 / falloff)));
            data[i] = (Math.random() * 2 - 1) * envelope * 0.8;
        }
        return buffer;
    }
}
