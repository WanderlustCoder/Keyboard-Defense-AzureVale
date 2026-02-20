#!/usr/bin/env python3
"""
Generate procedural SFX audio (.wav) from sfx_presets.json definitions.

Uses numpy for waveform synthesis and scipy for filtering.
Reads synthesis parameters (oscillator, ADSR envelope, filter, pitch slide)
and outputs 16-bit 44100Hz mono WAV files.

Usage:
    python tools/generate_sfx.py
"""

import json
import math
import struct
import wave
from pathlib import Path

import numpy as np
from scipy import signal as sp_signal

SAMPLE_RATE = 44100
BIT_DEPTH = 16
MAX_AMP = 32767


def oscillator(osc_type: str, freq: np.ndarray, t: np.ndarray) -> np.ndarray:
    """Generate waveform samples for the given oscillator type."""
    phase = 2 * np.pi * np.cumsum(freq / SAMPLE_RATE)
    if osc_type == "sine":
        return np.sin(phase)
    elif osc_type == "square":
        return np.sign(np.sin(phase))
    elif osc_type == "sawtooth":
        return 2 * (phase / (2 * np.pi) % 1) - 1
    elif osc_type == "triangle":
        return 2 * np.abs(2 * (phase / (2 * np.pi) % 1) - 1) - 1
    elif osc_type == "noise":
        return np.random.uniform(-1, 1, len(t))
    else:
        return np.sin(phase)


def adsr_envelope(
    attack_ms: float,
    decay_ms: float,
    sustain: float,
    release_ms: float,
    duration_ms: float,
) -> np.ndarray:
    """Generate ADSR envelope."""
    total_samples = int(SAMPLE_RATE * duration_ms / 1000)
    if total_samples == 0:
        return np.array([])

    attack_samples = int(SAMPLE_RATE * attack_ms / 1000)
    decay_samples = int(SAMPLE_RATE * decay_ms / 1000)
    release_samples = int(SAMPLE_RATE * release_ms / 1000)

    # Clamp to not exceed total
    attack_samples = min(attack_samples, total_samples)
    decay_samples = min(decay_samples, total_samples - attack_samples)
    sustain_samples = max(0, total_samples - attack_samples - decay_samples - release_samples)
    release_samples = min(release_samples, total_samples - attack_samples - decay_samples - sustain_samples)

    env = np.zeros(total_samples)
    idx = 0

    # Attack
    if attack_samples > 0:
        env[idx : idx + attack_samples] = np.linspace(0, 1, attack_samples)
        idx += attack_samples

    # Decay
    if decay_samples > 0:
        env[idx : idx + decay_samples] = np.linspace(1, sustain, decay_samples)
        idx += decay_samples

    # Sustain
    if sustain_samples > 0:
        env[idx : idx + sustain_samples] = sustain
        idx += sustain_samples

    # Release
    if release_samples > 0:
        start_level = env[idx - 1] if idx > 0 else sustain
        env[idx : idx + release_samples] = np.linspace(start_level, 0, release_samples)

    return env


def apply_pitch_slide(
    base_freq: float,
    start_offset: float,
    end_offset: float,
    curve: str,
    num_samples: int,
) -> np.ndarray:
    """Generate frequency array with pitch slide."""
    t_norm = np.linspace(0, 1, num_samples)
    if curve == "exponential":
        # Exponential interpolation
        t_curve = t_norm ** 2
    else:
        t_curve = t_norm

    freq_start = base_freq + start_offset
    freq_end = base_freq + end_offset
    return freq_start + (freq_end - freq_start) * t_curve


def apply_filter(samples: np.ndarray, filter_cfg: dict) -> np.ndarray:
    """Apply a filter to the audio samples."""
    filter_type = filter_cfg.get("type", "lowpass")
    cutoff = filter_cfg.get("cutoff_hz", 2000)
    resonance = filter_cfg.get("resonance", 0.1)

    # Normalize cutoff to Nyquist
    nyquist = SAMPLE_RATE / 2
    norm_cutoff = min(cutoff / nyquist, 0.99)
    if norm_cutoff <= 0.01:
        return samples

    # Quality factor from resonance
    Q = max(0.5, 0.5 + resonance * 5)

    try:
        if filter_type == "lowpass":
            b, a = sp_signal.butter(2, norm_cutoff, btype="low")
        elif filter_type == "highpass":
            b, a = sp_signal.butter(2, norm_cutoff, btype="high")
        elif filter_type == "bandpass":
            low = max(0.01, norm_cutoff * 0.8)
            high = min(0.99, norm_cutoff * 1.2)
            b, a = sp_signal.butter(2, [low, high], btype="band")
        else:
            return samples

        return sp_signal.lfilter(b, a, samples)
    except Exception:
        return samples


def synthesize_preset(preset: dict) -> np.ndarray:
    """Synthesize a complete SFX from a preset definition."""
    osc_cfg = preset.get("oscillator", {"type": "sine", "frequency": 440})
    env_cfg = preset.get("envelope", {"attack_ms": 5, "decay_ms": 50, "sustain": 0.3, "release_ms": 50})
    duration_ms = preset.get("duration_ms", 200)
    volume = preset.get("volume", 0.5)

    num_samples = int(SAMPLE_RATE * duration_ms / 1000)
    if num_samples == 0:
        return np.array([], dtype=np.int16)

    t = np.arange(num_samples) / SAMPLE_RATE
    base_freq = osc_cfg.get("frequency", 440)

    # Pitch slide
    pitch_cfg = preset.get("pitch_slide")
    if pitch_cfg:
        freq_array = apply_pitch_slide(
            base_freq,
            pitch_cfg.get("start_offset", 0),
            pitch_cfg.get("end_offset", 0),
            pitch_cfg.get("curve", "linear"),
            num_samples,
        )
    else:
        freq_array = np.full(num_samples, base_freq)

    # Generate waveform
    samples = oscillator(osc_cfg.get("type", "sine"), freq_array, t)

    # Apply harmonics if present
    harmonics = preset.get("harmonics", [])
    for h in harmonics:
        h_freq = freq_array * h.get("ratio", 2)
        h_amp = h.get("amplitude", 0.3)
        samples += oscillator(osc_cfg.get("type", "sine"), h_freq, t) * h_amp

    # Apply envelope
    env = adsr_envelope(
        env_cfg.get("attack_ms", 5),
        env_cfg.get("decay_ms", 50),
        env_cfg.get("sustain", 0.3),
        env_cfg.get("release_ms", 50),
        duration_ms,
    )
    if len(env) < len(samples):
        env = np.pad(env, (0, len(samples) - len(env)))
    elif len(env) > len(samples):
        env = env[: len(samples)]

    samples *= env

    # Apply filter
    filter_cfg = preset.get("filter")
    if filter_cfg:
        samples = apply_filter(samples, filter_cfg)

    # Normalize and apply volume
    peak = np.max(np.abs(samples))
    if peak > 0:
        samples = samples / peak
    samples *= volume

    # Convert to 16-bit PCM
    pcm = np.clip(samples * MAX_AMP, -MAX_AMP, MAX_AMP).astype(np.int16)
    return pcm


def write_wav(filepath: Path, pcm_data: np.ndarray):
    """Write PCM data to a WAV file."""
    filepath.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(filepath), "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)  # 16-bit
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data.tobytes())


# Extra SFX not in presets but needed by the Sfx enum
EXTRA_PRESETS = [
    {"id": "ui_hover", "oscillator": {"type": "sine", "frequency": 1200},
     "envelope": {"attack_ms": 2, "decay_ms": 20, "sustain": 0, "release_ms": 10},
     "volume": 0.15, "duration_ms": 30},
    {"id": "ui_error", "oscillator": {"type": "square", "frequency": 200},
     "envelope": {"attack_ms": 5, "decay_ms": 80, "sustain": 0.2, "release_ms": 50},
     "volume": 0.3, "duration_ms": 150,
     "filter": {"type": "lowpass", "cutoff_hz": 600, "resonance": 0.4}},
    {"id": "ui_open", "oscillator": {"type": "sine", "frequency": 600},
     "envelope": {"attack_ms": 5, "decay_ms": 40, "sustain": 0.2, "release_ms": 30},
     "volume": 0.25, "duration_ms": 80,
     "pitch_slide": {"start_offset": -200, "end_offset": 0, "curve": "exponential"}},
    {"id": "ui_close", "oscillator": {"type": "sine", "frequency": 400},
     "envelope": {"attack_ms": 5, "decay_ms": 40, "sustain": 0.1, "release_ms": 30},
     "volume": 0.25, "duration_ms": 80,
     "pitch_slide": {"start_offset": 200, "end_offset": 0, "curve": "exponential"}},
    {"id": "type_backspace", "oscillator": {"type": "noise", "frequency": 400},
     "envelope": {"attack_ms": 2, "decay_ms": 30, "sustain": 0, "release_ms": 15},
     "volume": 0.15, "duration_ms": 40,
     "filter": {"type": "lowpass", "cutoff_hz": 1200, "resonance": 0.2}},
    {"id": "word_perfect", "oscillator": {"type": "sine", "frequency": 1000},
     "envelope": {"attack_ms": 5, "decay_ms": 80, "sustain": 0.4, "release_ms": 80},
     "volume": 0.4, "duration_ms": 250,
     "pitch_slide": {"start_offset": -200, "end_offset": 200, "curve": "exponential"},
     "harmonics": [{"ratio": 2, "amplitude": 0.3}, {"ratio": 3, "amplitude": 0.15}]},
    {"id": "word_failed", "oscillator": {"type": "sawtooth", "frequency": 150},
     "envelope": {"attack_ms": 10, "decay_ms": 100, "sustain": 0.1, "release_ms": 80},
     "volume": 0.3, "duration_ms": 200,
     "filter": {"type": "lowpass", "cutoff_hz": 500, "resonance": 0.3}},
    {"id": "combo_max", "oscillator": {"type": "sine", "frequency": 1200},
     "envelope": {"attack_ms": 5, "decay_ms": 100, "sustain": 0.5, "release_ms": 150},
     "volume": 0.45, "duration_ms": 400,
     "pitch_slide": {"start_offset": -400, "end_offset": 200, "curve": "exponential"},
     "harmonics": [{"ratio": 1.5, "amplitude": 0.4}, {"ratio": 2, "amplitude": 0.3}]},
    {"id": "enemy_reach_base", "oscillator": {"type": "square", "frequency": 150},
     "envelope": {"attack_ms": 10, "decay_ms": 150, "sustain": 0.3, "release_ms": 100},
     "volume": 0.4, "duration_ms": 300,
     "filter": {"type": "lowpass", "cutoff_hz": 400, "resonance": 0.5}},
    {"id": "boss_roar", "oscillator": {"type": "sawtooth", "frequency": 80},
     "envelope": {"attack_ms": 50, "decay_ms": 200, "sustain": 0.6, "release_ms": 200},
     "volume": 0.5, "duration_ms": 600,
     "filter": {"type": "lowpass", "cutoff_hz": 300, "resonance": 0.6},
     "harmonics": [{"ratio": 1.5, "amplitude": 0.5}, {"ratio": 2, "amplitude": 0.3}]},
    {"id": "tower_build", "oscillator": {"type": "sine", "frequency": 500},
     "envelope": {"attack_ms": 10, "decay_ms": 100, "sustain": 0.3, "release_ms": 80},
     "volume": 0.35, "duration_ms": 200,
     "pitch_slide": {"start_offset": -100, "end_offset": 100, "curve": "linear"}},
    {"id": "tower_upgrade", "oscillator": {"type": "sine", "frequency": 700},
     "envelope": {"attack_ms": 5, "decay_ms": 80, "sustain": 0.4, "release_ms": 100},
     "volume": 0.35, "duration_ms": 250,
     "pitch_slide": {"start_offset": -200, "end_offset": 200, "curve": "exponential"},
     "harmonics": [{"ratio": 2, "amplitude": 0.2}]},
    {"id": "tower_sell", "oscillator": {"type": "sine", "frequency": 600},
     "envelope": {"attack_ms": 5, "decay_ms": 60, "sustain": 0.2, "release_ms": 60},
     "volume": 0.3, "duration_ms": 150,
     "pitch_slide": {"start_offset": 200, "end_offset": -200, "curve": "linear"}},
    {"id": "tower_shot", "oscillator": {"type": "noise", "frequency": 800},
     "envelope": {"attack_ms": 2, "decay_ms": 40, "sustain": 0.1, "release_ms": 30},
     "volume": 0.3, "duration_ms": 80,
     "filter": {"type": "highpass", "cutoff_hz": 600, "resonance": 0.3}},
    {"id": "wave_complete", "oscillator": {"type": "sine", "frequency": 800},
     "envelope": {"attack_ms": 10, "decay_ms": 100, "sustain": 0.4, "release_ms": 150},
     "volume": 0.4, "duration_ms": 350,
     "pitch_slide": {"start_offset": -200, "end_offset": 200, "curve": "exponential"},
     "harmonics": [{"ratio": 1.5, "amplitude": 0.3}]},
    {"id": "night_fall", "oscillator": {"type": "sine", "frequency": 300},
     "envelope": {"attack_ms": 50, "decay_ms": 200, "sustain": 0.3, "release_ms": 200},
     "volume": 0.35, "duration_ms": 500,
     "pitch_slide": {"start_offset": 100, "end_offset": -100, "curve": "linear"},
     "filter": {"type": "lowpass", "cutoff_hz": 800, "resonance": 0.2}},
    {"id": "dawn_break", "oscillator": {"type": "sine", "frequency": 600},
     "envelope": {"attack_ms": 50, "decay_ms": 200, "sustain": 0.3, "release_ms": 200},
     "volume": 0.35, "duration_ms": 500,
     "pitch_slide": {"start_offset": -100, "end_offset": 100, "curve": "linear"},
     "harmonics": [{"ratio": 2, "amplitude": 0.2}]},
    {"id": "gold_pickup", "oscillator": {"type": "sine", "frequency": 1000},
     "envelope": {"attack_ms": 2, "decay_ms": 40, "sustain": 0.2, "release_ms": 30},
     "volume": 0.3, "duration_ms": 80,
     "pitch_slide": {"start_offset": -200, "end_offset": 0, "curve": "exponential"}},
    {"id": "xp_gain", "oscillator": {"type": "sine", "frequency": 900},
     "envelope": {"attack_ms": 5, "decay_ms": 50, "sustain": 0.2, "release_ms": 40},
     "volume": 0.25, "duration_ms": 100,
     "pitch_slide": {"start_offset": -100, "end_offset": 100, "curve": "linear"}},
    {"id": "heal", "oscillator": {"type": "sine", "frequency": 700},
     "envelope": {"attack_ms": 20, "decay_ms": 100, "sustain": 0.3, "release_ms": 100},
     "volume": 0.3, "duration_ms": 250,
     "harmonics": [{"ratio": 2, "amplitude": 0.2}]},
    {"id": "status_apply", "oscillator": {"type": "square", "frequency": 500},
     "envelope": {"attack_ms": 5, "decay_ms": 60, "sustain": 0.2, "release_ms": 40},
     "volume": 0.25, "duration_ms": 120,
     "filter": {"type": "lowpass", "cutoff_hz": 1500, "resonance": 0.3}},
    {"id": "explore", "oscillator": {"type": "sine", "frequency": 550},
     "envelope": {"attack_ms": 10, "decay_ms": 80, "sustain": 0.3, "release_ms": 60},
     "volume": 0.3, "duration_ms": 180,
     "pitch_slide": {"start_offset": -50, "end_offset": 50, "curve": "linear"}},
    {"id": "build", "oscillator": {"type": "noise", "frequency": 400},
     "envelope": {"attack_ms": 5, "decay_ms": 60, "sustain": 0.2, "release_ms": 40},
     "volume": 0.3, "duration_ms": 120,
     "filter": {"type": "lowpass", "cutoff_hz": 1000, "resonance": 0.2}},
    {"id": "gather", "oscillator": {"type": "sine", "frequency": 800},
     "envelope": {"attack_ms": 2, "decay_ms": 30, "sustain": 0.1, "release_ms": 20},
     "volume": 0.25, "duration_ms": 60},
    {"id": "shield_block", "oscillator": {"type": "noise", "frequency": 600},
     "envelope": {"attack_ms": 2, "decay_ms": 80, "sustain": 0.2, "release_ms": 40},
     "volume": 0.35, "duration_ms": 150,
     "filter": {"type": "bandpass", "cutoff_hz": 800, "resonance": 0.4}},
    {"id": "miss_whiff", "oscillator": {"type": "noise", "frequency": 300},
     "envelope": {"attack_ms": 5, "decay_ms": 40, "sustain": 0, "release_ms": 30},
     "volume": 0.2, "duration_ms": 80,
     "filter": {"type": "highpass", "cutoff_hz": 400, "resonance": 0.2}},
    {"id": "loot_drop", "oscillator": {"type": "sine", "frequency": 1100},
     "envelope": {"attack_ms": 2, "decay_ms": 50, "sustain": 0.3, "release_ms": 60},
     "volume": 0.3, "duration_ms": 130,
     "pitch_slide": {"start_offset": 200, "end_offset": -100, "curve": "exponential"}},
    {"id": "quest_complete", "oscillator": {"type": "sine", "frequency": 900},
     "envelope": {"attack_ms": 10, "decay_ms": 120, "sustain": 0.4, "release_ms": 120},
     "volume": 0.4, "duration_ms": 300,
     "pitch_slide": {"start_offset": -200, "end_offset": 200, "curve": "exponential"},
     "harmonics": [{"ratio": 1.5, "amplitude": 0.3}, {"ratio": 2, "amplitude": 0.2}]},
    {"id": "research_complete", "oscillator": {"type": "sine", "frequency": 800},
     "envelope": {"attack_ms": 10, "decay_ms": 100, "sustain": 0.3, "release_ms": 100},
     "volume": 0.35, "duration_ms": 250,
     "pitch_slide": {"start_offset": -100, "end_offset": 150, "curve": "exponential"},
     "harmonics": [{"ratio": 2, "amplitude": 0.2}]},
    {"id": "title_unlock", "oscillator": {"type": "sine", "frequency": 1000},
     "envelope": {"attack_ms": 5, "decay_ms": 80, "sustain": 0.4, "release_ms": 100},
     "volume": 0.35, "duration_ms": 220,
     "pitch_slide": {"start_offset": -150, "end_offset": 150, "curve": "exponential"}},
    {"id": "victory", "oscillator": {"type": "sine", "frequency": 800},
     "envelope": {"attack_ms": 20, "decay_ms": 200, "sustain": 0.5, "release_ms": 300},
     "volume": 0.45, "duration_ms": 600,
     "pitch_slide": {"start_offset": -200, "end_offset": 300, "curve": "exponential"},
     "harmonics": [{"ratio": 1.5, "amplitude": 0.4}, {"ratio": 2, "amplitude": 0.3}, {"ratio": 3, "amplitude": 0.15}]},
    {"id": "defeat", "oscillator": {"type": "sawtooth", "frequency": 200},
     "envelope": {"attack_ms": 30, "decay_ms": 300, "sustain": 0.2, "release_ms": 200},
     "volume": 0.4, "duration_ms": 600,
     "pitch_slide": {"start_offset": 100, "end_offset": -150, "curve": "linear"},
     "filter": {"type": "lowpass", "cutoff_hz": 500, "resonance": 0.4}},
]


def main():
    monogame_root = Path(__file__).parent.parent
    presets_path = monogame_root / "data" / "audio" / "sfx_presets.json"
    output_dir = monogame_root / "Content" / "Audio" / "sfx"

    # Load presets
    with open(presets_path) as f:
        data = json.load(f)

    all_presets = data["presets"] + EXTRA_PRESETS

    # Deduplicate by ID (extras override if ID matches)
    preset_map = {}
    for p in all_presets:
        preset_map[p["id"]] = p

    output_dir.mkdir(parents=True, exist_ok=True)
    generated = 0

    print(f"Generating {len(preset_map)} SFX from presets...")
    for preset_id, preset in sorted(preset_map.items()):
        pcm = synthesize_preset(preset)
        if len(pcm) == 0:
            print(f"  SKIP {preset_id} (empty)")
            continue

        filepath = output_dir / f"{preset_id}.wav"
        write_wav(filepath, pcm)
        duration = len(pcm) / SAMPLE_RATE * 1000
        print(f"  {preset_id}.wav ({duration:.0f}ms)")
        generated += 1

    # Write manifest
    manifest = {
        "version": "1.0.0",
        "sample_rate": SAMPLE_RATE,
        "bit_depth": BIT_DEPTH,
        "channels": 1,
        "sfx": [
            {"id": pid, "path": f"sfx/{pid}.wav"}
            for pid in sorted(preset_map.keys())
        ],
    }
    manifest_path = output_dir.parent / "audio_manifest.json"
    with open(manifest_path, "w") as f:
        json.dump(manifest, f, indent=2)

    print(f"\nDone: {generated} SFX generated")
    print(f"Output: {output_dir}")
    print(f"Manifest: {manifest_path}")


if __name__ == "__main__":
    main()
