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
    public static HitPause Instance => _instance ??= new();

    public const float PresetMicro = 0.02f;
    public const float PresetLight = 0.05f;
    public const float PresetMedium = 0.10f;
    public const float PresetHeavy = 0.18f;
    public const float PresetExtreme = 0.30f;

    private const float MinDuration = 0.01f;
    private const float MaxDuration = 0.5f;

    private float _remaining;

    public event Action<float>? PauseStarted;
    public event Action? PauseEnded;

    public bool IsPausing => _remaining > 0f;
    public float RemainingTime => _remaining;

    /// <summary>
    /// Returns the time scale factor. 0 when paused, 1 when normal.
    /// Use this to scale game delta time.
    /// </summary>
    public float TimeScale => IsPausing ? 0f : 1f;

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

    public void PauseMicro() => Pause(PresetMicro);
    public void PauseLight() => Pause(PresetLight);
    public void PauseMedium() => Pause(PresetMedium);
    public void PauseHeavy() => Pause(PresetHeavy);
    public void PauseExtreme() => Pause(PresetExtreme);

    public void Cancel()
    {
        if (_remaining > 0f)
        {
            _remaining = 0f;
            PauseEnded?.Invoke();
        }
    }

    public void Reset()
    {
        _remaining = 0f;
    }

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
