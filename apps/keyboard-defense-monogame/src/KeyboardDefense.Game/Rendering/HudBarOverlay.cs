using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;
using KeyboardDefense.Game.Services;
using KeyboardDefense.Game.UI;

namespace KeyboardDefense.Game.Rendering;

/// <summary>
/// SpriteBatch-rendered HUD bar replacing the Myra label-based HUD.
/// Draws icons, progress bars, and shadowed text across a gradient background.
/// </summary>
public class HudBarOverlay
{
    private readonly HudPainter _painter = new();

    // Icon textures (null-safe — falls back to text-only)
    private Texture2D? _icoHp;
    private Texture2D? _icoGold;
    private Texture2D? _icoWood;
    private Texture2D? _icoStone;
    private Texture2D? _icoFood;
    private Texture2D? _icoThreat;

    private const int BarHeight = 44;

    // Gradient colors
    private static readonly Color GradTop = new(15, 13, 25);
    private static readonly Color GradBottom = new(25, 22, 40);
    private static readonly Color DividerColor = new Color(61, 56, 92) * 0.4f;

    // Build mode flag — set externally by WorldScreen
    public bool BuildMode { get; set; }

    public void Initialize(GraphicsDevice device, SpriteFont font)
    {
        _painter.Initialize(device, font);

        var loader = AssetLoader.Instance;
        _icoHp = loader.GetIconTexture("hp");
        _icoGold = loader.GetIconTexture("gold");
        _icoWood = loader.GetIconTexture("wood");
        _icoStone = loader.GetIconTexture("stone");
        _icoFood = loader.GetIconTexture("food");
        _icoThreat = loader.GetIconTexture("threat");
    }

    public void Draw(SpriteBatch sb, GameState state, int screenWidth)
    {
        if (!_painter.IsReady) return;

        var barRect = new Rectangle(0, 0, screenWidth, BarHeight);

        // Background gradient + bottom border
        _painter.DrawGradientV(sb, barRect, GradTop, GradBottom);
        _painter.DrawRect(sb, new Rectangle(0, BarHeight - 1, screenWidth, 1), DividerColor);

        int x = 12;
        int cy = BarHeight / 2; // vertical center

        // Section 1: Day
        string dayText = $"DAY {state.Day}";
        _painter.DrawTextShadowed(sb, new Vector2(x, cy - 8), dayText, ThemeColors.Accent, 0.55f);
        x += 70;
        DrawDivider(sb, x, barRect);
        x += 8;

        // Section 2: HP with progress bar
        float hpMax = 20f;
        float hpPct = Math.Clamp(state.Hp / hpMax, 0f, 1f);
        Color hpColor = ThemeColors.GetHealthColor(hpPct);

        _painter.DrawIconLabel(sb, new Vector2(x, cy - 8), _icoHp, "HP", ThemeColors.Text, 0.45f);
        x += 52;
        _painter.DrawProgressBar(sb, new Rectangle(x, cy - 5, 80, 10), hpPct, hpColor, Color.Black * 0.4f);
        x += 84;
        _painter.DrawTextShadowed(sb, new Vector2(x, cy - 7), $"{state.Hp}/20", hpColor, 0.45f);
        x += 50;
        DrawDivider(sb, x, barRect);
        x += 8;

        // Section 3: Resources (gold, wood, stone, food)
        int wood = state.Resources.GetValueOrDefault("wood", 0);
        int stone = state.Resources.GetValueOrDefault("stone", 0);
        int food = state.Resources.GetValueOrDefault("food", 0);

        _painter.DrawIconLabel(sb, new Vector2(x, cy - 8), _icoGold, state.Gold.ToString(), ThemeColors.ResourceGold, 0.45f);
        x += 60;
        _painter.DrawIconLabel(sb, new Vector2(x, cy - 8), _icoWood, wood.ToString(), ThemeColors.ResourceWood, 0.45f);
        x += 50;
        _painter.DrawIconLabel(sb, new Vector2(x, cy - 8), _icoStone, stone.ToString(), ThemeColors.ResourceStone, 0.45f);
        x += 50;
        _painter.DrawIconLabel(sb, new Vector2(x, cy - 8), _icoFood, food.ToString(), ThemeColors.ResourceFood, 0.45f);
        x += 50;
        DrawDivider(sb, x, barRect);
        x += 8;

        // Section 4: Threat with progress bar
        float threat = MathHelper.Clamp(state.ThreatLevel, 0f, 1f);
        int threatPct = (int)(threat * 100);
        Color threatBarColor = Color.Lerp(ThemeColors.AccentCyan, ThemeColors.DamageRed, threat);

        _painter.DrawIconLabel(sb, new Vector2(x, cy - 8), _icoThreat, "", ThemeColors.Text, 0.45f);
        x += 20;
        _painter.DrawProgressBar(sb, new Rectangle(x, cy - 5, 60, 10), threat, threatBarColor, Color.Black * 0.4f);
        x += 64;

        string threatText = $"{threatPct}%";
        if (threat >= 0.8f)
            _painter.DrawTextGlow(sb, new Vector2(x, cy - 7), threatText, ThemeColors.DamageRed, ThemeColors.DamageRed, 0.45f);
        else
            _painter.DrawTextShadowed(sb, new Vector2(x, cy - 7), threatText, threatBarColor, 0.45f);
        x += 42;
        DrawDivider(sb, x, barRect);
        x += 8;

        // Section 5: Zone / Time / Mode info
        string zone = SimMap.GetZoneName(SimMap.GetZoneAt(state, state.PlayerPos));
        string time = GetTimeOfDayName(state.TimeOfDay);
        string mode = state.ActivityMode switch
        {
            "exploration" => BuildMode ? "BUILD" : "Exploring",
            "encounter" => "COMBAT!",
            "wave_assault" => "WAVE ASSAULT!",
            "harvest_challenge" => "HARVESTING",
            _ => state.ActivityMode,
        };

        _painter.DrawTextShadowed(sb, new Vector2(x, cy - 12), $"{zone} \u00b7 {time}", ThemeColors.AccentCyan, 0.4f);

        Color modeColor = mode == "COMBAT!" ? ThemeColors.DamageRed : ThemeColors.Accent;
        if (mode == "COMBAT!")
            _painter.DrawTextGlow(sb, new Vector2(x, cy + 2), mode, modeColor, ThemeColors.DamageRed, 0.4f);
        else
            _painter.DrawTextShadowed(sb, new Vector2(x, cy + 2), mode, modeColor, 0.4f);
    }

    private void DrawDivider(SpriteBatch sb, int x, Rectangle barRect)
    {
        _painter.DrawRect(sb, new Rectangle(x, barRect.Y + 6, 1, barRect.Height - 12), DividerColor);
    }

    private static string GetTimeOfDayName(float time) => time switch
    {
        < 0.15f => "Night",
        < 0.30f => "Dawn",
        < 0.70f => "Day",
        < 0.85f => "Dusk",
        _ => "Night",
    };
}
