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
    public static float Linear(float t) => t;
    public static float EaseIn(float t) => t * t;
    public static float EaseOut(float t) => 1f - (1f - t) * (1f - t);
    public static float EaseInOut(float t) => t < 0.5f ? 2f * t * t : 1f - MathF.Pow(-2f * t + 2f, 2f) / 2f;
    public static float EaseOutBack(float t)
    {
        const float c1 = 1.70158f;
        const float c3 = c1 + 1f;
        return 1f + c3 * MathF.Pow(t - 1f, 3f) + c1 * MathF.Pow(t - 1f, 2f);
    }
    public static float EaseOutElastic(float t)
    {
        if (t <= 0f) return 0f;
        if (t >= 1f) return 1f;
        return MathF.Pow(2f, -10f * t) * MathF.Sin((t * 10f - 0.75f) * (2f * MathF.PI / 3f)) + 1f;
    }
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
    public static float Lerp(float a, float b, float t) => a + (b - a) * t;
    public static Vector2 Lerp(Vector2 a, Vector2 b, float t) => Vector2.Lerp(a, b, t);
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

    public float Value { get; private set; }
    public bool IsActive => _active;
    public bool IsComplete => !_active;

    public TweenValue(float initialValue = 0f)
    {
        Value = initialValue;
        _easing = Transitions.EaseOut;
    }

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

    public void Cancel()
    {
        _active = false;
    }
}
