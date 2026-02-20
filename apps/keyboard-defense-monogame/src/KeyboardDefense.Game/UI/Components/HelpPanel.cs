using Microsoft.Xna.Framework;
using Myra.Graphics2D.UI;
using KeyboardDefense.Core.Data;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Help panel showing available commands and keyboard shortcuts.
/// </summary>
public class HelpPanel : BasePanel
{
    public HelpPanel() : base(Locale.Tr("ui.help"))
    {
        RootWidget.Width = 550;
        RootWidget.Height = 500;

        AddSection("Day Phase Commands", new[]
        {
            ("gather [resource]", "Gather wood, stone, or food"),
            ("build [type] [x] [y]", "Build a structure (tower, wall, farm, etc.)"),
            ("explore", "Explore a new area on the map"),
            ("status", "View current game state"),
            ("help", "Show available commands"),
            ("end", "End day phase and begin night defense"),
        });

        AddWidget(new HorizontalSeparator());

        AddSection("Night Phase", new[]
        {
            ("Type enemy words", "Type the word shown on an enemy to damage it"),
            ("wait", "Skip a turn (enemies advance)"),
        });

        AddWidget(new HorizontalSeparator());

        AddSection("Keyboard Shortcuts", new[]
        {
            ("F1", "Help (this panel)"),
            ("F2", "Settings"),
            ("F3", "Typing Stats"),
            ("F4", "Bestiary"),
            ("F5", "Save/Load"),
            ("F6", "Quests"),
            ("F7", "Upgrades"),
            ("F8", "Trade / Crafting"),
            ("F9", "Achievements"),
            ("F10", "Active Buffs"),
            ("F11", "Inventory / Equipment"),
            ("F12", "Difficulty"),
            ("Escape", "Close any open panel"),
            ("Enter", "Submit typed command/word"),
        });

        AddWidget(new HorizontalSeparator());

        AddSection("Tips", new[]
        {
            ("Combo", "Chain correct words for bonus damage"),
            ("Accuracy", "Higher accuracy earns better rewards"),
            ("Explore", "Discover resources and quests on the map"),
            ("Build", "Towers auto-attack enemies at night"),
        });
    }

    private void AddSection(string title, (string Key, string Description)[] entries)
    {
        AddWidget(new Label
        {
            Text = title,
            TextColor = ThemeColors.AccentCyan,
        });

        foreach (var (key, desc) in entries)
        {
            var row = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };
            row.Widgets.Add(new Label
            {
                Text = key,
                TextColor = ThemeColors.Accent,
                Width = 180,
            });
            row.Widgets.Add(new Label
            {
                Text = desc,
                TextColor = ThemeColors.Text,
            });
            AddWidget(row);
        }
    }
}
