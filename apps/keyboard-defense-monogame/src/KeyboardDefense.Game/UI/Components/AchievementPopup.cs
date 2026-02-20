using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Achievement unlock popup with slide-in animation.
/// Ported from ui/components/achievement_popup.gd.
/// </summary>
public class AchievementPopup
{
    private string _title = "";
    private string _description = "";
    private float _timer;
    private float _totalDuration;
    private bool _active;

    private const float SlideInTime = 0.4f;
    private const float DisplayTime = 4.0f;
    private const float SlideOutTime = 0.4f;
    private const float TotalTime = SlideInTime + DisplayTime + SlideOutTime;

    public bool IsActive => _active;

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

        // Draw title
        var titleColor = ThemeColors.GoldAccent;
        spriteBatch.DrawString(font, $"Achievement: {_title}", new Vector2(slideX + 10, y + 10), titleColor);

        // Draw description
        var descColor = ThemeColors.TextDim;
        spriteBatch.DrawString(font, _description, new Vector2(slideX + 10, y + 30), descColor);
    }

    private static float EaseOutBack(float t)
    {
        const float c1 = 1.70158f;
        const float c3 = c1 + 1;
        return 1 + c3 * MathF.Pow(t - 1, 3) + c1 * MathF.Pow(t - 1, 2);
    }
}
