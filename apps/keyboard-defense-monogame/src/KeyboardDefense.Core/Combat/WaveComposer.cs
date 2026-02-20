using System;
using System.Collections.Generic;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.Combat;

/// <summary>
/// Wave composition with themed enemy waves.
/// Ported from sim/wave_composer.gd.
/// </summary>
public static class WaveComposer
{
    public static readonly string[] WaveThemes =
    {
        "standard", "swarm", "elite", "speedy", "tanky",
        "magic", "undead", "burning", "frozen", "boss_assault"
    };

    public static readonly Dictionary<string, string[]> ThemeKinds = new()
    {
        ["standard"] = new[] { "raider", "scout", "armored" },
        ["swarm"] = new[] { "scout", "scout", "swarm" },
        ["elite"] = new[] { "armored", "berserker", "champion" },
        ["speedy"] = new[] { "scout", "phantom" },
        ["tanky"] = new[] { "armored", "tank" },
        ["magic"] = new[] { "phantom", "healer" },
        ["undead"] = new[] { "raider", "phantom" },
        ["burning"] = new[] { "raider", "berserker" },
        ["frozen"] = new[] { "armored", "scout" },
        ["boss_assault"] = new[] { "raider", "armored", "champion" },
    };

    public static WaveSpec ComposeWave(GameState state, int waveIndex, int totalWaves)
    {
        string theme = SelectTheme(state, waveIndex, totalWaves);
        int enemyCount = CalculateEnemyCount(state.Day, waveIndex, totalWaves);
        var kinds = ThemeKinds.GetValueOrDefault(theme, ThemeKinds["standard"])!;

        var enemies = new List<string>();
        for (int i = 0; i < enemyCount; i++)
        {
            int kindIndex = SimRng.RollRange(state, 0, kinds.Length - 1);
            enemies.Add(kinds[kindIndex]);
        }

        bool hasBoss = theme == "boss_assault" && waveIndex == totalWaves - 1;

        return new WaveSpec
        {
            Theme = theme,
            Enemies = enemies,
            HasBoss = hasBoss,
            WaveIndex = waveIndex,
            TotalWaves = totalWaves
        };
    }

    public static string SelectTheme(GameState state, int waveIndex, int totalWaves)
    {
        if (waveIndex == totalWaves - 1 && state.Day % 7 == 0)
            return "boss_assault";

        int roll = SimRng.RollRange(state, 0, WaveThemes.Length - 2); // Exclude boss_assault
        return WaveThemes[roll];
    }

    public static int CalculateEnemyCount(int day, int waveIndex, int totalWaves)
    {
        int baseCount = 2 + day / 2;
        double waveMult = 1.0 + (double)waveIndex / Math.Max(1, totalWaves);
        return Math.Max(1, (int)(baseCount * waveMult));
    }

    public static string GetThemeDisplayName(string theme) => theme switch
    {
        "standard" => "Standard",
        "swarm" => "Swarm",
        "elite" => "Elite",
        "speedy" => "Speedy",
        "tanky" => "Tanky",
        "magic" => "Magic",
        "undead" => "Undead",
        "burning" => "Burning",
        "frozen" => "Frozen",
        "boss_assault" => "Boss Assault",
        _ => theme,
    };
}

public class WaveSpec
{
    public string Theme { get; set; } = "standard";
    public List<string> Enemies { get; set; } = new();
    public bool HasBoss { get; set; }
    public int WaveIndex { get; set; }
    public int TotalWaves { get; set; }
}
