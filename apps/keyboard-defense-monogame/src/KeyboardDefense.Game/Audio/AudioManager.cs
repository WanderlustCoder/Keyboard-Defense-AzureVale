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
    /// <summary>
    /// Identifiers for one-shot sound effects used throughout gameplay and UI flows.
    /// </summary>
    public enum Sfx
    {
        /// <summary>
        /// UI key tap feedback.
        /// </summary>
        UiKeytap,
        /// <summary>
        /// UI confirm action feedback.
        /// </summary>
        UiConfirm,
        /// <summary>
        /// UI cancel action feedback.
        /// </summary>
        UiCancel,
        /// <summary>
        /// UI hover feedback.
        /// </summary>
        UiHover,
        /// <summary>
        /// UI error feedback.
        /// </summary>
        UiError,
        /// <summary>
        /// UI open transition feedback.
        /// </summary>
        UiOpen,
        /// <summary>
        /// UI close transition feedback.
        /// </summary>
        UiClose,
        /// <summary>
        /// Correct typing input feedback.
        /// </summary>
        TypeCorrect,
        /// <summary>
        /// Incorrect typing input feedback.
        /// </summary>
        TypeWrong,
        /// <summary>
        /// Backspace typing feedback.
        /// </summary>
        TypeBackspace,
        /// <summary>
        /// Word completion feedback.
        /// </summary>
        WordComplete,
        /// <summary>
        /// Perfect word completion feedback.
        /// </summary>
        WordPerfect,
        /// <summary>
        /// Failed word attempt feedback.
        /// </summary>
        WordFailed,
        /// <summary>
        /// Combo increase feedback.
        /// </summary>
        ComboUp,
        /// <summary>
        /// Combo break feedback.
        /// </summary>
        ComboBreak,
        /// <summary>
        /// Maximum combo feedback.
        /// </summary>
        ComboMax,
        /// <summary>
        /// Enemy hit impact feedback.
        /// </summary>
        EnemyHit,
        /// <summary>
        /// Enemy death feedback.
        /// </summary>
        EnemyDeath,
        /// <summary>
        /// Enemy spawn feedback.
        /// </summary>
        EnemySpawn,
        /// <summary>
        /// Enemy reached base warning feedback.
        /// </summary>
        EnemyReachBase,
        /// <summary>
        /// Boss appearance feedback.
        /// </summary>
        BossAppear,
        /// <summary>
        /// Boss roar feedback.
        /// </summary>
        BossRoar,
        /// <summary>
        /// Boss defeat feedback.
        /// </summary>
        BossDefeat,
        /// <summary>
        /// Tower attack shot feedback.
        /// </summary>
        TowerShot,
        /// <summary>
        /// Tower build placement feedback.
        /// </summary>
        TowerBuild,
        /// <summary>
        /// Tower upgrade feedback.
        /// </summary>
        TowerUpgrade,
        /// <summary>
        /// Tower sell feedback.
        /// </summary>
        TowerSell,
        /// <summary>
        /// Wave start feedback.
        /// </summary>
        WaveStart,
        /// <summary>
        /// Wave completion feedback.
        /// </summary>
        WaveComplete,
        /// <summary>
        /// Nightfall transition feedback.
        /// </summary>
        NightFall,
        /// <summary>
        /// Dawn transition feedback.
        /// </summary>
        DawnBreak,
        /// <summary>
        /// Gold pickup feedback.
        /// </summary>
        GoldPickup,
        /// <summary>
        /// Experience gain feedback.
        /// </summary>
        XpGain,
        /// <summary>
        /// Level-up feedback.
        /// </summary>
        LevelUp,
        /// <summary>
        /// Healing feedback.
        /// </summary>
        Heal,
        /// <summary>
        /// Critical-hit feedback.
        /// </summary>
        CriticalHit,
        /// <summary>
        /// Status effect application feedback.
        /// </summary>
        StatusApply,
        /// <summary>
        /// Status effect expiration feedback.
        /// </summary>
        StatusExpire,
        /// <summary>
        /// Exploration action feedback.
        /// </summary>
        Explore,
        /// <summary>
        /// Build action feedback.
        /// </summary>
        Build,
        /// <summary>
        /// Gather action feedback.
        /// </summary>
        Gather,
        /// <summary>
        /// Victory feedback.
        /// </summary>
        Victory,
        /// <summary>
        /// Defeat feedback.
        /// </summary>
        Defeat,
        /// <summary>
        /// Shield block feedback.
        /// </summary>
        ShieldBlock,
        /// <summary>
        /// Missed attack whiff feedback.
        /// </summary>
        MissWhiff,
        /// <summary>
        /// Loot drop feedback.
        /// </summary>
        LootDrop,
        /// <summary>
        /// Quest completion feedback.
        /// </summary>
        QuestComplete,
        /// <summary>
        /// Research completion feedback.
        /// </summary>
        ResearchComplete,
        /// <summary>
        /// Achievement unlock feedback.
        /// </summary>
        AchievementUnlock,
        /// <summary>
        /// Title unlock feedback.
        /// </summary>
        TitleUnlock,
    }

    /// <summary>
    /// Identifiers for background music selections managed by the audio runtime.
    /// </summary>
    public enum MusicTrack
    {
        /// <summary>
        /// No music track.
        /// </summary>
        None,
        /// <summary>
        /// Main menu music.
        /// </summary>
        Menu,
        /// <summary>
        /// Calm exploration or daytime loop.
        /// </summary>
        Calm,
        /// <summary>
        /// Standard battle loop.
        /// </summary>
        Battle,
        /// <summary>
        /// High-intensity battle loop.
        /// </summary>
        BattleTense,
        /// <summary>
        /// Boss encounter loop.
        /// </summary>
        Boss,
        /// <summary>
        /// Victory music cue.
        /// </summary>
        Victory
    }

    private static AudioManager? _instance;
    /// <summary>
    /// Gets the shared audio manager singleton instance, creating it on first access.
    /// </summary>
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

    /// <summary>
    /// Gets or sets the master sound-effect volume in the range [0, 1].
    /// </summary>
    public float SfxVolume
    {
        get => _sfxVolume;
        set => _sfxVolume = MathHelper.Clamp(value, 0f, 1f);
    }

    /// <summary>
    /// Gets or sets the master music volume in the range [0, 1], then applies it to active playback.
    /// </summary>
    public float MusicVolume
    {
        get => _musicVolume;
        set
        {
            _musicVolume = MathHelper.Clamp(value, 0f, 1f);
            ApplyMusicVolume();
        }
    }

    /// <summary>
    /// Gets or sets a value indicating whether all audio output is muted.
    /// </summary>
    public bool Muted
    {
        get => _muted;
        set
        {
            _muted = value;
            MediaPlayer.IsMuted = value;
        }
    }

    /// <summary>
    /// Plays a registered sound effect with optional per-call volume adjustment.
    /// </summary>
    /// <param name="sfx">The sound effect identifier to play.</param>
    /// <param name="volumeOffset">A volume offset added to the master SFX volume before clamping.</param>
    /// <remarks>
    /// Calls are rate-limited per effect to prevent rapid retrigger spam.
    /// </remarks>
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

    /// <summary>
    /// Plays a registered sound effect with custom pitch and optional volume adjustment.
    /// </summary>
    /// <param name="sfx">The sound effect identifier to play.</param>
    /// <param name="pitch">Pitch shift in the range [-1, 1].</param>
    /// <param name="volumeOffset">A volume offset added to the master SFX volume before clamping.</param>
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

    /// <summary>
    /// Starts playback of the requested music track, replacing any currently playing track.
    /// </summary>
    /// <param name="track">The music track to play, or <see cref="MusicTrack.None"/> to stop playback.</param>
    /// <remarks>
    /// WAV-backed <see cref="SoundEffect"/> music is preferred; <see cref="Song"/> playback is used as fallback.
    /// </remarks>
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

    /// <summary>
    /// Stops all active music playback and clears the current track selection.
    /// </summary>
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

    /// <summary>
    /// Enables music ducking so background audio is reduced for moment-to-moment clarity.
    /// </summary>
    public void StartDucking()
    {
        _duckingActive = true;
        _duckFactor = 0.3f;
        ApplyMusicVolume();
    }

    /// <summary>
    /// Disables music ducking and restores full background music volume.
    /// </summary>
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

    /// <summary>
    /// Registers a sound effect instance for later playback by ID.
    /// </summary>
    /// <param name="sfx">The identifier used by playback calls.</param>
    /// <param name="effect">The sound effect asset to cache.</param>
    public void RegisterSfx(Sfx sfx, SoundEffect effect)
    {
        _sfxCache[sfx] = effect;
    }

    /// <summary>
    /// Registers a song asset for a music track fallback path.
    /// </summary>
    /// <param name="track">The music track identifier to register.</param>
    /// <param name="song">The song asset to cache.</param>
    public void RegisterMusic(MusicTrack track, Song song)
    {
        _musicCache[track] = song;
    }

    /// <summary>
    /// Registers a WAV-backed music effect for looped track playback.
    /// </summary>
    /// <param name="track">The music track identifier to register.</param>
    /// <param name="effect">The sound effect asset used as looped music.</param>
    public void RegisterMusicEffect(MusicTrack track, SoundEffect effect)
    {
        _musicEffectCache[track] = effect;
    }

    /// <summary>
    /// Advances audio runtime state, including smooth ducking transitions over time.
    /// </summary>
    /// <param name="gameTime">Frame timing used to interpolate ducking changes.</param>
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
    /// <summary>
    /// Plays the UI confirm sound effect.
    /// </summary>
    public void PlayUiConfirm() => PlaySfx(Sfx.UiConfirm);
    /// <summary>
    /// Plays the UI cancel sound effect.
    /// </summary>
    public void PlayUiCancel() => PlaySfx(Sfx.UiCancel);
    /// <summary>
    /// Plays the UI hover sound effect at slightly reduced volume.
    /// </summary>
    public void PlayUiHover() => PlaySfx(Sfx.UiHover, -0.2f);
    /// <summary>
    /// Plays the UI error sound effect.
    /// </summary>
    public void PlayUiError() => PlaySfx(Sfx.UiError);
    /// <summary>
    /// Plays the typing-correct sound effect.
    /// </summary>
    public void PlayTypeCorrect() => PlaySfx(Sfx.TypeCorrect);
    /// <summary>
    /// Plays the typing-wrong sound effect.
    /// </summary>
    public void PlayTypeWrong() => PlaySfx(Sfx.TypeWrong);
    /// <summary>
    /// Plays the word-complete sound effect.
    /// </summary>
    public void PlayWordComplete() => PlaySfx(Sfx.WordComplete);
    /// <summary>
    /// Plays the combo-increase sound effect.
    /// </summary>
    public void PlayComboUp() => PlaySfx(Sfx.ComboUp);
    /// <summary>
    /// Plays the critical-hit sound effect.
    /// </summary>
    public void PlayCriticalHit() => PlaySfx(Sfx.CriticalHit);
    /// <summary>
    /// Plays the enemy-death sound effect.
    /// </summary>
    public void PlayEnemyDeath() => PlaySfx(Sfx.EnemyDeath);
    /// <summary>
    /// Plays the victory sound effect.
    /// </summary>
    public void PlayVictory() => PlaySfx(Sfx.Victory);
    /// <summary>
    /// Plays the defeat sound effect.
    /// </summary>
    public void PlayDefeat() => PlaySfx(Sfx.Defeat);
}
