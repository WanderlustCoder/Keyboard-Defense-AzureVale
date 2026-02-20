using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using KeyboardDefense.Game.UI;

namespace KeyboardDefense.Game.Input;

/// <summary>
/// Visual keyboard display with key highlighting, finger zones, and feedback.
/// Ported from game/keyboard_display.gd (358 lines).
/// </summary>
public class KeyboardDisplay
{
    private static readonly string[][] Rows =
    {
        new[] { "`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=" },
        new[] { "q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "[", "]", "\\" },
        new[] { "a", "s", "d", "f", "g", "h", "j", "k", "l", ";", "'" },
        new[] { "z", "x", "c", "v", "b", "n", "m", ",", ".", "/" },
        new[] { " " },
    };

    private static readonly float[] RowOffsets = { 0f, 0.5f, 0.75f, 1.25f, 3.5f };

    private static readonly Dictionary<string, int> FingerZones = new()
    {
        ["`"] = 0, ["1"] = 0, ["q"] = 0, ["a"] = 0, ["z"] = 0,
        ["2"] = 1, ["w"] = 1, ["s"] = 1, ["x"] = 1,
        ["3"] = 2, ["e"] = 2, ["d"] = 2, ["c"] = 2,
        ["4"] = 3, ["5"] = 3, ["r"] = 3, ["t"] = 3, ["f"] = 3, ["g"] = 3, ["v"] = 3, ["b"] = 3,
        ["6"] = 4, ["7"] = 4, ["y"] = 4, ["h"] = 4, ["u"] = 4, ["j"] = 4, ["n"] = 4, ["m"] = 4,
        ["8"] = 5, ["i"] = 5, ["k"] = 5, [","] = 5,
        ["9"] = 6, ["o"] = 6, ["l"] = 6, ["."] = 6,
        ["0"] = 7, ["-"] = 7, ["="] = 7, ["p"] = 7, [";"] = 7, ["'"] = 7, ["/"] = 7,
        ["["] = 7, ["]"] = 7, ["\\"] = 7,
        [" "] = 8,
    };

    private static readonly Color[] FingerColors =
    {
        new(180, 80, 80),   // Left pinky
        new(200, 130, 60),  // Left ring
        new(200, 180, 60),  // Left middle
        new(100, 180, 80),  // Left index
        new(80, 160, 180),  // Right index
        new(100, 120, 200), // Right middle
        new(140, 80, 200),  // Right ring
        new(180, 80, 160),  // Right pinky
        new(120, 120, 140), // Thumbs
    };

    private const float KeySize = 40f;
    private const float KeyGap = 4f;
    private const float FlashDuration = 0.3f;

    private readonly Dictionary<string, float> _flashTimers = new();
    private readonly Dictionary<string, bool> _flashCorrect = new();
    private HashSet<string> _activeCharset = new();
    private string _nextKey = "";

    private Texture2D? _pixel;
    private SpriteFont? _font;

    public void Initialize(GraphicsDevice device, SpriteFont font)
    {
        _pixel = new Texture2D(device, 1, 1);
        _pixel.SetData(new[] { Color.White });
        _font = font;
    }

    public void UpdateState(IEnumerable<string> charset, string nextKey)
    {
        _activeCharset = new HashSet<string>(charset.Select(c => c.ToLowerInvariant()));
        _nextKey = nextKey.ToLowerInvariant();
    }

    public void FlashKey(string key, bool correct)
    {
        string k = key.ToLowerInvariant();
        _flashTimers[k] = FlashDuration;
        _flashCorrect[k] = correct;
    }

    public void Update(GameTime gameTime)
    {
        float dt = (float)gameTime.ElapsedGameTime.TotalSeconds;
        var expired = new List<string>();
        foreach (var (key, timer) in _flashTimers)
        {
            _flashTimers[key] = timer - dt;
            if (_flashTimers[key] <= 0)
                expired.Add(key);
        }
        foreach (var key in expired)
        {
            _flashTimers.Remove(key);
            _flashCorrect.Remove(key);
        }
    }

    public void Draw(SpriteBatch spriteBatch, Vector2 position, float totalTime)
    {
        if (_pixel == null || _font == null) return;

        float totalWidth = 14 * (KeySize + KeyGap);
        float startX = position.X - totalWidth * 0.5f;

        for (int row = 0; row < Rows.Length; row++)
        {
            float rowOffset = RowOffsets[row] * (KeySize + KeyGap);
            float x = startX + rowOffset;
            float y = position.Y + row * (KeySize + KeyGap);

            foreach (string key in Rows[row])
            {
                float width = key == " " ? KeySize * 6 + KeyGap * 5 : KeySize;
                var rect = new Rectangle((int)x, (int)y, (int)width, (int)KeySize);

                Color bgColor = GetKeyColor(key, totalTime);
                spriteBatch.Draw(_pixel, rect, bgColor);

                // Key label
                string label = key == " " ? "SPACE" : key.ToUpperInvariant();
                var textSize = _font.MeasureString(label);
                float scale = Math.Min(0.7f, (width - 8) / Math.Max(1, textSize.X));
                spriteBatch.DrawString(_font, label,
                    new Vector2(rect.X + (width - textSize.X * scale) * 0.5f,
                                rect.Y + (KeySize - textSize.Y * scale) * 0.5f),
                    Color.White, 0f, Vector2.Zero, scale, SpriteEffects.None, 0f);

                x += width + KeyGap;
            }
        }
    }

    private Color GetKeyColor(string key, float totalTime)
    {
        string k = key.ToLowerInvariant();

        // Flash override
        if (_flashTimers.TryGetValue(k, out float timer))
        {
            float t = timer / FlashDuration;
            return _flashCorrect.GetValueOrDefault(k, true)
                ? Color.Lerp(new Color(40, 40, 50), ThemeColors.HealGreen, t)
                : Color.Lerp(new Color(40, 40, 50), ThemeColors.DamageRed, t);
        }

        // Next key pulsing
        if (k == _nextKey)
        {
            float pulse = 0.5f + 0.5f * MathF.Sin(totalTime * 4f);
            return Color.Lerp(new Color(60, 60, 80), ThemeColors.Cyan, pulse);
        }

        // Active charset highlight
        if (_activeCharset.Contains(k))
        {
            int finger = FingerZones.GetValueOrDefault(k, 8);
            Color fingerColor = finger < FingerColors.Length ? FingerColors[finger] : new Color(80, 80, 100);
            return new Color(fingerColor.R / 3, fingerColor.G / 3, fingerColor.B / 3);
        }

        // Inactive
        return new Color(30, 30, 40);
    }
}
