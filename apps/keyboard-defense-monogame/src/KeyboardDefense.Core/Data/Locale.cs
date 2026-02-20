using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;

namespace KeyboardDefense.Core.Data;

/// <summary>
/// Localization system with translation loading and formatting.
/// Ported from sim/locale.gd.
/// </summary>
public static class Locale
{
    public static readonly string[] SupportedLocales = { "en", "es", "de", "fr", "pt" };
    private static string _currentLocale = "en";
    private static Dictionary<string, string> _translations = new();

    public static string CurrentLocale => _currentLocale;

    public static void SetLocale(string locale)
    {
        if (SupportedLocales.Contains(locale))
            _currentLocale = locale;
    }

    public static void LoadTranslations(Dictionary<string, string> translations)
    {
        _translations = translations;
    }

    public static string Tr(string key)
    {
        return _translations.GetValueOrDefault(key, key);
    }

    public static string Tr(string key, Dictionary<string, string> placeholders)
    {
        string text = Tr(key);
        foreach (var (placeholder, value) in placeholders)
            text = text.Replace($"{{{placeholder}}}", value);
        return text;
    }

    public static bool HasTranslation(string key) => _translations.ContainsKey(key);

    public static string FormatNumber(int number) => number.ToString("N0", CultureInfo.CurrentCulture);
    public static string FormatPercent(double value) => value.ToString("P0", CultureInfo.CurrentCulture);

    public static string FormatDuration(double seconds)
    {
        if (seconds < 60) return $"{(int)seconds}s";
        int minutes = (int)(seconds / 60);
        int secs = (int)(seconds % 60);
        return secs > 0 ? $"{minutes}m {secs}s" : $"{minutes}m";
    }
}
