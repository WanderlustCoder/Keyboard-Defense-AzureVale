using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using KeyboardDefense.Game.Rendering;
using KeyboardDefense.Game.Services;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Achievement unlock popup with slide-in animation, gold frame, and glow text.
/// Ported from ui/components/achievement_popup.gd.
/// </summary>
public class AchievementPopup
{
    private string _title = "";
    private string _description = "";
    private float _timer;
    private float _totalDuration;
    private bool _active;

    private readonly NineSliceFrame _frame = new();
    private readonly HudPainter _painter = new();
    private Texture2D? _trophyIcon;

    private const float SlideInTime = 0.4f;
    private const float DisplayTime = 4.0f;
    private const float SlideOutTime = 0.4f;
    private const float TotalTime = SlideInTime + DisplayTime + SlideOutTime;
    private const int IconSize = 20;
    private const int IconPadding = 6;

    public bool IsActive => _active;

    public void Initialize(GraphicsDevice device, SpriteFont font)
    {
        _frame.Initialize(device, font);
        _frame.LoadFrameTextures(AssetLoader.Instance);
        _painter.Initialize(device, font);
        _trophyIcon = AssetLoader.Instance.GetUiTexture("trophy");
    }

    public void Show(string title, string description)
    {
        _title = title;
        _description = description;
        _timer = 0;
        _totalDuration = TotalTime;
        _active = true;
    }

    public void Update(float deltaTime)
    {
        if (!_active) return;

        _timer += deltaTime;
        if (_timer >= _totalDuration)
        {
            _active = false;
        }
    }

    public void Draw(SpriteBatch spriteBatch, SpriteFont? font, int screenWidth, int screenHeight)
    {
        if (!_active || font == null) return;

        // Calculate slide position
        float slideX;
        if (_timer < SlideInTime)
        {
            float t = _timer / SlideInTime;
            slideX = MathHelper.Lerp(screenWidth, screenWidth - 320, EaseOutBack(t));
        }
        else if (_timer < SlideInTime + DisplayTime)
        {
            slideX = screenWidth - 320;
        }
        else
        {
            float t = (_timer - SlideInTime - DisplayTime) / SlideOutTime;
            slideX = MathHelper.Lerp(screenWidth - 320, screenWidth, t * t);
        }

        float y = 60;
        var panelRect = new Rectangle((int)slideX, (int)y, 300, 50);

        // Gold NineSliceFrame
        if (_frame.IsReady)
            _frame.DrawFrame(spriteBatch, panelRect, FrameStyles.Gold);

        // Trophy icon + title with glow
        float textX = slideX + 10;
        if (_trophyIcon != null)
        {
            int iconY = (int)y + 6;
            spriteBatch.Draw(_trophyIcon, new Rectangle((int)(slideX + 8), iconY, IconSize, IconSize), Color.White);
            textX = slideX + 8 + IconSize + IconPadding;
        }

        string titleText = $"Achievement: {_title}";
        if (_painter.IsReady)
        {
            _painter.DrawTextGlow(spriteBatch, new Vector2(textX, y + 8),
                titleText, ThemeColors.GoldAccent, ThemeColors.GoldAccent, 0.45f);
            _painter.DrawTextShadowed(spriteBatch, new Vector2(textX, y + 28),
                _description, ThemeColors.TextDim, 0.4f);
        }
        else
        {
            spriteBatch.DrawString(font, titleText, new Vector2(textX, y + 8), ThemeColors.GoldAccent);
            spriteBatch.DrawString(font, _description, new Vector2(textX, y + 28), ThemeColors.TextDim);
        }
    }

    private static float EaseOutBack(float t)
    {
        const float c1 = 1.70158f;
        const float c3 = c1 + 1;
        return 1 + c3 * MathF.Pow(t - 1, 3) + c1 * MathF.Pow(t - 1, 2);
    }
}
