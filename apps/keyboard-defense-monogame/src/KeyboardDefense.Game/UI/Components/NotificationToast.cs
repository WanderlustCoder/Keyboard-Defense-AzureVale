using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using KeyboardDefense.Game.Services;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Toast notification overlay drawn via SpriteBatch.
/// Ported from ui/components/notification_toast.gd.
/// </summary>
public class NotificationToast
{
    private Notification? _current;
    private float _alpha;
    private float _slideOffset;
    private Texture2D? _pixel;

    private const float FadeInTime = 0.3f;
    private const float FadeOutTime = 0.5f;
    private const float SlideDistance = 30f;

    public void Show(Notification notification)
    {
        _current = notification;
        _alpha = 0;
        _slideOffset = SlideDistance;
    }

    public void Hide()
    {
        _current = null;
    }

    public void Update(float deltaTime)
    {
        if (_current == null) return;

        float progress = _current.Progress;

        // Fade in
        if (progress < 0.1f)
        {
            float t = progress / 0.1f;
            _alpha = t;
            _slideOffset = SlideDistance * (1 - t);
        }
        // Visible
        else if (progress < 0.8f)
        {
            _alpha = 1;
            _slideOffset = 0;
        }
        // Fade out
        else
        {
            float t = (progress - 0.8f) / 0.2f;
            _alpha = 1 - t;
            _slideOffset = -SlideDistance * t;
        }
    }

    public void Draw(SpriteBatch spriteBatch, SpriteFont? font, int screenWidth)
    {
        if (_current == null || font == null || _alpha <= 0.01f) return;

        if (_pixel == null)
        {
            _pixel = new Texture2D(spriteBatch.GraphicsDevice, 1, 1);
            _pixel.SetData(new[] { Color.White });
        }

        string text = _current.Message;
        Vector2 size = font.MeasureString(text);

        float x = (screenWidth - size.X) / 2;
        float y = 20 + _slideOffset;

        var bgRect = new Rectangle((int)(x - 16), (int)(y - 8), (int)(size.X + 32), (int)(size.Y + 16));

        // Background
        spriteBatch.Draw(_pixel, bgRect, ThemeColors.BgPanel * _alpha);

        // Border
        Color borderColor = ThemeColors.Border * _alpha;
        spriteBatch.Draw(_pixel, new Rectangle(bgRect.X, bgRect.Y, bgRect.Width, 1), borderColor);
        spriteBatch.Draw(_pixel, new Rectangle(bgRect.X, bgRect.Bottom - 1, bgRect.Width, 1), borderColor);
        spriteBatch.Draw(_pixel, new Rectangle(bgRect.X, bgRect.Y, 1, bgRect.Height), borderColor);
        spriteBatch.Draw(_pixel, new Rectangle(bgRect.Right - 1, bgRect.Y, 1, bgRect.Height), borderColor);

        // Colored left-edge strip based on notification type
        Color edgeColor = _current.GetColor() * _alpha;
        spriteBatch.Draw(_pixel, new Rectangle(bgRect.X, bgRect.Y, 4, bgRect.Height), edgeColor);

        // Text with shadow
        Color shadowColor = Color.Black * (_alpha * 0.5f);
        spriteBatch.DrawString(font, text, new Vector2(x + 1, y + 1), shadowColor);

        Color textColor = _current.GetColor() * _alpha;
        spriteBatch.DrawString(font, text, new Vector2(x, y), textColor);
    }
}
