const DEFAULT_VOLUME = 0.8;
export class SoundManager {
    constructor() {
        this.enabled = true;
        this.sounds = new Map();
        this.initialized = false;
        this.volume = DEFAULT_VOLUME;
        this.intensity = 1;
        this.ctx = new AudioContext();
        this.masterGain = this.ctx.createGain();
        this.masterGain.gain.value = DEFAULT_VOLUME;
        this.masterGain.connect(this.ctx.destination);
    }
    async ensureInitialized() {
        if (this.initialized) {
            return;
        }
        if (this.ctx.state === "suspended") {
            await this.ctx.resume();
        }
        this.loadSounds();
        this.initialized = true;
    }
    play(key, detune = 0) {
        if (!this.enabled || !this.initialized)
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
    setEnabled(enabled) {
        this.enabled = enabled;
        const nextGain = enabled ? this.volume : 0;
        this.masterGain.gain.value = nextGain;
    }
    isEnabled() {
        return this.enabled;
    }
    setVolume(volume) {
        const clamped = Math.max(0, Math.min(1, Number.isFinite(volume) ? volume : this.volume));
        this.volume = clamped;
        if (this.enabled) {
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
    }
    getIntensity() {
        return this.intensity;
    }
    loadSounds() {
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
