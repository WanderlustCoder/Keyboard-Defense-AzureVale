using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using KeyboardDefense.Game.UI;

namespace KeyboardDefense.Game.Rendering;

/// <summary>
/// Red vignette border flash on encounter enter/exit transitions.
/// Follows the CombatVfx SpriteBatch overlay pattern.
/// </summary>
public class CombatTransition
{
    private Texture2D? _pixel;
    private float _timer;
    private float _duration;
    private Color _color;
    private bool _active;

    private const float EnterDuration = 0.8f;
    private const float ExitDuration = 0.5f;
    private const int VignetteBorder = 80;

    public void Initialize(GraphicsDevice device)
    {
        _pixel = new Texture2D(device, 1, 1);
        _pixel.SetData(new[] { Color.White });
    }

    /// <summary>Flash red vignette on encounter start.</summary>
    public void TriggerEnter()
    {
        _timer = 0f;
        _duration = EnterDuration;
        _color = new Color(180, 30, 20);
        _active = true;
    }

    /// <summary>Subtle flash on encounter exit.</summary>
    public void TriggerExit()
    {
        _timer = 0f;
        _duration = ExitDuration;
        _color = new Color(60, 120, 60);
        _active = true;
    }

    public void Update(float deltaTime)
    {
        if (!_active) return;
        _timer += deltaTime;
        if (_timer >= _duration)
            _active = false;
    }

    /// <summary>
    /// Draw vignette border overlay. Call with a plain SpriteBatch (no camera transform).
    /// </summary>
    public void Draw(SpriteBatch spriteBatch, int screenWidth, int screenHeight)
    {
        if (!_active || _pixel == null) return;

        float progress = MathHelper.Clamp(_timer / _duration, 0f, 1f);
        float alpha = (1f - progress) * 0.5f; // fade out from 50% opacity

        var tint = _color * alpha;
        int border = VignetteBorder;

        // Top edge
        spriteBatch.Draw(_pixel, new Rectangle(0, 0, screenWidth, border), tint);
        // Bottom edge
        spriteBatch.Draw(_pixel, new Rectangle(0, screenHeight - border, screenWidth, border), tint);
        // Left edge
        spriteBatch.Draw(_pixel, new Rectangle(0, border, border, screenHeight - border * 2), tint);
        // Right edge
        spriteBatch.Draw(_pixel, new Rectangle(screenWidth - border, border, border, screenHeight - border * 2), tint);
    }
}
