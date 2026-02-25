using System;
using System.IO;
using Newtonsoft.Json;

namespace KeyboardDefense.Game.Services;

/// <summary>
/// Handles settings persistence and state.
/// Ported from game/settings_manager.gd.
/// </summary>
public class SettingsManager
{
    private static readonly string SettingsDir = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
        "KeyboardDefense");
    private static readonly string SettingsPath = Path.Combine(SettingsDir, "settings.json");

    // Audio
    /// <summary>
    /// Gets or sets the background music volume level.
    /// </summary>
    public float MusicVolume { get; set; } = 0.8f;
    /// <summary>
    /// Gets or sets the sound effects volume level.
    /// </summary>
    public float SfxVolume { get; set; } = 1.0f;
    /// <summary>
    /// Gets or sets a value indicating whether background music playback is enabled.
    /// </summary>
    public bool MusicEnabled { get; set; } = true;
    /// <summary>
    /// Gets or sets a value indicating whether sound effects playback is enabled.
    /// </summary>
    public bool SfxEnabled { get; set; } = true;
    /// <summary>
    /// Gets or sets a value indicating whether typing sounds are enabled.
    /// </summary>
    public bool TypingSounds { get; set; } = true;

    // Gameplay
    /// <summary>
    /// Gets or sets a value indicating whether screen shake effects are enabled.
    /// </summary>
    public bool ScreenShake { get; set; } = true;
    /// <summary>
    /// Gets or sets a value indicating whether words-per-minute is shown in the HUD.
    /// </summary>
    public bool ShowWpm { get; set; } = true;
    /// <summary>
    /// Gets or sets a value indicating whether typing accuracy is shown in the HUD.
    /// </summary>
    public bool ShowAccuracy { get; set; } = true;

    // Language
    /// <summary>
    /// Gets or sets the active language code.
    /// </summary>
    public string Language { get; set; } = "en";

    // Accessibility
    /// <summary>
    /// Gets or sets a value indicating whether reduced motion mode is enabled.
    /// </summary>
    public bool ReducedMotion { get; set; }
    /// <summary>
    /// Gets or sets a value indicating whether high contrast mode is enabled.
    /// </summary>
    public bool HighContrast { get; set; }
    /// <summary>
    /// Gets or sets a value indicating whether large text mode is enabled.
    /// </summary>
    public bool LargeText { get; set; }
    /// <summary>
    /// Gets or sets the colorblind mode identifier.
    /// </summary>
    public string ColorblindMode { get; set; } = "none";
    /// <summary>
    /// Gets or sets a value indicating whether focus indicators are shown.
    /// </summary>
    public bool FocusIndicators { get; set; } = true;
    /// <summary>
    /// Gets or sets a value indicating whether screen reader hints are enabled.
    /// </summary>
    public bool ScreenReaderHints { get; set; }

    /// <summary>
    /// Occurs when settings are changed through reset behavior.
    /// </summary>
    public event Action? SettingsChanged;

    /// <summary>
    /// Loads settings values from disk if a persisted settings file is present.
    /// </summary>
    public void LoadSettings()
    {
        if (!File.Exists(SettingsPath))
            return;
        try
        {
            string json = File.ReadAllText(SettingsPath);
            var data = JsonConvert.DeserializeObject<SettingsData>(json);
            if (data == null) return;

            MusicVolume = data.MusicVolume;
            SfxVolume = data.SfxVolume;
            MusicEnabled = data.MusicEnabled;
            SfxEnabled = data.SfxEnabled;
            TypingSounds = data.TypingSounds;
            ScreenShake = data.ScreenShake;
            ShowWpm = data.ShowWpm;
            ShowAccuracy = data.ShowAccuracy;
            Language = data.Language;
            ReducedMotion = data.ReducedMotion;
            HighContrast = data.HighContrast;
            LargeText = data.LargeText;
            ColorblindMode = data.ColorblindMode;
            FocusIndicators = data.FocusIndicators;
            ScreenReaderHints = data.ScreenReaderHints;
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Failed to load settings: {ex.Message}");
        }
    }

    /// <summary>
    /// Saves current settings values to disk.
    /// </summary>
    public void SaveSettings()
    {
        try
        {
            Directory.CreateDirectory(SettingsDir);
            var data = new SettingsData
            {
                MusicVolume = MusicVolume,
                SfxVolume = SfxVolume,
                MusicEnabled = MusicEnabled,
                SfxEnabled = SfxEnabled,
                TypingSounds = TypingSounds,
                ScreenShake = ScreenShake,
                ShowWpm = ShowWpm,
                ShowAccuracy = ShowAccuracy,
                Language = Language,
                ReducedMotion = ReducedMotion,
                HighContrast = HighContrast,
                LargeText = LargeText,
                ColorblindMode = ColorblindMode,
                FocusIndicators = FocusIndicators,
                ScreenReaderHints = ScreenReaderHints,
            };
            string json = JsonConvert.SerializeObject(data, Formatting.Indented);
            File.WriteAllText(SettingsPath, json);
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Failed to save settings: {ex.Message}");
        }
    }

    /// <summary>
    /// Restores all settings values to their default state and raises <see cref="SettingsChanged"/>.
    /// </summary>
    public void ResetToDefaults()
    {
        MusicVolume = 0.8f;
        SfxVolume = 1.0f;
        MusicEnabled = true;
        SfxEnabled = true;
        TypingSounds = true;
        ScreenShake = true;
        ShowWpm = true;
        ShowAccuracy = true;
        Language = "en";
        ReducedMotion = false;
        HighContrast = false;
        LargeText = false;
        ColorblindMode = "none";
        FocusIndicators = true;
        ScreenReaderHints = false;
        SettingsChanged?.Invoke();
    }

    private class SettingsData
    {
        /// <summary>
        /// Gets or sets the persisted background music volume level.
        /// </summary>
        public float MusicVolume { get; set; } = 0.8f;
        /// <summary>
        /// Gets or sets the persisted sound effects volume level.
        /// </summary>
        public float SfxVolume { get; set; } = 1.0f;
        /// <summary>
        /// Gets or sets a value indicating whether background music is enabled.
        /// </summary>
        public bool MusicEnabled { get; set; } = true;
        /// <summary>
        /// Gets or sets a value indicating whether sound effects are enabled.
        /// </summary>
        public bool SfxEnabled { get; set; } = true;
        /// <summary>
        /// Gets or sets a value indicating whether typing sounds are enabled.
        /// </summary>
        public bool TypingSounds { get; set; } = true;
        /// <summary>
        /// Gets or sets a value indicating whether screen shake is enabled.
        /// </summary>
        public bool ScreenShake { get; set; } = true;
        /// <summary>
        /// Gets or sets a value indicating whether words-per-minute is shown.
        /// </summary>
        public bool ShowWpm { get; set; } = true;
        /// <summary>
        /// Gets or sets a value indicating whether typing accuracy is shown.
        /// </summary>
        public bool ShowAccuracy { get; set; } = true;
        /// <summary>
        /// Gets or sets the persisted language code.
        /// </summary>
        public string Language { get; set; } = "en";
        /// <summary>
        /// Gets or sets a value indicating whether reduced motion is enabled.
        /// </summary>
        public bool ReducedMotion { get; set; }
        /// <summary>
        /// Gets or sets a value indicating whether high contrast mode is enabled.
        /// </summary>
        public bool HighContrast { get; set; }
        /// <summary>
        /// Gets or sets a value indicating whether large text mode is enabled.
        /// </summary>
        public bool LargeText { get; set; }
        /// <summary>
        /// Gets or sets the persisted colorblind mode identifier.
        /// </summary>
        public string ColorblindMode { get; set; } = "none";
        /// <summary>
        /// Gets or sets a value indicating whether focus indicators are shown.
        /// </summary>
        public bool FocusIndicators { get; set; } = true;
        /// <summary>
        /// Gets or sets a value indicating whether screen reader hints are enabled.
        /// </summary>
        public bool ScreenReaderHints { get; set; }
    }
}
