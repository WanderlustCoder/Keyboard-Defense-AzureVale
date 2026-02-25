using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.E2E;

public class ProgressionIntegrationTests
{
    [Fact]
    public void QuestAcceptance_DayAndDependencyGatesUpdateAvailableQuests()
    {
        var state = CreateState("progression_quest_acceptance");
        state.Day = 1;

        var dayOneAvailable = WorldQuests.GetAvailableQuests(state);

        Assert.Contains("first_tower", dayOneAvailable);
        Assert.DoesNotContain("supply_run", dayOneAvailable);
        Assert.DoesNotContain("kingdom_builder", dayOneAvailable);

        state.Structures.Clear();
        state.Structures[1] = "tower";
        WorldQuests.CheckCompletions(state);
        Assert.Contains("first_tower", state.CompletedQuests);

        state.Day = 2;
        var dayTwoAvailable = WorldQuests.GetAvailableQuests(state);

        Assert.Contains("supply_run", dayTwoAvailable);
        Assert.Contains("kingdom_builder", dayTwoAvailable);
    }

    [Fact]
    public void QuestProgressTracking_FirstTowerQuestReportsAndCompletesAtTarget()
    {
        var state = CreateState("progression_quest_progress");
        state.Day = 0;
        state.Discovered.Clear();
        state.Structures.Clear();

        var quest = Assert.IsType<QuestDef>(Quests.GetQuest("first_tower"));

        var before = WorldQuests.GetProgress(state, "first_tower");
        Assert.Equal((0, quest.Condition.Value), before);

        state.Structures[5] = "tower";
        var after = WorldQuests.GetProgress(state, "first_tower");
        Assert.Equal((quest.Condition.Value, quest.Condition.Value), after);

        int goldBefore = state.Gold;
        var events = WorldQuests.CheckCompletions(state);

        Assert.Contains("first_tower", state.CompletedQuests);
        Assert.Equal(goldBefore + quest.Rewards["gold"], state.Gold);
        Assert.Contains(events, e => e.Contains("First Defense", StringComparison.Ordinal));
    }

    [Fact]
    public void QuestCompletion_AppliesMultiResourceRewards()
    {
        var state = CreateState("progression_quest_rewards");
        var quest = Assert.IsType<QuestDef>(Quests.GetQuest("defender_of_the_realm"));

        int goldBefore = state.Gold;
        int skillPointsBefore = state.SkillPoints;
        int woodBefore = state.Resources.GetValueOrDefault("wood", 0);
        int stoneBefore = state.Resources.GetValueOrDefault("stone", 0);

        var result = Quests.CompleteQuest(state, "defender_of_the_realm");

        Assert.True(Convert.ToBoolean(result["ok"]));
        Assert.Contains("defender_of_the_realm", state.CompletedQuests);
        Assert.Equal(goldBefore + quest.Rewards["gold"], state.Gold);
        Assert.Equal(skillPointsBefore + quest.Rewards["skill_point"], state.SkillPoints);
        Assert.Equal(woodBefore + quest.Rewards["wood"], state.Resources["wood"]);
        Assert.Equal(stoneBefore + quest.Rewards["stone"], state.Resources["stone"]);
    }

    [Fact]
    public void UpgradePurchase_TracksOwnershipAndPreventsDuplicatePurchases()
    {
        var state = CreateState("progression_upgrade_purchase");
        var upgrade = GetAnyUpgrade("kingdom");
        string upgradeId = UpgradeId(upgrade);
        int runtimeCost = RuntimeUpgradeCost(upgrade);

        Assert.False(string.IsNullOrWhiteSpace(upgradeId));

        state.Gold = runtimeCost + 100;
        int goldBefore = state.Gold;

        var first = Upgrades.Purchase(state, upgradeId, "kingdom");
        var second = Upgrades.Purchase(state, upgradeId, "kingdom");

        Assert.True(Convert.ToBoolean(first["ok"]));
        Assert.Contains(upgradeId, state.PurchasedKingdomUpgrades);
        Assert.Equal(goldBefore - runtimeCost, state.Gold);

        Assert.False(Convert.ToBoolean(second["ok"]));
        Assert.Equal("Already purchased.", second["error"]);
    }

    [Fact]
    public void UpgradePurchaseAndStatEffectApplication_HeroAndSkillBonusesStack()
    {
        var state = CreateState("progression_upgrade_stats");
        var unitUpgrade = GetAnyUpgrade("unit");
        string unitUpgradeId = UpgradeId(unitUpgrade);

        Assert.False(string.IsNullOrWhiteSpace(unitUpgradeId));

        state.Gold = RuntimeUpgradeCost(unitUpgrade) + 100;
        var purchase = Upgrades.Purchase(state, unitUpgradeId, "unit");
        Assert.True(Convert.ToBoolean(purchase["ok"]));

        state.HeroId = "warrior";
        state.SkillPoints = 1;
        var unlock = Skills.UnlockSkill(state, "quick_fingers");
        Assert.True(Convert.ToBoolean(unlock["ok"]));

        double heroDamageMult = HeroTypes.GetHeroBonus(state.HeroId, "damage_mult", 1.0);
        double combinedDamageMult = Skills.GetBonusValue(state, "damage_mult", heroDamageMult);

        Assert.True(combinedDamageMult > heroDamageMult);
        Assert.Equal(heroDamageMult * 1.1, combinedDamageMult, 3);
        Assert.Contains(unitUpgradeId, state.PurchasedUnitUpgrades);
    }

    [Fact]
    public void HeroLevelUpMechanics_ScholarXpMultiplierReachesHigherLevelThanCommander()
    {
        int commanderLevel = SimulateHeroLevel("commander", encounterCount: 8, baseXpPerEncounter: 45);
        int scholarLevel = SimulateHeroLevel("scholar", encounterCount: 8, baseXpPerEncounter: 45);

        Assert.True(commanderLevel >= 2);
        Assert.True(scholarLevel > commanderLevel);
    }

    [Fact]
    public void MilestoneUnlockChains_ComboAndDayMilestonesUnlockTogether()
    {
        var state = CreateState("progression_milestone_chains");
        state.Day = 30;
        state.MaxComboEver = 50;

        var earned = Milestones.CheckNewMilestones(state);

        Assert.Contains("combo_5", earned);
        Assert.Contains("combo_20", earned);
        Assert.Contains("combo_50", earned);
        Assert.Contains("day_7", earned);
        Assert.Contains("day_14", earned);
        Assert.Contains("day_30", earned);

        var secondPass = Milestones.CheckNewMilestones(state);
        Assert.Empty(secondPass);
    }

    [Fact]
    public void MilestoneUnlockChains_ExplorationMilestoneUnlocksExplorerTitle()
    {
        var state = CreateState("progression_milestone_title");
        state.MapW = 4;
        state.MapH = 4;
        state.Discovered.Clear();
        for (int i = 0; i < 8; i++)
            state.Discovered.Add(i);

        var earned = Milestones.CheckNewMilestones(state);
        Assert.Contains("explore_25", earned);
        Assert.Contains("explore_50", earned);

        var unlockedTitles = Titles.GetUnlockedTitles(state);
        Assert.Contains("explorer", unlockedTitles);

        Assert.True(Titles.EquipTitle(state, "explorer"));
        Assert.Equal("explorer", state.ActiveTitle);
    }

    [Fact]
    public void ProgressionPersistence_SaveLoad_RoundTripsQuestUpgradeMilestoneAndHeroState()
    {
        var state = CreateState("progression_save_load");

        var kingdomUpgrade = GetAnyUpgrade("kingdom");
        var unitUpgrade = GetAnyUpgrade("unit");
        string kingdomUpgradeId = UpgradeId(kingdomUpgrade);
        string unitUpgradeId = UpgradeId(unitUpgrade);

        state.Gold = RuntimeUpgradeCost(kingdomUpgrade) + RuntimeUpgradeCost(unitUpgrade) + 200;
        Assert.True(Convert.ToBoolean(Upgrades.Purchase(state, kingdomUpgradeId, "kingdom")["ok"]));
        Assert.True(Convert.ToBoolean(Upgrades.Purchase(state, unitUpgradeId, "unit")["ok"]));

        Assert.True(Convert.ToBoolean(Quests.CompleteQuest(state, "word_smith")["ok"]));
        Assert.True(Convert.ToBoolean(Skills.UnlockSkill(state, "quick_fingers")["ok"]));

        state.Day = 7;
        state.MaxComboEver = 20;
        var earnedMilestones = Milestones.CheckNewMilestones(state);
        Assert.Contains("day_7", earnedMilestones);
        Assert.Contains("combo_20", earnedMilestones);

        state.HeroId = "scholar";
        state.HeroAbilityCooldown = 2.5f;
        state.HeroActiveEffects.Add(new Dictionary<string, object>
        {
            ["type"] = "focus",
            ["stacks"] = 2,
        });

        var loaded = Roundtrip(state);

        Assert.Contains("word_smith", loaded.CompletedQuests);
        Assert.Contains(kingdomUpgradeId, loaded.PurchasedKingdomUpgrades);
        Assert.Contains(unitUpgradeId, loaded.PurchasedUnitUpgrades);
        Assert.Contains("quick_fingers", loaded.UnlockedSkills);
        Assert.Contains("day_7", loaded.Milestones);
        Assert.Contains("combo_20", loaded.Milestones);

        Assert.Equal("scholar", loaded.HeroId);
        Assert.Equal(2.5f, loaded.HeroAbilityCooldown, 0.01f);
        Assert.Single(loaded.HeroActiveEffects);
        Assert.Equal(state.SkillPoints, loaded.SkillPoints);
    }

    private static GameState CreateState(string seed)
    {
        var state = DefaultState.Create(seed);
        state.CompletedQuests.Clear();
        state.Milestones.Clear();
        state.UnlockedSkills.Clear();
        state.PurchasedKingdomUpgrades.Clear();
        state.PurchasedUnitUpgrades.Clear();
        state.BossesDefeated.Clear();
        state.EnemiesDefeated = 0;
        state.MaxComboEver = 0;
        state.WavesSurvived = 0;
        state.SkillPoints = 0;
        state.TypingMetrics["battle_words_typed"] = 0;
        return state;
    }

    private static GameState Roundtrip(GameState state)
    {
        string json = SaveManager.StateToJson(state);
        Assert.False(string.IsNullOrWhiteSpace(json));

        var (ok, loaded, error) = SaveManager.StateFromJson(json);
        Assert.True(ok, error ?? "Progression save/load roundtrip failed.");
        Assert.NotNull(loaded);
        return loaded!;
    }

    private static Dictionary<string, object> GetAnyUpgrade(string category)
    {
        var upgrades = category == "kingdom" ? Upgrades.GetKingdomUpgrades() : Upgrades.GetUnitUpgrades();
        Assert.NotEmpty(upgrades);
        return upgrades[0];
    }

    private static string UpgradeId(Dictionary<string, object> upgrade)
        => upgrade.GetValueOrDefault("id")?.ToString() ?? string.Empty;

    private static int RuntimeUpgradeCost(Dictionary<string, object> upgrade)
        => Convert.ToInt32(upgrade.GetValueOrDefault("gold_cost", 0));

    private static int SimulateHeroLevel(string heroId, int encounterCount, int baseXpPerEncounter)
    {
        int level = 1;
        int xpPool = 0;
        int xpToNextLevel = 100;
        double xpMultiplier = HeroTypes.GetHeroBonus(heroId, "xp_mult", 1.0);

        for (int i = 0; i < encounterCount; i++)
        {
            int gainedXp = (int)Math.Round(baseXpPerEncounter * xpMultiplier, MidpointRounding.AwayFromZero);
            xpPool += gainedXp;

            while (xpPool >= xpToNextLevel)
            {
                xpPool -= xpToNextLevel;
                level++;
                xpToNextLevel = (int)Math.Round(xpToNextLevel * 1.25, MidpointRounding.AwayFromZero);
            }
        }

        return level;
    }
}
