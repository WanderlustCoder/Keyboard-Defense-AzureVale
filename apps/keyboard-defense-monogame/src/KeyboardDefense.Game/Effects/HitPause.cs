using System;
using Microsoft.Xna.Framework;
using KeyboardDefense.Game.Services;

namespace KeyboardDefense.Game.Effects;

/// <summary>
/// Hit pause (freeze frame) effect for combat feedback.
/// Ported from game/hit_pause.gd (164 lines).
/// </summary>
public class HitPause
{
    private static HitPause? _instance;

    /// <summary>
    /// Gets the singleton hit pause controller instance.
    /// </summary>
    public static HitPause Instance => _instance ??= new();

    /// <summary>
    /// Micro pause preset duration in seconds.
    /// </summary>
    public const float PresetMicro = 0.02f;

    /// <summary>
    /// Light pause preset duration in seconds.
    /// </summary>
    public const float PresetLight = 0.05f;

    /// <summary>
    /// Medium pause preset duration in seconds.
    /// </summary>
    public const float PresetMedium = 0.10f;

    /// <summary>
    /// Heavy pause preset duration in seconds.
    /// </summary>
    public const float PresetHeavy = 0.18f;

    /// <summary>
    /// Extreme pause preset duration in seconds.
    /// </summary>
    public const float PresetExtreme = 0.30f;

    private const float MinDuration = 0.01f;
    private const float MaxDuration = 0.5f;

    private float _remaining;

    /// <summary>
    /// Occurs when a pause starts or extends to a longer duration.
    /// </summary>
    public event Action<float>? PauseStarted;

    /// <summary>
    /// Occurs when the active pause ends.
    /// </summary>
    public event Action? PauseEnded;

    /// <summary>
    /// Gets a value indicating whether hit pause is currently active.
    /// </summary>
    public bool IsPausing => _remaining > 0f;

    /// <summary>
    /// Gets the remaining paused time in seconds.
    /// </summary>
    public float RemainingTime => _remaining;

    /// <summary>
    /// Returns the time scale factor. 0 when paused, 1 when normal.
    /// Use this to scale game delta time.
    /// </summary>
    public float TimeScale => IsPausing ? 0f : 1f;

    /// <summary>
    /// Starts a hit pause using a duration clamped to the configured minimum and maximum.
    /// </summary>
    /// <param name="duration">Requested pause duration in seconds.</param>
    public void Pause(float duration)
    {
        // Skip if reduced motion is enabled
        var sm = KeyboardDefenseGame.Instance?.SettingsManager;
        if (sm != null && sm.ReducedMotion)
            return;

        float clamped = MathHelper.Clamp(duration, MinDuration, MaxDuration);
        if (clamped > _remaining)
        {
            _remaining = clamped;
            PauseStarted?.Invoke(clamped);
        }
    }

    /// <summary>
    /// Starts hit pause using the micro preset duration.
    /// </summary>
    public void PauseMicro() => Pause(PresetMicro);

    /// <summary>
    /// Starts hit pause using the light preset duration.
    /// </summary>
    public void PauseLight() => Pause(PresetLight);

    /// <summary>
    /// Starts hit pause using the medium preset duration.
    /// </summary>
    public void PauseMedium() => Pause(PresetMedium);

    /// <summary>
    /// Starts hit pause using the heavy preset duration.
    /// </summary>
    public void PauseHeavy() => Pause(PresetHeavy);

    /// <summary>
    /// Starts hit pause using the extreme preset duration.
    /// </summary>
    public void PauseExtreme() => Pause(PresetExtreme);

    /// <summary>
    /// Ends an active pause immediately.
    /// </summary>
    public void Cancel()
    {
        if (_remaining > 0f)
        {
            _remaining = 0f;
            PauseEnded?.Invoke();
        }
    }

    /// <summary>
    /// Clears pause state without raising events.
    /// </summary>
    public void Reset()
    {
        _remaining = 0f;
    }

    /// <summary>
    /// Advances pause timing and ends pause when remaining time reaches zero.
    /// </summary>
    /// <param name="gameTime">Frame timing information used to decrement remaining pause time.</param>
    public void Update(GameTime gameTime)
    {
        if (_remaining <= 0f) return;

        float dt = (float)gameTime.ElapsedGameTime.TotalSeconds;
        _remaining -= dt;

        if (_remaining <= 0f)
        {
            _remaining = 0f;
            PauseEnded?.Invoke();
        }
    }
}
