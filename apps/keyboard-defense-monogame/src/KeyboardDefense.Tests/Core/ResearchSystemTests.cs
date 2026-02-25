using System.Linq;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class ResearchSystemTests
{
    [Fact]
    public void StartResearch_RequiresCompletedPrerequisite()
    {
        var state = CreateState(gold: 500);

        bool started = ResearchData.StartResearch(state, "advanced_towers");

        Assert.False(started);
        Assert.Equal(500, state.Gold);
        Assert.Equal(string.Empty, state.ActiveResearch);
        Assert.Equal(0, state.ResearchProgress);
    }

    [Fact]
    public void StartResearch_WithCompletedPrerequisite_Succeeds()
    {
        var state = CreateState(gold: 500);
        state.CompletedResearch.Add("arrow_mastery");

        bool started = ResearchData.StartResearch(state, "advanced_towers");

        Assert.True(started);
        Assert.Equal("advanced_towers", state.ActiveResearch);
        Assert.Equal(500 - 120, state.Gold);
        Assert.Equal(0, state.ResearchProgress);
    }

    [Fact]
    public void StartResearch_DeductsExactConfiguredCost()
    {
        var state = CreateState(gold: 1000);
        var def = Assert.IsType<ResearchDef>(ResearchData.GetResearch("improved_walls"));

        bool started = ResearchData.StartResearch(state, "improved_walls");

        Assert.True(started);
        Assert.Equal(1000 - def.GoldCost, state.Gold);
    }

    [Fact]
    public void ResearchCosts_ScaleUpAcrossCombatChain()
    {
        int arrowMasteryCost = Assert.IsType<ResearchDef>(ResearchData.GetResearch("arrow_mastery")).GoldCost;
        int advancedTowersCost = Assert.IsType<ResearchDef>(ResearchData.GetResearch("advanced_towers")).GoldCost;
        int legendaryWeaponsCost = Assert.IsType<ResearchDef>(ResearchData.GetResearch("legendary_weapons")).GoldCost;

        Assert.True(arrowMasteryCost < advancedTowersCost);
        Assert.True(advancedTowersCost < legendaryWeaponsCost);
    }

    [Fact]
    public void CompleteResearch_UnlocksAdvancedBuildingEffect()
    {
        var state = CreateState(gold: 1000);
        CompleteResearch(state, "arrow_mastery");

        var beforeAdvanced = ResearchData.GetTotalEffects(state);
        Assert.False(beforeAdvanced.ContainsKey("unlock_advanced"));

        Assert.True(ResearchData.StartResearch(state, "advanced_towers"));
        var advancedDef = Assert.IsType<ResearchDef>(ResearchData.GetResearch("advanced_towers"));

        for (int i = 0; i < advancedDef.WavesRequired - 1; i++)
        {
            bool completedEarly = ResearchData.AdvanceResearch(state);
            Assert.False(completedEarly);
            Assert.False(ResearchData.GetTotalEffects(state).ContainsKey("unlock_advanced"));
        }

        bool completed = ResearchData.AdvanceResearch(state);
        Assert.True(completed);

        var effects = ResearchData.GetTotalEffects(state);
        Assert.True(effects.ContainsKey("unlock_advanced"));
        Assert.Equal(1.0, effects["unlock_advanced"], 3);
    }

    [Fact]
    public void GetAvailableResearch_TraversesFromRootToLeaf()
    {
        var state = CreateState(gold: 2000);

        var initial = ResearchData.GetAvailableResearch(state);
        Assert.Contains("arrow_mastery", initial);
        Assert.DoesNotContain("advanced_towers", initial);
        Assert.DoesNotContain("legendary_weapons", initial);

        CompleteResearch(state, "arrow_mastery");
        var afterArrowMastery = ResearchData.GetAvailableResearch(state);
        Assert.Contains("advanced_towers", afterArrowMastery);
        Assert.DoesNotContain("legendary_weapons", afterArrowMastery);

        CompleteResearch(state, "advanced_towers");
        var afterAdvancedTowers = ResearchData.GetAvailableResearch(state);
        Assert.Contains("legendary_weapons", afterAdvancedTowers);
    }

    [Fact]
    public void StartResearch_WhenAnotherResearchIsActive_Fails()
    {
        var state = CreateState(gold: 500);
        Assert.True(ResearchData.StartResearch(state, "improved_walls"));
        int goldAfterFirstStart = state.Gold;

        bool startedSecond = ResearchData.StartResearch(state, "typing_mastery");

        Assert.False(startedSecond);
        Assert.Equal("improved_walls", state.ActiveResearch);
        Assert.Equal(goldAfterFirstStart, state.Gold);
        Assert.Equal(0, state.ResearchProgress);
    }

    [Fact]
    public void StartResearch_CannotResearchSameTechTwice()
    {
        var state = CreateState(gold: 500);
        CompleteResearch(state, "improved_walls");
        int goldAfterFirstCompletion = state.Gold;

        bool startedAgain = ResearchData.StartResearch(state, "improved_walls");

        Assert.False(startedAgain);
        Assert.Equal(goldAfterFirstCompletion, state.Gold);
        Assert.Equal(1, state.CompletedResearch.Count(id => id == "improved_walls"));
    }

    [Fact]
    public void ActiveResearchProgress_PersistsThroughSaveRoundTrip()
    {
        var state = CreateState(gold: 500);
        Assert.True(ResearchData.StartResearch(state, "improved_walls"));
        Assert.False(ResearchData.AdvanceResearch(state));
        state.CompletedResearch.Add("resource_efficiency");

        string json = SaveManager.StateToJson(state);
        var (ok, loaded, error) = SaveManager.StateFromJson(json);

        Assert.True(ok, error ?? "Expected save/load round-trip to succeed.");
        var loadedState = Assert.IsType<GameState>(loaded);
        Assert.Equal("improved_walls", loadedState.ActiveResearch);
        Assert.Equal(1, loadedState.ResearchProgress);
        Assert.Contains("resource_efficiency", loadedState.CompletedResearch);
    }

    private static GameState CreateState(int gold)
    {
        var state = DefaultState.Create(useWorldSpec: false);
        state.Gold = gold;
        state.ActiveResearch = string.Empty;
        state.ResearchProgress = 0;
        state.CompletedResearch.Clear();
        return state;
    }

    private static void CompleteResearch(GameState state, string researchId)
    {
        bool started = ResearchData.StartResearch(state, researchId);
        Assert.True(started);

        var def = Assert.IsType<ResearchDef>(ResearchData.GetResearch(researchId));
        for (int i = 0; i < def.WavesRequired - 1; i++)
        {
            bool completedEarly = ResearchData.AdvanceResearch(state);
            Assert.False(completedEarly);
        }

        bool completed = ResearchData.AdvanceResearch(state);
        Assert.True(completed);
        Assert.Contains(researchId, state.CompletedResearch);
        Assert.Equal(string.Empty, state.ActiveResearch);
        Assert.Equal(0, state.ResearchProgress);
    }
}
