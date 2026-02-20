using System;
using Microsoft.Xna.Framework;
using Myra.Graphics2D.UI;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Game.Services;
using Newtonsoft.Json.Linq;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Save/Load panel with 3 save slots showing day, gold, HP, and save date.
/// </summary>
public class SaveLoadPanel : BasePanel
{
    private readonly VerticalStackPanel _slotList;
    private bool _isSaveMode;

    public event Action? SaveLoadCompleted;

    public SaveLoadPanel() : base(Locale.Tr("panels.save_load"))
    {
        RootWidget.Width = 450;
        RootWidget.Height = 400;

        var modeBar = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };
        var saveBtn = ButtonFactory.Primary("Save Game", () => SetMode(true));
        saveBtn.Width = 120;
        saveBtn.Height = DesignSystem.SizeButtonSm;
        modeBar.Widgets.Add(saveBtn);

        var loadBtn = ButtonFactory.Secondary("Load Game", () => SetMode(false));
        loadBtn.Width = 120;
        loadBtn.Height = DesignSystem.SizeButtonSm;
        modeBar.Widgets.Add(loadBtn);

        AddWidget(modeBar);
        AddWidget(new HorizontalSeparator());

        _slotList = new VerticalStackPanel { Spacing = DesignSystem.SpaceSm };
        AddWidget(_slotList);

        SetMode(false);
    }

    private void SetMode(bool save)
    {
        _isSaveMode = save;
        RefreshSlots();
    }

    public void RefreshSlots()
    {
        _slotList.Widgets.Clear();

        _slotList.Widgets.Add(new Label
        {
            Text = _isSaveMode ? "Select a slot to save:" : "Select a slot to load:",
            TextColor = ThemeColors.TextDim,
        });

        for (int slot = 0; slot < 3; slot++)
        {
            int s = slot;
            string? metaJson = GameController.GetSlotInfo(slot);

            var slotPanel = new VerticalStackPanel { Spacing = 2 };

            string slotLabel = $"Slot {slot + 1}";
            string slotInfo = "Empty";
            Color infoColor = ThemeColors.TextDisabled;

            if (metaJson != null)
            {
                try
                {
                    var meta = JObject.Parse(metaJson);
                    int day = meta.Value<int>("day");
                    string phase = meta.Value<string>("phase") ?? "?";
                    int gold = meta.Value<int>("gold");
                    int hp = meta.Value<int>("hp");
                    string savedAt = meta.Value<string>("savedAt") ?? "";
                    slotInfo = $"Day {day} | HP: {hp} | Gold: {gold} | {savedAt}";
                    infoColor = ThemeColors.Text;
                }
                catch
                {
                    slotInfo = "Corrupted save";
                    infoColor = ThemeColors.Error;
                }
            }

            var btn = new Button
            {
                Height = 60,
                HorizontalAlignment = HorizontalAlignment.Stretch,
            };

            var content = new VerticalStackPanel { Spacing = 2 };
            content.Widgets.Add(new Label
            {
                Text = slotLabel,
                TextColor = ThemeColors.Accent,
            });
            content.Widgets.Add(new Label
            {
                Text = slotInfo,
                TextColor = infoColor,
            });
            btn.Content = content;

            bool hasData = metaJson != null;
            btn.Enabled = _isSaveMode || hasData;

            btn.Click += (_, _) =>
            {
                if (_isSaveMode)
                {
                    GameController.Instance.SaveGame(s);
                    RefreshSlots();
                    SaveLoadCompleted?.Invoke();
                }
                else if (hasData)
                {
                    GameController.Instance.LoadGame(s);
                    SaveLoadCompleted?.Invoke();
                }
            };

            _slotList.Widgets.Add(btn);
        }
    }
}
