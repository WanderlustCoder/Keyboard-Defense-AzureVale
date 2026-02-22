using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using KeyboardDefense.Game.UI;

namespace KeyboardDefense.Game.Rendering;

/// <summary>
/// SpriteBatch-rendered scrolling event log with color-coded entries and fade-out.
/// Replaces the Myra ScrollViewer-based event log in BattlefieldScreen.
/// </summary>
public class EventLogOverlay
{
    private readonly HudPainter _painter = new();
    private readonly List<LogEntry> _entries = new();
    private const int MaxEntries = 15;
    private const float EntryHeight = 16f;
    private const float TextScale = 0.4f;

    private static readonly Color BgTop = Color.Transparent;
    private static readonly Color BgBottom = new(10, 9, 18, 180);

    public void Initialize(GraphicsDevice device, SpriteFont font)
    {
        _painter.Initialize(device, font);
    }

    public void Append(string message)
    {
        var color = ClassifyColor(message);
        _entries.Add(new LogEntry(message, color));
        while (_entries.Count > MaxEntries)
            _entries.RemoveAt(0);
    }

    public void Draw(SpriteBatch sb, Rectangle bounds)
    {
        if (!_painter.IsReady || _entries.Count == 0) return;

        // Semi-transparent gradient background
        _painter.DrawGradientV(sb, bounds, BgTop, BgBottom, 6);

        // Left accent line
        _painter.DrawRect(sb, new Rectangle(bounds.X, bounds.Y, 2, bounds.Height), ThemeColors.Border * 0.4f);

        int count = _entries.Count;
        int visible = Math.Min(count, (int)(bounds.Height / EntryHeight));
        int startIdx = count - visible;

        for (int i = 0; i < visible; i++)
        {
            var entry = _entries[startIdx + i];
            float y = bounds.Y + bounds.Height - (visible - i) * EntryHeight;

            // Fade-out for top entries (first 3 visible entries fade)
            float alpha = 1f;
            if (i < 3)
                alpha = (i + 1) / 4f;

            var textColor = entry.Color * alpha;
            _painter.DrawTextShadowed(sb, new Vector2(bounds.X + 8, y), entry.Message, textColor, TextScale);
        }
    }

    private static Color ClassifyColor(string message)
    {
        // Damage events
        if (message.Contains("damage", StringComparison.OrdinalIgnoreCase) ||
            message.Contains("hit", StringComparison.OrdinalIgnoreCase) ||
            message.Contains("attack", StringComparison.OrdinalIgnoreCase))
            return ThemeColors.DamageRed;

        // Gold/reward events
        if (message.Contains("gold", StringComparison.OrdinalIgnoreCase) ||
            message.Contains("reward", StringComparison.OrdinalIgnoreCase) ||
            message.Contains("earned", StringComparison.OrdinalIgnoreCase))
            return ThemeColors.ResourceGold;

        // Combat phase events
        if (message.Contains("night", StringComparison.OrdinalIgnoreCase) ||
            message.Contains("wave", StringComparison.OrdinalIgnoreCase) ||
            message.Contains("spawn", StringComparison.OrdinalIgnoreCase))
            return ThemeColors.AccentCyan;

        // Milestone/achievement events
        if (message.Contains("milestone", StringComparison.OrdinalIgnoreCase) ||
            message.Contains("achievement", StringComparison.OrdinalIgnoreCase))
            return ThemeColors.GoldAccent;

        // System/info
        return ThemeColors.Text;
    }

    private record LogEntry(string Message, Color Color);
}
