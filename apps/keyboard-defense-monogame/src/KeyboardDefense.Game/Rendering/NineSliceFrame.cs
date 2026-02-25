using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using KeyboardDefense.Game.Services;
using KeyboardDefense.Game.UI;

namespace KeyboardDefense.Game.Rendering;

/// <summary>
/// Panel frame drawing with texture-based 9-slice support and procedural fallback.
/// If UI textures are loaded, draws textured corners + tiled edges.
/// Otherwise falls back to gradient backgrounds, borders, highlights, and corner dots.
/// </summary>
public class NineSliceFrame
{
    private Texture2D? _pixel;
    private SpriteFont? _font;

    // Texture-based 9-slice pieces (null = use procedural fallback)
    private Texture2D? _cornerTL;
    private Texture2D? _edgeH;
    private Texture2D? _edgeV;
    private bool _texturesLoaded;

    /// <summary>
    /// Allocates the fallback 1x1 pixel texture and caches the UI font used for frame title rendering.
    /// </summary>
    /// <param name="device">Graphics device that owns the generated fallback texture.</param>
    /// <param name="font">Font cached for frame text measurement and drawing.</param>
    public void Initialize(GraphicsDevice device, SpriteFont font)
    {
        _pixel = new Texture2D(device, 1, 1);
        _pixel.SetData(new[] { Color.White });
        _font = font;
    }

    /// <summary>
    /// Gets whether initialization has created the fallback texture required for drawing frames.
    /// </summary>
    public bool IsReady => _pixel != null;

    /// <summary>
    /// Loads the frame corner and edge textures from the asset loader, using procedural rendering if any texture is unavailable.
    /// </summary>
    /// <param name="loader">Asset loader used to resolve frame texture IDs.</param>
    public void LoadFrameTextures(AssetLoader loader)
    {
        _cornerTL = loader.GetUiTexture("frame_corner");
        _edgeH = loader.GetUiTexture("frame_edge_h");
        _edgeV = loader.GetUiTexture("frame_edge_v");
        _texturesLoaded = _cornerTL != null && _edgeH != null && _edgeV != null;
    }

    /// <summary>
    /// Draws a frame within the specified rectangle using textured 9-slice output when ready, otherwise a procedural fallback frame.
    /// </summary>
    /// <param name="sb">Sprite batch used for all frame draw calls.</param>
    /// <param name="rect">Destination rectangle for the frame outer bounds.</param>
    /// <param name="style">Style colors and accents applied to the frame render.</param>
    public void DrawFrame(SpriteBatch sb, Rectangle rect, FrameStyle style)
    {
        if (_pixel == null) return;

        if (_texturesLoaded)
            DrawTexturedFrame(sb, rect, style);
        else
            DrawProceduralFrame(sb, rect, style);
    }

    private void DrawTexturedFrame(SpriteBatch sb, Rectangle rect, FrameStyle style)
    {
        // Gradient background fill
        DrawGradientBg(sb, rect, style);

        int cornerSize = _cornerTL!.Width;
        Color tint = style.AccentColor;

        // Four corners (TL as-is, TR/BL/BR flipped)
        sb.Draw(_cornerTL, new Rectangle(rect.X, rect.Y, cornerSize, cornerSize),
            null, tint, 0f, Vector2.Zero, SpriteEffects.None, 0f);
        sb.Draw(_cornerTL, new Rectangle(rect.Right - cornerSize, rect.Y, cornerSize, cornerSize),
            null, tint, 0f, Vector2.Zero, SpriteEffects.FlipHorizontally, 0f);
        sb.Draw(_cornerTL, new Rectangle(rect.X, rect.Bottom - cornerSize, cornerSize, cornerSize),
            null, tint, 0f, Vector2.Zero, SpriteEffects.FlipVertically, 0f);
        sb.Draw(_cornerTL, new Rectangle(rect.Right - cornerSize, rect.Bottom - cornerSize, cornerSize, cornerSize),
            null, tint, 0f, Vector2.Zero, SpriteEffects.FlipHorizontally | SpriteEffects.FlipVertically, 0f);

        // Top and bottom edges (tiled)
        int edgeW = _edgeH!.Width;
        int edgeH = _edgeH.Height;
        int hSpan = rect.Width - cornerSize * 2;
        for (int x = 0; x < hSpan; x += edgeW)
        {
            int w = Math.Min(edgeW, hSpan - x);
            var src = new Rectangle(0, 0, w, edgeH);
            // Top
            sb.Draw(_edgeH, new Rectangle(rect.X + cornerSize + x, rect.Y, w, edgeH), src, tint);
            // Bottom (flipped)
            sb.Draw(_edgeH, new Rectangle(rect.X + cornerSize + x, rect.Bottom - edgeH, w, edgeH),
                src, tint, 0f, Vector2.Zero, SpriteEffects.FlipVertically, 0f);
        }

        // Left and right edges (tiled)
        int vEdgeW = _edgeV!.Width;
        int vEdgeH = _edgeV.Height;
        int vSpan = rect.Height - cornerSize * 2;
        for (int y = 0; y < vSpan; y += vEdgeH)
        {
            int h = Math.Min(vEdgeH, vSpan - y);
            var src = new Rectangle(0, 0, vEdgeW, h);
            // Left
            sb.Draw(_edgeV, new Rectangle(rect.X, rect.Y + cornerSize + y, vEdgeW, h), src, tint);
            // Right (flipped)
            sb.Draw(_edgeV, new Rectangle(rect.Right - vEdgeW, rect.Y + cornerSize + y, vEdgeW, h),
                src, tint, 0f, Vector2.Zero, SpriteEffects.FlipHorizontally, 0f);
        }
    }

    private void DrawProceduralFrame(SpriteBatch sb, Rectangle rect, FrameStyle style)
    {
        // Outer shadow (2px)
        var shadowRect = new Rectangle(rect.X + 2, rect.Y + 2, rect.Width, rect.Height);
        sb.Draw(_pixel!, shadowRect, Color.Black * 0.4f);

        // Gradient background
        DrawGradientBg(sb, rect, style);

        // Inner highlight (1px top)
        sb.Draw(_pixel!, new Rectangle(rect.X + 2, rect.Y + 2, rect.Width - 4, 1),
            style.HighlightColor * 0.2f);

        // Inner shadow (1px bottom)
        sb.Draw(_pixel!, new Rectangle(rect.X + 2, rect.Bottom - 3, rect.Width - 4, 1),
            Color.Black * 0.3f);

        // Main border (2px)
        DrawBorder(sb, rect, style.BorderColor, 2);

        // Corner dots
        if (style.ShowCornerDots)
        {
            Color dot = style.AccentColor * 0.6f;
            sb.Draw(_pixel!, new Rectangle(rect.X + 2, rect.Y + 2, 3, 3), dot);
            sb.Draw(_pixel!, new Rectangle(rect.Right - 5, rect.Y + 2, 3, 3), dot);
            sb.Draw(_pixel!, new Rectangle(rect.X + 2, rect.Bottom - 5, 3, 3), dot);
            sb.Draw(_pixel!, new Rectangle(rect.Right - 5, rect.Bottom - 5, 3, 3), dot);
        }
    }

    private void DrawGradientBg(SpriteBatch sb, Rectangle rect, FrameStyle style)
    {
        int strips = 12;
        int stripH = Math.Max(1, rect.Height / strips);
        for (int i = 0; i < strips; i++)
        {
            float t = (float)i / (strips - 1);
            Color c = Color.Lerp(style.BgTop, style.BgBottom, t);
            int y = rect.Y + i * stripH;
            int h = (i == strips - 1) ? (rect.Bottom - y) : stripH;
            sb.Draw(_pixel!, new Rectangle(rect.X, y, rect.Width, h), c);
        }
    }

    /// <summary>
    /// Draws a title bar inset from the panel frame with a four-strip vertical gradient, separator line, and centered title text at 0.55 scale.
    /// </summary>
    /// <param name="sb">Sprite batch used to draw the title bar background and text.</param>
    /// <param name="font">Font used to measure and render the title text.</param>
    /// <param name="panelRect">Outer panel frame rectangle used to position the title bar.</param>
    /// <param name="title">Panel title text rendered in the title bar center.</param>
    /// <param name="style">Frame style values that provide bar and text colors.</param>
    /// <param name="height">Title bar height in pixels; defaults to 32.</param>
    public void DrawTitleBar(SpriteBatch sb, SpriteFont font, Rectangle panelRect, string title, FrameStyle style, int height = 32)
    {
        if (_pixel == null) return;

        var barRect = new Rectangle(panelRect.X + 2, panelRect.Y + 2, panelRect.Width - 4, height);

        // Title bar gradient
        int strips = 4;
        int stripH = Math.Max(1, barRect.Height / strips);
        for (int i = 0; i < strips; i++)
        {
            float t = (float)i / (strips - 1);
            Color c = Color.Lerp(style.TitleBgTop, style.TitleBgBottom, t);
            int y = barRect.Y + i * stripH;
            int h = (i == strips - 1) ? (barRect.Bottom - y) : stripH;
            sb.Draw(_pixel, new Rectangle(barRect.X, y, barRect.Width, h), c);
        }

        // Separator line
        sb.Draw(_pixel, new Rectangle(barRect.X, barRect.Bottom, barRect.Width, 1),
            style.BorderColor * 0.6f);

        // Centered title text with shadow
        Vector2 titleSize = font.MeasureString(title);
        float scale = 0.55f;
        Vector2 scaledSize = titleSize * scale;
        float titleX = barRect.X + (barRect.Width - scaledSize.X) / 2;
        float titleY = barRect.Y + (barRect.Height - scaledSize.Y) / 2;

        sb.DrawString(font, title, new Vector2(titleX + 1, titleY + 1), Color.Black * 0.5f,
            0f, Vector2.Zero, scale, SpriteEffects.None, 0f);
        sb.DrawString(font, title, new Vector2(titleX, titleY), style.TitleColor,
            0f, Vector2.Zero, scale, SpriteEffects.None, 0f);
    }

    private void DrawBorder(SpriteBatch sb, Rectangle rect, Color color, int thickness)
    {
        sb.Draw(_pixel!, new Rectangle(rect.X, rect.Y, rect.Width, thickness), color);
        sb.Draw(_pixel!, new Rectangle(rect.X, rect.Bottom - thickness, rect.Width, thickness), color);
        sb.Draw(_pixel!, new Rectangle(rect.X, rect.Y + thickness, thickness, rect.Height - thickness * 2), color);
        sb.Draw(_pixel!, new Rectangle(rect.Right - thickness, rect.Y + thickness, thickness, rect.Height - thickness * 2), color);
    }
}
