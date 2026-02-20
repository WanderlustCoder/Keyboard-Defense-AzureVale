using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using KeyboardDefense.Game.UI;

namespace KeyboardDefense.Game.Rendering;

/// <summary>
/// Status effect indicators (burn, slow, poison, etc) shown on units.
/// Ported from game/status_indicators.gd (162 lines).
/// </summary>
public class StatusIndicators
{
    private class Indicator
    {
        public int TargetId;
        public string StatusType = "";
        public float Duration;
        public float Elapsed;
        public bool Active;
    }

    private static StatusIndicators? _instance;
    public static StatusIndicators Instance => _instance ??= new();

    private const float IndicatorSize = 12f;
    private const float IndicatorSpacing = 14f;
    private const float PulseSpeed = 3f;

    private static readonly Dictionary<string, Color> StatusColors = new()
    {
        ["burn"] = new Color(255, 100, 0),
        ["slow"] = new Color(100, 150, 255),
        ["poison"] = new Color(100, 255, 50),
        ["shield"] = ThemeColors.ShieldBlue,
        ["stun"] = new Color(255, 255, 100),
        ["weaken"] = new Color(180, 80, 180),
        ["haste"] = new Color(0, 255, 200),
        ["armor"] = new Color(180, 180, 200),
    };

    private readonly List<Indicator> _indicators = new();
    private Texture2D? _pixel;

    public int ActiveCount => _indicators.Count;

    public void Initialize(GraphicsDevice device)
    {
        _pixel = new Texture2D(device, 1, 1);
        _pixel.SetData(new[] { Color.White });
    }

    public void AddIndicator(int targetId, string statusType, float duration)
    {
        // Don't duplicate
        foreach (var ind in _indicators)
        {
            if (ind.TargetId == targetId && ind.StatusType == statusType)
            {
                ind.Duration = duration;
                ind.Elapsed = 0f;
                return;
            }
        }

        _indicators.Add(new Indicator
        {
            TargetId = targetId,
            StatusType = statusType,
            Duration = duration,
            Elapsed = 0f,
            Active = true,
        });
    }

    public void RemoveIndicator(int targetId, string statusType)
    {
        _indicators.RemoveAll(i => i.TargetId == targetId && i.StatusType == statusType);
    }

    public void RemoveAllForTarget(int targetId)
    {
        _indicators.RemoveAll(i => i.TargetId == targetId);
    }

    public bool HasIndicator(int targetId, string statusType)
    {
        foreach (var ind in _indicators)
            if (ind.TargetId == targetId && ind.StatusType == statusType)
                return true;
        return false;
    }

    public void Update(GameTime gameTime)
    {
        float dt = (float)gameTime.ElapsedGameTime.TotalSeconds;

        for (int i = _indicators.Count - 1; i >= 0; i--)
        {
            var ind = _indicators[i];
            ind.Elapsed += dt;
            if (ind.Duration > 0 && ind.Elapsed >= ind.Duration)
                _indicators.RemoveAt(i);
        }
    }

    public void DrawForTarget(SpriteBatch spriteBatch, int targetId, Vector2 position, float totalTime)
    {
        if (_pixel == null) return;

        int count = 0;
        foreach (var ind in _indicators)
        {
            if (ind.TargetId != targetId) continue;

            float offsetX = count * IndicatorSpacing;
            var pos = new Vector2(
                position.X + offsetX - (IndicatorSpacing * GetTargetIndicatorCount(targetId) - IndicatorSpacing) * 0.5f,
                position.Y - 20f);

            float pulse = 0.7f + 0.3f * MathF.Sin(totalTime * PulseSpeed + count);
            var color = StatusColors.GetValueOrDefault(ind.StatusType, Color.White) * pulse;

            spriteBatch.Draw(_pixel, new Rectangle(
                (int)(pos.X - IndicatorSize * 0.5f),
                (int)(pos.Y - IndicatorSize * 0.5f),
                (int)IndicatorSize, (int)IndicatorSize), color);

            count++;
        }
    }

    private int GetTargetIndicatorCount(int targetId)
    {
        int count = 0;
        foreach (var ind in _indicators)
            if (ind.TargetId == targetId) count++;
        return count;
    }

    public void Clear()
    {
        _indicators.Clear();
    }
}
