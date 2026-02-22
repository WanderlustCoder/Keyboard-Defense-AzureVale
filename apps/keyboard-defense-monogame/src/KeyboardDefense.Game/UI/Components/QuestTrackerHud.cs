using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;
using KeyboardDefense.Game.Rendering;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// SpriteBatch-drawn quest tracker in top-right corner during exploration.
/// Shows up to 3 active quests with name and progress bar.
/// </summary>
public class QuestTrackerHud
{
    private readonly HudPainter _painter = new();

    private const int MaxDisplayQuests = 3;
    private const int BarWidth = 120;
    private const int BarHeight = 8;
    private const int PanelWidth = 200;
    private const int EntryHeight = 32;
    private const int PanelPadding = 8;

    private static readonly Color BgTop = new(20, 18, 32, 200);
    private static readonly Color BgBottom = new(12, 10, 22, 220);

    public void Initialize(GraphicsDevice device, SpriteFont font)
    {
        _painter.Initialize(device, font);
    }

    /// <summary>
    /// Draw quest tracker overlay. Call in screen space (no camera transform).
    /// Positioned in top-right, below the minimap.
    /// </summary>
    public void Draw(SpriteBatch spriteBatch, GameState state, int screenWidth, int screenHeight)
    {
        if (!_painter.IsReady) return;
        if (state.ActivityMode != "exploration") return;

        var activeQuests = Quests.GetActiveQuests(state);
        if (activeQuests.Count == 0) return;

        int displayed = Math.Min(activeQuests.Count, MaxDisplayQuests);
        int panelHeight = PanelPadding * 2 + displayed * EntryHeight + 20; // +20 for header

        int panelX = screenWidth - PanelWidth - 230; // Left of minimap with gap
        int panelY = 10;

        var panelRect = new Rectangle(panelX, panelY, PanelWidth, panelHeight);

        // Gradient background
        _painter.DrawGradientV(spriteBatch, panelRect, BgTop, BgBottom, 6);

        // Border
        _painter.DrawBorder(spriteBatch, panelRect, ThemeColors.Border * 0.6f, 1);

        // Gold header line
        _painter.DrawRect(spriteBatch,
            new Rectangle(panelX, panelY, PanelWidth, 1), ThemeColors.GoldAccent * 0.5f);

        // Header text
        _painter.DrawTextShadowed(spriteBatch,
            new Vector2(panelX + PanelPadding, panelY + PanelPadding),
            "QUESTS", ThemeColors.GoldAccent, 0.5f);

        int entryY = panelY + PanelPadding + 18;

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
            _painter.DrawTextShadowed(spriteBatch,
                new Vector2(panelX + PanelPadding, y), name, nameColor, 0.4f);

            // Progress bar with border
            int barX = panelX + PanelPadding;
            int barY = y + 14;

            if (completed)
            {
                _painter.DrawProgressBar(spriteBatch,
                    new Rectangle(barX, barY, BarWidth, BarHeight),
                    1f, ThemeColors.Success * 0.8f, Color.Black * 0.4f);
                _painter.DrawTextShadowed(spriteBatch,
                    new Vector2(barX + BarWidth + 4, barY - 2), "OK", ThemeColors.Success, 0.35f);
            }
            else if (target > 0)
            {
                float fill = MathHelper.Clamp((float)current / target, 0f, 1f);
                _painter.DrawProgressBar(spriteBatch,
                    new Rectangle(barX, barY, BarWidth, BarHeight),
                    fill, ThemeColors.AccentCyan * 0.8f, Color.Black * 0.4f);

                string progress = $"{current}/{target}";
                _painter.DrawTextShadowed(spriteBatch,
                    new Vector2(barX + BarWidth + 4, barY - 2), progress, ThemeColors.TextDim, 0.35f);
            }
        }
    }
}
