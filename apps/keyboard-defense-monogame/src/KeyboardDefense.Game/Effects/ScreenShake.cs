using System;
using Microsoft.Xna.Framework;
using KeyboardDefense.Game.Services;

namespace KeyboardDefense.Game.Effects;

/// <summary>
/// Camera shake system using trauma-based approach.
/// Ported from game/screen_shake.gd (171 lines).
/// Respects ReducedMotion and ScreenShake settings from SettingsManager.
/// </summary>
public class ScreenShake
{
    private static ScreenShake? _instance;
    public static ScreenShake Instance => _instance ??= new();

    public const float PresetLight = 0.2f;
    public const float PresetMedium = 0.4f;
    public const float PresetHeavy = 0.7f;
    public const float PresetExtreme = 1.0f;

    private const float MaxOffset = 16f;
    private const float MaxRotation = 0.05f;
    private const float DecayRate = 2.0f;
    private const float TraumaPower = 2.0f;

    private float _trauma;
    private float _noiseTime;
    private readonly Random _rng = new();

    public event Action<float>? TraumaChanged;

    public float Trauma => _trauma;
    public bool IsShaking => _trauma > 0.001f;

    public Vector2 Offset { get; private set; }
    public float Rotation { get; private set; }

    public void AddTrauma(float amount)
    {
        // Skip if reduced motion or screen shake disabled
        var sm = KeyboardDefenseGame.Instance?.SettingsManager;
        if (sm != null && (sm.ReducedMotion || !sm.ScreenShake))
            return;

        float prev = _trauma;
        _trauma = MathHelper.Clamp(_trauma + amount, 0f, 1f);
        if (Math.Abs(_trauma - prev) > 0.001f)
            TraumaChanged?.Invoke(_trauma);
    }

    public void SetTrauma(float amount)
    {
        _trauma = MathHelper.Clamp(amount, 0f, 1f);
        TraumaChanged?.Invoke(_trauma);
    }

    public void ShakeLight() => AddTrauma(PresetLight);
    public void ShakeMedium() => AddTrauma(PresetMedium);
    public void ShakeHeavy() => AddTrauma(PresetHeavy);
    public void ShakeExtreme() => AddTrauma(PresetExtreme);

    public void Reset()
    {
        _trauma = 0f;
        _noiseTime = 0f;
        Offset = Vector2.Zero;
        Rotation = 0f;
    }

    public void Update(GameTime gameTime)
    {
        if (_trauma <= 0f)
        {
            Offset = Vector2.Zero;
            Rotation = 0f;
            return;
        }

        float dt = (float)gameTime.ElapsedGameTime.TotalSeconds;
        _noiseTime += dt;

        float shake = MathF.Pow(_trauma, TraumaPower);

        float noiseX = (float)(_rng.NextDouble() * 2 - 1);
        float noiseY = (float)(_rng.NextDouble() * 2 - 1);
        float noiseR = (float)(_rng.NextDouble() * 2 - 1);

        Offset = new Vector2(
            MaxOffset * shake * noiseX,
            MaxOffset * shake * noiseY);
        Rotation = MaxRotation * shake * noiseR;

        _trauma = MathHelper.Clamp(_trauma - DecayRate * dt, 0f, 1f);
    }
}
