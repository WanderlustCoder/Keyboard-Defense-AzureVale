using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using KeyboardDefense.Game.UI;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Debug performance overlay showing FPS, memory usage, and draw call estimate.
/// Toggle visibility with F3 key. Draws in top-right corner.
/// </summary>
public class PerfOverlay
{
    private const float UpdateInterval = 0.5f;
    private const int Padding = 8;
    private const int LineHeight = 18;

    private SpriteBatch _spriteBatch;
    private SpriteFont _font;
    private Texture2D _pixel;

    private bool _visible;
    private KeyboardState _previousKeyState;

    // FPS tracking
    private int _frameCount;
    private float _elapsed;
    private float _fps;

    // Memory tracking
    private long _managedMemoryBytes;

    // Draw call estimate (incremented externally or estimated from SpriteBatch usage)
    private int _drawCallEstimate;
    private int _lastDrawCallEstimate;

    public PerfOverlay(GraphicsDevice graphicsDevice, SpriteBatch spriteBatch, SpriteFont font)
    {
        _spriteBatch = spriteBatch;
        _font = font;

        _pixel = new Texture2D(graphicsDevice, 1, 1);
        _pixel.SetData(new[] { Color.White });

        _previousKeyState = Keyboard.GetState();
    }

    /// <summary>
    /// Call once per frame from the game's Update method.
    /// </summary>
    public void Update(GameTime gameTime)
    {
        // Toggle with F3
        var currentKeyState = Keyboard.GetState();
        if (currentKeyState.IsKeyDown(Keys.F3) && _previousKeyState.IsKeyUp(Keys.F3))
            _visible = !_visible;
        _previousKeyState = currentKeyState;

        if (!_visible) return;

        _frameCount++;
        _elapsed += (float)gameTime.ElapsedGameTime.TotalSeconds;

        if (_elapsed >= UpdateInterval)
        {
            _fps = _frameCount / _elapsed;
            _managedMemoryBytes = GC.GetTotalMemory(false);
            _lastDrawCallEstimate = _drawCallEstimate;

            _frameCount = 0;
            _elapsed = 0f;
        }

        // Reset draw call counter each frame
        _drawCallEstimate = 0;
    }

    /// <summary>
    /// Increment draw call estimate. Call this from rendering code
    /// each time SpriteBatch.Begin/End is invoked, or pass a batch count.
    /// </summary>
    public void AddDrawCalls(int count = 1)
    {
        _drawCallEstimate += count;
    }

    /// <summary>
    /// Call once per frame from the game's Draw method, after all other drawing.
    /// </summary>
    public void Draw()
    {
        if (!_visible) return;

        string fpsText = $"FPS: {_fps:F1}";
        string memText = $"MEM: {_managedMemoryBytes / (1024.0 * 1024.0):F1} MB";
        string drawText = $"DRAW: ~{_lastDrawCallEstimate}";

        // Measure text widths to determine background size
        var fpsSize = _font.MeasureString(fpsText);
        var memSize = _font.MeasureString(memText);
        var drawSize = _font.MeasureString(drawText);

        float maxWidth = MathF.Max(fpsSize.X, MathF.Max(memSize.X, drawSize.X));
        int bgWidth = (int)maxWidth + Padding * 2;
        int bgHeight = LineHeight * 3 + Padding * 2;

        // Position in top-right corner
        int screenWidth = _spriteBatch.GraphicsDevice.Viewport.Width;
        int bgX = screenWidth - bgWidth - Padding;
        int bgY = Padding;

        _spriteBatch.Begin(
            blendState: BlendState.AlphaBlend,
            samplerState: SamplerState.PointClamp);

        // Semi-transparent background
        _spriteBatch.Draw(_pixel,
            new Rectangle(bgX, bgY, bgWidth, bgHeight),
            new Color(0, 0, 0) * 0.7f);

        // FPS text - color coded
        Color fpsColor = _fps >= 55f ? ThemeColors.Success
            : _fps >= 30f ? ThemeColors.Warning
            : ThemeColors.Error;

        float textX = bgX + Padding;
        float textY = bgY + Padding;

        _spriteBatch.DrawString(_font, fpsText,
            new Vector2(textX, textY), fpsColor,
            0f, Vector2.Zero, 0.8f, SpriteEffects.None, 0f);

        _spriteBatch.DrawString(_font, memText,
            new Vector2(textX, textY + LineHeight), ThemeColors.AccentBlue,
            0f, Vector2.Zero, 0.8f, SpriteEffects.None, 0f);

        _spriteBatch.DrawString(_font, drawText,
            new Vector2(textX, textY + LineHeight * 2), ThemeColors.TextDim,
            0f, Vector2.Zero, 0.8f, SpriteEffects.None, 0f);

        _spriteBatch.End();
    }
}
