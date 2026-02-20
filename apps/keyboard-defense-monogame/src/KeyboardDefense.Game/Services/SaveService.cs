using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace KeyboardDefense.Game.Services;

/// <summary>
/// Cross-platform save path management for Keyboard Defense.
/// Provides consistent save directories across Windows, Linux, and macOS
/// using Environment.SpecialFolder.ApplicationData as the base.
/// </summary>
public static class SaveService
{
    private const string AppName = "KeyboardDefense";
    private const string SavesSubdir = "saves";
    private const string SaveFilePrefix = "save";
    private const string SaveFileExtension = ".json";
    private const string MetaSuffix = "_meta";

    private static readonly string BaseDir = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
        AppName);

    private static readonly string SavesDir = Path.Combine(BaseDir, SavesSubdir);

    /// <summary>
    /// Returns the application data root directory.
    /// Windows: %APPDATA%\KeyboardDefense
    /// Linux:   ~/.config/KeyboardDefense
    /// macOS:   ~/Library/Application Support/KeyboardDefense
    /// </summary>
    public static string GetBaseDir() => BaseDir;

    /// <summary>
    /// Returns the saves subdirectory path.
    /// e.g. %APPDATA%/KeyboardDefense/saves/
    /// </summary>
    public static string GetSavesDir() => SavesDir;

    /// <summary>
    /// Returns the full path for a save slot file.
    /// Slot 0 returns "save.json", slot N returns "save_N.json".
    /// </summary>
    public static string GetSavePath(int slot)
    {
        string fileName = slot == 0
            ? $"{SaveFilePrefix}{SaveFileExtension}"
            : $"{SaveFilePrefix}_{slot}{SaveFileExtension}";
        return Path.Combine(SavesDir, fileName);
    }

    /// <summary>
    /// Returns the full path for a save slot's metadata file.
    /// </summary>
    public static string GetMetaPath(int slot)
    {
        return Path.Combine(SavesDir, $"{SaveFilePrefix}_{slot}{MetaSuffix}{SaveFileExtension}");
    }

    /// <summary>
    /// Ensures the saves directory exists. Called automatically before writes.
    /// </summary>
    public static void EnsureSaveDirectory()
    {
        try
        {
            Directory.CreateDirectory(SavesDir);
        }
        catch (IOException ex)
        {
            System.Diagnostics.Debug.WriteLine($"Failed to create save directory: {ex.Message}");
        }
        catch (UnauthorizedAccessException ex)
        {
            System.Diagnostics.Debug.WriteLine($"No permission to create save directory: {ex.Message}");
        }
    }

    /// <summary>
    /// Lists all available save files, returning slot numbers that have save data.
    /// </summary>
    public static List<int> GetAllSaves()
    {
        var saves = new List<int>();

        try
        {
            if (!Directory.Exists(SavesDir))
                return saves;

            // Check slot 0 (save.json)
            if (File.Exists(GetSavePath(0)))
                saves.Add(0);

            // Scan for save_N.json files
            var files = Directory.GetFiles(SavesDir, $"{SaveFilePrefix}_*{SaveFileExtension}");
            foreach (string file in files)
            {
                string name = Path.GetFileNameWithoutExtension(file);

                // Skip metadata files
                if (name.EndsWith(MetaSuffix, StringComparison.Ordinal))
                    continue;

                // Extract slot number from "save_N"
                string suffix = name.Substring(SaveFilePrefix.Length + 1);
                if (int.TryParse(suffix, out int slot) && slot > 0)
                    saves.Add(slot);
            }

            saves.Sort();
        }
        catch (IOException ex)
        {
            System.Diagnostics.Debug.WriteLine($"Failed to enumerate saves: {ex.Message}");
        }

        return saves;
    }

    /// <summary>
    /// Writes text content to a save slot file with IO error handling.
    /// Creates the saves directory if it doesn't exist.
    /// </summary>
    public static bool WriteSlot(int slot, string content)
    {
        try
        {
            EnsureSaveDirectory();
            File.WriteAllText(GetSavePath(slot), content);
            return true;
        }
        catch (IOException ex)
        {
            System.Diagnostics.Debug.WriteLine($"Failed to write save slot {slot}: {ex.Message}");
            return false;
        }
        catch (UnauthorizedAccessException ex)
        {
            System.Diagnostics.Debug.WriteLine($"No permission to write save slot {slot}: {ex.Message}");
            return false;
        }
    }

    /// <summary>
    /// Reads text content from a save slot file.
    /// Returns null if the file doesn't exist or can't be read.
    /// </summary>
    public static string? ReadSlot(int slot)
    {
        try
        {
            string path = GetSavePath(slot);
            if (!File.Exists(path))
                return null;
            return File.ReadAllText(path);
        }
        catch (IOException ex)
        {
            System.Diagnostics.Debug.WriteLine($"Failed to read save slot {slot}: {ex.Message}");
            return null;
        }
    }

    /// <summary>
    /// Writes metadata JSON for a save slot.
    /// </summary>
    public static bool WriteMeta(int slot, string metaJson)
    {
        try
        {
            EnsureSaveDirectory();
            File.WriteAllText(GetMetaPath(slot), metaJson);
            return true;
        }
        catch (IOException ex)
        {
            System.Diagnostics.Debug.WriteLine($"Failed to write save meta {slot}: {ex.Message}");
            return false;
        }
        catch (UnauthorizedAccessException ex)
        {
            System.Diagnostics.Debug.WriteLine($"No permission to write save meta {slot}: {ex.Message}");
            return false;
        }
    }

    /// <summary>
    /// Reads metadata JSON for a save slot. Returns null if unavailable.
    /// </summary>
    public static string? ReadMeta(int slot)
    {
        try
        {
            string path = GetMetaPath(slot);
            if (!File.Exists(path))
                return null;
            return File.ReadAllText(path);
        }
        catch (IOException ex)
        {
            System.Diagnostics.Debug.WriteLine($"Failed to read save meta {slot}: {ex.Message}");
            return null;
        }
    }

    /// <summary>
    /// Checks whether any save file exists in the saves directory.
    /// Also checks the legacy location (base dir without /saves/) for migration.
    /// </summary>
    public static bool HasAnySave()
    {
        // Check new saves directory
        if (GetAllSaves().Count > 0)
            return true;

        // Check legacy location for backward compatibility
        return HasLegacySave();
    }

    /// <summary>
    /// Checks for saves in the legacy location (BaseDir without /saves/ subdir).
    /// </summary>
    private static bool HasLegacySave()
    {
        try
        {
            if (!Directory.Exists(BaseDir))
                return false;

            return File.Exists(Path.Combine(BaseDir, "save.json"))
                || File.Exists(Path.Combine(BaseDir, "save_1.json"))
                || File.Exists(Path.Combine(BaseDir, "save_2.json"));
        }
        catch
        {
            return false;
        }
    }

    /// <summary>
    /// Migrates saves from the legacy location (BaseDir) to the new saves subdirectory.
    /// Called once during initialization. Safe to call multiple times.
    /// </summary>
    public static void MigrateLegacySaves()
    {
        try
        {
            if (!Directory.Exists(BaseDir))
                return;

            var legacyFiles = Directory.GetFiles(BaseDir, "save*.json");
            if (legacyFiles.Length == 0)
                return;

            EnsureSaveDirectory();

            foreach (string legacyPath in legacyFiles)
            {
                string fileName = Path.GetFileName(legacyPath);
                string newPath = Path.Combine(SavesDir, fileName);

                // Don't overwrite if already migrated
                if (File.Exists(newPath))
                    continue;

                File.Copy(legacyPath, newPath);
            }
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Save migration failed: {ex.Message}");
        }
    }
}
