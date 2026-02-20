#!/usr/bin/env python3
"""
Generate procedural music loops (.wav) from music_presets.json definitions.

Creates loopable background music tracks with layered instruments:
pad, pluck, bass, and percussion.

Usage:
    python tools/generate_music.py
"""

import json
import math
import wave
from pathlib import Path

import numpy as np
from scipy import signal as sp_signal

SAMPLE_RATE = 44100
MAX_AMP = 32767

# Note frequencies (Hz) for octave 4
NOTE_FREQ = {
    "C": 261.63, "C#": 277.18, "D": 293.66, "D#": 311.13,
    "E": 329.63, "F": 349.23, "F#": 369.99, "G": 392.00,
    "G#": 415.30, "A": 440.00, "A#": 466.16, "Bb": 466.16,
    "B": 493.88,
}

SCALES = {
    "C_major": ["C", "D", "E", "F", "G", "A", "B"],
    "A_minor": ["A", "B", "C", "D", "E", "F", "G"],
    "D_minor": ["D", "E", "F", "G", "A", "Bb", "C"],
    "G_minor": ["G", "A", "Bb", "C", "D", "D#", "F"],
}

# Chord progressions per mood (scale degrees, 0-indexed)
PROGRESSIONS = {
    "peaceful": [[0, 2, 4], [3, 5, 0], [4, 6, 1], [0, 2, 4]],  # I-IV-V-I
    "tense": [[0, 2, 4], [5, 0, 2], [3, 5, 0], [4, 6, 1]],  # i-vi-iv-v
    "intense": [[0, 2, 4], [4, 6, 1], [3, 5, 0], [0, 2, 4]],  # i-v-iv-i
}


def note_freq(note: str, octave: int = 4) -> float:
    """Get frequency for a note at a given octave."""
    base = NOTE_FREQ.get(note, 440.0)
    return base * (2 ** (octave - 4))


def sine_wave(freq: float, duration: float, sr: int = SAMPLE_RATE) -> np.ndarray:
    """Generate a sine wave."""
    t = np.arange(int(sr * duration)) / sr
    return np.sin(2 * np.pi * freq * t)


def triangle_wave(freq: float, duration: float, sr: int = SAMPLE_RATE) -> np.ndarray:
    """Generate a triangle wave."""
    t = np.arange(int(sr * duration)) / sr
    return 2 * np.abs(2 * (freq * t % 1) - 1) - 1


def square_wave(freq: float, duration: float, sr: int = SAMPLE_RATE) -> np.ndarray:
    """Generate a soft square wave (with harmonics rolled off)."""
    t = np.arange(int(sr * duration)) / sr
    sig = np.sign(np.sin(2 * np.pi * freq * t))
    # Soften with lowpass
    nyq = sr / 2
    cutoff = min(freq * 6, nyq * 0.9) / nyq
    if 0 < cutoff < 1:
        b, a = sp_signal.butter(2, cutoff, btype="low")
        sig = sp_signal.lfilter(b, a, sig)
    return sig


def noise_burst(duration: float, sr: int = SAMPLE_RATE) -> np.ndarray:
    """Generate filtered noise."""
    n = int(sr * duration)
    return np.random.uniform(-1, 1, n)


def apply_envelope(samples: np.ndarray, attack_s: float, release_s: float) -> np.ndarray:
    """Apply attack/release envelope."""
    n = len(samples)
    env = np.ones(n)
    attack_n = min(int(attack_s * SAMPLE_RATE), n // 2)
    release_n = min(int(release_s * SAMPLE_RATE), n // 2)

    if attack_n > 0:
        env[:attack_n] = np.linspace(0, 1, attack_n)
    if release_n > 0:
        env[-release_n:] = np.linspace(1, 0, release_n)

    return samples * env


def generate_pad(scale_notes, chord_prog, bpm, bars, attack_ms, release_ms, pad_type, volume):
    """Generate sustained pad layer."""
    beat_dur = 60.0 / bpm
    bar_dur = beat_dur * 4
    total_dur = bar_dur * bars
    total_samples = int(total_dur * SAMPLE_RATE)
    output = np.zeros(total_samples)

    chords_per_bar = 1
    chord_dur = bar_dur / chords_per_bar

    for bar in range(bars):
        chord_idx = bar % len(chord_prog)
        chord_degrees = chord_prog[chord_idx]

        for degree in chord_degrees:
            note_name = scale_notes[degree % len(scale_notes)]
            octave = 3 if degree < len(scale_notes) else 4
            freq = note_freq(note_name, octave)

            tone = sine_wave(freq, chord_dur)
            # Add slight detuned layer for richness
            tone += sine_wave(freq * 1.003, chord_dur) * 0.3

            if pad_type == "dark_pad":
                tone += triangle_wave(freq * 0.5, chord_dur) * 0.4

            tone = apply_envelope(tone, attack_ms / 1000, release_ms / 1000)

            start = int(bar * bar_dur * SAMPLE_RATE)
            end = start + len(tone)
            if end > total_samples:
                tone = tone[: total_samples - start]
                end = total_samples
            output[start:end] += tone * volume * 0.3

    return output


def generate_pluck(scale_notes, chord_prog, bpm, bars, notes_per_bar, pattern, pluck_type, volume):
    """Generate plucked/melodic layer."""
    beat_dur = 60.0 / bpm
    bar_dur = beat_dur * 4
    total_dur = bar_dur * bars
    total_samples = int(total_dur * SAMPLE_RATE)
    output = np.zeros(total_samples)

    note_dur = bar_dur / notes_per_bar
    attack_s = 0.005
    release_s = note_dur * 0.6

    rng = np.random.RandomState(42)

    for bar in range(bars):
        chord_idx = bar % len(chord_prog)
        chord_degrees = chord_prog[chord_idx]

        for note_i in range(notes_per_bar):
            # Skip some notes based on pattern
            if pattern == "arpeggiated":
                degree = chord_degrees[note_i % len(chord_degrees)]
            elif pattern == "rhythmic":
                if rng.random() < 0.3:
                    continue
                degree = chord_degrees[note_i % len(chord_degrees)]
            elif pattern == "syncopated":
                if note_i % 2 == 0 and rng.random() < 0.4:
                    continue
                degree = chord_degrees[rng.randint(len(chord_degrees))]
            else:
                degree = chord_degrees[note_i % len(chord_degrees)]

            note_name = scale_notes[degree % len(scale_notes)]
            octave = 5 if pluck_type == "aggressive" else 4
            freq = note_freq(note_name, octave)

            if pluck_type == "soft_pluck":
                tone = sine_wave(freq, note_dur)
                tone += sine_wave(freq * 2, note_dur) * 0.15
            elif pluck_type == "staccato":
                tone = triangle_wave(freq, note_dur * 0.5)
                tone = np.pad(tone, (0, max(0, int(note_dur * SAMPLE_RATE) - len(tone))))
            else:  # aggressive
                tone = square_wave(freq, note_dur * 0.7)
                tone = np.pad(tone, (0, max(0, int(note_dur * SAMPLE_RATE) - len(tone))))

            tone = apply_envelope(tone, attack_s, release_s)

            t_offset = bar * bar_dur + note_i * note_dur
            start = int(t_offset * SAMPLE_RATE)
            end = start + len(tone)
            if end > total_samples:
                tone = tone[: total_samples - start]
                end = total_samples
            if start < total_samples:
                output[start:end] += tone * volume * 0.4

    return output


def generate_bass(scale_notes, chord_prog, bpm, bars, bass_type, bass_pattern, volume):
    """Generate bass layer."""
    beat_dur = 60.0 / bpm
    bar_dur = beat_dur * 4
    total_dur = bar_dur * bars
    total_samples = int(total_dur * SAMPLE_RATE)
    output = np.zeros(total_samples)

    if bass_pattern == "eighth_notes":
        notes_per_bar = 8
    elif bass_pattern == "driving":
        notes_per_bar = 8
    else:
        notes_per_bar = 4

    note_dur = bar_dur / notes_per_bar

    for bar in range(bars):
        chord_idx = bar % len(chord_prog)
        root_degree = chord_prog[chord_idx][0]
        note_name = scale_notes[root_degree % len(scale_notes)]
        freq = note_freq(note_name, 2)  # Bass octave

        for note_i in range(notes_per_bar):
            if bass_type == "pulse_bass":
                tone = square_wave(freq, note_dur * 0.8)
            else:  # heavy_bass
                tone = sine_wave(freq, note_dur * 0.9)
                tone += sine_wave(freq * 2, note_dur * 0.9) * 0.3

            tone = apply_envelope(tone, 0.01, note_dur * 0.3)

            # Pad to note duration
            target_len = int(note_dur * SAMPLE_RATE)
            if len(tone) < target_len:
                tone = np.pad(tone, (0, target_len - len(tone)))
            else:
                tone = tone[:target_len]

            t_offset = bar * bar_dur + note_i * note_dur
            start = int(t_offset * SAMPLE_RATE)
            end = start + len(tone)
            if end > total_samples:
                tone = tone[: total_samples - start]
                end = total_samples
            if start < total_samples:
                output[start:end] += tone * volume * 0.5

    return output


def generate_percussion(bpm, bars, perc_type, perc_pattern, volume):
    """Generate percussion layer."""
    beat_dur = 60.0 / bpm
    bar_dur = beat_dur * 4
    total_dur = bar_dur * bars
    total_samples = int(total_dur * SAMPLE_RATE)
    output = np.zeros(total_samples)

    if perc_pattern == "hi_hat_only":
        hits_per_bar = 8
        hit_dur = 0.03
    else:  # intense / full_kit
        hits_per_bar = 16
        hit_dur = 0.04

    rng = np.random.RandomState(99)

    for bar in range(bars):
        for hit_i in range(hits_per_bar):
            t_offset = bar * bar_dur + hit_i * (bar_dur / hits_per_bar)

            # Hi-hat: filtered noise
            if perc_pattern == "hi_hat_only" or hit_i % 2 == 0:
                hit = noise_burst(hit_dur)
                # Highpass filter for hi-hat
                nyq = SAMPLE_RATE / 2
                cutoff = min(6000 / nyq, 0.99)
                b, a = sp_signal.butter(2, cutoff, btype="high")
                hit = sp_signal.lfilter(b, a, hit)
                hit = apply_envelope(hit, 0.001, hit_dur * 0.5)
                hit_vol = volume * 0.3
            else:
                # Kick on beat 0 and 2
                if hit_i % (hits_per_bar // 2) == 0:
                    t_kick = np.arange(int(0.08 * SAMPLE_RATE)) / SAMPLE_RATE
                    freq_kick = 150 * np.exp(-t_kick * 30)
                    hit = np.sin(2 * np.pi * np.cumsum(freq_kick / SAMPLE_RATE))
                    hit = apply_envelope(hit, 0.002, 0.04)
                    hit_vol = volume * 0.5
                else:
                    continue

            start = int(t_offset * SAMPLE_RATE)
            end = start + len(hit)
            if end > total_samples:
                hit = hit[: total_samples - start]
                end = total_samples
            if start < total_samples:
                output[start:end] += hit * hit_vol

    return output


def synthesize_track(preset: dict) -> np.ndarray:
    """Synthesize a complete music track from a preset."""
    bpm = preset["bpm"]
    bars = preset["bars"]
    key = preset["key"]
    instruments = preset["instruments"]
    mood = preset.get("mood", "peaceful")

    scale_notes = SCALES.get(key, SCALES["C_major"])
    chord_prog = PROGRESSIONS.get(mood, PROGRESSIONS["peaceful"])

    beat_dur = 60.0 / bpm
    bar_dur = beat_dur * 4
    total_dur = bar_dur * bars
    total_samples = int(total_dur * SAMPLE_RATE)

    mix = np.zeros(total_samples)

    # Pad
    pad_cfg = instruments.get("pad", {})
    if pad_cfg.get("enabled", False):
        pad = generate_pad(
            scale_notes, chord_prog, bpm, bars,
            pad_cfg.get("attack_ms", 500),
            pad_cfg.get("release_ms", 800),
            pad_cfg.get("type", "sine_pad"),
            pad_cfg.get("volume", 0.3),
        )
        if len(pad) > total_samples:
            pad = pad[:total_samples]
        mix[: len(pad)] += pad

    # Pluck
    pluck_cfg = instruments.get("pluck", {})
    if pluck_cfg.get("enabled", False):
        pluck = generate_pluck(
            scale_notes, chord_prog, bpm, bars,
            pluck_cfg.get("notes_per_bar", 4),
            pluck_cfg.get("pattern", "arpeggiated"),
            pluck_cfg.get("type", "soft_pluck"),
            pluck_cfg.get("volume", 0.25),
        )
        if len(pluck) > total_samples:
            pluck = pluck[:total_samples]
        mix[: len(pluck)] += pluck

    # Bass
    bass_cfg = instruments.get("bass", {})
    if bass_cfg.get("enabled", False):
        bass = generate_bass(
            scale_notes, chord_prog, bpm, bars,
            bass_cfg.get("type", "pulse_bass"),
            bass_cfg.get("pattern", "eighth_notes"),
            bass_cfg.get("volume", 0.35),
        )
        if len(bass) > total_samples:
            bass = bass[:total_samples]
        mix[: len(bass)] += bass

    # Percussion
    perc_cfg = instruments.get("percussion", {})
    if perc_cfg.get("enabled", False):
        perc = generate_percussion(
            bpm, bars,
            perc_cfg.get("type", "light_drums"),
            perc_cfg.get("pattern", "hi_hat_only"),
            perc_cfg.get("volume", 0.2),
        )
        if len(perc) > total_samples:
            perc = perc[:total_samples]
        mix[: len(perc)] += perc

    # Normalize
    peak = np.max(np.abs(mix))
    if peak > 0:
        mix = mix / peak * 0.85

    return np.clip(mix * MAX_AMP, -MAX_AMP, MAX_AMP).astype(np.int16)


def write_wav(filepath: Path, pcm_data: np.ndarray):
    """Write PCM data to a WAV file."""
    filepath.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(filepath), "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data.tobytes())


# Extra tracks not in presets
EXTRA_TRACKS = [
    {
        "id": "menu",
        "description": "Menu ambient loop",
        "bpm": 60,
        "bars": 16,
        "key": "C_major",
        "instruments": {
            "pad": {"enabled": True, "type": "sine_pad", "volume": 0.25,
                    "attack_ms": 800, "release_ms": 1000},
            "pluck": {"enabled": True, "type": "soft_pluck", "volume": 0.15,
                      "pattern": "arpeggiated", "notes_per_bar": 2},
            "bass": {"enabled": False},
            "percussion": {"enabled": False},
        },
        "density": 0.2,
        "mood": "peaceful",
    },
    {
        "id": "victory",
        "description": "Victory celebration loop",
        "bpm": 100,
        "bars": 8,
        "key": "C_major",
        "instruments": {
            "pad": {"enabled": True, "type": "sine_pad", "volume": 0.3,
                    "attack_ms": 200, "release_ms": 400},
            "pluck": {"enabled": True, "type": "soft_pluck", "volume": 0.35,
                      "pattern": "arpeggiated", "notes_per_bar": 8},
            "bass": {"enabled": True, "type": "pulse_bass", "volume": 0.3,
                     "pattern": "eighth_notes"},
            "percussion": {"enabled": True, "type": "light_drums", "volume": 0.2,
                           "pattern": "hi_hat_only"},
        },
        "density": 0.5,
        "mood": "peaceful",
    },
]


def main():
    monogame_root = Path(__file__).parent.parent
    presets_path = monogame_root / "data" / "audio" / "music_presets.json"
    output_dir = monogame_root / "Content" / "Audio" / "music"

    with open(presets_path) as f:
        data = json.load(f)

    all_presets = data["presets"] + EXTRA_TRACKS

    output_dir.mkdir(parents=True, exist_ok=True)
    generated = 0

    print(f"Generating {len(all_presets)} music tracks...")
    for preset in all_presets:
        preset_id = preset["id"]
        bpm = preset["bpm"]
        bars = preset["bars"]
        beat_dur = 60.0 / bpm
        duration = beat_dur * 4 * bars

        print(f"  {preset_id} ({bpm} BPM, {bars} bars, {duration:.1f}s)...")

        pcm = synthesize_track(preset)
        filepath = output_dir / f"{preset_id}.wav"
        write_wav(filepath, pcm)
        generated += 1

        print(f"    -> {filepath.name} ({len(pcm) / SAMPLE_RATE:.1f}s)")

    print(f"\nDone: {generated} music tracks generated")
    print(f"Output: {output_dir}")


if __name__ == "__main__":
    main()
