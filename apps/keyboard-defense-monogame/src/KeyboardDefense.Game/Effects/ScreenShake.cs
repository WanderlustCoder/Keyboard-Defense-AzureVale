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

    /// <summary>
    /// Gets the singleton screen shake controller instance.
    /// </summary>
    public static ScreenShake Instance => _instance ??= new();

    /// <summary>
    /// Light trauma preset for subtle impact feedback.
    /// </summary>
    public const float PresetLight = 0.2f;

    /// <summary>
    /// Medium trauma preset for standard impact feedback.
    /// </summary>
    public const float PresetMedium = 0.4f;

    /// <summary>
    /// Heavy trauma preset for strong impact feedback.
    /// </summary>
    public const float PresetHeavy = 0.7f;

    /// <summary>
    /// Extreme trauma preset for maximum impact feedback.
    /// </summary>
    public const float PresetExtreme = 1.0f;

    private const float MaxOffset = 16f;
    private const float MaxRotation = 0.05f;
    private const float DecayRate = 2.0f;
    private const float TraumaPower = 2.0f;

    private float _trauma;
    private float _noiseTime;
    private readonly Random _rng = new();

    /// <summary>
    /// Occurs when the trauma amount changes.
    /// </summary>
    public event Action<float>? TraumaChanged;

    /// <summary>
    /// Gets the current trauma value in the range 0 to 1.
    /// </summary>
    public float Trauma => _trauma;

    /// <summary>
    /// Gets a value indicating whether shake output is currently active.
    /// </summary>
    public bool IsShaking => _trauma > 0.001f;

    /// <summary>
    /// Gets the current per-frame camera offset produced by shake.
    /// </summary>
    public Vector2 Offset { get; private set; }

    /// <summary>
    /// Gets the current per-frame camera rotation produced by shake.
    /// </summary>
    public float Rotation { get; private set; }

    /// <summary>
    /// Adds trauma to the shake system, clamped to the range 0 to 1.
    /// </summary>
    /// <param name="amount">Trauma amount to add.</param>
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

    /// <summary>
    /// Sets trauma directly, overriding the current value.
    /// </summary>
    /// <param name="amount">Target trauma amount clamped to the range 0 to 1.</param>
    public void SetTrauma(float amount)
    {
        _trauma = MathHelper.Clamp(amount, 0f, 1f);
        TraumaChanged?.Invoke(_trauma);
    }

    /// <summary>
    /// Applies the light trauma preset.
    /// </summary>
    public void ShakeLight() => AddTrauma(PresetLight);

    /// <summary>
    /// Applies the medium trauma preset.
    /// </summary>
    public void ShakeMedium() => AddTrauma(PresetMedium);

    /// <summary>
    /// Applies the heavy trauma preset.
    /// </summary>
    public void ShakeHeavy() => AddTrauma(PresetHeavy);

    /// <summary>
    /// Applies the extreme trauma preset.
    /// </summary>
    public void ShakeExtreme() => AddTrauma(PresetExtreme);

    /// <summary>
    /// Clears trauma and resets all shake outputs to neutral values.
    /// </summary>
    public void Reset()
    {
        _trauma = 0f;
        _noiseTime = 0f;
        Offset = Vector2.Zero;
        Rotation = 0f;
    }

    /// <summary>
    /// Advances shake simulation, generating random offset/rotation and decaying trauma over time.
    /// </summary>
    /// <param name="gameTime">Frame timing information used for decay and time accumulation.</param>
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
