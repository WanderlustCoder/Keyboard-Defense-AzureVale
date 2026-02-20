using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using KeyboardDefense.Game.UI;

namespace KeyboardDefense.Game.Rendering;

/// <summary>
/// QWERTY keyboard overlay with finger zone colors, key flash on press,
/// and next-expected-key highlight.
/// </summary>
public class KeyboardOverlay
{
    private Texture2D? _pixel;
    private SpriteFont? _font;

    private const int KeySize = 38;
    private const int KeySpacing = 4;
    private const int SpaceWidth = 240;
    private const int WideKeyWidth = 60;
    private const float FlashDuration = 0.2f;
    private const float PulseSpeed = 4f;

    // Key flash timers
    private readonly Dictionary<char, float> _flashTimers = new();

    // Next expected character (highlighted)
    private char _expectedChar;

    // Characters to highlight as part of the active lesson's finger zone
    private HashSet<char> _highlightedChars = new();

    // Finger zone colors (0=left pinky, 1=left ring, 2=left middle, 3=left index,
    // 4=right index, 5=right middle, 6=right ring, 7=right pinky)
    private static readonly Color[] FingerColors = new Color[]
    {
        new(180, 100, 150),  // left pinky - pink
        new(100, 130, 200),  // left ring - blue
        new(100, 180, 100),  // left middle - green
        new(200, 150, 80),   // left index - orange
        new(200, 150, 80),   // right index - orange
        new(100, 180, 100),  // right middle - green
        new(100, 130, 200),  // right ring - blue
        new(180, 100, 150),  // right pinky - pink
    };

    private static readonly string[] Rows = new[]
    {
        "qwertyuiop",
        "asdfghjkl;",
        "zxcvbnm,./"
    };

    // Finger zone index for each key by row
    private static readonly int[][] FingerZones = new[]
    {
        new[] { 0, 1, 2, 3, 3, 4, 4, 5, 6, 7 }, // top row
        new[] { 0, 1, 2, 3, 3, 4, 4, 5, 6, 7 }, // home row
        new[] { 0, 1, 2, 3, 3, 4, 5, 6, 7, 7 }, // bottom row
    };

    private float _totalTime;

    public void Initialize(GraphicsDevice device, SpriteFont font)
    {
        _pixel = new Texture2D(device, 1, 1);
        _pixel.SetData(new[] { Color.White });
        _font = font;
    }

    public void SetExpectedChar(char c)
    {
        _expectedChar = char.ToLower(c);
    }

    public void FlashKey(char c)
    {
        _flashTimers[char.ToLower(c)] = FlashDuration;
    }

    /// <summary>Set the chars to highlight as the active lesson's target finger zone.</summary>
    public void SetHighlightedChars(HashSet<char> chars)
    {
        _highlightedChars = chars;
    }

    /// <summary>Clear the finger zone highlight.</summary>
    public void ClearHighlightedChars()
    {
        _highlightedChars = new HashSet<char>();
    }

    public void Update(GameTime gameTime)
    {
        float dt = (float)gameTime.ElapsedGameTime.TotalSeconds;
        _totalTime += dt;

        // Decay flash timers
        var keys = new List<char>(_flashTimers.Keys);
        foreach (char key in keys)
        {
            _flashTimers[key] -= dt;
            if (_flashTimers[key] <= 0f)
                _flashTimers.Remove(key);
        }
    }

    public void Draw(SpriteBatch spriteBatch, Vector2 origin)
    {
        if (_pixel == null || _font == null) return;

        spriteBatch.Begin(
            blendState: BlendState.AlphaBlend,
            samplerState: SamplerState.PointClamp);

        // Draw background
        int totalWidth = 10 * (KeySize + KeySpacing) + 40;
        int totalHeight = 3 * (KeySize + KeySpacing) + KeySize + KeySpacing + 20; // rows + spacebar
        var bgRect = new Rectangle((int)origin.X - 10, (int)origin.Y - 8, totalWidth + 20, totalHeight + 16);
        spriteBatch.Draw(_pixel!, bgRect, new Color(15, 12, 25) * 0.9f);

        // Draw keyboard rows
        float[] rowOffsets = { 0, 15, 30 }; // Staggered QWERTY layout

        for (int row = 0; row < Rows.Length; row++)
        {
            string rowKeys = Rows[row];
            float rowX = origin.X + rowOffsets[row];
            float rowY = origin.Y + row * (KeySize + KeySpacing);

            for (int col = 0; col < rowKeys.Length; col++)
            {
                char c = rowKeys[col];
                float x = rowX + col * (KeySize + KeySpacing);

                int fingerIdx = col < FingerZones[row].Length ? FingerZones[row][col] : 7;
                bool isHighlighted = _highlightedChars.Count > 0 && _highlightedChars.Contains(c);
                // Highlighted chars (lesson target zone) are brighter
                float zoneAlpha = isHighlighted ? 0.6f : (_highlightedChars.Count > 0 ? 0.15f : 0.3f);
                Color baseColor = FingerColors[fingerIdx] * zoneAlpha;

                // Flash effect
                bool isFlashing = _flashTimers.TryGetValue(c, out float flashTime) && flashTime > 0;
                if (isFlashing)
                {
                    float flashT = flashTime / FlashDuration;
                    baseColor = Color.Lerp(baseColor, new Color(255, 230, 100), flashT * 0.8f);
                }

                // Expected char highlight (pulsing border)
                bool isExpected = c == _expectedChar;

                var keyRect = new Rectangle((int)x, (int)rowY, KeySize, KeySize);

                // Key background
                spriteBatch.Draw(_pixel!, keyRect, baseColor);

                // Key border
                Color borderColor = isExpected
                    ? ThemeColors.AccentCyan * (0.6f + MathF.Sin(_totalTime * PulseSpeed) * 0.4f)
                    : ThemeColors.Border * 0.5f;
                int borderThick = isExpected ? 2 : 1;
                DrawRectOutline(spriteBatch, keyRect, borderColor, borderThick);

                // Key label
                string label = c.ToString().ToUpper();
                var labelSize = _font.MeasureString(label);
                spriteBatch.DrawString(_font, label,
                    new Vector2(x + (KeySize - labelSize.X) * 0.5f, rowY + (KeySize - labelSize.Y) * 0.5f),
                    isExpected ? ThemeColors.AccentCyan : Color.White * 0.9f);
            }
        }

        // Spacebar
        float spaceY = origin.Y + 3 * (KeySize + KeySpacing);
        float spaceX = origin.X + 80;
        bool spaceFlash = _flashTimers.TryGetValue(' ', out float sFlash) && sFlash > 0;
        bool spaceExpected = _expectedChar == ' ';

        Color spaceColor = new Color(40, 35, 55);
        if (spaceFlash)
            spaceColor = Color.Lerp(spaceColor, new Color(255, 230, 100), (sFlash / FlashDuration) * 0.8f);

        var spaceRect = new Rectangle((int)spaceX, (int)spaceY, SpaceWidth, KeySize - 4);
        spriteBatch.Draw(_pixel!, spaceRect, spaceColor);

        Color spaceBorder = spaceExpected
            ? ThemeColors.AccentCyan * (0.6f + MathF.Sin(_totalTime * PulseSpeed) * 0.4f)
            : ThemeColors.Border * 0.5f;
        DrawRectOutline(spriteBatch, spaceRect, spaceBorder, spaceExpected ? 2 : 1);

        string spaceLabel = "SPACE";
        var spaceLabelSize = _font.MeasureString(spaceLabel);
        spriteBatch.DrawString(_font, spaceLabel,
            new Vector2(spaceX + (SpaceWidth - spaceLabelSize.X * 0.7f) * 0.5f, spaceY + 6),
            Color.White * 0.6f, 0f, Vector2.Zero, 0.7f, SpriteEffects.None, 0f);

        spriteBatch.End();
    }

    /// <summary>
    /// Total height of the keyboard display.
    /// </summary>
    public int TotalHeight => 4 * (KeySize + KeySpacing) + 16;

    private void DrawRectOutline(SpriteBatch spriteBatch, Rectangle rect, Color color, int thickness)
    {
        spriteBatch.Draw(_pixel!, new Rectangle(rect.X, rect.Y, rect.Width, thickness), color);
        spriteBatch.Draw(_pixel!, new Rectangle(rect.X, rect.Bottom - thickness, rect.Width, thickness), color);
        spriteBatch.Draw(_pixel!, new Rectangle(rect.X, rect.Y, thickness, rect.Height), color);
        spriteBatch.Draw(_pixel!, new Rectangle(rect.Right - thickness, rect.Y, thickness, rect.Height), color);
    }
}
