using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;
using KeyboardDefense.Game.Services;
using KeyboardDefense.Game.UI;

namespace KeyboardDefense.Game.Rendering;

/// <summary>
/// SpriteBatch-rendered battle HUD bar replacing Myra label-based HUD.
/// Shows phase, HP, gold, enemies, wave progress, prompt, timer, and typing stats.
/// </summary>
public class BattleHudOverlay
{
    private readonly HudPainter _painter = new();

    private Texture2D? _icoHp;
    private Texture2D? _icoGold;
    private Texture2D? _icoEnemy;

    private const int BarHeight = 44;

    private static readonly Color GradTop = new(15, 13, 25);
    private static readonly Color GradBottom = new(25, 22, 40);
    private static readonly Color DividerColor = new Color(61, 56, 92) * 0.4f;

    public bool SingleWaveMode { get; set; }

    public void Initialize(GraphicsDevice device, SpriteFont font)
    {
        _painter.Initialize(device, font);

        var loader = AssetLoader.Instance;
        _icoHp = loader.GetIconTexture("hp");
        _icoGold = loader.GetIconTexture("gold");
        _icoEnemy = loader.GetIconTexture("threat");
    }

    public void Draw(SpriteBatch sb, GameState state, int screenWidth)
    {
        if (!_painter.IsReady) return;

        var barRect = new Rectangle(0, 0, screenWidth, BarHeight);

        // Background gradient + bottom border
        _painter.DrawGradientV(sb, barRect, GradTop, GradBottom);
        _painter.DrawRect(sb, new Rectangle(0, BarHeight - 1, screenWidth, 1), DividerColor);

        int x = 12;
        int cy = BarHeight / 2;

        // Section 1: Phase indicator
        string phase = state.Phase;
        bool isNight = phase == "night";
        string phaseText = phase.ToUpperInvariant();
        if (SingleWaveMode) phaseText += " (WAVE)";

        if (isNight)
            _painter.DrawTextGlow(sb, new Vector2(x, cy - 8), phaseText, ThemeColors.DamageRed, ThemeColors.DamageRed, 0.5f);
        else
            _painter.DrawTextShadowed(sb, new Vector2(x, cy - 8), phaseText, ThemeColors.AccentCyan, 0.5f);

        x += (int)(_painter.Font!.MeasureString(phaseText).X * 0.5f) + 12;
        DrawDivider(sb, x, barRect);
        x += 8;

        // Section 2: Day
        string dayText = $"DAY {state.Day}";
        _painter.DrawTextShadowed(sb, new Vector2(x, cy - 8), dayText, ThemeColors.Accent, 0.5f);
        x += 64;
        DrawDivider(sb, x, barRect);
        x += 8;

        // Section 3: HP with progress bar
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

        // Section 4: Gold
        _painter.DrawIconLabel(sb, new Vector2(x, cy - 8), _icoGold, state.Gold.ToString(), ThemeColors.ResourceGold, 0.45f);
        x += 60;
        DrawDivider(sb, x, barRect);
        x += 8;

        // Section 5: Enemies
        int enemyCount = state.Enemies.Count;
        Color enemyColor = enemyCount > 5 ? ThemeColors.DamageRed : ThemeColors.Error;
        _painter.DrawIconLabel(sb, new Vector2(x, cy - 8), _icoEnemy, "", ThemeColors.Text, 0.45f);
        x += 20;
        if (enemyCount > 5)
            _painter.DrawTextGlow(sb, new Vector2(x, cy - 7), enemyCount.ToString(), enemyColor, ThemeColors.DamageRed, 0.5f);
        else
            _painter.DrawTextShadowed(sb, new Vector2(x, cy - 7), enemyCount.ToString(), enemyColor, 0.5f);
        x += 30;
        DrawDivider(sb, x, barRect);
        x += 8;

        if (SingleWaveMode)
            DrawWaveSection(sb, state, ref x, cy, barRect);

        // Section: Prompt
        string prompt = string.IsNullOrEmpty(state.NightPrompt) ? "" : state.NightPrompt;
        if (!string.IsNullOrEmpty(prompt))
        {
            _painter.DrawTextShadowed(sb, new Vector2(x, cy - 12), "TARGET", ThemeColors.TextDim, 0.35f);
            _painter.DrawTextGlow(sb, new Vector2(x, cy), prompt, ThemeColors.AccentCyan, ThemeColors.AccentCyan, 0.55f);
            x += (int)(_painter.Font!.MeasureString(prompt).X * 0.55f) + 16;
            DrawDivider(sb, x, barRect);
            x += 8;
        }

        // Section: WPM/Accuracy (right-aligned)
        int combo = TypingMetrics.GetComboCount(state);
        if (combo > 0)
        {
            string comboText = $"x{combo}";
            Color comboColor = combo >= 10 ? ThemeColors.GoldAccent : ThemeColors.AccentCyan;
            if (combo >= 10)
                _painter.DrawTextGlow(sb, new Vector2(x, cy - 8), comboText, comboColor, ThemeColors.GoldAccent, 0.5f);
            else
                _painter.DrawTextShadowed(sb, new Vector2(x, cy - 8), comboText, comboColor, 0.5f);
        }
    }

    private void DrawWaveSection(SpriteBatch sb, GameState state, ref int x, int cy, Rectangle barRect)
    {
        // Wave progress
        int total = Math.Max(1, state.NightWaveTotal);
        int spawned = Math.Max(0, total - state.NightSpawnRemaining);
        float wavePct = Math.Clamp((float)spawned / total, 0f, 1f);

        _painter.DrawTextShadowed(sb, new Vector2(x, cy - 12), "WAVE", ThemeColors.TextDim, 0.35f);
        _painter.DrawProgressBar(sb, new Rectangle(x, cy + 1, 60, 8), wavePct, ThemeColors.AccentBlue, Color.Black * 0.4f);
        x += 64;
        _painter.DrawTextShadowed(sb, new Vector2(x, cy - 7), $"{spawned}/{total}", ThemeColors.AccentBlue, 0.4f);
        x += 42;

        // Timer
        float runClock = ReadMetricFloat(state, "vs_run_clock_sec");
        string timerText = FormatSeconds(runClock);
        _painter.DrawTextShadowed(sb, new Vector2(x, cy - 7), timerText, ThemeColors.AccentCyan, 0.45f);
        x += 50;

        // Words / Misses
        int words = ReadMetricInt(state, "battle_words_typed");
        int misses = ReadMetricInt(state, "vs_miss_count");
        _painter.DrawTextShadowed(sb, new Vector2(x, cy - 7), $"W:{words} M:{misses}", ThemeColors.TextDim, 0.4f);
        x += 80;

        DrawDivider(sb, x, barRect);
        x += 8;
    }

    private void DrawDivider(SpriteBatch sb, int x, Rectangle barRect)
    {
        _painter.DrawRect(sb, new Rectangle(x, barRect.Y + 6, 1, barRect.Height - 12), DividerColor);
    }

    private static string FormatSeconds(float value)
    {
        int total = Math.Max(0, (int)MathF.Floor(value));
        return $"{total / 60}:{total % 60:D2}";
    }

    private static int ReadMetricInt(GameState state, string key, int fallback = 0)
    {
        if (!state.TypingMetrics.TryGetValue(key, out var value) || value == null)
            return fallback;
        if (value is int i) return i;
        return int.TryParse(value.ToString(), out int parsed) ? parsed : fallback;
    }

    private static float ReadMetricFloat(GameState state, string key, float fallback = 0f)
    {
        if (!state.TypingMetrics.TryGetValue(key, out var value) || value == null)
            return fallback;
        if (value is float f) return f;
        if (value is double d) return (float)d;
        return float.TryParse(value.ToString(), out float parsed) ? parsed : fallback;
    }
}
