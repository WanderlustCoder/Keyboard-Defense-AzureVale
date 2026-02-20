using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework.Input;
using Myra.Graphics2D.UI;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Game.Services;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Keybinding configuration panel with rebind support and conflict detection.
/// </summary>
public class KeybindPanel : BasePanel
{
    private readonly VerticalStackPanel _content;
    private string? _rebindingAction;
    private Label? _rebindPrompt;
    private KeyboardState _prevKeyboard;

    public KeybindPanel() : base(Locale.Tr("panels.key_bindings"))
    {
        RootWidget.Width = 550;
        RootWidget.Height = 550;

        _content = new VerticalStackPanel { Spacing = DesignSystem.SpaceSm };
        var scroll = new ScrollViewer
        {
            Content = _content,
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Stretch,
        };
        AddWidget(scroll);
    }

    public void Refresh()
    {
        _content.Widgets.Clear();
        _rebindingAction = null;

        // Conflict warnings
        var conflicts = KeybindManager.Instance.GetConflicts();
        if (conflicts.Count > 0)
        {
            _content.Widgets.Add(new Label
            {
                Text = $"Conflicts detected ({conflicts.Count}):",
                TextColor = ThemeColors.Warning,
            });
            foreach (var (a1, a2) in conflicts)
            {
                var b1 = KeybindManager.Instance.GetBinding(a1);
                var b2 = KeybindManager.Instance.GetBinding(a2);
                _content.Widgets.Add(new Label
                {
                    Text = $"  {b1?.Label ?? a1} and {b2?.Label ?? a2} share {b1?.DisplayString}",
                    TextColor = ThemeColors.Error,
                });
            }
            _content.Widgets.Add(new HorizontalSeparator());
        }

        // Rebind prompt area
        _rebindPrompt = new Label
        {
            Text = "",
            TextColor = ThemeColors.AccentCyan,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        _content.Widgets.Add(_rebindPrompt);

        // Group bindings by category
        var bindings = KeybindManager.Instance.GetAllBindings();
        string? lastCategory = null;

        foreach (var (action, bind) in bindings)
        {
            string category = GetCategory(action);
            if (category != lastCategory)
            {
                if (lastCategory != null)
                    _content.Widgets.Add(new Panel { Height = DesignSystem.SpaceXs });
                _content.Widgets.Add(new Label
                {
                    Text = category,
                    TextColor = ThemeColors.Accent,
                });
                lastCategory = category;
            }

            var row = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };
            row.Widgets.Add(new Label
            {
                Text = bind.Label,
                TextColor = ThemeColors.Text,
                Width = 180,
            });

            // Current binding
            var defaults = KeybindManager.Instance.GetAllBindings();
            bool isDefault = IsDefaultBinding(action, bind);

            row.Widgets.Add(new Label
            {
                Text = bind.DisplayString,
                TextColor = isDefault ? ThemeColors.TextDim : ThemeColors.AccentBlue,
                Width = 120,
            });

            // Rebind button
            string capturedAction = action;
            var rebindBtn = ButtonFactory.Secondary("Rebind", () => StartRebind(capturedAction));
            rebindBtn.Width = 70;
            rebindBtn.Height = 26;
            row.Widgets.Add(rebindBtn);

            // Reset button (only if not default)
            if (!isDefault)
            {
                var resetBtn = ButtonFactory.Ghost("Reset", () =>
                {
                    KeybindManager.Instance.ResetBinding(capturedAction);
                    KeybindManager.Instance.Save();
                    Refresh();
                });
                resetBtn.Width = 60;
                resetBtn.Height = 26;
                row.Widgets.Add(resetBtn);
            }

            _content.Widgets.Add(row);
        }

        _content.Widgets.Add(new HorizontalSeparator());

        // Reset all button
        var resetAllBtn = ButtonFactory.Danger("Reset All to Defaults", () =>
        {
            KeybindManager.Instance.ResetAllToDefaults();
            KeybindManager.Instance.Save();
            Refresh();
        });
        resetAllBtn.HorizontalAlignment = HorizontalAlignment.Center;
        _content.Widgets.Add(resetAllBtn);
    }

    private void StartRebind(string action)
    {
        _rebindingAction = action;
        var bind = KeybindManager.Instance.GetBinding(action);
        if (_rebindPrompt != null)
            _rebindPrompt.Text = $"Press any key for '{bind?.Label ?? action}'... (Escape to cancel)";
    }

    /// <summary>
    /// Call each frame while panel is open. Captures key press for rebinding.
    /// </summary>
    public void UpdateInput()
    {
        if (_rebindingAction == null) return;

        var kb = Keyboard.GetState();
        var pressed = kb.GetPressedKeys();

        // Wait for a non-modifier key press
        foreach (var key in pressed)
        {
            if (_prevKeyboard.IsKeyDown(key)) continue;
            if (key == Keys.LeftControl || key == Keys.RightControl
                || key == Keys.LeftShift || key == Keys.RightShift
                || key == Keys.LeftAlt || key == Keys.RightAlt)
                continue;

            if (key == Keys.Escape)
            {
                // Cancel rebind
                _rebindingAction = null;
                if (_rebindPrompt != null) _rebindPrompt.Text = "";
                _prevKeyboard = kb;
                return;
            }

            bool ctrl = kb.IsKeyDown(Keys.LeftControl) || kb.IsKeyDown(Keys.RightControl);
            bool shift = kb.IsKeyDown(Keys.LeftShift) || kb.IsKeyDown(Keys.RightShift);
            bool alt = kb.IsKeyDown(Keys.LeftAlt) || kb.IsKeyDown(Keys.RightAlt);

            KeybindManager.Instance.SetBinding(_rebindingAction, key, ctrl, shift, alt);
            KeybindManager.Instance.Save();
            _rebindingAction = null;
            Refresh();
            _prevKeyboard = kb;
            return;
        }

        _prevKeyboard = kb;
    }

    public bool IsRebinding => _rebindingAction != null;

    private static bool IsDefaultBinding(string action, Keybind current)
    {
        var mgr = KeybindManager.Instance;
        // Compare by resetting and checking — simpler: just check fields
        mgr.ResetBinding(action);
        var def = mgr.GetBinding(action);
        if (def == null) return true;
        bool same = def.Key == current.Key && def.Ctrl == current.Ctrl
            && def.Shift == current.Shift && def.Alt == current.Alt;
        // Restore the current binding if it was different
        if (!same)
            mgr.SetBinding(action, current.Key, current.Ctrl, current.Shift, current.Alt);
        return same;
    }

    private static string GetCategory(string action) => action switch
    {
        _ when action.StartsWith("panel_") => "Panels",
        _ when action.StartsWith("move_") => "Navigation",
        "submit" or "cancel" or "pause" => "General",
        "speed_up" or "speed_down" => "Battle",
        _ => "Other",
    };
}
