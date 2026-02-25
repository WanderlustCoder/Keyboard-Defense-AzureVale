using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using KeyboardDefense.Game.Services;
using KeyboardDefense.Game.UI;

namespace KeyboardDefense.Game.Rendering;

/// <summary>
/// Draws SpriteBatch frames around active Myra panels.
/// Queries the panel's RootWidget bounds and FrameStyle to render
/// a procedural dark-fantasy border via NineSliceFrame.
/// </summary>
public class PanelFrameRenderer
{
    private readonly NineSliceFrame _frame = new();
    private SpriteFont? _font;

    /// <summary>
    /// Initializes the panel frame renderer resources and attempts to load frame textures from the shared asset loader.
    /// </summary>
    /// <param name="device">Graphics device used by the underlying frame renderer.</param>
    /// <param name="font">Font cached for title bar text rendering.</param>
    public void Initialize(GraphicsDevice device, SpriteFont font)
    {
        _frame.Initialize(device, font);
        _frame.LoadFrameTextures(AssetLoader.Instance);
        _font = font;
    }

    /// <summary>
    /// Gets whether the underlying frame renderer is initialized and ready to draw panel frames.
    /// </summary>
    public bool IsReady => _frame.IsReady;

    /// <summary>
    /// Draws a frame and title bar around a visible panel using the panel root bounds expanded by 4 pixels on each side.
    /// </summary>
    /// <param name="sb">Sprite batch used to draw frame and title bar geometry.</param>
    /// <param name="panel">Panel whose style, title, and bounds determine the rendered frame.</param>
    public void DrawPanelFrame(SpriteBatch sb, BasePanel panel)
    {
        if (!_frame.IsReady || _font == null) return;
        if (!panel.Visible) return;

        var root = panel.RootWidget;
        if (root.Bounds.Width <= 0 || root.Bounds.Height <= 0) return;

        var bounds = root.Bounds;
        // Expand slightly to draw frame around the Myra widget
        var frameRect = new Rectangle(bounds.X - 4, bounds.Y - 4, bounds.Width + 8, bounds.Height + 8);

        _frame.DrawFrame(sb, frameRect, panel.Style);
        _frame.DrawTitleBar(sb, _font, frameRect, panel.Title, panel.Style);
    }
}
