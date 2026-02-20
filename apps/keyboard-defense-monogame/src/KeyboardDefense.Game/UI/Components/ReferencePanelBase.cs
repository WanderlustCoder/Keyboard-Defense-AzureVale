using System.Collections.Generic;
using Myra.Graphics2D.UI;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Base class for read-only reference panels that display categorized data.
/// Replaces 60+ individual Godot reference panel files with a single template.
/// </summary>
public class ReferencePanelBase : BasePanel
{
    public ReferencePanelBase(string title, List<ReferenceSection> sections) : base(title)
    {
        RootWidget.Width = 600;
        RootWidget.Height = 500;

        var content = new VerticalStackPanel { Spacing = 4 };

        foreach (var section in sections)
        {
            // Section header
            content.Widgets.Add(new Label
            {
                Text = section.Title,
                TextColor = ThemeColors.Accent,
            });
            content.Widgets.Add(new HorizontalSeparator());

            if (!string.IsNullOrEmpty(section.Description))
            {
                content.Widgets.Add(new Label
                {
                    Text = section.Description,
                    TextColor = ThemeColors.TextDim,
                    Wrap = true,
                });
            }

            foreach (var entry in section.Entries)
            {
                var row = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };

                if (!string.IsNullOrEmpty(entry.Label))
                {
                    row.Widgets.Add(new Label
                    {
                        Text = entry.Label,
                        TextColor = entry.LabelColor ?? ThemeColors.AccentCyan,
                        Width = 180,
                    });
                }

                row.Widgets.Add(new Label
                {
                    Text = entry.Value,
                    TextColor = entry.ValueColor ?? ThemeColors.Text,
                    Wrap = true,
                });

                content.Widgets.Add(row);
            }

            content.Widgets.Add(new Panel { Height = DesignSystem.SpaceXs });
        }

        var scroll = new ScrollViewer
        {
            Content = content,
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Stretch,
        };
        AddWidget(scroll);
    }
}

public class ReferenceSection
{
    public string Title { get; set; } = "";
    public string? Description { get; set; }
    public List<ReferenceEntry> Entries { get; set; } = new();
}

public class ReferenceEntry
{
    public string? Label { get; set; }
    public string Value { get; set; } = "";
    public Microsoft.Xna.Framework.Color? LabelColor { get; set; }
    public Microsoft.Xna.Framework.Color? ValueColor { get; set; }
}
