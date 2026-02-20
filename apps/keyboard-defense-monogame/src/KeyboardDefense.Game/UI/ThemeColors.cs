using Microsoft.Xna.Framework;
using KeyboardDefense.Game.Services;

namespace KeyboardDefense.Game.UI;

/// <summary>
/// Centralized color definitions for Keyboard Defense UI.
/// Ported from ui/theme_colors.gd.
/// </summary>
public static class ThemeColors
{
    // =========================================================================
    // BACKGROUND COLORS
    // =========================================================================
    public static readonly Color BgDark = new(10, 9, 15);
    public static readonly Color BgPanel = new Color(20, 18, 31) * new Color(255, 255, 255, 242);
    public static readonly Color BgCard = new(36, 31, 56);
    public static readonly Color BgCardDisabled = new(28, 26, 43);
    public static readonly Color BgButton = new(46, 41, 71);
    public static readonly Color BgButtonHover = new(56, 51, 89);
    public static readonly Color BgInput = new(15, 14, 23);

    // =========================================================================
    // BORDER COLORS
    // =========================================================================
    public static readonly Color Border = new(61, 56, 92);
    public static readonly Color BorderHighlight = new(89, 82, 133);
    public static readonly Color BorderFocus = new(115, 107, 158);
    public static readonly Color BorderDisabled = new(51, 46, 71);

    // =========================================================================
    // TEXT COLORS
    // =========================================================================
    public static readonly Color Text = new(240, 240, 250);
    public static readonly Color TextDim = new Color(240, 240, 250) * 0.55f;
    public static readonly Color TextDisabled = new Color(128, 128, 140) * 0.6f;
    public static readonly Color TextPlaceholder = new Color(128, 128, 140) * 0.8f;

    // =========================================================================
    // ACCENT COLORS
    // =========================================================================
    public static readonly Color Accent = new(250, 214, 112);
    public static readonly Color AccentBlue = new(166, 219, 255);
    public static readonly Color AccentCyan = new(115, 191, 242);

    // =========================================================================
    // STATUS COLORS
    // =========================================================================
    public static readonly Color Success = new(115, 209, 140);
    public static readonly Color Warning = new(250, 214, 112);
    public static readonly Color Error = new(245, 115, 115);
    public static readonly Color Info = new(166, 219, 255);

    // =========================================================================
    // GAMEPLAY COLORS
    // =========================================================================
    public static readonly Color Threat = new(230, 102, 89);
    public static readonly Color CastleHealthy = new(115, 209, 140);
    public static readonly Color CastleDamaged = new(245, 115, 115);
    public static readonly Color BuffActive = new(250, 214, 112);
    public static readonly Color TypedCorrect = new(166, 219, 255);
    public static readonly Color TypedError = new(245, 115, 115);
    public static readonly Color TypedPending = new Color(240, 240, 250) * 0.4f;

    // =========================================================================
    // SHADOW COLORS
    // =========================================================================
    public static readonly Color Shadow = new Color(0, 0, 0) * 0.25f;
    public static readonly Color ShadowDeep = new Color(0, 0, 0) * 0.4f;
    public static readonly Color Glow = new Color(250, 214, 112) * 0.3f;
    public static readonly Color GlowBlue = new Color(166, 219, 255) * 0.3f;
    public static readonly Color GlowError = new Color(245, 115, 115) * 0.3f;

    // =========================================================================
    // OVERLAY COLORS
    // =========================================================================
    public static readonly Color Overlay = new Color(0, 0, 0) * 0.6f;
    public static readonly Color OverlayLight = new Color(255, 255, 255) * 0.05f;
    public static readonly Color OverlayDark = new Color(0, 0, 0) * 0.3f;

    // =========================================================================
    // RESOURCE COLORS
    // =========================================================================
    public static readonly Color ResourceWood = new(153, 102, 51);
    public static readonly Color ResourceStone = new(128, 128, 140);
    public static readonly Color ResourceFood = new(102, 179, 77);
    public static readonly Color ResourceGold = new(250, 214, 112);

    // =========================================================================
    // FACTION COLORS
    // =========================================================================
    public static readonly Color FactionPlayer = new(77, 128, 230);
    public static readonly Color FactionNeutral = new(128, 128, 128);
    public static readonly Color FactionHostile = new(230, 77, 77);
    public static readonly Color FactionAllied = new(77, 179, 102);

    // =========================================================================
    // RARITY COLORS
    // =========================================================================
    public static readonly Color RarityCommon = new(179, 179, 179);
    public static readonly Color RarityUncommon = new(77, 204, 77);
    public static readonly Color RarityRare = new(77, 128, 230);
    public static readonly Color RarityEpic = new(179, 77, 230);
    public static readonly Color RarityLegendary = new(250, 214, 112);

    // =========================================================================
    // MORALE COLORS
    // =========================================================================
    public static readonly Color MoraleCritical = new(230, 51, 51);
    public static readonly Color MoraleLow = new(230, 128, 51);
    public static readonly Color MoraleNormal = new(179, 179, 77);
    public static readonly Color MoraleHigh = new(102, 204, 102);
    public static readonly Color MoraleExcellent = new(77, 230, 128);

    // =========================================================================
    // HIGH CONTRAST MODE COLORS
    // =========================================================================
    public static readonly Color HcBg = Color.Black;
    public static readonly Color HcFg = Color.White;
    public static readonly Color HcAccent = Color.Yellow;
    public static readonly Color HcError = new(255, 77, 77);
    public static readonly Color HcSuccess = new(77, 255, 77);
    public static readonly Color HcBorder = Color.White;

    // =========================================================================
    // GAMEPLAY ALIASES (used by rendering, effects, input display)
    // =========================================================================
    public static readonly Color GoldAccent = Accent;
    public static readonly Color GoldBright = Accent;
    public static readonly Color Cyan = AccentCyan;
    public static readonly Color ShieldBlue = AccentBlue;
    public static readonly Color DamageRed = Error;
    public static readonly Color HealGreen = Success;
    public static readonly Color TextMuted = TextDim;
    public static readonly Color ComboOrange = Warning;
    public static readonly Color BtnPrimary = BgButton;
    public static readonly Color BtnPrimaryHover = BgButtonHover;
    public static readonly Color BtnSecondary = BgCard;
    public static readonly Color BtnSecondaryHover = BgCardDisabled;

    // =========================================================================
    // UTILITY FUNCTIONS
    // =========================================================================

    public static Color WithAlpha(Color color, float alpha)
        => color * alpha;

    public static Color GetResourceColor(string resource) => resource switch
    {
        "wood" => ResourceWood,
        "stone" => ResourceStone,
        "food" => ResourceFood,
        "gold" => ResourceGold,
        _ => Text,
    };

    public static Color GetRarityColor(int tier) => tier switch
    {
        1 => RarityCommon,
        2 => RarityUncommon,
        3 => RarityRare,
        4 => RarityEpic,
        5 => RarityLegendary,
        _ => RarityCommon,
    };

    public static Color GetMoraleColor(float morale)
    {
        if (morale < 20) return MoraleCritical;
        if (morale < 40) return MoraleLow;
        if (morale < 60) return MoraleNormal;
        if (morale < 80) return MoraleHigh;
        return MoraleExcellent;
    }

    public static Color GetHealthColor(float percentage)
    {
        if (percentage > 0.6f) return CastleHealthy;
        if (percentage > 0.3f) return Warning;
        return CastleDamaged;
    }

    public static Color Lerp(Color from, Color to, float t)
        => Color.Lerp(from, to, MathHelper.Clamp(t, 0f, 1f));

    // =========================================================================
    // ACCESSIBILITY-AWARE HELPERS
    // =========================================================================

    /// <summary>
    /// Returns the appropriate color based on current accessibility settings.
    /// Uses high contrast colors when that mode is enabled, otherwise returns
    /// the colorblind-safe variant for gameplay colors.
    /// </summary>
    public static Color GetAccessibleColor(Color normalColor, bool isForeground = true)
    {
        var sm = KeyboardDefenseGame.Instance?.SettingsManager;
        if (sm == null) return normalColor;

        if (sm.HighContrast)
            return Accessibility.GetHighContrastColor(normalColor, isForeground);

        return normalColor;
    }

    /// <summary>
    /// Returns the colorblind-safe gameplay color for a named element.
    /// Falls back to normal palette if colorblind mode is "none".
    /// </summary>
    public static Color GetGameplayColor(string colorKey)
    {
        var sm = KeyboardDefenseGame.Instance?.SettingsManager;
        if (sm == null) return Accessibility.GetColor(colorKey, Accessibility.ColorMode.Normal);

        var mode = sm.ColorblindMode switch
        {
            "protanopia" => Accessibility.ColorMode.Protanopia,
            "deuteranopia" => Accessibility.ColorMode.Deuteranopia,
            "tritanopia" => Accessibility.ColorMode.Tritanopia,
            _ => Accessibility.ColorMode.Normal,
        };

        return Accessibility.GetColor(colorKey, mode);
    }

    /// <summary>
    /// Returns the background color respecting high contrast mode.
    /// </summary>
    public static Color GetBg() => GetAccessibleColor(BgPanel, false);

    /// <summary>
    /// Returns the text color respecting high contrast mode.
    /// </summary>
    public static Color GetText() => GetAccessibleColor(Text, true);
}
