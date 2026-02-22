using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;
using KeyboardDefense.Game.UI;

namespace KeyboardDefense.Game.Rendering;

/// <summary>
/// Screen-space overlay for inline combat encounters:
/// combo counter with tiered colors, encounter banner, and approach timers.
/// Follows the CombatVfx SpriteBatch overlay pattern.
/// </summary>
public class InlineCombatOverlay
{
    private Texture2D? _pixel;
    private SpriteFont? _font;

    // Combo display
    private int _displayCombo;
    private float _comboPopTimer;
    private const float ComboPopDuration = 0.3f;

    // Gradient colors for combat banner
    private static readonly Color BannerLeft = new(40, 15, 15);
    private static readonly Color BannerRight = new(20, 15, 20);
    private static readonly Color BannerBorder = new(180, 50, 50);

    public void Initialize(GraphicsDevice device, SpriteFont font)
    {
        _pixel = new Texture2D(device, 1, 1);
        _pixel.SetData(new[] { Color.White });
        _font = font;
    }

    public void Update(float deltaTime, GameState state)
    {
        if (state.ActivityMode != "encounter") return;

        int combo = TypingMetrics.GetComboCount(state);
        if (combo != _displayCombo)
        {
            _displayCombo = combo;
            _comboPopTimer = ComboPopDuration;
        }

        if (_comboPopTimer > 0)
            _comboPopTimer = MathF.Max(0, _comboPopTimer - deltaTime);
    }

    /// <summary>
    /// Draw inline combat HUD overlays. Call in screen space (no camera transform).
    /// </summary>
    public void Draw(SpriteBatch spriteBatch, GameState state, int screenWidth, int screenHeight)
    {
        if (_pixel == null || _font == null) return;
        if (state.ActivityMode != "encounter") return;

        DrawEncounterBanner(spriteBatch, state, screenWidth);
        DrawComboCounter(spriteBatch, state, screenWidth, screenHeight);
        DrawApproachTimers(spriteBatch, state, screenWidth, screenHeight);
    }

    private void DrawEncounterBanner(SpriteBatch spriteBatch, GameState state, int screenWidth)
    {
        int count = state.EncounterEnemies.Count;
        string text = count == 1 ? "COMBAT! 1 enemy remaining" : $"COMBAT! {count} enemies remaining";

        var size = _font!.MeasureString(text);
        float scale = 0.8f;
        int bannerHeight = 36;
        int bannerY = 50;

        int bannerWidth = (int)(size.X * scale) + 40;
        int bannerX = (screenWidth - bannerWidth) / 2;

        // Horizontal gradient: dark red-tinted left → dark right
        int steps = 8;
        int stripW = Math.Max(1, bannerWidth / steps);
        for (int i = 0; i < steps; i++)
        {
            float t = (float)i / (steps - 1);
            Color c = Color.Lerp(BannerLeft, BannerRight, t) * 0.85f;
            int sx = bannerX + i * stripW;
            int sw = (i == steps - 1) ? (bannerX + bannerWidth - sx) : stripW;
            spriteBatch.Draw(_pixel!, new Rectangle(sx, bannerY, sw, bannerHeight), c);
        }

        // Top and bottom red border
        spriteBatch.Draw(_pixel!, new Rectangle(bannerX, bannerY, bannerWidth, 1), BannerBorder * 0.6f);
        spriteBatch.Draw(_pixel!, new Rectangle(bannerX, bannerY + bannerHeight - 1, bannerWidth, 1), BannerBorder * 0.6f);

        // Text centered in banner
        var textPos = new Vector2(
            bannerX + (bannerWidth - size.X * scale) / 2,
            bannerY + (bannerHeight - size.Y * scale) / 2);
        spriteBatch.DrawString(_font, text, textPos, ThemeColors.DamageRed,
            0f, Vector2.Zero, scale, SpriteEffects.None, 0f);
    }

    private void DrawComboCounter(SpriteBatch spriteBatch, GameState state, int screenWidth, int screenHeight)
    {
        int combo = TypingMetrics.GetComboCount(state);
        if (combo < 2) return;

        // Tiered colors
        Color comboColor;
        string tierLabel;
        if (combo >= 20)
        {
            comboColor = ThemeColors.GoldAccent;
            tierLabel = "LEGENDARY";
        }
        else if (combo >= 10)
        {
            comboColor = new Color(180, 80, 220); // Purple
            tierLabel = "AMAZING";
        }
        else if (combo >= 5)
        {
            comboColor = ThemeColors.AccentCyan;
            tierLabel = "GREAT";
        }
        else
        {
            comboColor = ThemeColors.Text;
            tierLabel = "";
        }

        string comboText = $"x{combo}";
        var size = _font!.MeasureString(comboText);

        // Pop-scale animation
        float popScale = 1f;
        if (_comboPopTimer > 0)
        {
            float t = _comboPopTimer / ComboPopDuration;
            popScale = 1f + 0.4f * Transitions.EaseOutElastic(1f - t);
        }

        float scale = 1.6f * popScale;
        int x = screenWidth - 120;
        int y = 220;

        // Glow effect — 4 offset draws in tier color at 30% alpha
        if (!string.IsNullOrEmpty(tierLabel))
        {
            Color glowColor = comboColor * 0.3f;
            spriteBatch.DrawString(_font, comboText,
                new Vector2(x - 1, y), glowColor,
                0f, Vector2.Zero, scale, SpriteEffects.None, 0f);
            spriteBatch.DrawString(_font, comboText,
                new Vector2(x + 1, y), glowColor,
                0f, Vector2.Zero, scale, SpriteEffects.None, 0f);
            spriteBatch.DrawString(_font, comboText,
                new Vector2(x, y - 1), glowColor,
                0f, Vector2.Zero, scale, SpriteEffects.None, 0f);
            spriteBatch.DrawString(_font, comboText,
                new Vector2(x, y + 1), glowColor,
                0f, Vector2.Zero, scale, SpriteEffects.None, 0f);
        }

        // Shadow
        spriteBatch.DrawString(_font, comboText,
            new Vector2(x + 2, y + 2), Color.Black * 0.5f,
            0f, Vector2.Zero, scale, SpriteEffects.None, 0f);
        // Main
        spriteBatch.DrawString(_font, comboText,
            new Vector2(x, y), comboColor,
            0f, Vector2.Zero, scale, SpriteEffects.None, 0f);

        // Tier label below
        if (!string.IsNullOrEmpty(tierLabel))
        {
            var tierSize = _font.MeasureString(tierLabel);
            float tierScale = 0.5f;
            spriteBatch.DrawString(_font, tierLabel,
                new Vector2(x + (size.X * scale - tierSize.X * tierScale) / 2, y + size.Y * scale + 2),
                comboColor * 0.8f,
                0f, Vector2.Zero, tierScale, SpriteEffects.None, 0f);
        }
    }

    private void DrawApproachTimers(SpriteBatch spriteBatch, GameState state, int screenWidth, int screenHeight)
    {
        // Draw per-enemy approach progress bars at bottom-left
        int barWidth = 150;
        int barHeight = 12;
        int startX = 10;
        int startY = screenHeight - 180;

        for (int i = 0; i < state.EncounterEnemies.Count && i < 5; i++)
        {
            var enemy = state.EncounterEnemies[i];
            float approach = Convert.ToSingle(enemy.GetValueOrDefault("approach_progress", 0f));
            string kind = enemy.GetValueOrDefault("kind")?.ToString() ?? "enemy";

            int y = startY + i * (barHeight + 6);

            // Label
            string label = kind.Length > 10 ? kind[..10] : kind;
            spriteBatch.DrawString(_font!, label,
                new Vector2(startX, y - 2), ThemeColors.Text,
                0f, Vector2.Zero, 0.45f, SpriteEffects.None, 0f);

            // Bar background
            int barX = startX + 80;
            spriteBatch.Draw(_pixel!, new Rectangle(barX, y, barWidth, barHeight),
                Color.Black * 0.5f);

            // Fill — color shifts from cyan to red as they approach
            float fill = MathHelper.Clamp(approach, 0f, 1f);
            Color barColor = Color.Lerp(ThemeColors.AccentCyan, ThemeColors.DamageRed, fill);
            spriteBatch.Draw(_pixel!, new Rectangle(barX, y, (int)(barWidth * fill), barHeight),
                barColor);
        }
    }

    /// <summary>Reset combo display when leaving encounter.</summary>
    public void Reset()
    {
        _displayCombo = 0;
        _comboPopTimer = 0;
    }
}
