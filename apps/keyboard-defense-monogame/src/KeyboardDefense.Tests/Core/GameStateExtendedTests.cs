using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

/// <summary>
/// Extended tests for GameState — constructor defaults, collection initialization,
/// Index calculations, and property coverage for all 80+ fields.
/// </summary>
public class GameStateExtendedTests
{
    // =========================================================================
    // Constructor — Core defaults
    // =========================================================================

    [Fact]
    public void Constructor_Day_IsOne()
    {
        var s = new GameState();
        Assert.Equal(1, s.Day);
    }

    [Fact]
    public void Constructor_Phase_IsDay()
    {
        var s = new GameState();
        Assert.Equal("day", s.Phase);
    }

    [Fact]
    public void Constructor_ApAndApMax_AreThree()
    {
        var s = new GameState();
        Assert.Equal(3, s.ApMax);
        Assert.Equal(3, s.Ap);
        Assert.Equal(s.ApMax, s.Ap);
    }

    [Fact]
    public void Constructor_HpAndMaxHp_AreTen()
    {
        var s = new GameState();
        Assert.Equal(10, s.Hp);
        Assert.Equal(10, s.MaxHp);
    }

    [Fact]
    public void Constructor_Threat_IsZero()
    {
        var s = new GameState();
        Assert.Equal(0, s.Threat);
    }

    [Fact]
    public void Constructor_MapDimensions_Are32x32()
    {
        var s = new GameState();
        Assert.Equal(32, s.MapW);
        Assert.Equal(32, s.MapH);
    }

    [Fact]
    public void Constructor_BasePos_IsCenterOfMap()
    {
        var s = new GameState();
        Assert.Equal(new GridPoint(16, 16), s.BasePos);
    }

    [Fact]
    public void Constructor_CursorPos_EqualsBasePos()
    {
        var s = new GameState();
        Assert.Equal(s.BasePos, s.CursorPos);
    }

    [Fact]
    public void Constructor_PlayerPos_EqualsBasePos()
    {
        var s = new GameState();
        Assert.Equal(s.BasePos, s.PlayerPos);
    }

    [Fact]
    public void Constructor_NightFields_AreDefault()
    {
        var s = new GameState();
        Assert.Equal("", s.NightPrompt);
        Assert.Equal(0, s.NightSpawnRemaining);
        Assert.Equal(0, s.NightWaveTotal);
    }

    [Fact]
    public void Constructor_EnemyNextId_IsOne()
    {
        var s = new GameState();
        Assert.Equal(1, s.EnemyNextId);
    }

    [Fact]
    public void Constructor_LastPathOpen_IsTrue()
    {
        var s = new GameState();
        Assert.True(s.LastPathOpen);
    }

    [Fact]
    public void Constructor_RngFields_AreDefault()
    {
        var s = new GameState();
        Assert.Equal("default", s.RngSeed);
        Assert.Equal(0, s.RngState);
    }

    [Fact]
    public void Constructor_LessonId_IsFullAlpha()
    {
        var s = new GameState();
        Assert.Equal("full_alpha", s.LessonId);
    }

    [Fact]
    public void Constructor_Version_IsOne()
    {
        var s = new GameState();
        Assert.Equal(1, s.Version);
    }

    // =========================================================================
    // Constructor — Resource/Building collections
    // =========================================================================

    [Fact]
    public void Constructor_AllResourceKeys_ArePresent()
    {
        var s = new GameState();
        foreach (var key in GameState.ResourceKeys)
        {
            Assert.True(s.Resources.ContainsKey(key), $"Missing resource key: {key}");
            Assert.Equal(0, s.Resources[key]);
        }
    }

    [Fact]
    public void Constructor_ResourceKeys_AreExactly_WoodStoneFood()
    {
        Assert.Equal(new[] { "wood", "stone", "food" }, GameState.ResourceKeys);
    }

    [Fact]
    public void Constructor_AllBuildingKeys_ArePresent()
    {
        var s = new GameState();
        foreach (var key in GameState.BuildingKeys)
        {
            Assert.True(s.Buildings.ContainsKey(key), $"Missing building key: {key}");
            Assert.Equal(0, s.Buildings[key]);
        }
    }

    [Fact]
    public void Constructor_BuildingKeys_AreNine()
    {
        Assert.Equal(9, GameState.BuildingKeys.Length);
        Assert.Contains("farm", GameState.BuildingKeys);
        Assert.Contains("tower", GameState.BuildingKeys);
        Assert.Contains("barracks", GameState.BuildingKeys);
    }

    [Fact]
    public void Constructor_Terrain_HasMapWxMapH_Entries()
    {
        var s = new GameState();
        Assert.Equal(32 * 32, s.Terrain.Count);
    }

    [Fact]
    public void Constructor_Terrain_AllEntriesAreEmptyStrings()
    {
        var s = new GameState();
        Assert.All(s.Terrain, t => Assert.Equal("", t));
    }

    // =========================================================================
    // Constructor — Collection initialization (non-null)
    // =========================================================================

    [Fact]
    public void Constructor_Structures_IsEmptyDictionary()
    {
        var s = new GameState();
        Assert.NotNull(s.Structures);
        Assert.Empty(s.Structures);
    }

    [Fact]
    public void Constructor_StructureLevels_IsEmptyDictionary()
    {
        var s = new GameState();
        Assert.NotNull(s.StructureLevels);
        Assert.Empty(s.StructureLevels);
    }

    [Fact]
    public void Constructor_Discovered_ContainsOnlyBasePos()
    {
        var s = new GameState();
        Assert.Single(s.Discovered);
        Assert.Contains(s.Index(s.BasePos.X, s.BasePos.Y), s.Discovered);
    }

    [Fact]
    public void Constructor_Enemies_IsEmptyList()
    {
        var s = new GameState();
        Assert.NotNull(s.Enemies);
        Assert.Empty(s.Enemies);
    }

    [Fact]
    public void Constructor_ActivePois_IsEmpty()
    {
        var s = new GameState();
        Assert.NotNull(s.ActivePois);
        Assert.Empty(s.ActivePois);
    }

    [Fact]
    public void Constructor_EventCooldowns_IsEmpty()
    {
        var s = new GameState();
        Assert.NotNull(s.EventCooldowns);
        Assert.Empty(s.EventCooldowns);
    }

    [Fact]
    public void Constructor_EventFlags_IsEmpty()
    {
        var s = new GameState();
        Assert.NotNull(s.EventFlags);
        Assert.Empty(s.EventFlags);
    }

    [Fact]
    public void Constructor_PendingEvent_IsEmpty()
    {
        var s = new GameState();
        Assert.NotNull(s.PendingEvent);
        Assert.Empty(s.PendingEvent);
    }

    [Fact]
    public void Constructor_ActiveBuffs_IsEmpty()
    {
        var s = new GameState();
        Assert.NotNull(s.ActiveBuffs);
        Assert.Empty(s.ActiveBuffs);
    }

    // =========================================================================
    // Constructor — Upgrade/Economy defaults
    // =========================================================================

    [Fact]
    public void Constructor_Gold_IsZero()
    {
        var s = new GameState();
        Assert.Equal(0, s.Gold);
    }

    [Fact]
    public void Constructor_UpgradeLists_AreEmpty()
    {
        var s = new GameState();
        Assert.NotNull(s.PurchasedKingdomUpgrades);
        Assert.Empty(s.PurchasedKingdomUpgrades);
        Assert.NotNull(s.PurchasedUnitUpgrades);
        Assert.Empty(s.PurchasedUnitUpgrades);
    }

    // =========================================================================
    // Constructor — Progression defaults
    // =========================================================================

    [Fact]
    public void Constructor_ProgressionSets_AreEmpty()
    {
        var s = new GameState();
        Assert.Empty(s.CompletedQuests);
        Assert.Empty(s.BossesDefeated);
        Assert.Empty(s.Milestones);
        Assert.Empty(s.UnlockedSkills);
    }

    [Fact]
    public void Constructor_ProgressionCounters_AreZero()
    {
        var s = new GameState();
        Assert.Equal(0, s.SkillPoints);
        Assert.Equal(0, s.EnemiesDefeated);
        Assert.Equal(0, s.MaxComboEver);
        Assert.Equal(0, s.WavesSurvived);
    }

    [Fact]
    public void Constructor_ActiveTitle_IsEmpty()
    {
        var s = new GameState();
        Assert.Equal("", s.ActiveTitle);
    }

    // =========================================================================
    // Constructor — Worker system
    // =========================================================================

    [Fact]
    public void Constructor_Workers_DefaultValues()
    {
        var s = new GameState();
        Assert.Equal(3, s.TotalWorkers);
        Assert.Equal(3, s.WorkerCount);
        Assert.Equal(10, s.MaxWorkers);
        Assert.Equal(1, s.WorkerUpkeep);
    }

    [Fact]
    public void Constructor_Workers_DictionariesAreEmpty()
    {
        var s = new GameState();
        Assert.NotNull(s.Workers);
        Assert.Empty(s.Workers);
        Assert.NotNull(s.WorkerAssignments);
        Assert.Empty(s.WorkerAssignments);
    }

    // =========================================================================
    // Constructor — Trade system
    // =========================================================================

    [Fact]
    public void Constructor_TradeRates_HasEightEntries()
    {
        var s = new GameState();
        Assert.Equal(8, s.TradeRates.Count);
    }

    [Fact]
    public void Constructor_TradeRates_WoodToStone_IsOnePointFive()
    {
        var s = new GameState();
        Assert.Equal(1.5, s.TradeRates["wood_to_stone"], 5);
    }

    [Fact]
    public void Constructor_TradeHistory_IsEmpty()
    {
        var s = new GameState();
        Assert.NotNull(s.TradeHistory);
        Assert.Empty(s.TradeHistory);
    }

    [Fact]
    public void Constructor_LastTradeDay_IsZero()
    {
        var s = new GameState();
        Assert.Equal(0, s.LastTradeDay);
    }

    // =========================================================================
    // Constructor — Faction/Diplomacy
    // =========================================================================

    [Fact]
    public void Constructor_FactionAgreements_HasFourCategories()
    {
        var s = new GameState();
        Assert.Equal(4, s.FactionAgreements.Count);
        Assert.True(s.FactionAgreements.ContainsKey("trade"));
        Assert.True(s.FactionAgreements.ContainsKey("non_aggression"));
        Assert.True(s.FactionAgreements.ContainsKey("alliance"));
        Assert.True(s.FactionAgreements.ContainsKey("war"));
    }

    [Fact]
    public void Constructor_FactionAgreements_AllCategoriesAreEmpty()
    {
        var s = new GameState();
        Assert.All(s.FactionAgreements.Values, list => Assert.Empty(list));
    }

    [Fact]
    public void Constructor_FactionRelations_IsEmpty()
    {
        var s = new GameState();
        Assert.NotNull(s.FactionRelations);
        Assert.Empty(s.FactionRelations);
    }

    // =========================================================================
    // Constructor — Accessibility
    // =========================================================================

    [Fact]
    public void Constructor_SpeedMultiplier_IsOne()
    {
        var s = new GameState();
        Assert.Equal(1.0f, s.SpeedMultiplier);
    }

    [Fact]
    public void Constructor_PracticeMode_IsFalse()
    {
        var s = new GameState();
        Assert.False(s.PracticeMode);
    }

    // =========================================================================
    // Constructor — Open-world
    // =========================================================================

    [Fact]
    public void Constructor_OpenWorldFields_AreDefault()
    {
        var s = new GameState();
        Assert.Equal("down", s.PlayerFacing);
        Assert.Empty(s.Npcs);
        Assert.Empty(s.RoamingEnemies);
        Assert.Empty(s.RoamingResources);
        Assert.Equal(0.0f, s.ThreatLevel);
        Assert.Equal(0.25f, s.TimeOfDay);
        Assert.Equal(0.0f, s.WorldTickAccum);
    }

    // =========================================================================
    // Constructor — Unified threat
    // =========================================================================

    [Fact]
    public void Constructor_ActivityMode_IsExploration()
    {
        var s = new GameState();
        Assert.Equal("exploration", s.ActivityMode);
    }

    [Fact]
    public void Constructor_EncounterEnemies_IsEmpty()
    {
        var s = new GameState();
        Assert.Empty(s.EncounterEnemies);
    }

    [Fact]
    public void Constructor_WaveCooldown_IsZero()
    {
        var s = new GameState();
        Assert.Equal(0.0f, s.WaveCooldown);
    }

    // =========================================================================
    // Constructor — Expedition system
    // =========================================================================

    [Fact]
    public void Constructor_ExpeditionFields_AreDefault()
    {
        var s = new GameState();
        Assert.Empty(s.ActiveExpeditions);
        Assert.Equal(1, s.ExpeditionNextId);
        Assert.Empty(s.ExpeditionHistory);
    }

    // =========================================================================
    // Constructor — Loot tracking
    // =========================================================================

    [Fact]
    public void Constructor_LootFields_AreDefault()
    {
        var s = new GameState();
        Assert.Empty(s.LootPending);
        Assert.Equal(1.0f, s.LastLootQuality);
        Assert.Equal(0, s.PerfectKills);
    }

    // =========================================================================
    // Constructor — Tower system
    // =========================================================================

    [Fact]
    public void Constructor_TowerCollections_AreEmpty()
    {
        var s = new GameState();
        Assert.Empty(s.TowerStates);
        Assert.Empty(s.ActiveSynergies);
        Assert.Empty(s.SummonedUnits);
        Assert.Empty(s.ActiveTraps);
        Assert.Empty(s.TowerCharge);
        Assert.Empty(s.TowerCooldowns);
        Assert.Empty(s.TowerSummonIds);
    }

    [Fact]
    public void Constructor_SummonedNextId_IsOne()
    {
        var s = new GameState();
        Assert.Equal(1, s.SummonedNextId);
    }

    [Fact]
    public void Constructor_TargetingMode_IsNearest()
    {
        var s = new GameState();
        Assert.Equal("nearest", s.TargetingMode);
    }

    // =========================================================================
    // Constructor — TypingMetrics
    // =========================================================================

    [Fact]
    public void Constructor_TypingMetrics_HasExpectedKeys()
    {
        var s = new GameState();
        Assert.True(s.TypingMetrics.ContainsKey("battle_chars_typed"));
        Assert.True(s.TypingMetrics.ContainsKey("battle_words_typed"));
        Assert.True(s.TypingMetrics.ContainsKey("battle_start_msec"));
        Assert.True(s.TypingMetrics.ContainsKey("battle_errors"));
        Assert.True(s.TypingMetrics.ContainsKey("rolling_window_chars"));
        Assert.True(s.TypingMetrics.ContainsKey("unique_letters_window"));
        Assert.True(s.TypingMetrics.ContainsKey("perfect_word_streak"));
        Assert.True(s.TypingMetrics.ContainsKey("current_word_errors"));
    }

    [Fact]
    public void Constructor_TypingMetrics_CountersAreZero()
    {
        var s = new GameState();
        Assert.Equal(0, Convert.ToInt32(s.TypingMetrics["battle_chars_typed"]));
        Assert.Equal(0, Convert.ToInt32(s.TypingMetrics["battle_words_typed"]));
        Assert.Equal(0, Convert.ToInt32(s.TypingMetrics["battle_errors"]));
        Assert.Equal(0, Convert.ToInt32(s.TypingMetrics["perfect_word_streak"]));
        Assert.Equal(0, Convert.ToInt32(s.TypingMetrics["current_word_errors"]));
    }

    // =========================================================================
    // Constructor — Hero system
    // =========================================================================

    [Fact]
    public void Constructor_HeroFields_AreDefault()
    {
        var s = new GameState();
        Assert.Equal("", s.HeroId);
        Assert.Equal(0.0f, s.HeroAbilityCooldown);
        Assert.Empty(s.HeroActiveEffects);
    }

    // =========================================================================
    // Constructor — Title system
    // =========================================================================

    [Fact]
    public void Constructor_TitleFields_AreDefault()
    {
        var s = new GameState();
        Assert.Equal("", s.EquippedTitle);
        Assert.Empty(s.UnlockedTitles);
        Assert.Empty(s.UnlockedBadges);
    }

    // =========================================================================
    // Constructor — Daily challenge
    // =========================================================================

    [Fact]
    public void Constructor_DailyChallengeFields_AreDefault()
    {
        var s = new GameState();
        Assert.Empty(s.CompletedDailyChallenges);
        Assert.Equal("", s.DailyChallengeDate);
        Assert.Equal(0, s.PerfectNightsToday);
        Assert.Equal(0, s.NoDamageNightsToday);
        Assert.Equal(0, s.FastestNightSeconds);
    }

    // =========================================================================
    // Constructor — Victory system
    // =========================================================================

    [Fact]
    public void Constructor_VictoryFields_AreDefault()
    {
        var s = new GameState();
        Assert.Empty(s.VictoryAchieved);
        Assert.False(s.VictoryChecked);
        Assert.Equal(0, s.PeakGold);
        Assert.False(s.StoryCompleted);
        Assert.Equal(1, s.CurrentAct);
    }

    // =========================================================================
    // Constructor — Research system
    // =========================================================================

    [Fact]
    public void Constructor_ResearchFields_AreDefault()
    {
        var s = new GameState();
        Assert.Equal("", s.ActiveResearch);
        Assert.Equal(0, s.ResearchProgress);
        Assert.Empty(s.CompletedResearch);
    }

    // =========================================================================
    // Constructor — Inventory & equipment
    // =========================================================================

    [Fact]
    public void Constructor_InventoryAndEquipment_AreEmpty()
    {
        var s = new GameState();
        Assert.Empty(s.Inventory);
        Assert.Empty(s.EquippedItems);
    }

    // =========================================================================
    // Constructor — Citizens
    // =========================================================================

    [Fact]
    public void Constructor_Citizens_IsEmpty()
    {
        var s = new GameState();
        Assert.Empty(s.Citizens);
    }

    // =========================================================================
    // Constructor — Resource nodes
    // =========================================================================

    [Fact]
    public void Constructor_ResourceNodes_AreEmpty()
    {
        var s = new GameState();
        Assert.Empty(s.ResourceNodes);
        Assert.Empty(s.HarvestedNodes);
    }

    // =========================================================================
    // Constructor — AutoTower settings
    // =========================================================================

    [Fact]
    public void Constructor_AutoTower_IsNotNull()
    {
        var s = new GameState();
        Assert.NotNull(s.AutoTower);
    }

    // =========================================================================
    // Index — calculations
    // =========================================================================

    [Fact]
    public void Index_Origin_IsZero()
    {
        var s = new GameState();
        Assert.Equal(0, s.Index(0, 0));
    }

    [Fact]
    public void Index_FirstRow_IsDirectOffset()
    {
        var s = new GameState();
        Assert.Equal(5, s.Index(5, 0));
    }

    [Fact]
    public void Index_SecondRow_OffsetsMapWidth()
    {
        var s = new GameState();
        Assert.Equal(32, s.Index(0, 1));
        Assert.Equal(37, s.Index(5, 1));
    }

    [Fact]
    public void Index_LastTile_IsMapWxMapHMinusOne()
    {
        var s = new GameState();
        Assert.Equal(32 * 32 - 1, s.Index(31, 31));
    }

    [Fact]
    public void Index_RowMajorProperty_YDominatesX()
    {
        var s = new GameState();
        // (1, 0) < (0, 1) in row-major
        Assert.True(s.Index(1, 0) < s.Index(0, 1));
    }

    [Fact]
    public void Index_ConsecutiveInRow_DifferByOne()
    {
        var s = new GameState();
        for (int x = 0; x < 31; x++)
        {
            Assert.Equal(1, s.Index(x + 1, 5) - s.Index(x, 5));
        }
    }

    [Fact]
    public void Index_ConsecutiveInColumn_DifferByMapW()
    {
        var s = new GameState();
        for (int y = 0; y < 31; y++)
        {
            Assert.Equal(s.MapW, s.Index(5, y + 1) - s.Index(5, y));
        }
    }

    // =========================================================================
    // Mutability — properties can be set
    // =========================================================================

    [Fact]
    public void Day_CanBeSet()
    {
        var s = new GameState();
        s.Day = 42;
        Assert.Equal(42, s.Day);
    }

    [Fact]
    public void Phase_CanBeChanged()
    {
        var s = new GameState();
        s.Phase = "night";
        Assert.Equal("night", s.Phase);
    }

    [Fact]
    public void Gold_CanExceedMaxHp_NoClamp()
    {
        var s = new GameState();
        s.Gold = 999_999;
        Assert.Equal(999_999, s.Gold);
    }

    [Fact]
    public void Enemies_CanBeAppendedTo()
    {
        var s = new GameState();
        s.Enemies.Add(new Dictionary<string, object> { ["hp"] = 5 });
        Assert.Single(s.Enemies);
    }

    [Fact]
    public void Structures_CanBePlacedByIndex()
    {
        var s = new GameState();
        int idx = s.Index(10, 10);
        s.Structures[idx] = "tower";
        Assert.Equal("tower", s.Structures[idx]);
    }

    [Fact]
    public void Discovered_CanAddTiles()
    {
        var s = new GameState();
        int idx = s.Index(0, 0);
        s.Discovered.Add(idx);
        Assert.Contains(idx, s.Discovered);
    }

    // =========================================================================
    // Two instances are independent
    // =========================================================================

    [Fact]
    public void TwoInstances_DoNotShareState()
    {
        var a = new GameState();
        var b = new GameState();

        a.Day = 99;
        a.Gold = 5000;
        a.Resources["wood"] = 100;

        Assert.Equal(1, b.Day);
        Assert.Equal(0, b.Gold);
        Assert.Equal(0, b.Resources["wood"]);
    }

    [Fact]
    public void TwoInstances_DoNotShareCollections()
    {
        var a = new GameState();
        var b = new GameState();

        a.Enemies.Add(new Dictionary<string, object> { ["hp"] = 1 });
        a.Discovered.Add(999);

        Assert.Empty(b.Enemies);
        Assert.DoesNotContain(999, b.Discovered);
    }
}
