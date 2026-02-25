using System;
using Microsoft.Xna.Framework;

namespace KeyboardDefense.Game.UI;

/// <summary>
/// UI animation/tweening utilities for panel transitions.
/// Replaces Godot Tween system with manual interpolation.
/// Ported from ui/transitions.gd.
/// </summary>
public static class Transitions
{
    // Easing functions
    /// <summary>
    /// Applies linear easing and returns the input progress unchanged.
    /// </summary>
    /// <param name="t">Normalized progress from 0 to 1.</param>
    /// <returns>The same normalized progress value.</returns>
    public static float Linear(float t) => t;

    /// <summary>
    /// Applies quadratic ease-in so motion starts slowly and accelerates.
    /// </summary>
    /// <param name="t">Normalized progress from 0 to 1.</param>
    /// <returns>Eased progress value.</returns>
    public static float EaseIn(float t) => t * t;

    /// <summary>
    /// Applies quadratic ease-out so motion starts quickly and decelerates.
    /// </summary>
    /// <param name="t">Normalized progress from 0 to 1.</param>
    /// <returns>Eased progress value.</returns>
    public static float EaseOut(float t) => 1f - (1f - t) * (1f - t);

    /// <summary>
    /// Applies quadratic ease-in-out with acceleration in the first half and deceleration in the second half.
    /// </summary>
    /// <param name="t">Normalized progress from 0 to 1.</param>
    /// <returns>Eased progress value.</returns>
    public static float EaseInOut(float t) => t < 0.5f ? 2f * t * t : 1f - MathF.Pow(-2f * t + 2f, 2f) / 2f;

    /// <summary>
    /// Applies a back ease-out curve that slightly overshoots before settling at the end value.
    /// </summary>
    /// <param name="t">Normalized progress from 0 to 1.</param>
    /// <returns>Eased progress value with end overshoot.</returns>
    public static float EaseOutBack(float t)
    {
        const float c1 = 1.70158f;
        const float c3 = c1 + 1f;
        return 1f + c3 * MathF.Pow(t - 1f, 3f) + c1 * MathF.Pow(t - 1f, 2f);
    }

    /// <summary>
    /// Applies an elastic ease-out curve with damped oscillation near the end.
    /// </summary>
    /// <param name="t">Normalized progress from 0 to 1.</param>
    /// <returns>Eased progress value with spring-like recoil.</returns>
    public static float EaseOutElastic(float t)
    {
        if (t <= 0f) return 0f;
        if (t >= 1f) return 1f;
        return MathF.Pow(2f, -10f * t) * MathF.Sin((t * 10f - 0.75f) * (2f * MathF.PI / 3f)) + 1f;
    }

    /// <summary>
    /// Applies a bounce ease-out curve that simulates successive diminishing rebounds.
    /// </summary>
    /// <param name="t">Normalized progress from 0 to 1.</param>
    /// <returns>Eased progress value with bounce behavior.</returns>
    public static float EaseOutBounce(float t)
    {
        if (t < 1f / 2.75f)
            return 7.5625f * t * t;
        if (t < 2f / 2.75f)
            return 7.5625f * (t -= 1.5f / 2.75f) * t + 0.75f;
        if (t < 2.5f / 2.75f)
            return 7.5625f * (t -= 2.25f / 2.75f) * t + 0.9375f;
        return 7.5625f * (t -= 2.625f / 2.75f) * t + 0.984375f;
    }

    // Interpolation helpers
    /// <summary>
    /// Linearly interpolates between two scalar values.
    /// </summary>
    /// <param name="a">Start value.</param>
    /// <param name="b">End value.</param>
    /// <param name="t">Interpolation factor, typically in the range 0 to 1.</param>
    /// <returns>Interpolated scalar value.</returns>
    public static float Lerp(float a, float b, float t) => a + (b - a) * t;

    /// <summary>
    /// Linearly interpolates between two 2D vectors.
    /// </summary>
    /// <param name="a">Start vector.</param>
    /// <param name="b">End vector.</param>
    /// <param name="t">Interpolation factor, typically in the range 0 to 1.</param>
    /// <returns>Interpolated vector value.</returns>
    public static Vector2 Lerp(Vector2 a, Vector2 b, float t) => Vector2.Lerp(a, b, t);

    /// <summary>
    /// Linearly interpolates between two colors.
    /// </summary>
    /// <param name="a">Start color.</param>
    /// <param name="b">End color.</param>
    /// <param name="t">Interpolation factor, typically in the range 0 to 1.</param>
    /// <returns>Interpolated color value.</returns>
    public static Color Lerp(Color a, Color b, float t) => Color.Lerp(a, b, t);
}

/// <summary>
/// Simple tween value that interpolates over time.
/// </summary>
public class TweenValue
{
    private float _from;
    private float _to;
    private float _duration;
    private float _elapsed;
    private Func<float, float> _easing;
    private bool _active;

    /// <summary>
    /// Gets the current tweened value.
    /// </summary>
    public float Value { get; private set; }

    /// <summary>
    /// Gets a value indicating whether the tween is currently running.
    /// </summary>
    public bool IsActive => _active;

    /// <summary>
    /// Gets a value indicating whether the tween has finished or has been canceled.
    /// </summary>
    public bool IsComplete => !_active;

    /// <summary>
    /// Creates a tween container with an initial value.
    /// </summary>
    /// <param name="initialValue">Initial scalar value stored by the tween.</param>
    public TweenValue(float initialValue = 0f)
    {
        Value = initialValue;
        _easing = Transitions.EaseOut;
    }

    /// <summary>
    /// Starts a tween from one value to another over a duration using an optional easing function.
    /// </summary>
    /// <param name="from">Starting value.</param>
    /// <param name="to">Target value.</param>
    /// <param name="duration">Tween duration in seconds; values less than or equal to zero are clamped to a tiny positive minimum.</param>
    /// <param name="easing">Optional easing function that maps normalized progress to eased progress.</param>
    public void Start(float from, float to, float duration, Func<float, float>? easing = null)
    {
        _from = from;
        _to = to;
        _duration = Math.Max(0.001f, duration);
        _elapsed = 0f;
        _easing = easing ?? Transitions.EaseOut;
        _active = true;
        Value = from;
    }

    /// <summary>
    /// Advances the tween by elapsed time and updates the current value.
    /// </summary>
    /// <param name="deltaTime">Elapsed time in seconds since the previous update.</param>
    public void Update(float deltaTime)
    {
        if (!_active) return;

        _elapsed += deltaTime;
        float t = MathHelper.Clamp(_elapsed / _duration, 0f, 1f);
        float easedT = _easing(t);
        Value = Transitions.Lerp(_from, _to, easedT);

        if (_elapsed >= _duration)
        {
            Value = _to;
            _active = false;
        }
    }

    /// <summary>
    /// Stops the tween immediately and leaves the current value unchanged.
    /// </summary>
    public void Cancel()
    {
        _active = false;
    }
}
