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
    /// <summary>
    /// Base dark background color for scene backdrops.
    /// </summary>
    public static readonly Color BgDark = new(10, 9, 15);
    /// <summary>
    /// Primary panel background color used by framed UI surfaces.
    /// </summary>
    public static readonly Color BgPanel = new Color(20, 18, 31) * new Color(255, 255, 255, 242);
    /// <summary>
    /// Card background color for elevated content blocks.
    /// </summary>
    public static readonly Color BgCard = new(36, 31, 56);
    /// <summary>
    /// Disabled card background color for unavailable content.
    /// </summary>
    public static readonly Color BgCardDisabled = new(28, 26, 43);
    /// <summary>
    /// Primary button background color.
    /// </summary>
    public static readonly Color BgButton = new(46, 41, 71);
    /// <summary>
    /// Hover-state background color for primary buttons.
    /// </summary>
    public static readonly Color BgButtonHover = new(56, 51, 89);
    /// <summary>
    /// Input field background color.
    /// </summary>
    public static readonly Color BgInput = new(15, 14, 23);

    // =========================================================================
    // BORDER COLORS
    // =========================================================================
    /// <summary>
    /// Default border color for standard UI frames.
    /// </summary>
    public static readonly Color Border = new(61, 56, 92);
    /// <summary>
    /// Highlight border color for emphasized edges.
    /// </summary>
    public static readonly Color BorderHighlight = new(89, 82, 133);
    /// <summary>
    /// Focus border color for focused controls.
    /// </summary>
    public static readonly Color BorderFocus = new(115, 107, 158);
    /// <summary>
    /// Border color used for disabled controls.
    /// </summary>
    public static readonly Color BorderDisabled = new(51, 46, 71);

    // =========================================================================
    // TEXT COLORS
    // =========================================================================
    /// <summary>
    /// Primary text color.
    /// </summary>
    public static readonly Color Text = new(240, 240, 250);
    /// <summary>
    /// Secondary dimmed text color.
    /// </summary>
    public static readonly Color TextDim = new Color(240, 240, 250) * 0.55f;
    /// <summary>
    /// Disabled text color.
    /// </summary>
    public static readonly Color TextDisabled = new Color(128, 128, 140) * 0.6f;
    /// <summary>
    /// Placeholder text color for input hints.
    /// </summary>
    public static readonly Color TextPlaceholder = new Color(128, 128, 140) * 0.8f;

    // =========================================================================
    // ACCENT COLORS
    // =========================================================================
    /// <summary>
    /// Primary accent color used for highlights and rewards.
    /// </summary>
    public static readonly Color Accent = new(250, 214, 112);
    /// <summary>
    /// Blue accent color used for informational emphasis.
    /// </summary>
    public static readonly Color AccentBlue = new(166, 219, 255);
    /// <summary>
    /// Cyan accent color used for alternate highlights.
    /// </summary>
    public static readonly Color AccentCyan = new(115, 191, 242);

    // =========================================================================
    // STATUS COLORS
    // =========================================================================
    /// <summary>
    /// Success status color.
    /// </summary>
    public static readonly Color Success = new(115, 209, 140);
    /// <summary>
    /// Warning status color.
    /// </summary>
    public static readonly Color Warning = new(250, 214, 112);
    /// <summary>
    /// Error status color.
    /// </summary>
    public static readonly Color Error = new(245, 115, 115);
    /// <summary>
    /// Informational status color.
    /// </summary>
    public static readonly Color Info = new(166, 219, 255);

    // =========================================================================
    // GAMEPLAY COLORS
    // =========================================================================
    /// <summary>
    /// Threat indicator color for dangerous entities.
    /// </summary>
    public static readonly Color Threat = new(230, 102, 89);
    /// <summary>
    /// Health color used when the castle is in a healthy state.
    /// </summary>
    public static readonly Color CastleHealthy = new(115, 209, 140);
    /// <summary>
    /// Health color used when the castle is in a damaged state.
    /// </summary>
    public static readonly Color CastleDamaged = new(245, 115, 115);
    /// <summary>
    /// Color used to indicate active buffs.
    /// </summary>
    public static readonly Color BuffActive = new(250, 214, 112);
    /// <summary>
    /// Typing feedback color for correct input.
    /// </summary>
    public static readonly Color TypedCorrect = new(166, 219, 255);
    /// <summary>
    /// Typing feedback color for incorrect input.
    /// </summary>
    public static readonly Color TypedError = new(245, 115, 115);
    /// <summary>
    /// Typing feedback color for pending characters.
    /// </summary>
    public static readonly Color TypedPending = new Color(240, 240, 250) * 0.4f;

    // =========================================================================
    // SHADOW COLORS
    // =========================================================================
    /// <summary>
    /// Standard drop-shadow color.
    /// </summary>
    public static readonly Color Shadow = new Color(0, 0, 0) * 0.25f;
    /// <summary>
    /// Deeper shadow color for stronger depth.
    /// </summary>
    public static readonly Color ShadowDeep = new Color(0, 0, 0) * 0.4f;
    /// <summary>
    /// Warm glow color for highlighted elements.
    /// </summary>
    public static readonly Color Glow = new Color(250, 214, 112) * 0.3f;
    /// <summary>
    /// Blue glow color for informational highlights.
    /// </summary>
    public static readonly Color GlowBlue = new Color(166, 219, 255) * 0.3f;
    /// <summary>
    /// Red glow color for error or damage highlights.
    /// </summary>
    public static readonly Color GlowError = new Color(245, 115, 115) * 0.3f;

    // =========================================================================
    // OVERLAY COLORS
    // =========================================================================
    /// <summary>
    /// Dark overlay color for modal dimming.
    /// </summary>
    public static readonly Color Overlay = new Color(0, 0, 0) * 0.6f;
    /// <summary>
    /// Light overlay color for subtle surface shine.
    /// </summary>
    public static readonly Color OverlayLight = new Color(255, 255, 255) * 0.05f;
    /// <summary>
    /// Secondary dark overlay color for layered effects.
    /// </summary>
    public static readonly Color OverlayDark = new Color(0, 0, 0) * 0.3f;

    // =========================================================================
    // RESOURCE COLORS
    // =========================================================================
    /// <summary>
    /// Resource color for wood.
    /// </summary>
    public static readonly Color ResourceWood = new(153, 102, 51);
    /// <summary>
    /// Resource color for stone.
    /// </summary>
    public static readonly Color ResourceStone = new(128, 128, 140);
    /// <summary>
    /// Resource color for food.
    /// </summary>
    public static readonly Color ResourceFood = new(102, 179, 77);
    /// <summary>
    /// Resource color for gold.
    /// </summary>
    public static readonly Color ResourceGold = new(250, 214, 112);

    // =========================================================================
    // FACTION COLORS
    // =========================================================================
    /// <summary>
    /// Faction color for player-controlled entities.
    /// </summary>
    public static readonly Color FactionPlayer = new(77, 128, 230);
    /// <summary>
    /// Faction color for neutral entities.
    /// </summary>
    public static readonly Color FactionNeutral = new(128, 128, 128);
    /// <summary>
    /// Faction color for hostile entities.
    /// </summary>
    public static readonly Color FactionHostile = new(230, 77, 77);
    /// <summary>
    /// Faction color for allied entities.
    /// </summary>
    public static readonly Color FactionAllied = new(77, 179, 102);

    // =========================================================================
    // RARITY COLORS
    // =========================================================================
    /// <summary>
    /// Item rarity color for common tier.
    /// </summary>
    public static readonly Color RarityCommon = new(179, 179, 179);
    /// <summary>
    /// Item rarity color for uncommon tier.
    /// </summary>
    public static readonly Color RarityUncommon = new(77, 204, 77);
    /// <summary>
    /// Item rarity color for rare tier.
    /// </summary>
    public static readonly Color RarityRare = new(77, 128, 230);
    /// <summary>
    /// Item rarity color for epic tier.
    /// </summary>
    public static readonly Color RarityEpic = new(179, 77, 230);
    /// <summary>
    /// Item rarity color for legendary tier.
    /// </summary>
    public static readonly Color RarityLegendary = new(250, 214, 112);

    // =========================================================================
    // MORALE COLORS
    // =========================================================================
    /// <summary>
    /// Morale color for critical morale levels.
    /// </summary>
    public static readonly Color MoraleCritical = new(230, 51, 51);
    /// <summary>
    /// Morale color for low morale levels.
    /// </summary>
    public static readonly Color MoraleLow = new(230, 128, 51);
    /// <summary>
    /// Morale color for normal morale levels.
    /// </summary>
    public static readonly Color MoraleNormal = new(179, 179, 77);
    /// <summary>
    /// Morale color for high morale levels.
    /// </summary>
    public static readonly Color MoraleHigh = new(102, 204, 102);
    /// <summary>
    /// Morale color for excellent morale levels.
    /// </summary>
    public static readonly Color MoraleExcellent = new(77, 230, 128);

    // =========================================================================
    // HIGH CONTRAST MODE COLORS
    // =========================================================================
    /// <summary>
    /// High-contrast background color.
    /// </summary>
    public static readonly Color HcBg = Color.Black;
    /// <summary>
    /// High-contrast foreground color.
    /// </summary>
    public static readonly Color HcFg = Color.White;
    /// <summary>
    /// High-contrast accent color.
    /// </summary>
    public static readonly Color HcAccent = Color.Yellow;
    /// <summary>
    /// High-contrast error color.
    /// </summary>
    public static readonly Color HcError = new(255, 77, 77);
    /// <summary>
    /// High-contrast success color.
    /// </summary>
    public static readonly Color HcSuccess = new(77, 255, 77);
    /// <summary>
    /// High-contrast border color.
    /// </summary>
    public static readonly Color HcBorder = Color.White;

    // =========================================================================
    // GAMEPLAY ALIASES (used by rendering, effects, input display)
    // =========================================================================
    /// <summary>
    /// Gold accent alias for reward-related visuals.
    /// </summary>
    public static readonly Color GoldAccent = Accent;
    /// <summary>
    /// Bright gold alias used for emphasized reward highlights.
    /// </summary>
    public static readonly Color GoldBright = Accent;
    /// <summary>
    /// Cyan alias used by legacy gameplay rendering paths.
    /// </summary>
    public static readonly Color Cyan = AccentCyan;
    /// <summary>
    /// Shield blue alias used by defensive effect visuals.
    /// </summary>
    public static readonly Color ShieldBlue = AccentBlue;
    /// <summary>
    /// Damage red alias used by combat feedback.
    /// </summary>
    public static readonly Color DamageRed = Error;
    /// <summary>
    /// Heal green alias used by restoration feedback.
    /// </summary>
    public static readonly Color HealGreen = Success;
    /// <summary>
    /// Muted text alias used by legacy UI components.
    /// </summary>
    public static readonly Color TextMuted = TextDim;
    /// <summary>
    /// Combo orange alias used by combo indicators.
    /// </summary>
    public static readonly Color ComboOrange = Warning;
    /// <summary>
    /// Primary button alias used by gameplay HUD controls.
    /// </summary>
    public static readonly Color BtnPrimary = BgButton;
    /// <summary>
    /// Primary button hover alias used by gameplay HUD controls.
    /// </summary>
    public static readonly Color BtnPrimaryHover = BgButtonHover;
    /// <summary>
    /// Secondary button alias used by gameplay HUD controls.
    /// </summary>
    public static readonly Color BtnSecondary = BgCard;
    /// <summary>
    /// Secondary button hover alias used by gameplay HUD controls.
    /// </summary>
    public static readonly Color BtnSecondaryHover = BgCardDisabled;

    // =========================================================================
    // UTILITY FUNCTIONS
    // =========================================================================

    /// <summary>
    /// Returns a copy of the color with the provided alpha multiplier applied.
    /// </summary>
    public static Color WithAlpha(Color color, float alpha)
        => color * alpha;

    /// <summary>
    /// Returns the configured color token for a resource key.
    /// </summary>
    public static Color GetResourceColor(string resource) => resource switch
    {
        "wood" => ResourceWood,
        "stone" => ResourceStone,
        "food" => ResourceFood,
        "gold" => ResourceGold,
        _ => Text,
    };

    /// <summary>
    /// Returns the configured rarity color for a numeric rarity tier.
    /// </summary>
    public static Color GetRarityColor(int tier) => tier switch
    {
        1 => RarityCommon,
        2 => RarityUncommon,
        3 => RarityRare,
        4 => RarityEpic,
        5 => RarityLegendary,
        _ => RarityCommon,
    };

    /// <summary>
    /// Returns the morale color bucket for a morale percentage value.
    /// </summary>
    public static Color GetMoraleColor(float morale)
    {
        if (morale < 20) return MoraleCritical;
        if (morale < 40) return MoraleLow;
        if (morale < 60) return MoraleNormal;
        if (morale < 80) return MoraleHigh;
        return MoraleExcellent;
    }

    /// <summary>
    /// Returns a castle health color based on current health percentage.
    /// </summary>
    public static Color GetHealthColor(float percentage)
    {
        if (percentage > 0.6f) return CastleHealthy;
        if (percentage > 0.3f) return Warning;
        return CastleDamaged;
    }

    /// <summary>
    /// Linearly interpolates between two colors with clamped interpolation.
    /// </summary>
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

/// <summary>
/// Describes the color and ornament settings for a UI frame skin.
/// </summary>
public record FrameStyle(
    Color BgTop, Color BgBottom, Color BorderColor, Color HighlightColor,
    Color AccentColor, Color TitleBgTop, Color TitleBgBottom, Color TitleColor,
    bool ShowCornerDots);

/// <summary>
/// Provides predefined frame style presets for common UI contexts.
/// </summary>
public static class FrameStyles
{
    /// <summary>
    /// Default frame style preset for standard UI panels.
    /// </summary>
    public static readonly FrameStyle Default = new(
        BgTop: new Color(18, 16, 28),
        BgBottom: new Color(12, 10, 20),
        BorderColor: ThemeColors.Border,
        HighlightColor: ThemeColors.BorderHighlight,
        AccentColor: ThemeColors.Accent,
        TitleBgTop: new Color(30, 26, 48),
        TitleBgBottom: new Color(20, 18, 35),
        TitleColor: ThemeColors.Accent,
        ShowCornerDots: true);

    /// <summary>
    /// Combat frame style preset for battle-focused panels.
    /// </summary>
    public static readonly FrameStyle Combat = new(
        BgTop: new Color(25, 12, 14),
        BgBottom: new Color(15, 8, 10),
        BorderColor: ThemeColors.DamageRed,
        HighlightColor: new Color(180, 60, 60),
        AccentColor: ThemeColors.DamageRed,
        TitleBgTop: new Color(40, 16, 18),
        TitleBgBottom: new Color(25, 12, 14),
        TitleColor: ThemeColors.DamageRed,
        ShowCornerDots: true);

    /// <summary>
    /// Gold frame style preset for economy and reward panels.
    /// </summary>
    public static readonly FrameStyle Gold = new(
        BgTop: new Color(22, 18, 12),
        BgBottom: new Color(14, 12, 8),
        BorderColor: ThemeColors.GoldAccent,
        HighlightColor: new Color(200, 170, 80),
        AccentColor: ThemeColors.GoldAccent,
        TitleBgTop: new Color(35, 28, 15),
        TitleBgBottom: new Color(22, 18, 12),
        TitleColor: ThemeColors.GoldAccent,
        ShowCornerDots: true);

    /// <summary>
    /// Information frame style preset for informational panels.
    /// </summary>
    public static readonly FrameStyle Info = new(
        BgTop: new Color(14, 18, 28),
        BgBottom: new Color(10, 12, 20),
        BorderColor: ThemeColors.AccentBlue,
        HighlightColor: new Color(100, 140, 200),
        AccentColor: ThemeColors.AccentBlue,
        TitleBgTop: new Color(20, 28, 45),
        TitleBgBottom: new Color(14, 18, 28),
        TitleColor: ThemeColors.AccentBlue,
        ShowCornerDots: false);
}
