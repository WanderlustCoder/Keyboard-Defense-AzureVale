#!/usr/bin/env python3
"""
Audio Synthesizer for Keyboard Defense
Generates WAV files from sfx_presets.json definitions.
Pure Python implementation - no external dependencies.
"""

import json
import struct
import math
import random
import os

SAMPLE_RATE = 44100
BIT_DEPTH = 16
MAX_AMPLITUDE = 32767

def generate_sine(phase):
    """Generate sine wave sample."""
    return math.sin(2.0 * math.pi * phase)

def generate_square(phase):
    """Generate square wave sample."""
    return 1.0 if (phase % 1.0) < 0.5 else -1.0

def generate_sawtooth(phase):
    """Generate sawtooth wave sample."""
    return 2.0 * (phase % 1.0) - 1.0

def generate_triangle(phase):
    """Generate triangle wave sample."""
    t = phase % 1.0
    return 4.0 * abs(t - 0.5) - 1.0

def generate_noise():
    """Generate white noise sample."""
    return random.uniform(-1.0, 1.0)

def get_oscillator(osc_type):
    """Return oscillator function for given type."""
    oscillators = {
        "sine": generate_sine,
        "square": generate_square,
        "sawtooth": generate_sawtooth,
        "triangle": generate_triangle,
        "noise": lambda p: generate_noise()
    }
    return oscillators.get(osc_type, generate_sine)

def calculate_envelope(sample_idx, total_samples, envelope, sample_rate):
    """Calculate ADSR envelope value at given sample."""
    attack_samples = int(envelope.get("attack_ms", 10) * sample_rate / 1000)
    decay_samples = int(envelope.get("decay_ms", 50) * sample_rate / 1000)
    release_samples = int(envelope.get("release_ms", 50) * sample_rate / 1000)
    sustain_level = envelope.get("sustain", 0.5)

    # Calculate envelope phases
    attack_end = attack_samples
    decay_end = attack_end + decay_samples
    release_start = total_samples - release_samples

    if sample_idx < attack_end:
        # Attack phase - linear ramp up
        if attack_samples > 0:
            return sample_idx / attack_samples
        return 1.0
    elif sample_idx < decay_end:
        # Decay phase - exponential decay to sustain
        decay_progress = (sample_idx - attack_end) / max(1, decay_samples)
        return 1.0 - (1.0 - sustain_level) * decay_progress
    elif sample_idx < release_start:
        # Sustain phase
        return sustain_level
    else:
        # Release phase - exponential decay to zero
        if release_samples > 0:
            release_progress = (sample_idx - release_start) / release_samples
            return sustain_level * (1.0 - release_progress)
        return 0.0

def calculate_pitch(sample_idx, total_samples, base_freq, pitch_slide):
    """Calculate frequency at given sample with pitch slide."""
    if not pitch_slide:
        return base_freq

    start_offset = pitch_slide.get("start_offset", 0)
    end_offset = pitch_slide.get("end_offset", 0)
    curve = pitch_slide.get("curve", "linear")

    progress = sample_idx / max(1, total_samples)

    if curve == "exponential":
        # Exponential interpolation
        progress = progress * progress

    offset = start_offset + (end_offset - start_offset) * progress
    return base_freq + offset

class SimpleFilter:
    """Simple IIR filter implementation."""

    def __init__(self, filter_type, cutoff_hz, resonance, sample_rate):
        self.filter_type = filter_type
        self.cutoff = cutoff_hz
        self.resonance = resonance
        self.sample_rate = sample_rate

        # Filter state
        self.lp_out = 0.0
        self.bp_out = 0.0
        self.hp_out = 0.0

        # Calculate coefficients
        self.update_coefficients()

    def update_coefficients(self):
        """Calculate filter coefficients."""
        # Normalize cutoff to 0-1 range
        fc = min(0.99, self.cutoff / (self.sample_rate / 2))

        # Simple SVF-style coefficients
        self.g = math.tan(math.pi * fc * 0.5)
        self.k = 2.0 - 2.0 * self.resonance

    def process(self, sample):
        """Process single sample through filter."""
        # State variable filter
        hp = (sample - self.k * self.bp_out - self.lp_out) / (1 + self.k * self.g + self.g * self.g)
        bp = self.g * hp + self.bp_out
        lp = self.g * bp + self.lp_out

        self.hp_out = hp
        self.bp_out = bp
        self.lp_out = lp

        if self.filter_type == "lowpass":
            return lp
        elif self.filter_type == "highpass":
            return hp
        elif self.filter_type == "bandpass":
            return bp
        return sample

def synthesize_preset(preset):
    """Synthesize audio from a preset definition."""
    duration_ms = preset.get("duration_ms", 100)
    total_samples = int(duration_ms * SAMPLE_RATE / 1000)

    oscillator_def = preset.get("oscillator", {})
    osc_type = oscillator_def.get("type", "sine")
    base_freq = oscillator_def.get("frequency", 440)

    envelope = preset.get("envelope", {})
    pitch_slide = preset.get("pitch_slide", None)
    harmonics = preset.get("harmonics", [])
    filter_def = preset.get("filter", None)
    volume = preset.get("volume", 0.5)

    # Get oscillator function
    osc_func = get_oscillator(osc_type)

    # Setup filter if defined
    audio_filter = None
    if filter_def:
        audio_filter = SimpleFilter(
            filter_def.get("type", "lowpass"),
            filter_def.get("cutoff_hz", 2000),
            filter_def.get("resonance", 0.5),
            SAMPLE_RATE
        )

    # Generate samples
    samples = []
    phase = 0.0
    harmonic_phases = [0.0] * len(harmonics)

    for i in range(total_samples):
        # Calculate current frequency with pitch slide
        freq = calculate_pitch(i, total_samples, base_freq, pitch_slide)

        # Generate main oscillator sample
        if osc_type == "noise":
            sample = generate_noise()
        else:
            sample = osc_func(phase)
            phase += freq / SAMPLE_RATE

        # Add harmonics
        for h_idx, harmonic in enumerate(harmonics):
            ratio = harmonic.get("ratio", 2.0)
            amp = harmonic.get("amplitude", 0.5)

            if osc_type == "noise":
                h_sample = generate_noise()
            else:
                h_sample = osc_func(harmonic_phases[h_idx])
                harmonic_phases[h_idx] += (freq * ratio) / SAMPLE_RATE

            sample += h_sample * amp

        # Normalize if harmonics added
        if harmonics:
            total_amp = 1.0 + sum(h.get("amplitude", 0.5) for h in harmonics)
            sample /= total_amp

        # Apply filter
        if audio_filter:
            sample = audio_filter.process(sample)

        # Apply envelope
        env_value = calculate_envelope(i, total_samples, envelope, SAMPLE_RATE)
        sample *= env_value

        # Apply volume
        sample *= volume

        # Soft clip to prevent harsh distortion
        sample = math.tanh(sample * 1.5) / 1.5

        samples.append(sample)

    return samples

def write_wav(filename, samples):
    """Write samples to WAV file."""
    num_samples = len(samples)

    with open(filename, 'wb') as f:
        # WAV header
        f.write(b'RIFF')
        f.write(struct.pack('<I', 36 + num_samples * 2))  # File size - 8
        f.write(b'WAVE')

        # Format chunk
        f.write(b'fmt ')
        f.write(struct.pack('<I', 16))  # Chunk size
        f.write(struct.pack('<H', 1))   # Audio format (PCM)
        f.write(struct.pack('<H', 1))   # Num channels (mono)
        f.write(struct.pack('<I', SAMPLE_RATE))  # Sample rate
        f.write(struct.pack('<I', SAMPLE_RATE * 2))  # Byte rate
        f.write(struct.pack('<H', 2))   # Block align
        f.write(struct.pack('<H', 16))  # Bits per sample

        # Data chunk
        f.write(b'data')
        f.write(struct.pack('<I', num_samples * 2))

        # Write samples
        for sample in samples:
            # Clamp to valid range
            clamped = max(-1.0, min(1.0, sample))
            int_sample = int(clamped * MAX_AMPLITUDE)
            f.write(struct.pack('<h', int_sample))

def generate_music_loop(filename, duration_sec, bpm=100, key="C", mood="neutral"):
    """Generate a simple procedural music loop."""
    total_samples = int(duration_sec * SAMPLE_RATE)
    samples = []

    # Define scales
    scales = {
        "C": [261.63, 293.66, 329.63, 349.23, 392.00, 440.00, 493.88],  # C major
        "Am": [220.00, 246.94, 261.63, 293.66, 329.63, 349.23, 392.00],  # A minor
        "Em": [164.81, 185.00, 196.00, 220.00, 246.94, 261.63, 293.66],  # E minor
    }

    scale = scales.get(key, scales["C"])

    # Mood affects timbre and progression
    if mood == "tense":
        base_scale = scales.get("Am", scales["C"])
    elif mood == "triumphant":
        base_scale = scales.get("C", scales["C"])
    else:
        base_scale = scale

    beat_samples = int(60.0 / bpm * SAMPLE_RATE)

    # Bass line pattern (root notes)
    bass_pattern = [0, 0, 4, 4, 3, 3, 4, 4]  # Scale degrees

    # Chord progression
    chord_pattern = [
        [0, 2, 4],  # I
        [3, 5, 0],  # IV
        [4, 6, 1],  # V
        [0, 2, 4],  # I
    ]

    # Arpeggio pattern
    arp_pattern = [0, 2, 4, 2]

    phase_bass = 0.0
    phase_pads = [0.0, 0.0, 0.0]
    phase_arp = 0.0

    for i in range(total_samples):
        sample = 0.0

        # Current beat position
        beat_pos = (i / beat_samples) % len(bass_pattern)
        measure_pos = (i / (beat_samples * 4)) % len(chord_pattern)
        arp_pos = (i / (beat_samples / 2)) % len(arp_pattern)

        beat_idx = int(beat_pos)
        chord_idx = int(measure_pos)
        arp_idx = int(arp_pos)

        # Bass (low sine + square for punch)
        bass_note = base_scale[bass_pattern[beat_idx] % len(base_scale)] / 2
        bass_env = 0.3 * math.exp(-3.0 * (beat_pos % 1.0))
        phase_bass += bass_note / SAMPLE_RATE
        sample += (0.7 * math.sin(2 * math.pi * phase_bass) +
                   0.3 * generate_square(phase_bass)) * bass_env * 0.25

        # Pad chords (soft sines)
        chord = chord_pattern[chord_idx]
        for p_idx, degree in enumerate(chord):
            pad_freq = base_scale[degree % len(base_scale)]
            phase_pads[p_idx] += pad_freq / SAMPLE_RATE
            # Slow attack/release for pads
            pad_env = 0.15
            sample += math.sin(2 * math.pi * phase_pads[p_idx]) * pad_env * 0.15

        # Arpeggio (triangle wave)
        arp_degree = chord[arp_pattern[arp_idx] % len(chord)]
        arp_freq = base_scale[arp_degree % len(base_scale)] * 2  # Octave up
        phase_arp += arp_freq / SAMPLE_RATE
        arp_env = 0.2 * math.exp(-4.0 * ((i / (beat_samples / 2)) % 1.0))
        sample += generate_triangle(phase_arp) * arp_env * 0.2

        # Master envelope for loop point smoothing
        fade_samples = int(0.05 * SAMPLE_RATE)  # 50ms fade
        if i < fade_samples:
            sample *= i / fade_samples
        elif i > total_samples - fade_samples:
            sample *= (total_samples - i) / fade_samples

        # Soft limit
        sample = math.tanh(sample)
        samples.append(sample * 0.7)

    write_wav(filename, samples)

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_dir = os.path.dirname(script_dir)

    # Load presets
    presets_path = os.path.join(project_dir, "data", "audio", "sfx_presets.json")
    with open(presets_path, 'r') as f:
        data = json.load(f)

    # Create output directory
    sfx_dir = os.path.join(project_dir, "assets", "audio", "sfx")
    music_dir = os.path.join(project_dir, "assets", "audio", "music")
    os.makedirs(sfx_dir, exist_ok=True)
    os.makedirs(music_dir, exist_ok=True)

    print("Synthesizing SFX from presets...")
    print(f"Output: {sfx_dir}")
    print()

    # Generate each SFX
    for preset in data.get("presets", []):
        preset_id = preset.get("id", "unknown")
        output_path = os.path.join(sfx_dir, f"{preset_id}.wav")

        print(f"  Generating: {preset_id}.wav")
        samples = synthesize_preset(preset)
        write_wav(output_path, samples)

    sfx_count = len(data.get("presets", []))
    print(f"\nGenerated {sfx_count} SFX files.")

    # Generate music tracks
    print("\nGenerating music tracks...")
    print(f"Output: {music_dir}")
    print()

    music_tracks = [
        ("battle_calm.wav", 16, 90, "C", "neutral"),
        ("battle_tense.wav", 16, 110, "Am", "tense"),
        ("victory.wav", 8, 120, "C", "triumphant"),
        ("defeat.wav", 8, 70, "Em", "tense"),
        ("menu.wav", 20, 85, "C", "neutral"),
        ("kingdom.wav", 20, 80, "C", "neutral"),
    ]

    for track_name, duration, bpm, key, mood in music_tracks:
        output_path = os.path.join(music_dir, track_name)
        print(f"  Generating: {track_name} ({duration}s, {bpm} BPM)")
        generate_music_loop(output_path, duration, bpm, key, mood)

    print(f"\nGenerated {len(music_tracks)} music tracks.")
    print("\n" + "=" * 40)
    print("Audio generation complete!")
    print(f"  SFX: {sfx_count} files")
    print(f"  Music: {len(music_tracks)} files")

if __name__ == "__main__":
    main()
