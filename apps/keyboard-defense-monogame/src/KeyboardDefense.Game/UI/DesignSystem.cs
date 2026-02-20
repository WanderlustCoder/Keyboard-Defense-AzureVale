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
    public const int FontDisplay = 32;
    public const int FontH1 = 24;
    public const int FontH2 = 20;
    public const int FontH3 = 18;
    public const int FontBody = 16;
    public const int FontBodySmall = 14;
    public const int FontCaption = 12;
    public const int FontMono = 16;
    public const float LineHeight = 1.4f;

    // =========================================================================
    // SPACING SCALE (4px base unit)
    // =========================================================================
    public const int SpaceXs = 4;
    public const int SpaceSm = 8;
    public const int SpaceMd = 12;
    public const int SpaceLg = 16;
    public const int SpaceXl = 24;
    public const int SpaceXxl = 32;

    // =========================================================================
    // SIZING
    // =========================================================================
    public const int SizeTouchMin = 44;
    public const int SizeButtonSm = 32;
    public const int SizeButtonMd = 40;
    public const int SizeButtonLg = 48;
    public const int SizeIconSm = 16;
    public const int SizeIconMd = 24;
    public const int SizeIconLg = 32;
    public const int SizeIconXl = 48;
    public const int SizePanelSm = 320;
    public const int SizePanelMd = 480;
    public const int SizePanelLg = 640;
    public const int SizePanelXl = 800;

    // =========================================================================
    // BORDER RADIUS
    // =========================================================================
    public const int RadiusXs = 2;
    public const int RadiusSm = 4;
    public const int RadiusMd = 8;
    public const int RadiusLg = 12;
    public const int RadiusFull = 9999;

    // =========================================================================
    // ANIMATION TIMING (seconds)
    // =========================================================================
    public const float AnimInstant = 0.05f;
    public const float AnimFast = 0.15f;
    public const float AnimNormal = 0.25f;
    public const float AnimSlow = 0.4f;
    public const float AnimDramatic = 0.6f;

    // =========================================================================
    // Z-INDEX LAYERS
    // =========================================================================
    public const int ZGame = 0;
    public const int ZHud = 10;
    public const int ZPanel = 20;
    public const int ZTooltip = 30;
    public const int ZModal = 40;
    public const int ZNotification = 50;
    public const int ZLoading = 60;

    // =========================================================================
    // ALIASES (used by UI components)
    // =========================================================================
    public const int SpacingXs = SpaceXs;
    public const int SpacingSm = SpaceSm;
    public const int SpacingMd = SpaceMd;
    public const int SpacingLg = SpaceLg;
    public const int ButtonWidthMd = SizePanelSm;
    public const int ButtonHeightMd = SizeButtonMd;

    // =========================================================================
    // UTILITY
    // =========================================================================

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
