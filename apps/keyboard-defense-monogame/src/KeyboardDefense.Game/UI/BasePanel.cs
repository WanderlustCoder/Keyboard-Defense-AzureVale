using System;
using Microsoft.Xna.Framework;
using Myra.Graphics2D.Brushes;
using Myra.Graphics2D.UI;

namespace KeyboardDefense.Game.UI;

/// <summary>
/// Base panel class for all game UI panels (overlays, menus, info panels).
/// Ported from ui/base_panel.gd.
/// </summary>
public class BasePanel
{
    public string Title { get; set; }
    public bool Visible { get; set; }
    public Panel RootWidget { get; }
    public FrameStyle Style { get; set; } = FrameStyles.Default;

    private readonly VerticalStackPanel _content;
    private readonly Label _titleLabel;

    // Animation
    private readonly TweenValue _fadeAnim = new(0f);
    private readonly TweenValue _slideAnim = new(0f);

    public event Action? Opened;
    public event Action? Closed;

    public BasePanel(string title)
    {
        Title = title;

        RootWidget = new Panel
        {
            Width = 500,
            Height = 400,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
            Visible = false,
            Background = new SolidBrush(ThemeColors.BgPanel),
            Border = new SolidBrush(ThemeColors.Border),
            BorderThickness = new Myra.Graphics2D.Thickness(1),
            Padding = new Myra.Graphics2D.Thickness(8, 36, 8, 8),
        };

        var layout = new VerticalStackPanel { Spacing = DesignSystem.SpacingMd };

        // Title bar
        var titleBar = new HorizontalStackPanel { Spacing = DesignSystem.SpacingSm };
        _titleLabel = new Label
        {
            Text = title,
            TextColor = ThemeColors.Accent,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        var closeBtn = ButtonFactory.Ghost("X", Close);
        closeBtn.HorizontalAlignment = HorizontalAlignment.Right;
        closeBtn.Width = 32;
        closeBtn.Height = 32;
        closeBtn.OverBackground = new SolidBrush(ThemeColors.DamageRed * 0.3f);

        titleBar.Widgets.Add(_titleLabel);
        titleBar.Widgets.Add(closeBtn);
        layout.Widgets.Add(titleBar);

        // Separator
        layout.Widgets.Add(new HorizontalSeparator());

        // Content area
        _content = new VerticalStackPanel { Spacing = DesignSystem.SpacingSm };
        layout.Widgets.Add(_content);

        RootWidget.Widgets.Add(layout);
    }

    public VerticalStackPanel Content => _content;

    public void Open()
    {
        Visible = true;
        RootWidget.Visible = true;

        // Trigger fade-in + slide-up animation
        _fadeAnim.Start(0f, 1f, DesignSystem.AnimNormal, Transitions.EaseOut);
        _slideAnim.Start(30f, 0f, DesignSystem.AnimNormal, Transitions.EaseOutBack);

        Opened?.Invoke();
    }

    public void Close()
    {
        Visible = false;
        RootWidget.Visible = false;
        _fadeAnim.Cancel();
        _slideAnim.Cancel();
        Closed?.Invoke();
    }

    public void Toggle()
    {
        if (Visible) Close();
        else Open();
    }

    /// <summary>Update open/close animation. Call once per frame.</summary>
    public void UpdateAnimation(float deltaTime)
    {
        _fadeAnim.Update(deltaTime);
        _slideAnim.Update(deltaTime);

        if (Visible)
        {
            RootWidget.Opacity = _fadeAnim.IsComplete ? 1f : _fadeAnim.Value;
            RootWidget.Top = (int)(_slideAnim.IsComplete ? 0 : _slideAnim.Value);
        }
    }

    public void AddWidget(Widget widget)
    {
        _content.Widgets.Add(widget);
    }

    public void ClearContent()
    {
        _content.Widgets.Clear();
    }

    public void SetTitle(string title)
    {
        Title = title;
        _titleLabel.Text = title;
    }
}
