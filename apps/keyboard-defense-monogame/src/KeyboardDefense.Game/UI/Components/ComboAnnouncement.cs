using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Combo streak announcement overlay with scaling text effect.
/// Ported from ui/components/combo_announcement.gd.
/// </summary>
public class ComboAnnouncement
{
    private int _comboCount;
    private string _message = "";
    private float _timer;
    private bool _active;

    private const float TotalDuration = 1.5f;
    private const float ScaleUpTime = 0.2f;

    public bool IsActive => _active;

    public void Show(int comboCount, string message = "")
    {
        _comboCount = comboCount;
        _message = string.IsNullOrEmpty(message) ? $"x{comboCount} COMBO!" : message;
        _timer = 0;
        _active = true;
    }

    public void Update(float deltaTime)
    {
        if (!_active) return;
        _timer += deltaTime;
        if (_timer >= TotalDuration)
            _active = false;
    }

    public void Draw(SpriteBatch spriteBatch, SpriteFont? font, int screenWidth, int screenHeight)
    {
        if (!_active || font == null) return;

        float progress = _timer / TotalDuration;

        // Scale up then settle
        float scale;
        if (progress < ScaleUpTime / TotalDuration)
        {
            float t = progress / (ScaleUpTime / TotalDuration);
            scale = MathHelper.Lerp(0.5f, 1.5f, t);
        }
        else
        {
            float t = (progress - ScaleUpTime / TotalDuration) / (1 - ScaleUpTime / TotalDuration);
            scale = MathHelper.Lerp(1.5f, 1.0f, t);
        }

        // Fade out in last 30%
        float alpha = progress > 0.7f ? 1 - (progress - 0.7f) / 0.3f : 1f;

        Vector2 textSize = font.MeasureString(_message);
        Vector2 origin = textSize / 2;
        Vector2 position = new Vector2(screenWidth / 2f, screenHeight / 3f);

        // Color based on combo count
        Color color;
        if (_comboCount >= 10)
            color = ThemeColors.GoldAccent;
        else if (_comboCount >= 5)
            color = ThemeColors.ComboOrange;
        else
            color = ThemeColors.AccentCyan;

        spriteBatch.DrawString(
            font, _message, position,
            color * alpha,
            0f, origin, scale,
            SpriteEffects.None, 0);
    }
}
