using System;
using Microsoft.Xna.Framework;
using Myra.Graphics2D.UI;

namespace KeyboardDefense.Game.UI;

/// <summary>
/// Factory for consistently styled UI buttons.
/// Ported from ui/base_button.gd (ButtonFactory).
/// </summary>
public static class ButtonFactory
{
    public static Button Primary(string text, Action? onClick = null)
    {
        var btn = CreateBase(text, ThemeColors.BtnPrimary, ThemeColors.BtnPrimaryHover);
        if (onClick != null) btn.Click += (_, _) => onClick();
        return btn;
    }

    public static Button Secondary(string text, Action? onClick = null)
    {
        var btn = CreateBase(text, ThemeColors.BtnSecondary, ThemeColors.BtnSecondaryHover);
        if (onClick != null) btn.Click += (_, _) => onClick();
        return btn;
    }

    public static Button Danger(string text, Action? onClick = null)
    {
        var btn = CreateBase(text, ThemeColors.DamageRed, new Color(220, 80, 80));
        if (onClick != null) btn.Click += (_, _) => onClick();
        return btn;
    }

    public static Button Ghost(string text, Action? onClick = null)
    {
        var btn = CreateBase(text, Color.Transparent, new Color(60, 60, 80));
        if (onClick != null) btn.Click += (_, _) => onClick();
        return btn;
    }

    public static Button Icon(string icon, string tooltip, Action? onClick = null)
    {
        var btn = CreateBase(icon, Color.Transparent, new Color(60, 60, 80));
        btn.Width = DesignSystem.ButtonHeightMd;
        if (onClick != null) btn.Click += (_, _) => onClick();
        return btn;
    }

    private static Button CreateBase(string text, Color bgColor, Color hoverColor)
    {
        var btn = new Button
        {
            Content = new Label
            {
                Text = text,
                TextColor = ThemeColors.Text,
            },
            Width = DesignSystem.ButtonWidthMd,
            Height = DesignSystem.ButtonHeightMd,
            HorizontalAlignment = HorizontalAlignment.Center,
            Background = new Myra.Graphics2D.Brushes.SolidBrush(bgColor),
            OverBackground = new Myra.Graphics2D.Brushes.SolidBrush(hoverColor),
            Border = new Myra.Graphics2D.Brushes.SolidBrush(ThemeColors.Border),
            BorderThickness = new Myra.Graphics2D.Thickness(1),
        };
        return btn;
    }
}
