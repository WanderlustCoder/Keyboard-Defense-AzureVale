using System.Collections.Generic;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.E2E;

public class SaveManagerRoundtripExtendedTests
{
    private static GameState CreateTestState()
    {
        return new GameState
        {
            MapW = 8,
            MapH = 8,
            Hp = 15,
            RngSeed = "roundtrip_test",
        };
    }

    private static GameState Roundtrip(GameState state)
    {
        string json = SaveManager.StateToJson(state);
        var (ok, loaded, error) = SaveManager.StateFromJson(json);
        Assert.True(ok, error ?? "Roundtrip failed");
        Assert.NotNull(loaded);
        return loaded!;
    }

    // --- Event System ---

    [Fact]
    public void Roundtrip_EventCooldowns()
    {
        var state = CreateTestState();
        state.EventCooldowns["raid"] = 3;
        state.EventCooldowns["merchant"] = 1;
        var loaded = Roundtrip(state);
        Assert.Equal(3, loaded.EventCooldowns["raid"]);
        Assert.Equal(1, loaded.EventCooldowns["merchant"]);
    }

    [Fact]
    public void Roundtrip_ActiveBuffs()
    {
        var state = CreateTestState();
        state.ActiveBuffs.Add(new Dictionary<string, object> { ["type"] = "shield", ["duration"] = 5 });
        var loaded = Roundtrip(state);
        Assert.Single(loaded.ActiveBuffs);
        Assert.Equal("shield", loaded.ActiveBuffs[0]["type"]);
    }

    // --- Progression ---

    [Fact]
    public void Roundtrip_BossesDefeated()
    {
        var state = CreateTestState();
        state.BossesDefeated.Add("dragon_king");
        state.BossesDefeated.Add("lich_lord");
        var loaded = Roundtrip(state);
        Assert.Contains("dragon_king", loaded.BossesDefeated);
        Assert.Contains("lich_lord", loaded.BossesDefeated);
    }

    [Fact]
    public void Roundtrip_Milestones()
    {
        var state = CreateTestState();
        state.Milestones.Add("first_wave");
        var loaded = Roundtrip(state);
        Assert.Contains("first_wave", loaded.Milestones);
    }

    [Fact]
    public void Roundtrip_UnlockedSkills()
    {
        var state = CreateTestState();
        state.UnlockedSkills.Add("double_strike");
        state.UnlockedSkills.Add("healing_word");
        var loaded = Roundtrip(state);
        Assert.Equal(2, loaded.UnlockedSkills.Count);
        Assert.Contains("double_strike", loaded.UnlockedSkills);
    }

    [Fact]
    public void Roundtrip_ActiveTitle()
    {
        var state = CreateTestState();
        state.ActiveTitle = "Dragon Slayer";
        var loaded = Roundtrip(state);
        Assert.Equal("Dragon Slayer", loaded.ActiveTitle);
    }

    // --- Inventory ---

    [Fact]
    public void Roundtrip_Inventory()
    {
        var state = CreateTestState();
        state.Inventory["health_potion"] = 5;
        state.Inventory["iron_sword"] = 1;
        var loaded = Roundtrip(state);
        Assert.Equal(5, loaded.Inventory["health_potion"]);
        Assert.Equal(1, loaded.Inventory["iron_sword"]);
    }

    [Fact]
    public void Roundtrip_EquippedItems()
    {
        var state = CreateTestState();
        state.EquippedItems["weapon"] = "iron_sword";
        state.EquippedItems["armor"] = "leather_vest";
        var loaded = Roundtrip(state);
        Assert.Equal("iron_sword", loaded.EquippedItems["weapon"]);
        Assert.Equal("leather_vest", loaded.EquippedItems["armor"]);
    }

    // --- Workers ---

    [Fact]
    public void Roundtrip_WorkerFields()
    {
        var state = CreateTestState();
        state.WorkerCount = 5;
        state.TotalWorkers = 7;
        state.MaxWorkers = 15;
        state.WorkerUpkeep = 2;
        var loaded = Roundtrip(state);
        Assert.Equal(5, loaded.WorkerCount);
        Assert.Equal(7, loaded.TotalWorkers);
        Assert.Equal(15, loaded.MaxWorkers);
        Assert.Equal(2, loaded.WorkerUpkeep);
    }

    // --- Research ---

    [Fact]
    public void Roundtrip_Research()
    {
        var state = CreateTestState();
        state.ActiveResearch = "iron_working";
        state.ResearchProgress = 42;
        state.CompletedResearch.Add("basic_tools");
        var loaded = Roundtrip(state);
        Assert.Equal("iron_working", loaded.ActiveResearch);
        Assert.Equal(42, loaded.ResearchProgress);
        Assert.Contains("basic_tools", loaded.CompletedResearch);
    }

    // --- Trade ---

    [Fact]
    public void Roundtrip_TradeRates()
    {
        var state = CreateTestState();
        state.TradeRates["wood_to_stone"] = 2.5;
        state.TradeRates["stone_to_gold"] = 0.75;
        state.LastTradeDay = 5;
        var loaded = Roundtrip(state);
        Assert.Equal(2.5, loaded.TradeRates["wood_to_stone"], 0.001);
        Assert.Equal(0.75, loaded.TradeRates["stone_to_gold"], 0.001);
        Assert.Equal(5, loaded.LastTradeDay);
    }

    // --- Faction ---

    [Fact]
    public void Roundtrip_FactionRelations()
    {
        var state = CreateTestState();
        state.FactionRelations["elves"] = 50;
        state.FactionRelations["orcs"] = -20;
        var loaded = Roundtrip(state);
        Assert.Equal(50, loaded.FactionRelations["elves"]);
        Assert.Equal(-20, loaded.FactionRelations["orcs"]);
    }

    [Fact]
    public void Roundtrip_FactionAgreements()
    {
        var state = CreateTestState();
        state.FactionAgreements["trade"].Add("elves");
        state.FactionAgreements["alliance"].Add("dwarves");
        var loaded = Roundtrip(state);
        Assert.Contains("elves", loaded.FactionAgreements["trade"]);
        Assert.Contains("dwarves", loaded.FactionAgreements["alliance"]);
    }

    // --- Accessibility ---

    [Fact]
    public void Roundtrip_Accessibility()
    {
        var state = CreateTestState();
        state.SpeedMultiplier = 1.5f;
        state.PracticeMode = true;
        var loaded = Roundtrip(state);
        Assert.Equal(1.5f, loaded.SpeedMultiplier, 0.01f);
        Assert.True(loaded.PracticeMode);
    }

    // --- Open-world timing ---

    [Fact]
    public void Roundtrip_WorldTickAccum()
    {
        var state = CreateTestState();
        state.WorldTickAccum = 0.75f;
        state.ThreatDecayAccum = 0.3f;
        var loaded = Roundtrip(state);
        Assert.Equal(0.75f, loaded.WorldTickAccum, 0.01f);
        Assert.Equal(0.3f, loaded.ThreatDecayAccum, 0.01f);
    }

    // --- Resource Nodes ---

    [Fact]
    public void Roundtrip_ResourceNodes()
    {
        var state = CreateTestState();
        state.ResourceNodes[42] = new Dictionary<string, object>
        {
            ["type"] = "wood_grove",
            ["cooldown"] = 0f,
        };
        state.HarvestedNodes["wood_grove"] = 3;
        var loaded = Roundtrip(state);
        Assert.True(loaded.ResourceNodes.ContainsKey(42));
        Assert.Equal("wood_grove", loaded.ResourceNodes[42]["type"]);
        Assert.Equal(3, loaded.HarvestedNodes["wood_grove"]);
    }

    // --- Tower State ---

    [Fact]
    public void Roundtrip_TowerStates()
    {
        var state = CreateTestState();
        state.TowerStates[5] = new Dictionary<string, object>
        {
            ["kind"] = "arrow_tower",
            ["level"] = 2,
        };
        state.TowerCharge[5] = 3;
        state.TowerCooldowns[5] = 1;
        var loaded = Roundtrip(state);
        Assert.True(loaded.TowerStates.ContainsKey(5));
        Assert.Equal("arrow_tower", loaded.TowerStates[5]["kind"]);
        Assert.Equal(3, loaded.TowerCharge[5]);
        Assert.Equal(1, loaded.TowerCooldowns[5]);
    }

    [Fact]
    public void Roundtrip_TowerSummonIds()
    {
        var state = CreateTestState();
        state.TowerSummonIds[1] = new List<int> { 10, 11, 12 };
        var loaded = Roundtrip(state);
        Assert.Equal(new List<int> { 10, 11, 12 }, loaded.TowerSummonIds[1]);
    }

    [Fact]
    public void Roundtrip_AutoTowerSettings()
    {
        var state = CreateTestState();
        state.AutoTower.AutoBuild = true;
        state.AutoTower.BuildPriority = "offense";
        state.AutoTower.AutoUpgrade = true;
        state.AutoTower.AutoRepair = false;
        state.AutoTower.ResourceReservePercent = 50;
        var loaded = Roundtrip(state);
        Assert.True(loaded.AutoTower.AutoBuild);
        Assert.Equal("offense", loaded.AutoTower.BuildPriority);
        Assert.True(loaded.AutoTower.AutoUpgrade);
        Assert.False(loaded.AutoTower.AutoRepair);
        Assert.Equal(50, loaded.AutoTower.ResourceReservePercent);
    }

    // --- Hero ---

    [Fact]
    public void Roundtrip_HeroFields()
    {
        var state = CreateTestState();
        state.HeroId = "paladin";
        state.HeroAbilityCooldown = 3.5f;
        state.HeroActiveEffects.Add(new Dictionary<string, object> { ["type"] = "regen", ["stacks"] = 2 });
        var loaded = Roundtrip(state);
        Assert.Equal("paladin", loaded.HeroId);
        Assert.Equal(3.5f, loaded.HeroAbilityCooldown, 0.01f);
        Assert.Single(loaded.HeroActiveEffects);
    }

    // --- Titles ---

    [Fact]
    public void Roundtrip_Titles()
    {
        var state = CreateTestState();
        state.EquippedTitle = "Grandmaster Typist";
        state.UnlockedTitles.Add("Grandmaster Typist");
        state.UnlockedTitles.Add("Explorer");
        state.UnlockedBadges.Add("first_blood");
        var loaded = Roundtrip(state);
        Assert.Equal("Grandmaster Typist", loaded.EquippedTitle);
        Assert.Equal(2, loaded.UnlockedTitles.Count);
        Assert.Single(loaded.UnlockedBadges);
    }

    // --- Daily Challenges ---

    [Fact]
    public void Roundtrip_DailyChallenges()
    {
        var state = CreateTestState();
        state.CompletedDailyChallenges.Add("speed_demon");
        state.DailyChallengeDate = "2026-02-21";
        state.PerfectNightsToday = 2;
        state.NoDamageNightsToday = 1;
        state.FastestNightSeconds = 45;
        var loaded = Roundtrip(state);
        Assert.Contains("speed_demon", loaded.CompletedDailyChallenges);
        Assert.Equal("2026-02-21", loaded.DailyChallengeDate);
        Assert.Equal(2, loaded.PerfectNightsToday);
        Assert.Equal(1, loaded.NoDamageNightsToday);
        Assert.Equal(45, loaded.FastestNightSeconds);
    }

    // --- Victory ---

    [Fact]
    public void Roundtrip_Victory()
    {
        var state = CreateTestState();
        state.VictoryAchieved.Add("typing_mastery");
        state.VictoryChecked = true;
        state.PeakGold = 999;
        state.StoryCompleted = true;
        state.CurrentAct = 3;
        var loaded = Roundtrip(state);
        Assert.Contains("typing_mastery", loaded.VictoryAchieved);
        Assert.True(loaded.VictoryChecked);
        Assert.Equal(999, loaded.PeakGold);
        Assert.True(loaded.StoryCompleted);
        Assert.Equal(3, loaded.CurrentAct);
    }

    // --- Loot ---

    [Fact]
    public void Roundtrip_Loot()
    {
        var state = CreateTestState();
        state.LootPending.Add(new Dictionary<string, object> { ["item"] = "gem", ["qty"] = 1 });
        state.LastLootQuality = 1.5f;
        state.PerfectKills = 8;
        var loaded = Roundtrip(state);
        Assert.Single(loaded.LootPending);
        Assert.Equal(1.5f, loaded.LastLootQuality, 0.01f);
        Assert.Equal(8, loaded.PerfectKills);
    }

    // --- TypingMetrics with long values ---

    [Fact]
    public void Roundtrip_TypingMetrics_LongValues()
    {
        var state = CreateTestState();
        state.TypingMetrics["battle_start_msec"] = 9876543210L;
        state.TypingMetrics["battle_chars_typed"] = 42;
        string json = SaveManager.StateToJson(state);
        var (ok, loaded, error) = SaveManager.StateFromJson(json);
        Assert.True(ok, error ?? "Failed");
        Assert.Equal(9876543210L, System.Convert.ToInt64(loaded!.TypingMetrics["battle_start_msec"]));
        Assert.Equal(42, System.Convert.ToInt32(loaded.TypingMetrics["battle_chars_typed"]));
    }

    // --- Citizens ---

    [Fact]
    public void Roundtrip_Citizens()
    {
        var state = CreateTestState();
        state.Citizens.Add(new Dictionary<string, object> { ["name"] = "Ada", ["role"] = "smith" });
        var loaded = Roundtrip(state);
        Assert.Single(loaded.Citizens);
        Assert.Equal("Ada", loaded.Citizens[0]["name"]);
    }

    // --- Expeditions ---

    [Fact]
    public void Roundtrip_Expeditions()
    {
        var state = CreateTestState();
        state.ExpeditionNextId = 5;
        state.ActiveExpeditions.Add(new Dictionary<string, object> { ["id"] = 4, ["status"] = "active" });
        var loaded = Roundtrip(state);
        Assert.Equal(5, loaded.ExpeditionNextId);
        Assert.Single(loaded.ActiveExpeditions);
    }

    // --- Targeting ---

    [Fact]
    public void Roundtrip_TargetingMode()
    {
        var state = CreateTestState();
        state.TargetingMode = "strongest";
        var loaded = Roundtrip(state);
        Assert.Equal("strongest", loaded.TargetingMode);
    }
}
