using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// SpriteBatch-drawn quest tracker in top-right corner during exploration.
/// Shows up to 3 active quests with name and progress bar.
/// </summary>
public class QuestTrackerHud
{
    private Texture2D? _pixel;
    private SpriteFont? _font;

    private const int MaxDisplayQuests = 3;
    private const int BarWidth = 120;
    private const int BarHeight = 8;
    private const int PanelWidth = 200;
    private const int EntryHeight = 32;
    private const int PanelPadding = 8;

    public void Initialize(GraphicsDevice device, SpriteFont font)
    {
        _pixel = new Texture2D(device, 1, 1);
        _pixel.SetData(new[] { Color.White });
        _font = font;
    }

    /// <summary>
    /// Draw quest tracker overlay. Call in screen space (no camera transform).
    /// Positioned in top-right, below the minimap.
    /// </summary>
    public void Draw(SpriteBatch spriteBatch, GameState state, int screenWidth, int screenHeight)
    {
        if (_pixel == null || _font == null) return;
        if (state.ActivityMode != "exploration") return;

        var activeQuests = Quests.GetActiveQuests(state);
        if (activeQuests.Count == 0) return;

        int displayed = Math.Min(activeQuests.Count, MaxDisplayQuests);
        int panelHeight = PanelPadding * 2 + displayed * EntryHeight + 16; // +16 for header

        int panelX = screenWidth - PanelWidth - 220; // Left of minimap
        int panelY = 10;

        // Background
        spriteBatch.Draw(_pixel, new Rectangle(panelX, panelY, PanelWidth, panelHeight),
            Color.Black * 0.5f);

        // Header
        spriteBatch.DrawString(_font, "QUESTS",
            new Vector2(panelX + PanelPadding, panelY + PanelPadding),
            ThemeColors.GoldAccent,
            0f, Vector2.Zero, 0.5f, SpriteEffects.None, 0f);

        int entryY = panelY + PanelPadding + 16;

        for (int i = 0; i < displayed; i++)
        {
            string questId = activeQuests[i];
            var def = Quests.GetQuest(questId);
            if (def == null) continue;

            var (current, target) = WorldQuests.GetProgress(state, questId);
            bool completed = state.CompletedQuests.Contains(questId);

            int y = entryY + i * EntryHeight;

            // Quest name
            string name = def.Name.Length > 20 ? def.Name[..20] + ".." : def.Name;
            Color nameColor = completed ? ThemeColors.Success : ThemeColors.Text;
            spriteBatch.DrawString(_font, name,
                new Vector2(panelX + PanelPadding, y),
                nameColor,
                0f, Vector2.Zero, 0.4f, SpriteEffects.None, 0f);

            // Progress bar
            int barX = panelX + PanelPadding;
            int barY = y + 14;

            spriteBatch.Draw(_pixel, new Rectangle(barX, barY, BarWidth, BarHeight),
                Color.Black * 0.4f);

            if (completed)
            {
                // Full green bar + checkmark
                spriteBatch.Draw(_pixel, new Rectangle(barX, barY, BarWidth, BarHeight),
                    ThemeColors.Success * 0.8f);
                spriteBatch.DrawString(_font, "OK",
                    new Vector2(barX + BarWidth + 4, barY - 2),
                    ThemeColors.Success,
                    0f, Vector2.Zero, 0.35f, SpriteEffects.None, 0f);
            }
            else if (target > 0)
            {
                float fill = MathHelper.Clamp((float)current / target, 0f, 1f);
                spriteBatch.Draw(_pixel, new Rectangle(barX, barY, (int)(BarWidth * fill), BarHeight),
                    ThemeColors.AccentCyan * 0.8f);

                // Progress text
                string progress = $"{current}/{target}";
                spriteBatch.DrawString(_font, progress,
                    new Vector2(barX + BarWidth + 4, barY - 2),
                    ThemeColors.TextDim,
                    0f, Vector2.Zero, 0.35f, SpriteEffects.None, 0f);
            }
        }
    }
}
