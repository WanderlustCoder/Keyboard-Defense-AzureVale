using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Myra.Graphics2D.UI;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Panel showing available spells, their keywords, cooldown status,
/// and effect descriptions. Players type spell keywords to cast.
/// </summary>
public class SpellPanel : BasePanel
{
    private readonly VerticalStackPanel _spellList;
    private readonly Label _summaryLabel;

    public SpellPanel() : base(Locale.Tr("panels.spells"))
    {
        RootWidget.Width = 500;
        RootWidget.Height = 420;

        _summaryLabel = new Label
        {
            Text = "Type a spell keyword in the command input to cast.",
            TextColor = ThemeColors.AccentCyan,
        };
        AddWidget(_summaryLabel);
        AddWidget(new HorizontalSeparator());

        _spellList = new VerticalStackPanel { Spacing = 8 };
        var scroll = new ScrollViewer
        {
            Content = _spellList,
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Stretch,
        };
        AddWidget(scroll);

        AddWidget(new HorizontalSeparator());
        AddWidget(new Label
        {
            Text = "Cast: Type the spell keyword and press Enter.",
            TextColor = ThemeColors.TextDim,
        });
    }

    public void Refresh(GameState state)
    {
        _spellList.Widgets.Clear();

        var system = SpellSystem.Instance;
        int readyCount = 0;

        foreach (var (keyword, def) in SpellSystem.Registry)
        {
            var spellState = system.GetState(keyword);
            bool isReady = spellState?.IsReady ?? false;
            if (isReady) readyCount++;

            var row = new VerticalStackPanel { Spacing = 2 };

            // Top line: name + keyword + cooldown status
            var topRow = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };

            topRow.Widgets.Add(new Label
            {
                Text = def.Name,
                TextColor = isReady ? ThemeColors.Accent : ThemeColors.TextDim,
                Width = 90,
            });

            topRow.Widgets.Add(new Label
            {
                Text = $"[{def.Keyword}]",
                TextColor = isReady ? ThemeColors.AccentCyan : ThemeColors.TextDisabled,
                Width = 90,
            });

            // Cooldown indicator
            if (isReady)
            {
                topRow.Widgets.Add(new Label
                {
                    Text = "READY",
                    TextColor = ThemeColors.Success,
                    Width = 80,
                });
            }
            else
            {
                float remaining = spellState?.CooldownRemaining ?? 0f;
                float total = def.CooldownSeconds;
                float pct = total > 0f ? remaining / total : 0f;
                string cdText = $"{MathF.Ceiling(remaining):F0}s / {total:F0}s";

                topRow.Widgets.Add(new Label
                {
                    Text = cdText,
                    TextColor = ThemeColors.Warning,
                    Width = 100,
                });
            }

            row.Widgets.Add(topRow);

            // Bottom line: description + effect preview
            var descRow = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };

            descRow.Widgets.Add(new Label
            {
                Text = $"  {def.Description}",
                TextColor = ThemeColors.Text,
            });

            string effectPreview = GetEffectPreview(def);
            if (!string.IsNullOrEmpty(effectPreview))
            {
                descRow.Widgets.Add(new Label
                {
                    Text = effectPreview,
                    TextColor = GetEffectColor(def.Effect),
                });
            }

            row.Widgets.Add(descRow);

            // Cooldown bar
            if (!isReady && spellState != null)
            {
                float remaining = spellState.CooldownRemaining;
                float total = def.CooldownSeconds;
                float pct = total > 0f ? 1f - (remaining / total) : 1f;
                int barWidth = (int)(280 * pct);

                var barContainer = new HorizontalStackPanel { Spacing = 0 };
                barContainer.Widgets.Add(new Label
                {
                    Text = "  " + new string('\u2588', Math.Max(0, barWidth / 8)) +
                           new string('\u2591', Math.Max(0, (280 - barWidth) / 8)),
                    TextColor = ThemeColors.TextDim,
                });
                row.Widgets.Add(barContainer);
            }

            _spellList.Widgets.Add(row);
            _spellList.Widgets.Add(new HorizontalSeparator());
        }

        _summaryLabel.Text = $"{readyCount}/{SpellSystem.Registry.Count} spells ready. " +
            "Type a spell keyword in the command input to cast.";
        _summaryLabel.TextColor = readyCount > 0 ? ThemeColors.AccentCyan : ThemeColors.TextDim;
    }

    private static string GetEffectPreview(SpellDef def)
    {
        return def.Effect switch
        {
            SpellEffect.AreaDamage => "(5 dmg to all)",
            SpellEffect.HealCastle => "(+3 HP)",
            SpellEffect.FreezeEnemies => "(5s slow)",
            SpellEffect.ShieldCastle => "(blocks 2 hits)",
            SpellEffect.InstantKill => "(kills weakest)",
            _ => "",
        };
    }

    private static Color GetEffectColor(SpellEffect effect)
    {
        return effect switch
        {
            SpellEffect.AreaDamage => ThemeColors.Error,
            SpellEffect.HealCastle => ThemeColors.Success,
            SpellEffect.FreezeEnemies => ThemeColors.Info,
            SpellEffect.ShieldCastle => ThemeColors.ShieldBlue,
            SpellEffect.InstantKill => ThemeColors.Warning,
            _ => ThemeColors.Text,
        };
    }
}
