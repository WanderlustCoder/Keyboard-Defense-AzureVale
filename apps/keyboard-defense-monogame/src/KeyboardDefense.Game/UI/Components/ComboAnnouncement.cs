using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Combo streak announcement overlay with scaling text effect and glow.
/// Ported from ui/components/combo_announcement.gd.
/// </summary>
public class ComboAnnouncement : IDisposable
{
    private int _comboCount;
    private string _message = "";
    private float _timer;
    private bool _active;
    private Texture2D? _pixel;

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
        Color glowColor;
        if (_comboCount >= 20)
        {
            color = ThemeColors.GoldAccent;
            glowColor = ThemeColors.GoldAccent;
        }
        else if (_comboCount >= 10)
        {
            color = ThemeColors.GoldAccent;
            glowColor = ThemeColors.ComboOrange;
        }
        else if (_comboCount >= 5)
        {
            color = ThemeColors.ComboOrange;
            glowColor = ThemeColors.AccentCyan;
        }
        else
        {
            color = ThemeColors.AccentCyan;
            glowColor = Color.Transparent;
        }

        // Background glow circle for combo 5+
        if (_comboCount >= 5 && _pixel != null)
        {
            int glowSize = (int)(80 * scale);
            var glowRect = new Rectangle(
                (int)position.X - glowSize / 2,
                (int)position.Y - glowSize / 2,
                glowSize, glowSize);
            spriteBatch.Draw(_pixel, glowRect, glowColor * (alpha * 0.15f));
        }

        // Lazy init pixel for glow
        if (_pixel == null && _comboCount >= 5)
        {
            _pixel = new Texture2D(spriteBatch.GraphicsDevice, 1, 1);
            _pixel.SetData(new[] { Color.White });
        }

        // Glow text (4-offset for combo 5+)
        if (_comboCount >= 5)
        {
            Color gc = glowColor * (alpha * 0.3f);
            spriteBatch.DrawString(font, _message, position + new Vector2(-1, 0) * scale, gc,
                0f, origin, scale, SpriteEffects.None, 0);
            spriteBatch.DrawString(font, _message, position + new Vector2(1, 0) * scale, gc,
                0f, origin, scale, SpriteEffects.None, 0);
            spriteBatch.DrawString(font, _message, position + new Vector2(0, -1) * scale, gc,
                0f, origin, scale, SpriteEffects.None, 0);
            spriteBatch.DrawString(font, _message, position + new Vector2(0, 1) * scale, gc,
                0f, origin, scale, SpriteEffects.None, 0);
        }

        // Main text
        spriteBatch.DrawString(
            font, _message, position,
            color * alpha,
            0f, origin, scale,
            SpriteEffects.None, 0);
    }

    public void Dispose()
    {
        _pixel?.Dispose();
        _pixel = null;
    }
}
