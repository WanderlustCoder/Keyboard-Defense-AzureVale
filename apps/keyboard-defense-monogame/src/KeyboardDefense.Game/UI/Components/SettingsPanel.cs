using System;
using KeyboardDefense.Core.Data;
using Myra.Graphics2D.UI;
using KeyboardDefense.Game.Services;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Settings panel with audio, display, and accessibility options.
/// Ported from ui/components/settings_panel.gd.
/// </summary>
public class SettingsPanel : BasePanel
{
    private Label? _colorblindLabel;
    private Label? _languageLabel;

    public SettingsPanel() : base(Locale.Tr("ui.settings"))
    {
        RootWidget.Width = 520;
        RootWidget.Height = 600;

        var sm = KeyboardDefenseGame.Instance.SettingsManager;

        // Language section
        AddWidget(new Label { Text = Locale.Tr("settings.language"), TextColor = ThemeColors.Accent });
        var langRow = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };
        langRow.Widgets.Add(new Label
        {
            Text = Locale.Tr("settings.language"),
            TextColor = ThemeColors.Text,
            Width = 150,
        });
        _languageLabel = new Label
        {
            Text = GetLanguageName(sm.Language),
            TextColor = ThemeColors.AccentCyan,
            Width = 120,
        };
        langRow.Widgets.Add(_languageLabel);
        var langCycleBtn = ButtonFactory.Ghost(Locale.Tr("actions.cycle"), () =>
        {
            sm.Language = NextLanguage(sm.Language);
            Locale.SetLocale(sm.Language);
            DataLoader.LoadTranslations(DataLoader.DataDirectory, sm.Language);
            if (_languageLabel != null)
                _languageLabel.Text = GetLanguageName(sm.Language);
        });
        langCycleBtn.Width = 80;
        langCycleBtn.Height = DesignSystem.SizeButtonSm;
        langRow.Widgets.Add(langCycleBtn);
        AddWidget(langRow);
        AddWidget(new HorizontalSeparator());

        // Audio section
        AddWidget(new Label { Text = Locale.Tr("settings.audio"), TextColor = ThemeColors.Accent });
        AddWidget(CreateSliderRow(Locale.Tr("settings.master_volume"), 0, 100, (int)(sm.SfxVolume * 100), v =>
        {
            sm.SfxVolume = v / 100f;
        }));
        AddWidget(CreateSliderRow(Locale.Tr("settings.music_volume"), 0, 100, (int)(sm.MusicVolume * 100), v =>
        {
            sm.MusicVolume = v / 100f;
        }));
        AddWidget(CreateToggleRow(Locale.Tr("settings.typing_sounds"), sm.TypingSounds, v => sm.TypingSounds = v));
        AddWidget(new HorizontalSeparator());

        // Display section
        AddWidget(new Label { Text = Locale.Tr("settings.display"), TextColor = ThemeColors.Accent });
        AddWidget(CreateToggleRow(Locale.Tr("settings.screen_shake"), sm.ScreenShake, v => sm.ScreenShake = v));
        AddWidget(CreateToggleRow(Locale.Tr("settings.show_wpm"), sm.ShowWpm, v => sm.ShowWpm = v));
        AddWidget(CreateToggleRow(Locale.Tr("settings.show_accuracy"), sm.ShowAccuracy, v => sm.ShowAccuracy = v));
        AddWidget(new HorizontalSeparator());

        // Accessibility section
        AddWidget(new Label { Text = Locale.Tr("settings.accessibility"), TextColor = ThemeColors.Accent });
        AddWidget(CreateToggleRow(Locale.Tr("settings.reduced_motion"), sm.ReducedMotion, v =>
        {
            sm.ReducedMotion = v;
        }));
        AddWidget(CreateToggleRow(Locale.Tr("settings.high_contrast"), sm.HighContrast, v =>
        {
            sm.HighContrast = v;
        }));
        AddWidget(CreateToggleRow(Locale.Tr("settings.large_text"), sm.LargeText, v =>
        {
            sm.LargeText = v;
        }));
        AddWidget(CreateToggleRow(Locale.Tr("settings.focus_indicators"), sm.FocusIndicators, v =>
        {
            sm.FocusIndicators = v;
        }));

        // Colorblind mode selector
        var cbRow = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };
        cbRow.Widgets.Add(new Label
        {
            Text = Locale.Tr("settings.colorblind_mode"),
            TextColor = ThemeColors.Text,
            Width = 150,
        });
        _colorblindLabel = new Label
        {
            Text = FormatColorblindMode(sm.ColorblindMode),
            TextColor = ThemeColors.AccentCyan,
            Width = 120,
        };
        cbRow.Widgets.Add(_colorblindLabel);
        var cbCycleBtn = ButtonFactory.Ghost(Locale.Tr("actions.cycle"), () =>
        {
            sm.ColorblindMode = NextColorblindMode(sm.ColorblindMode);
            if (_colorblindLabel != null)
                _colorblindLabel.Text = FormatColorblindMode(sm.ColorblindMode);
        });
        cbCycleBtn.Width = 80;
        cbCycleBtn.Height = DesignSystem.SizeButtonSm;
        cbRow.Widgets.Add(cbCycleBtn);
        AddWidget(cbRow);

        AddWidget(new HorizontalSeparator());

        // Gameplay section
        AddWidget(new Label { Text = Locale.Tr("settings.gameplay"), TextColor = ThemeColors.Accent });
        AddWidget(CreateToggleRow(Locale.Tr("settings.practice_mode"), false, v =>
        {
            var state = GameController.Instance.State;
            state.PracticeMode = v;
        }));
        AddWidget(CreateSliderRow(Locale.Tr("settings.game_speed"), 50, 200, 100, v =>
        {
            var state = GameController.Instance.State;
            state.SpeedMultiplier = v / 100f;
        }));

        // Apply / Reset buttons
        AddWidget(new Panel { Height = DesignSystem.SpaceMd });
        var buttonRow = new HorizontalStackPanel
        {
            Spacing = DesignSystem.SpaceMd,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        buttonRow.Widgets.Add(ButtonFactory.Primary(Locale.Tr("actions.apply"), () =>
        {
            sm.SaveSettings();
            Close();
        }));
        buttonRow.Widgets.Add(ButtonFactory.Secondary(Locale.Tr("actions.reset_defaults"), () =>
        {
            sm.ResetToDefaults();
            sm.SaveSettings();
            Close();
        }));
        AddWidget(buttonRow);
    }

    private static string FormatColorblindMode(string mode) => mode switch
    {
        "protanopia" => Locale.Tr("settings.colorblind_protanopia"),
        "deuteranopia" => Locale.Tr("settings.colorblind_deuteranopia"),
        "tritanopia" => Locale.Tr("settings.colorblind_tritanopia"),
        _ => Locale.Tr("settings.colorblind_none"),
    };

    private static string NextColorblindMode(string current) => current switch
    {
        "none" => "protanopia",
        "protanopia" => "deuteranopia",
        "deuteranopia" => "tritanopia",
        "tritanopia" => "none",
        _ => "none",
    };

    private static string GetLanguageName(string locale) => locale switch
    {
        "en" => "English",
        "es" => "Español",
        "de" => "Deutsch",
        "fr" => "Français",
        "pt" => "Português",
        _ => locale,
    };

    private static string NextLanguage(string current)
    {
        var locales = Locale.SupportedLocales;
        int idx = Array.IndexOf(locales, current);
        return locales[(idx + 1) % locales.Length];
    }

    private static HorizontalStackPanel CreateSliderRow(string label, int min, int max, int initial, Action<int> onChange)
    {
        var row = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };
        row.Widgets.Add(new Label
        {
            Text = label,
            TextColor = ThemeColors.Text,
            Width = 150,
        });

        var valueLabel = new Label
        {
            Text = initial.ToString(),
            TextColor = ThemeColors.TextDim,
            Width = 40,
        };

        var slider = new HorizontalSlider
        {
            Minimum = min,
            Maximum = max,
            Value = initial,
            Width = 200,
        };
        slider.ValueChanged += (_, _) =>
        {
            int val = (int)slider.Value;
            valueLabel.Text = val.ToString();
            onChange(val);
        };

        row.Widgets.Add(slider);
        row.Widgets.Add(valueLabel);
        return row;
    }

    private static HorizontalStackPanel CreateToggleRow(string label, bool initial, Action<bool> onChange)
    {
        var row = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };
        row.Widgets.Add(new Label
        {
            Text = label,
            TextColor = ThemeColors.Text,
            Width = 150,
        });

        var toggle = new CheckButton
        {
            IsChecked = initial,
        };
        toggle.Click += (_, _) => onChange(toggle.IsChecked);
        row.Widgets.Add(toggle);
        return row;
    }
}
