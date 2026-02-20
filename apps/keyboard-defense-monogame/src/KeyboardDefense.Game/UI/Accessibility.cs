using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;

namespace KeyboardDefense.Game.UI;

/// <summary>
/// Accessibility utilities: colorblind palettes, high contrast, reduced motion, font scaling.
/// Ported from ui/accessibility.gd (369 lines).
/// </summary>
public static class Accessibility
{
    public enum ColorMode { Normal, Protanopia, Deuteranopia, Tritanopia }

    // Normal palette
    private static readonly Dictionary<string, Color> PaletteNormal = new()
    {
        ["damage"] = ThemeColors.DamageRed,
        ["heal"] = ThemeColors.HealGreen,
        ["gold"] = ThemeColors.GoldAccent,
        ["shield"] = ThemeColors.ShieldBlue,
        ["fire"] = new Color(255, 100, 0),
        ["ice"] = new Color(100, 200, 255),
        ["poison"] = new Color(100, 255, 50),
        ["electric"] = new Color(255, 255, 100),
        ["enemy"] = ThemeColors.DamageRed,
        ["friendly"] = ThemeColors.HealGreen,
        ["neutral"] = ThemeColors.TextMuted,
    };

    // Protanopia-safe palette (red-blind)
    private static readonly Dictionary<string, Color> PaletteProtanopia = new()
    {
        ["damage"] = new Color(0, 114, 178),
        ["heal"] = new Color(0, 158, 115),
        ["gold"] = new Color(240, 228, 66),
        ["shield"] = new Color(86, 180, 233),
        ["fire"] = new Color(230, 159, 0),
        ["ice"] = new Color(86, 180, 233),
        ["poison"] = new Color(0, 158, 115),
        ["electric"] = new Color(240, 228, 66),
        ["enemy"] = new Color(213, 94, 0),
        ["friendly"] = new Color(0, 158, 115),
        ["neutral"] = new Color(153, 153, 153),
    };

    // Deuteranopia-safe palette (green-blind)
    private static readonly Dictionary<string, Color> PaletteDeuteranopia = new()
    {
        ["damage"] = new Color(213, 94, 0),
        ["heal"] = new Color(0, 114, 178),
        ["gold"] = new Color(240, 228, 66),
        ["shield"] = new Color(86, 180, 233),
        ["fire"] = new Color(230, 159, 0),
        ["ice"] = new Color(86, 180, 233),
        ["poison"] = new Color(0, 158, 115),
        ["electric"] = new Color(240, 228, 66),
        ["enemy"] = new Color(204, 121, 167),
        ["friendly"] = new Color(0, 114, 178),
        ["neutral"] = new Color(153, 153, 153),
    };

    // Tritanopia-safe palette (blue-blind)
    private static readonly Dictionary<string, Color> PaletteTritanopia = new()
    {
        ["damage"] = new Color(213, 94, 0),
        ["heal"] = new Color(0, 158, 115),
        ["gold"] = new Color(240, 228, 66),
        ["shield"] = new Color(204, 121, 167),
        ["fire"] = new Color(230, 159, 0),
        ["ice"] = new Color(204, 121, 167),
        ["poison"] = new Color(0, 158, 115),
        ["electric"] = new Color(240, 228, 66),
        ["enemy"] = new Color(213, 94, 0),
        ["friendly"] = new Color(0, 158, 115),
        ["neutral"] = new Color(153, 153, 153),
    };

    private static readonly Dictionary<string, string> ShapeIndicators = new()
    {
        ["fire"] = "triangle",
        ["ice"] = "diamond",
        ["poison"] = "circle",
        ["electric"] = "star",
        ["damage"] = "cross",
        ["heal"] = "plus",
        ["shield"] = "square",
    };

    private static readonly Dictionary<string, string> ShapeSymbols = new()
    {
        ["triangle"] = "\u25b2",
        ["diamond"] = "\u25c6",
        ["circle"] = "\u25cf",
        ["star"] = "\u2605",
        ["cross"] = "\u2716",
        ["plus"] = "\u271a",
        ["square"] = "\u25a0",
    };

    public static Color GetColor(string colorKey, ColorMode mode = ColorMode.Normal)
    {
        var palette = GetPalette(mode);
        return palette.GetValueOrDefault(colorKey, Color.White);
    }

    public static Dictionary<string, Color> GetPalette(ColorMode mode) => mode switch
    {
        ColorMode.Protanopia => PaletteProtanopia,
        ColorMode.Deuteranopia => PaletteDeuteranopia,
        ColorMode.Tritanopia => PaletteTritanopia,
        _ => PaletteNormal,
    };

    public static string GetShapeIndicator(string elementType)
        => ShapeIndicators.GetValueOrDefault(elementType, "circle");

    public static string GetShapeSymbol(string shape)
        => ShapeSymbols.GetValueOrDefault(shape, "\u25cf");

    public static Color GetHighContrastColor(Color original, bool isForeground)
    {
        float brightness = (original.R * 0.299f + original.G * 0.587f + original.B * 0.114f) / 255f;
        if (isForeground)
            return brightness > 0.5f ? Color.White : new Color(240, 240, 240);
        return brightness > 0.5f ? new Color(10, 10, 10) : Color.Black;
    }

    public static float GetAnimationDuration(float baseDuration, bool reducedMotion)
        => reducedMotion ? Math.Min(baseDuration * 0.1f, 0.05f) : baseDuration;

    public static int GetParticleCount(int baseCount, bool reducedMotion)
        => reducedMotion ? Math.Max(1, baseCount / 4) : baseCount;

    public static bool ShouldSkipAnimation(bool reducedMotion) => reducedMotion;

    public static float GetFontSize(float baseSize, bool largeText)
        => largeText ? baseSize * 1.25f : baseSize;

    public static Vector2 GetMinTouchTarget(bool largeText)
        => largeText ? new Vector2(56, 56) : new Vector2(44, 44);
}
