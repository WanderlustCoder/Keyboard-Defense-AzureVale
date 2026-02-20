using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Myra.Graphics2D.UI;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.State;
using KeyboardDefense.Game.Services;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Panel for selecting tower targeting priority mode.
/// Ported from Godot's targeting mode selection UI.
/// </summary>
public class TargetingPanel : BasePanel
{
    private static readonly List<TargetingOption> Options = new()
    {
        new("nearest", "Nearest", "Target closest enemy to castle"),
        new("strongest", "Strongest", "Target enemy with highest HP"),
        new("fastest", "Fastest", "Target enemy with highest speed"),
        new("weakest", "Weakest", "Target enemy with lowest HP (finish them off)"),
        new("first", "First", "Target enemy that has been alive longest"),
    };

    private readonly VerticalStackPanel _optionList;
    private readonly List<Button> _optionButtons = new();

    public TargetingPanel() : base(Locale.Tr("panels.targeting"))
    {
        RootWidget.Width = 420;
        RootWidget.Height = 360;

        AddWidget(new Label
        {
            Text = Locale.Tr("panels.targeting_description"),
            TextColor = ThemeColors.TextDim,
            Wrap = true,
        });
        AddWidget(new HorizontalSeparator());

        _optionList = new VerticalStackPanel { Spacing = DesignSystem.SpaceSm };

        foreach (var option in Options)
        {
            var opt = option;
            var btn = CreateOptionButton(opt);
            _optionButtons.Add(btn);
            _optionList.Widgets.Add(btn);
        }

        AddWidget(_optionList);
    }

    public void Refresh(GameState state)
    {
        string current = state.TargetingMode;
        for (int i = 0; i < Options.Count; i++)
        {
            bool selected = Options[i].Id == current;
            UpdateButtonStyle(_optionButtons[i], Options[i], selected);
        }
    }

    private Button CreateOptionButton(TargetingOption option)
    {
        var layout = new VerticalStackPanel { Spacing = 2 };
        layout.Widgets.Add(new Label
        {
            Text = option.Name,
            TextColor = ThemeColors.Text,
        });
        layout.Widgets.Add(new Label
        {
            Text = option.Description,
            TextColor = ThemeColors.TextDim,
        });

        var btn = new Button
        {
            Content = layout,
            HorizontalAlignment = HorizontalAlignment.Stretch,
            Height = 52,
        };
        btn.Click += (_, _) =>
        {
            GameController.Instance.ApplyCommand($"target {option.Id}");
            Refresh(GameController.Instance.State);
        };
        return btn;
    }

    private static void UpdateButtonStyle(Button btn, TargetingOption option, bool selected)
    {
        if (btn.Content is VerticalStackPanel layout && layout.Widgets.Count >= 2)
        {
            var nameLabel = (Label)layout.Widgets[0];
            var descLabel = (Label)layout.Widgets[1];

            if (selected)
            {
                nameLabel.Text = $"> {option.Name} <";
                nameLabel.TextColor = ThemeColors.Accent;
                descLabel.TextColor = ThemeColors.Text;
            }
            else
            {
                nameLabel.Text = option.Name;
                nameLabel.TextColor = ThemeColors.Text;
                descLabel.TextColor = ThemeColors.TextDim;
            }
        }
    }

    private sealed record TargetingOption(string Id, string Name, string Description);
}
