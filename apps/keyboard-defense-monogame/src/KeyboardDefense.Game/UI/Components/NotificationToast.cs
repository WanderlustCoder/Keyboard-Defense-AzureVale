using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using KeyboardDefense.Game.Services;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Toast notification overlay drawn via SpriteBatch.
/// Ported from ui/components/notification_toast.gd.
/// </summary>
public class NotificationToast : IDisposable
{
    private Notification? _current;
    private float _alpha;
    private float _slideOffset;
    private Texture2D? _pixel;

    // Notification type icons (loaded lazily from AssetLoader)
    private Texture2D? _iconInfo;
    private Texture2D? _iconWarning;
    private Texture2D? _iconError;
    private Texture2D? _iconSuccess;
    private bool _iconsLoaded;

    private const float FadeInTime = 0.3f;
    private const float FadeOutTime = 0.5f;
    private const float SlideDistance = 30f;
    private const int IconSize = 16;
    private const int IconPadding = 6;

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

        if (!_iconsLoaded)
        {
            _iconsLoaded = true;
            var loader = AssetLoader.Instance;
            _iconInfo = loader.GetUiTexture("notify_info");
            _iconWarning = loader.GetUiTexture("notify_warning");
            _iconError = loader.GetUiTexture("notify_error");
            _iconSuccess = loader.GetUiTexture("notify_success");
        }

        string text = _current.Message;
        Vector2 size = font.MeasureString(text);

        // Determine icon for this notification type
        Texture2D? icon = GetIconForType(_current.Type);
        int iconOffset = icon != null ? IconSize + IconPadding : 0;

        float totalW = size.X + iconOffset;
        float x = (screenWidth - totalW) / 2;
        float y = 20 + _slideOffset;

        var bgRect = new Rectangle((int)(x - 16), (int)(y - 8), (int)(totalW + 32), (int)(size.Y + 16));

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

        // Draw icon if available
        if (icon != null)
        {
            int iconY = (int)(y + (size.Y - IconSize) / 2);
            spriteBatch.Draw(icon, new Rectangle((int)x, iconY, IconSize, IconSize), Color.White * _alpha);
        }

        // Text with shadow
        float textX = x + iconOffset;
        Color shadowColor = Color.Black * (_alpha * 0.5f);
        spriteBatch.DrawString(font, text, new Vector2(textX + 1, y + 1), shadowColor);

        Color textColor = _current.GetColor() * _alpha;
        spriteBatch.DrawString(font, text, new Vector2(textX, y), textColor);
    }

    private Texture2D? GetIconForType(NotificationManager.NotificationType type) => type switch
    {
        NotificationManager.NotificationType.Info => _iconInfo,
        NotificationManager.NotificationType.Warning => _iconWarning,
        NotificationManager.NotificationType.Error => _iconError,
        NotificationManager.NotificationType.Success => _iconSuccess,
        _ => null,
    };

    public void Dispose()
    {
        _pixel?.Dispose();
        _pixel = null;
    }
}
