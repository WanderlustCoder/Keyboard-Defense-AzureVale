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
    public float MusicVolume { get; set; } = 0.8f;
    public float SfxVolume { get; set; } = 1.0f;
    public bool MusicEnabled { get; set; } = true;
    public bool SfxEnabled { get; set; } = true;
    public bool TypingSounds { get; set; } = true;

    // Gameplay
    public bool ScreenShake { get; set; } = true;
    public bool ShowWpm { get; set; } = true;
    public bool ShowAccuracy { get; set; } = true;

    // Language
    public string Language { get; set; } = "en";

    // Accessibility
    public bool ReducedMotion { get; set; }
    public bool HighContrast { get; set; }
    public bool LargeText { get; set; }
    public string ColorblindMode { get; set; } = "none";
    public bool FocusIndicators { get; set; } = true;
    public bool ScreenReaderHints { get; set; }

    public event Action? SettingsChanged;

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
        public float MusicVolume { get; set; } = 0.8f;
        public float SfxVolume { get; set; } = 1.0f;
        public bool MusicEnabled { get; set; } = true;
        public bool SfxEnabled { get; set; } = true;
        public bool TypingSounds { get; set; } = true;
        public bool ScreenShake { get; set; } = true;
        public bool ShowWpm { get; set; } = true;
        public bool ShowAccuracy { get; set; } = true;
        public string Language { get; set; } = "en";
        public bool ReducedMotion { get; set; }
        public bool HighContrast { get; set; }
        public bool LargeText { get; set; }
        public string ColorblindMode { get; set; } = "none";
        public bool FocusIndicators { get; set; } = true;
        public bool ScreenReaderHints { get; set; }
    }
}
