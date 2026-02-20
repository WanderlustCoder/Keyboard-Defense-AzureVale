using System;
using System.Collections.Generic;

namespace KeyboardDefense.Core.Combat;

/// <summary>
/// Boss fight definitions with multi-phase mechanics.
/// Ported from sim/boss_encounters.gd.
/// </summary>
public static class BossEncounters
{
    public static readonly Dictionary<string, BossDef> Bosses = new()
    {
        ["grove_guardian"] = new("Grove Guardian", "evergrove", 7,
            300, 8, 25, 4,
            new[]
            {
                new BossPhase("Awakening", 1.0, new[] { "root_slam" }),
                new BossPhase("Fury", 0.5, new[] { "root_slam", "summon_treants" }),
                new BossPhase("Desperation", 0.25, new[] { "root_slam", "summon_treants", "nature_burst" }),
            }),
        ["mountain_king"] = new("Mountain King", "stonepass", 14,
            500, 15, 20, 6,
            new[]
            {
                new BossPhase("Siege", 1.0, new[] { "boulder_throw" }),
                new BossPhase("Rage", 0.5, new[] { "boulder_throw", "earthquake" }),
                new BossPhase("Last Stand", 0.25, new[] { "boulder_throw", "earthquake", "crystal_barrier" }),
            }),
        ["fen_seer"] = new("Fen Seer", "mistfen", 21,
            400, 5, 30, 5,
            new[]
            {
                new BossPhase("Visions", 1.0, new[] { "toxic_cloud" }),
                new BossPhase("Madness", 0.5, new[] { "toxic_cloud", "word_scramble" }),
                new BossPhase("Chaos", 0.25, new[] { "toxic_cloud", "word_scramble", "summon_phantoms" }),
            }),
        ["sunlord"] = new("Sunlord", "sunfields", 28,
            600, 12, 35, 7,
            new[]
            {
                new BossPhase("Dawn", 1.0, new[] { "solar_flare" }),
                new BossPhase("Zenith", 0.5, new[] { "solar_flare", "burning_ground" }),
                new BossPhase("Eclipse", 0.25, new[] { "solar_flare", "burning_ground", "supernova" }),
            }),
    };

    public static BossDef? GetBoss(string bossId) => Bosses.GetValueOrDefault(bossId);

    public static string? GetBossForRegion(string region)
    {
        foreach (var (id, def) in Bosses)
            if (def.Region == region) return id;
        return null;
    }

    public static List<string> GetAvailableBosses(int day)
    {
        var result = new List<string>();
        foreach (var (id, def) in Bosses)
            if (day >= def.UnlockDay) result.Add(id);
        return result;
    }

    public static int GetPhaseIndex(Dictionary<string, object> bossEnemy)
    {
        int hp = Convert.ToInt32(bossEnemy.GetValueOrDefault("hp", 0));
        int maxHp = Convert.ToInt32(bossEnemy.GetValueOrDefault("max_hp", 1));
        string bossId = bossEnemy.GetValueOrDefault("boss_id")?.ToString() ?? "";
        var def = GetBoss(bossId);
        if (def == null) return 0;

        double ratio = (double)hp / maxHp;
        for (int i = def.Phases.Length - 1; i >= 0; i--)
        {
            if (ratio <= def.Phases[i].HpThreshold)
                return i;
        }
        return 0;
    }

    public static bool CheckPhaseTransition(Dictionary<string, object> bossEnemy)
    {
        int currentPhase = Convert.ToInt32(bossEnemy.GetValueOrDefault("current_phase", 0));
        int newPhase = GetPhaseIndex(bossEnemy);
        if (newPhase != currentPhase)
        {
            bossEnemy["current_phase"] = newPhase;
            return true;
        }
        return false;
    }
}

public record BossDef(string Name, string Region, int UnlockDay, int Hp, int Armor, int Speed, int Damage, BossPhase[] Phases);
public record BossPhase(string Name, double HpThreshold, string[] Abilities);
