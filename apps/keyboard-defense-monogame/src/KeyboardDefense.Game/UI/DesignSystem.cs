namespace KeyboardDefense.Game.UI;

/// <summary>
/// Centralized design tokens for typography, spacing, sizing, and animation.
/// Ported from ui/design_system.gd.
/// </summary>
public static class DesignSystem
{
    // =========================================================================
    // TYPOGRAPHY SCALE (1.25 modular scale, 16px base)
    // =========================================================================
    /// <summary>
    /// Display headline font size token.
    /// </summary>
    public const int FontDisplay = 32;
    /// <summary>
    /// Primary heading level 1 font size token.
    /// </summary>
    public const int FontH1 = 24;
    /// <summary>
    /// Primary heading level 2 font size token.
    /// </summary>
    public const int FontH2 = 20;
    /// <summary>
    /// Primary heading level 3 font size token.
    /// </summary>
    public const int FontH3 = 18;
    /// <summary>
    /// Default body text font size token.
    /// </summary>
    public const int FontBody = 16;
    /// <summary>
    /// Secondary small body text font size token.
    /// </summary>
    public const int FontBodySmall = 14;
    /// <summary>
    /// Caption and helper text font size token.
    /// </summary>
    public const int FontCaption = 12;
    /// <summary>
    /// Monospace text font size token.
    /// </summary>
    public const int FontMono = 16;
    /// <summary>
    /// Standard text line-height multiplier.
    /// </summary>
    public const float LineHeight = 1.4f;

    // =========================================================================
    // SPACING SCALE (4px base unit)
    // =========================================================================
    /// <summary>
    /// Extra-small spacing token.
    /// </summary>
    public const int SpaceXs = 4;
    /// <summary>
    /// Small spacing token.
    /// </summary>
    public const int SpaceSm = 8;
    /// <summary>
    /// Medium spacing token.
    /// </summary>
    public const int SpaceMd = 12;
    /// <summary>
    /// Large spacing token.
    /// </summary>
    public const int SpaceLg = 16;
    /// <summary>
    /// Extra-large spacing token.
    /// </summary>
    public const int SpaceXl = 24;
    /// <summary>
    /// Double extra-large spacing token.
    /// </summary>
    public const int SpaceXxl = 32;

    // =========================================================================
    // SIZING
    // =========================================================================
    /// <summary>
    /// Minimum touch target size for interactable UI controls.
    /// </summary>
    public const int SizeTouchMin = 44;
    /// <summary>
    /// Small button height token.
    /// </summary>
    public const int SizeButtonSm = 32;
    /// <summary>
    /// Medium button height token.
    /// </summary>
    public const int SizeButtonMd = 40;
    /// <summary>
    /// Large button height token.
    /// </summary>
    public const int SizeButtonLg = 48;
    /// <summary>
    /// Small icon size token.
    /// </summary>
    public const int SizeIconSm = 16;
    /// <summary>
    /// Medium icon size token.
    /// </summary>
    public const int SizeIconMd = 24;
    /// <summary>
    /// Large icon size token.
    /// </summary>
    public const int SizeIconLg = 32;
    /// <summary>
    /// Extra-large icon size token.
    /// </summary>
    public const int SizeIconXl = 48;
    /// <summary>
    /// Small panel width token.
    /// </summary>
    public const int SizePanelSm = 320;
    /// <summary>
    /// Medium panel width token.
    /// </summary>
    public const int SizePanelMd = 480;
    /// <summary>
    /// Large panel width token.
    /// </summary>
    public const int SizePanelLg = 640;
    /// <summary>
    /// Extra-large panel width token.
    /// </summary>
    public const int SizePanelXl = 800;

    // =========================================================================
    // BORDER RADIUS
    // =========================================================================
    /// <summary>
    /// Extra-small corner radius token.
    /// </summary>
    public const int RadiusXs = 2;
    /// <summary>
    /// Small corner radius token.
    /// </summary>
    public const int RadiusSm = 4;
    /// <summary>
    /// Medium corner radius token.
    /// </summary>
    public const int RadiusMd = 8;
    /// <summary>
    /// Large corner radius token.
    /// </summary>
    public const int RadiusLg = 12;
    /// <summary>
    /// Fully rounded radius token for pills or circles.
    /// </summary>
    public const int RadiusFull = 9999;

    // =========================================================================
    // ANIMATION TIMING (seconds)
    // =========================================================================
    /// <summary>
    /// Near-instant animation duration token in seconds.
    /// </summary>
    public const float AnimInstant = 0.05f;
    /// <summary>
    /// Fast animation duration token in seconds.
    /// </summary>
    public const float AnimFast = 0.15f;
    /// <summary>
    /// Default animation duration token in seconds.
    /// </summary>
    public const float AnimNormal = 0.25f;
    /// <summary>
    /// Slow animation duration token in seconds.
    /// </summary>
    public const float AnimSlow = 0.4f;
    /// <summary>
    /// Dramatic animation duration token in seconds.
    /// </summary>
    public const float AnimDramatic = 0.6f;

    // =========================================================================
    // Z-INDEX LAYERS
    // =========================================================================
    /// <summary>
    /// Base z-layer for world gameplay rendering.
    /// </summary>
    public const int ZGame = 0;
    /// <summary>
    /// Z-layer for HUD elements above gameplay.
    /// </summary>
    public const int ZHud = 10;
    /// <summary>
    /// Z-layer for floating panels above the HUD.
    /// </summary>
    public const int ZPanel = 20;
    /// <summary>
    /// Z-layer for tooltips above panels.
    /// </summary>
    public const int ZTooltip = 30;
    /// <summary>
    /// Z-layer for modal dialogs above regular UI.
    /// </summary>
    public const int ZModal = 40;
    /// <summary>
    /// Z-layer for transient notifications above modals.
    /// </summary>
    public const int ZNotification = 50;
    /// <summary>
    /// Top z-layer for loading overlays.
    /// </summary>
    public const int ZLoading = 60;

    // =========================================================================
    // ALIASES (used by UI components)
    // =========================================================================
    /// <summary>
    /// Alias token for extra-small spacing.
    /// </summary>
    public const int SpacingXs = SpaceXs;
    /// <summary>
    /// Alias token for small spacing.
    /// </summary>
    public const int SpacingSm = SpaceSm;
    /// <summary>
    /// Alias token for medium spacing.
    /// </summary>
    public const int SpacingMd = SpaceMd;
    /// <summary>
    /// Alias token for large spacing.
    /// </summary>
    public const int SpacingLg = SpaceLg;
    /// <summary>
    /// Alias token for default medium button width.
    /// </summary>
    public const int ButtonWidthMd = SizePanelSm;
    /// <summary>
    /// Alias token for default medium button height.
    /// </summary>
    public const int ButtonHeightMd = SizeButtonMd;

    // =========================================================================
    // UTILITY
    // =========================================================================

    /// <summary>
    /// Resolves a named typography level to its configured font size token.
    /// </summary>
    public static int GetFontSize(string level) => level switch
    {
        "display" => FontDisplay,
        "h1" => FontH1,
        "h2" => FontH2,
        "h3" => FontH3,
        "body" => FontBody,
        "body_small" => FontBodySmall,
        "caption" => FontCaption,
        "mono" => FontMono,
        _ => FontBody,
    };

    /// <summary>
    /// Resolves a named spacing level to its configured spacing token.
    /// </summary>
    public static int GetSpacing(string level) => level switch
    {
        "xs" => SpaceXs,
        "sm" => SpaceSm,
        "md" => SpaceMd,
        "lg" => SpaceLg,
        "xl" => SpaceXl,
        "xxl" => SpaceXxl,
        _ => SpaceMd,
    };

    /// <summary>
    /// Resolves a named animation speed to its configured duration token.
    /// </summary>
    public static float GetAnimDuration(string speed) => speed switch
    {
        "instant" => AnimInstant,
        "fast" => AnimFast,
        "normal" => AnimNormal,
        "slow" => AnimSlow,
        "dramatic" => AnimDramatic,
        _ => AnimNormal,
    };
}
