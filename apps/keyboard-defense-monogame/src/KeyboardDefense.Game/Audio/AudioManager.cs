using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Audio;
using Microsoft.Xna.Framework.Media;

namespace KeyboardDefense.Game.Audio;

/// <summary>
/// Central audio system for SFX and music playback.
/// Ported from game/audio_manager.gd (773 lines).
/// </summary>
public class AudioManager
{
    public enum Sfx
    {
        UiKeytap, UiConfirm, UiCancel, UiHover, UiError, UiOpen, UiClose,
        TypeCorrect, TypeWrong, TypeBackspace,
        WordComplete, WordPerfect, WordFailed,
        ComboUp, ComboBreak, ComboMax,
        EnemyHit, EnemyDeath, EnemySpawn, EnemyReachBase,
        BossAppear, BossRoar, BossDefeat,
        TowerShot, TowerBuild, TowerUpgrade, TowerSell,
        WaveStart, WaveComplete, NightFall, DawnBreak,
        GoldPickup, XpGain, LevelUp, Heal,
        CriticalHit, StatusApply, StatusExpire,
        Explore, Build, Gather, Victory, Defeat,
        ShieldBlock, MissWhiff, LootDrop, QuestComplete,
        ResearchComplete, AchievementUnlock, TitleUnlock,
    }

    public enum MusicTrack
    {
        None, Menu, Calm, Battle, BattleTense, Boss, Victory
    }

    private static AudioManager? _instance;
    public static AudioManager Instance => _instance ??= new();

    private readonly Dictionary<Sfx, SoundEffect?> _sfxCache = new();
    private readonly Dictionary<MusicTrack, Song?> _musicCache = new();
    private readonly Dictionary<MusicTrack, SoundEffect?> _musicEffectCache = new();
    private readonly Dictionary<Sfx, double> _lastPlayTime = new();
    private SoundEffectInstance? _musicInstance;

    private MusicTrack _currentTrack = MusicTrack.None;
    private float _sfxVolume = 0.7f;
    private float _musicVolume = 0.5f;
    private bool _muted;
    private bool _duckingActive;
    private float _duckFactor = 1.0f;

    private const double RateLimitMs = 50.0;

    public float SfxVolume
    {
        get => _sfxVolume;
        set => _sfxVolume = MathHelper.Clamp(value, 0f, 1f);
    }

    public float MusicVolume
    {
        get => _musicVolume;
        set
        {
            _musicVolume = MathHelper.Clamp(value, 0f, 1f);
            ApplyMusicVolume();
        }
    }

    public bool Muted
    {
        get => _muted;
        set
        {
            _muted = value;
            MediaPlayer.IsMuted = value;
        }
    }

    public void PlaySfx(Sfx sfx, float volumeOffset = 0f)
    {
        if (_muted) return;

        double now = Environment.TickCount64;
        if (_lastPlayTime.TryGetValue(sfx, out double lastTime) && (now - lastTime) < RateLimitMs)
            return;
        _lastPlayTime[sfx] = now;

        if (_sfxCache.TryGetValue(sfx, out var effect) && effect != null)
        {
            float vol = MathHelper.Clamp(_sfxVolume + volumeOffset, 0f, 1f);
            effect.Play(vol, 0f, 0f);
        }
    }

    public void PlaySfxPitched(Sfx sfx, float pitch, float volumeOffset = 0f)
    {
        if (_muted) return;

        if (_sfxCache.TryGetValue(sfx, out var effect) && effect != null)
        {
            float vol = MathHelper.Clamp(_sfxVolume + volumeOffset, 0f, 1f);
            float p = MathHelper.Clamp(pitch, -1f, 1f);
            effect.Play(vol, p, 0f);
        }
    }

    public void PlayMusic(MusicTrack track)
    {
        if (track == _currentTrack) return;
        _currentTrack = track;

        if (track == MusicTrack.None)
        {
            StopMusicPlayback();
            return;
        }

        // Try SoundEffect-based music first (from WAV files)
        if (_musicEffectCache.TryGetValue(track, out var effect) && effect != null)
        {
            StopMusicPlayback();
            _musicInstance = effect.CreateInstance();
            _musicInstance.IsLooped = true;
            _musicInstance.Volume = _musicVolume * _duckFactor;
            _musicInstance.Play();
            return;
        }

        // Fallback to Song/MediaPlayer
        if (_musicCache.TryGetValue(track, out var song) && song != null)
        {
            StopMusicPlayback();
            MediaPlayer.Volume = _musicVolume * _duckFactor;
            MediaPlayer.IsRepeating = true;
            MediaPlayer.Play(song);
        }
    }

    public void StopMusic()
    {
        _currentTrack = MusicTrack.None;
        StopMusicPlayback();
    }

    private void StopMusicPlayback()
    {
        if (_musicInstance != null)
        {
            _musicInstance.Stop();
            _musicInstance.Dispose();
            _musicInstance = null;
        }
        MediaPlayer.Stop();
    }

    public void StartDucking()
    {
        _duckingActive = true;
        _duckFactor = 0.3f;
        ApplyMusicVolume();
    }

    public void StopDucking()
    {
        _duckingActive = false;
        _duckFactor = 1.0f;
        ApplyMusicVolume();
    }

    private void ApplyMusicVolume()
    {
        float vol = _musicVolume * _duckFactor;
        MediaPlayer.Volume = vol;
        if (_musicInstance != null)
            _musicInstance.Volume = vol;
    }

    public void RegisterSfx(Sfx sfx, SoundEffect effect)
    {
        _sfxCache[sfx] = effect;
    }

    public void RegisterMusic(MusicTrack track, Song song)
    {
        _musicCache[track] = song;
    }

    public void RegisterMusicEffect(MusicTrack track, SoundEffect effect)
    {
        _musicEffectCache[track] = effect;
    }

    public void Update(GameTime gameTime)
    {
        if (_duckingActive && _duckFactor < 0.3f)
        {
            _duckFactor = MathHelper.Lerp(_duckFactor, 0.3f, (float)gameTime.ElapsedGameTime.TotalSeconds * 5f);
            ApplyMusicVolume();
        }
        else if (!_duckingActive && _duckFactor < 1.0f)
        {
            _duckFactor = MathHelper.Lerp(_duckFactor, 1.0f, (float)gameTime.ElapsedGameTime.TotalSeconds * 3f);
            ApplyMusicVolume();
        }
    }

    // Convenience methods
    public void PlayUiConfirm() => PlaySfx(Sfx.UiConfirm);
    public void PlayUiCancel() => PlaySfx(Sfx.UiCancel);
    public void PlayUiHover() => PlaySfx(Sfx.UiHover, -0.2f);
    public void PlayUiError() => PlaySfx(Sfx.UiError);
    public void PlayTypeCorrect() => PlaySfx(Sfx.TypeCorrect);
    public void PlayTypeWrong() => PlaySfx(Sfx.TypeWrong);
    public void PlayWordComplete() => PlaySfx(Sfx.WordComplete);
    public void PlayComboUp() => PlaySfx(Sfx.ComboUp);
    public void PlayCriticalHit() => PlaySfx(Sfx.CriticalHit);
    public void PlayEnemyDeath() => PlaySfx(Sfx.EnemyDeath);
    public void PlayVictory() => PlaySfx(Sfx.Victory);
    public void PlayDefeat() => PlaySfx(Sfx.Defeat);
}
