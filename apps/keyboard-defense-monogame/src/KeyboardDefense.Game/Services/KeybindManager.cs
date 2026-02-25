using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Microsoft.Xna.Framework.Input;
using Newtonsoft.Json;

namespace KeyboardDefense.Game.Services;

/// <summary>
/// Manages customizable keybindings with persistence and conflict detection.
/// Maps action names to key combinations (key + optional modifiers).
/// </summary>
public class KeybindManager
{
    private static KeybindManager? _instance;
    /// <summary>
    /// Gets the singleton keybind manager instance used by the game runtime.
    /// </summary>
    public static KeybindManager Instance => _instance ??= new();

    private static readonly string SettingsDir = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
        "KeyboardDefense");
    private static readonly string BindingsPath = Path.Combine(SettingsDir, "keybindings.json");

    private readonly Dictionary<string, Keybind> _bindings = new();
    private readonly Dictionary<string, Keybind> _defaults = new();

    /// <summary>
    /// Raised after bindings are changed, reset, loaded, or otherwise updated.
    /// </summary>
    public event Action? BindingsChanged;

    /// <summary>
    /// Creates a keybind manager and registers the default action bindings.
    /// </summary>
    public KeybindManager()
    {
        RegisterDefaults();
    }

    private void RegisterDefaults()
    {
        // Panel hotkeys
        DefineDefault("panel_help", Keys.F1, "Help Panel");
        DefineDefault("panel_settings", Keys.F2, "Settings Panel");
        DefineDefault("panel_stats", Keys.F3, "Stats Panel");
        DefineDefault("panel_bestiary", Keys.F4, "Bestiary Panel");
        DefineDefault("panel_skills", Keys.F5, "Skills Panel");
        DefineDefault("panel_quests", Keys.F6, "Quests Panel");
        DefineDefault("panel_equipment", Keys.F7, "Equipment Panel");
        DefineDefault("panel_shop", Keys.F8, "Shop Panel");
        DefineDefault("panel_achievements", Keys.F9, "Achievements Panel");
        DefineDefault("panel_buffs", Keys.F10, "Buffs Panel");
        DefineDefault("panel_inventory", Keys.F11, "Inventory Panel");
        DefineDefault("panel_difficulty", Keys.F12, "Difficulty Panel");
        DefineDefault("panel_expeditions", Keys.D1, "Expeditions Panel");
        DefineDefault("panel_diplomacy", Keys.D2, "Diplomacy Panel");
        DefineDefault("panel_research", Keys.D3, "Research Panel");
        DefineDefault("panel_citizens", Keys.D4, "Citizens Panel");
        DefineDefault("panel_workers", Keys.D5, "Workers Panel");
        DefineDefault("panel_keybinds", Keys.D6, "Keybinds Panel");

        // Gameplay
        DefineDefault("submit", Keys.Enter, "Submit / Confirm");
        DefineDefault("cancel", Keys.Escape, "Cancel / Close Panel");
        DefineDefault("pause", Keys.P, "Pause", ctrl: true);

        // Navigation
        DefineDefault("move_up", Keys.W, "Move Up");
        DefineDefault("move_down", Keys.S, "Move Down");
        DefineDefault("move_left", Keys.A, "Move Left");
        DefineDefault("move_right", Keys.D, "Move Right");

        // Battle
        DefineDefault("speed_up", Keys.OemPlus, "Speed Up");
        DefineDefault("speed_down", Keys.OemMinus, "Speed Down");
    }

    private void DefineDefault(string action, Keys key, string label, bool ctrl = false, bool shift = false, bool alt = false)
    {
        var bind = new Keybind(key, ctrl, shift, alt, label, action);
        _defaults[action] = bind;
        if (!_bindings.ContainsKey(action))
            _bindings[action] = bind;
    }

    /// <summary>
    /// Gets the full keybind configuration for an action, if one exists.
    /// </summary>
    public Keybind? GetBinding(string action)
    {
        return _bindings.GetValueOrDefault(action);
    }

    /// <summary>
    /// Gets the primary key assigned to an action, or <see cref="Keys.None"/> if unbound.
    /// </summary>
    public Keys GetKey(string action)
    {
        return _bindings.TryGetValue(action, out var bind) ? bind.Key : Keys.None;
    }

    /// <summary>
    /// Returns a read-only view of all currently active action bindings.
    /// </summary>
    public IReadOnlyDictionary<string, Keybind> GetAllBindings() => _bindings;

    /// <summary>
    /// Sets or replaces a binding for an existing action and preserves its display label.
    /// </summary>
    public void SetBinding(string action, Keys key, bool ctrl = false, bool shift = false, bool alt = false)
    {
        if (!_defaults.ContainsKey(action)) return;
        var existing = _bindings.GetValueOrDefault(action);
        string label = existing?.Label ?? action;
        _bindings[action] = new Keybind(key, ctrl, shift, alt, label, action);
        BindingsChanged?.Invoke();
    }

    /// <summary>
    /// Restores a single action binding back to its registered default.
    /// </summary>
    public void ResetBinding(string action)
    {
        if (_defaults.TryGetValue(action, out var def))
        {
            _bindings[action] = def;
            BindingsChanged?.Invoke();
        }
    }

    /// <summary>
    /// Restores all action bindings to their default key combinations.
    /// </summary>
    public void ResetAllToDefaults()
    {
        _bindings.Clear();
        foreach (var (action, bind) in _defaults)
            _bindings[action] = bind;
        BindingsChanged?.Invoke();
    }

    /// <summary>
    /// Check if a keybind is pressed this frame (key down + modifiers match).
    /// </summary>
    public bool IsActionPressed(string action, KeyboardState current, KeyboardState previous)
    {
        if (!_bindings.TryGetValue(action, out var bind)) return false;
        if (!current.IsKeyDown(bind.Key) || previous.IsKeyDown(bind.Key)) return false;

        bool ctrlHeld = current.IsKeyDown(Keys.LeftControl) || current.IsKeyDown(Keys.RightControl);
        bool shiftHeld = current.IsKeyDown(Keys.LeftShift) || current.IsKeyDown(Keys.RightShift);
        bool altHeld = current.IsKeyDown(Keys.LeftAlt) || current.IsKeyDown(Keys.RightAlt);

        return ctrlHeld == bind.Ctrl && shiftHeld == bind.Shift && altHeld == bind.Alt;
    }

    /// <summary>
    /// Detect conflicts: multiple actions bound to the same key+modifier combo.
    /// </summary>
    public List<(string Action1, string Action2)> GetConflicts()
    {
        var conflicts = new List<(string, string)>();
        var keys = _bindings.ToList();
        for (int i = 0; i < keys.Count; i++)
        {
            for (int j = i + 1; j < keys.Count; j++)
            {
                if (keys[i].Value.Key == keys[j].Value.Key
                    && keys[i].Value.Ctrl == keys[j].Value.Ctrl
                    && keys[i].Value.Shift == keys[j].Value.Shift
                    && keys[i].Value.Alt == keys[j].Value.Alt)
                {
                    conflicts.Add((keys[i].Key, keys[j].Key));
                }
            }
        }
        return conflicts;
    }

    /// <summary>
    /// Saves non-default keybind overrides to the per-user settings file.
    /// </summary>
    public void Save()
    {
        try
        {
            Directory.CreateDirectory(SettingsDir);
            var data = new Dictionary<string, KeybindData>();
            foreach (var (action, bind) in _bindings)
            {
                // Only save non-default bindings
                if (_defaults.TryGetValue(action, out var def)
                    && def.Key == bind.Key && def.Ctrl == bind.Ctrl
                    && def.Shift == bind.Shift && def.Alt == bind.Alt)
                    continue;

                data[action] = new KeybindData
                {
                    Key = bind.Key.ToString(),
                    Ctrl = bind.Ctrl,
                    Shift = bind.Shift,
                    Alt = bind.Alt,
                };
            }
            string json = JsonConvert.SerializeObject(data, Formatting.Indented);
            File.WriteAllText(BindingsPath, json);
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Failed to save keybindings: {ex.Message}");
        }
    }

    /// <summary>
    /// Loads persisted keybind overrides and applies them on top of defaults.
    /// </summary>
    public void Load()
    {
        // Reset to defaults first
        ResetAllToDefaults();

        if (!File.Exists(BindingsPath)) return;
        try
        {
            string json = File.ReadAllText(BindingsPath);
            var data = JsonConvert.DeserializeObject<Dictionary<string, KeybindData>>(json);
            if (data == null) return;

            foreach (var (action, kd) in data)
            {
                if (!_defaults.ContainsKey(action)) continue;
                if (Enum.TryParse<Keys>(kd.Key, out var key))
                    SetBinding(action, key, kd.Ctrl, kd.Shift, kd.Alt);
            }
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Failed to load keybindings: {ex.Message}");
        }
    }

    private class KeybindData
    {
        /// <summary>
        /// Serialized key name used for deserialization into <see cref="Keys"/>.
        /// </summary>
        public string Key { get; set; } = "";
        /// <summary>
        /// Indicates whether Ctrl is required for the binding.
        /// </summary>
        public bool Ctrl { get; set; }
        /// <summary>
        /// Indicates whether Shift is required for the binding.
        /// </summary>
        public bool Shift { get; set; }
        /// <summary>
        /// Indicates whether Alt is required for the binding.
        /// </summary>
        public bool Alt { get; set; }
    }
}

/// <summary>
/// Immutable keybind configuration for a single action and its UI label.
/// </summary>
public record Keybind(Keys Key, bool Ctrl, bool Shift, bool Alt, string Label, string Action)
{
    /// <summary>
    /// Gets a user-facing string representation of the key and modifiers.
    /// </summary>
    public string DisplayString
    {
        get
        {
            var parts = new List<string>();
            if (Ctrl) parts.Add("Ctrl");
            if (Shift) parts.Add("Shift");
            if (Alt) parts.Add("Alt");
            parts.Add(FormatKeyName(Key));
            return string.Join("+", parts);
        }
    }

    private static string FormatKeyName(Keys key) => key switch
    {
        Keys.OemPlus => "+",
        Keys.OemMinus => "-",
        Keys.OemPeriod => ".",
        Keys.OemComma => ",",
        Keys.OemSemicolon => ";",
        Keys.Space => "Space",
        Keys.Back => "Backspace",
        Keys.Delete => "Delete",
        Keys.Tab => "Tab",
        Keys.Enter => "Enter",
        Keys.Escape => "Esc",
        _ when key >= Keys.D0 && key <= Keys.D9 => (key - Keys.D0).ToString(),
        _ when key >= Keys.F1 && key <= Keys.F12 => key.ToString(),
        _ => key.ToString(),
    };
}
