using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace KeyboardDefense.Game.Rendering;

/// <summary>
/// Reusable SpriteBatch drawing helpers for HUD elements:
/// rectangles, borders, gradients, progress bars, icon+label pairs, shadowed/glow text.
/// Manages its own 1x1 pixel texture and font reference.
/// </summary>
public class HudPainter
{
    private Texture2D? _pixel;
    private SpriteFont? _font;

    public void Initialize(GraphicsDevice device, SpriteFont font)
    {
        _pixel = new Texture2D(device, 1, 1);
        _pixel.SetData(new[] { Color.White });
        _font = font;
    }

    public bool IsReady => _pixel != null && _font != null;
    public SpriteFont? Font => _font;

    public void DrawRect(SpriteBatch sb, Rectangle rect, Color color)
    {
        if (_pixel == null) return;
        sb.Draw(_pixel, rect, color);
    }

    public void DrawBorder(SpriteBatch sb, Rectangle rect, Color color, int thickness = 1)
    {
        if (_pixel == null) return;
        // Top
        sb.Draw(_pixel, new Rectangle(rect.X, rect.Y, rect.Width, thickness), color);
        // Bottom
        sb.Draw(_pixel, new Rectangle(rect.X, rect.Bottom - thickness, rect.Width, thickness), color);
        // Left
        sb.Draw(_pixel, new Rectangle(rect.X, rect.Y + thickness, thickness, rect.Height - thickness * 2), color);
        // Right
        sb.Draw(_pixel, new Rectangle(rect.Right - thickness, rect.Y + thickness, thickness, rect.Height - thickness * 2), color);
    }

    public void DrawGradientV(SpriteBatch sb, Rectangle rect, Color top, Color bottom, int steps = 8)
    {
        if (_pixel == null) return;
        int stripH = Math.Max(1, rect.Height / steps);
        for (int i = 0; i < steps; i++)
        {
            float t = (float)i / (steps - 1);
            Color c = Color.Lerp(top, bottom, t);
            int y = rect.Y + i * stripH;
            int h = (i == steps - 1) ? (rect.Bottom - y) : stripH;
            sb.Draw(_pixel, new Rectangle(rect.X, y, rect.Width, h), c);
        }
    }

    public void DrawProgressBar(SpriteBatch sb, Rectangle rect, float fill, Color fillColor, Color bgColor)
    {
        if (_pixel == null) return;
        sb.Draw(_pixel, rect, bgColor);
        float clamped = MathHelper.Clamp(fill, 0f, 1f);
        int fillWidth = (int)(rect.Width * clamped);
        if (fillWidth > 0)
            sb.Draw(_pixel, new Rectangle(rect.X, rect.Y, fillWidth, rect.Height), fillColor);
        DrawBorder(sb, rect, Color.Black * 0.6f, 1);
    }

    public void DrawIconLabel(SpriteBatch sb, Vector2 pos, Texture2D? icon, string text, Color textColor, float scale = 0.5f)
    {
        if (_font == null) return;
        if (icon != null)
        {
            float iconScale = scale * 1.8f;
            int iconSize = (int)(16 * iconScale);
            sb.Draw(icon, new Rectangle((int)pos.X, (int)pos.Y, iconSize, iconSize), Color.White);
            var textPos = new Vector2(pos.X + iconSize + 3, pos.Y + (iconSize - _font.MeasureString(text).Y * scale) / 2);
            DrawTextShadowed(sb, textPos, text, textColor, scale);
        }
        else
        {
            DrawTextShadowed(sb, pos, text, textColor, scale);
        }
    }

    public void DrawTextShadowed(SpriteBatch sb, Vector2 pos, string text, Color color, float scale = 0.5f)
    {
        if (_font == null) return;
        sb.DrawString(_font, text, pos + new Vector2(1, 1), Color.Black * 0.5f,
            0f, Vector2.Zero, scale, SpriteEffects.None, 0f);
        sb.DrawString(_font, text, pos, color,
            0f, Vector2.Zero, scale, SpriteEffects.None, 0f);
    }

    public void DrawTextGlow(SpriteBatch sb, Vector2 pos, string text, Color color, Color glow, float scale = 0.5f)
    {
        if (_font == null) return;
        // 4 offset draws in glow color
        Color glowColor = glow * 0.3f;
        sb.DrawString(_font, text, pos + new Vector2(-1, 0), glowColor,
            0f, Vector2.Zero, scale, SpriteEffects.None, 0f);
        sb.DrawString(_font, text, pos + new Vector2(1, 0), glowColor,
            0f, Vector2.Zero, scale, SpriteEffects.None, 0f);
        sb.DrawString(_font, text, pos + new Vector2(0, -1), glowColor,
            0f, Vector2.Zero, scale, SpriteEffects.None, 0f);
        sb.DrawString(_font, text, pos + new Vector2(0, 1), glowColor,
            0f, Vector2.Zero, scale, SpriteEffects.None, 0f);
        // Main text
        sb.DrawString(_font, text, pos, color,
            0f, Vector2.Zero, scale, SpriteEffects.None, 0f);
    }
}
