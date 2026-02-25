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
    /// <summary>
    /// Supported locale codes accepted by <see cref="SetLocale"/>.
    /// </summary>
    public static readonly string[] SupportedLocales = { "en", "es", "de", "fr", "pt" };
    private static string _currentLocale = "en";
    private static Dictionary<string, string> _translations = new();

    /// <summary>
    /// Gets the currently active locale code.
    /// </summary>
    public static string CurrentLocale => _currentLocale;

    /// <summary>
    /// Sets the active locale when the provided code is in <see cref="SupportedLocales"/>.
    /// </summary>
    /// <param name="locale">Locale code to activate.</param>
    public static void SetLocale(string locale)
    {
        if (SupportedLocales.Contains(locale))
            _currentLocale = locale;
    }

    /// <summary>
    /// Replaces the in-memory translation table used for key lookup.
    /// </summary>
    /// <param name="translations">Mapping of localization keys to translated strings.</param>
    public static void LoadTranslations(Dictionary<string, string> translations)
    {
        _translations = translations;
    }

    /// <summary>
    /// Resolves a localization key to translated text, falling back to the key when missing.
    /// </summary>
    /// <param name="key">Localization key to resolve.</param>
    /// <returns>The translated string or the original key when no translation exists.</returns>
    public static string Tr(string key)
    {
        return _translations.GetValueOrDefault(key, key);
    }

    /// <summary>
    /// Resolves translated text and substitutes <c>{placeholder}</c> tokens with provided values.
    /// </summary>
    /// <param name="key">Localization key to resolve.</param>
    /// <param name="placeholders">Placeholder values keyed by token name without braces.</param>
    /// <returns>The translated and formatted text.</returns>
    public static string Tr(string key, Dictionary<string, string> placeholders)
    {
        string text = Tr(key);
        foreach (var (placeholder, value) in placeholders)
            text = text.Replace($"{{{placeholder}}}", value);
        return text;
    }

    /// <summary>
    /// Checks whether a translation entry exists for the given key.
    /// </summary>
    /// <param name="key">Localization key to test.</param>
    /// <returns><c>true</c> when a translation exists; otherwise, <c>false</c>.</returns>
    public static bool HasTranslation(string key) => _translations.ContainsKey(key);

    /// <summary>
    /// Formats an integer using the current culture's grouped number pattern.
    /// </summary>
    /// <param name="number">Numeric value to format.</param>
    /// <returns>The culture-formatted number string.</returns>
    public static string FormatNumber(int number) => number.ToString("N0", CultureInfo.CurrentCulture);

    /// <summary>
    /// Formats a ratio as a whole-percent string using the current culture.
    /// </summary>
    /// <param name="value">Ratio value where <c>1.0</c> represents 100%.</param>
    /// <returns>The culture-formatted percent string.</returns>
    public static string FormatPercent(double value) => value.ToString("P0", CultureInfo.CurrentCulture);

    /// <summary>
    /// Formats elapsed seconds into compact duration text such as <c>45s</c> or <c>2m 10s</c>.
    /// </summary>
    /// <param name="seconds">Duration in seconds.</param>
    /// <returns>A compact duration string in seconds and minutes.</returns>
    public static string FormatDuration(double seconds)
    {
        if (seconds < 60) return $"{(int)seconds}s";
        int minutes = (int)(seconds / 60);
        int secs = (int)(seconds % 60);
        return secs > 0 ? $"{minutes}m {secs}s" : $"{minutes}m";
    }
}
