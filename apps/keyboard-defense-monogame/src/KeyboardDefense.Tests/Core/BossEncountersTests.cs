using System.Collections.Generic;
using KeyboardDefense.Core.Combat;

namespace KeyboardDefense.Tests.Core;

public class BossEncountersTests
{
    [Fact]
    public void Bosses_Dictionary_HasFourExpectedBossIds()
    {
        Assert.Equal(4, BossEncounters.Bosses.Count);
        Assert.Contains("grove_guardian", BossEncounters.Bosses.Keys);
        Assert.Contains("mountain_king", BossEncounters.Bosses.Keys);
        Assert.Contains("fen_seer", BossEncounters.Bosses.Keys);
        Assert.Contains("sunlord", BossEncounters.Bosses.Keys);
    }

    [Fact]
    public void GetBoss_GroveGuardian_DataMatchesContract()
    {
        AssertBossData(
            bossId: "grove_guardian",
            region: "evergrove",
            unlockDay: 7,
            hp: 300,
            armor: 8,
            speed: 25,
            damage: 4,
            phaseOneAbilities: new[] { "root_slam" },
            phaseTwoAbilities: new[] { "root_slam", "summon_treants" },
            phaseThreeAbilities: new[] { "root_slam", "summon_treants", "nature_burst" });
    }

    [Fact]
    public void GetBoss_MountainKing_DataMatchesContract()
    {
        AssertBossData(
            bossId: "mountain_king",
            region: "stonepass",
            unlockDay: 14,
            hp: 500,
            armor: 15,
            speed: 20,
            damage: 6,
            phaseOneAbilities: new[] { "boulder_throw" },
            phaseTwoAbilities: new[] { "boulder_throw", "earthquake" },
            phaseThreeAbilities: new[] { "boulder_throw", "earthquake", "crystal_barrier" });
    }

    [Fact]
    public void GetBoss_FenSeer_DataMatchesContract()
    {
        AssertBossData(
            bossId: "fen_seer",
            region: "mistfen",
            unlockDay: 21,
            hp: 400,
            armor: 5,
            speed: 30,
            damage: 5,
            phaseOneAbilities: new[] { "toxic_cloud" },
            phaseTwoAbilities: new[] { "toxic_cloud", "word_scramble" },
            phaseThreeAbilities: new[] { "toxic_cloud", "word_scramble", "summon_phantoms" });
    }

    [Fact]
    public void GetBoss_Sunlord_DataMatchesContract()
    {
        AssertBossData(
            bossId: "sunlord",
            region: "sunfields",
            unlockDay: 28,
            hp: 600,
            armor: 12,
            speed: 35,
            damage: 7,
            phaseOneAbilities: new[] { "solar_flare" },
            phaseTwoAbilities: new[] { "solar_flare", "burning_ground" },
            phaseThreeAbilities: new[] { "solar_flare", "burning_ground", "supernova" });
    }

    [Fact]
    public void GetBoss_UnknownId_ReturnsNull()
    {
        Assert.Null(BossEncounters.GetBoss("unknown_boss"));
    }

    [Fact]
    public void GetBossForRegion_KnownRegions_ReturnExpectedBossIds()
    {
        Assert.Equal("grove_guardian", BossEncounters.GetBossForRegion("evergrove"));
        Assert.Equal("mountain_king", BossEncounters.GetBossForRegion("stonepass"));
        Assert.Equal("fen_seer", BossEncounters.GetBossForRegion("mistfen"));
        Assert.Equal("sunlord", BossEncounters.GetBossForRegion("sunfields"));
    }

    [Fact]
    public void GetBossForRegion_UnknownRegion_ReturnsNull()
    {
        Assert.Null(BossEncounters.GetBossForRegion("no_such_region"));
    }

    [Fact]
    public void GetAvailableBosses_Day1_ReturnsNone()
    {
        var available = BossEncounters.GetAvailableBosses(1);
        Assert.Empty(available);
    }

    [Fact]
    public void GetAvailableBosses_Day7_ReturnsOnlyGroveGuardian()
    {
        var available = BossEncounters.GetAvailableBosses(7);
        Assert.Single(available);
        Assert.Contains("grove_guardian", available);
    }

    [Fact]
    public void GetAvailableBosses_Day14_ReturnsTwoBosses()
    {
        var available = BossEncounters.GetAvailableBosses(14);
        Assert.Equal(2, available.Count);
        Assert.Contains("grove_guardian", available);
        Assert.Contains("mountain_king", available);
    }

    [Fact]
    public void GetAvailableBosses_Day21_ReturnsThreeBosses()
    {
        var available = BossEncounters.GetAvailableBosses(21);
        Assert.Equal(3, available.Count);
        Assert.Contains("grove_guardian", available);
        Assert.Contains("mountain_king", available);
        Assert.Contains("fen_seer", available);
    }

    [Fact]
    public void GetAvailableBosses_Day28_ReturnsAllBosses()
    {
        var available = BossEncounters.GetAvailableBosses(28);
        Assert.Equal(4, available.Count);
        Assert.Contains("grove_guardian", available);
        Assert.Contains("mountain_king", available);
        Assert.Contains("fen_seer", available);
        Assert.Contains("sunlord", available);
    }

    [Fact]
    public void GetPhaseIndex_UnknownBoss_ReturnsZero()
    {
        var enemy = CreateBossEnemy("not_a_boss", hp: 100, maxHp: 100);
        Assert.Equal(0, BossEncounters.GetPhaseIndex(enemy));
    }

    [Fact]
    public void GetPhaseIndex_FullHealth_ReturnsPhaseZero()
    {
        var enemy = CreateBossEnemy("grove_guardian", hp: 300, maxHp: 300);
        Assert.Equal(0, BossEncounters.GetPhaseIndex(enemy));
    }

    [Fact]
    public void GetPhaseIndex_AtHalfHealth_ReturnsPhaseOne()
    {
        var enemy = CreateBossEnemy("grove_guardian", hp: 150, maxHp: 300);
        Assert.Equal(1, BossEncounters.GetPhaseIndex(enemy));
    }

    [Fact]
    public void GetPhaseIndex_JustBelowHalfHealth_ReturnsPhaseOne()
    {
        var enemy = CreateBossEnemy("grove_guardian", hp: 149, maxHp: 300);
        Assert.Equal(1, BossEncounters.GetPhaseIndex(enemy));
    }

    [Fact]
    public void GetPhaseIndex_AtQuarterHealth_ReturnsPhaseTwo()
    {
        var enemy = CreateBossEnemy("grove_guardian", hp: 75, maxHp: 300);
        Assert.Equal(2, BossEncounters.GetPhaseIndex(enemy));
    }

    [Fact]
    public void CheckPhaseTransition_NoPhaseChange_ReturnsFalse()
    {
        var enemy = CreateBossEnemy("grove_guardian", hp: 150, maxHp: 300, currentPhase: 1);

        bool changed = BossEncounters.CheckPhaseTransition(enemy);

        Assert.False(changed);
        Assert.Equal(1, enemy["current_phase"]);
    }

    [Fact]
    public void CheckPhaseTransition_PhaseChanged_ReturnsTrueAndUpdatesCurrentPhase()
    {
        var enemy = CreateBossEnemy("grove_guardian", hp: 75, maxHp: 300, currentPhase: 0);

        bool changed = BossEncounters.CheckPhaseTransition(enemy);

        Assert.True(changed);
        Assert.Equal(2, enemy["current_phase"]);
    }

    [Fact]
    public void CheckPhaseTransition_MissingCurrentPhase_UsesDefaultAndUpdates()
    {
        var enemy = CreateBossEnemy("grove_guardian", hp: 150, maxHp: 300);

        bool changed = BossEncounters.CheckPhaseTransition(enemy);

        Assert.True(changed);
        Assert.Equal(1, enemy["current_phase"]);
    }

    private static Dictionary<string, object> CreateBossEnemy(string bossId, int hp, int maxHp, int? currentPhase = null)
    {
        var enemy = new Dictionary<string, object>
        {
            ["boss_id"] = bossId,
            ["hp"] = hp,
            ["max_hp"] = maxHp,
        };

        if (currentPhase.HasValue)
            enemy["current_phase"] = currentPhase.Value;

        return enemy;
    }

    private static void AssertBossData(
        string bossId,
        string region,
        int unlockDay,
        int hp,
        int armor,
        int speed,
        int damage,
        string[] phaseOneAbilities,
        string[] phaseTwoAbilities,
        string[] phaseThreeAbilities)
    {
        var boss = BossEncounters.GetBoss(bossId);
        Assert.NotNull(boss);
        Assert.Equal(region, boss!.Region);
        Assert.Equal(unlockDay, boss.UnlockDay);
        Assert.Equal(hp, boss.Hp);
        Assert.Equal(armor, boss.Armor);
        Assert.Equal(speed, boss.Speed);
        Assert.Equal(damage, boss.Damage);
        Assert.Equal(3, boss.Phases.Length);

        AssertPhase(boss.Phases[0], expectedThreshold: 1.0, phaseOneAbilities);
        AssertPhase(boss.Phases[1], expectedThreshold: 0.5, phaseTwoAbilities);
        AssertPhase(boss.Phases[2], expectedThreshold: 0.25, phaseThreeAbilities);
    }

    private static void AssertPhase(BossPhase phase, double expectedThreshold, string[] expectedAbilities)
    {
        Assert.Equal(expectedThreshold, phase.HpThreshold);
        Assert.Equal(expectedAbilities, phase.Abilities);
    }
}
