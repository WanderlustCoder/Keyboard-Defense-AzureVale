using System;
using Myra.Graphics2D.UI;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Modal dialog panel with confirm/cancel buttons.
/// Ported from ui/components/modal_panel.gd.
/// </summary>
public class ModalPanel : BasePanel
{
    private readonly Label _messageLabel;

    public event Action? Confirmed;
    public event Action? Cancelled;

    public ModalPanel(string title, string message, string confirmText = "OK", string cancelText = "Cancel")
        : base(title)
    {
        RootWidget.Width = 400;
        RootWidget.Height = 220;

        _messageLabel = new Label
        {
            Text = message,
            TextColor = ThemeColors.Text,
            Wrap = true,
            HorizontalAlignment = HorizontalAlignment.Stretch,
        };
        AddWidget(_messageLabel);

        AddWidget(new Panel { Height = DesignSystem.SpaceMd });

        var buttonRow = new HorizontalStackPanel
        {
            Spacing = DesignSystem.SpaceMd,
            HorizontalAlignment = HorizontalAlignment.Center,
        };

        var confirmBtn = ButtonFactory.Primary(confirmText, () =>
        {
            Confirmed?.Invoke();
            Close();
        });
        buttonRow.Widgets.Add(confirmBtn);

        var cancelBtn = ButtonFactory.Secondary(cancelText, () =>
        {
            Cancelled?.Invoke();
            Close();
        });
        buttonRow.Widgets.Add(cancelBtn);

        AddWidget(buttonRow);
    }

    public void SetMessage(string message) => _messageLabel.Text = message;
}
