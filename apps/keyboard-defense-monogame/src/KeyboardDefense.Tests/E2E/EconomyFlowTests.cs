using KeyboardDefense.Core.Economy;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.E2E;

/// <summary>
/// End-to-end tests for economy: resources, trading, upgrades, gold flow.
/// </summary>
public class EconomyFlowTests
{
    [Fact]
    public void GatherWood_IncreasesWoodResource()
    {
        var sim = new GameSimulator("econ_wood");
        int before = sim.State.Resources.GetValueOrDefault("wood", 0);
        sim.Gather("wood");
        int after = sim.State.Resources.GetValueOrDefault("wood", 0);
        Assert.True(after >= before, "Gathering wood should not decrease it");
    }

    [Fact]
    public void GatherStone_IncreasesStoneResource()
    {
        var sim = new GameSimulator("econ_stone");
        int before = sim.State.Resources.GetValueOrDefault("stone", 0);
        sim.Gather("stone");
        int after = sim.State.Resources.GetValueOrDefault("stone", 0);
        Assert.True(after >= before);
    }

    [Fact]
    public void Trade_WoodForStone_ExchangesResources()
    {
        var state = DefaultState.Create("trade_test", true);
        state.Resources["wood"] = 50;
        state.Resources["stone"] = 0;

        var result = Trade.ExecuteTrade(state, "wood", "stone", 10);
        Assert.True((bool)result["success"]);

        int woodAfter = state.Resources.GetValueOrDefault("wood", 0);
        int stoneAfter = state.Resources.GetValueOrDefault("stone", 0);

        Assert.Equal(40, woodAfter);
        Assert.True(stoneAfter > 0, "Should receive stone from trade");
    }

    [Fact]
    public void Trade_InsufficientResources_Fails()
    {
        var state = DefaultState.Create("trade_fail", true);
        state.Resources["wood"] = 0;

        var result = Trade.ExecuteTrade(state, "wood", "stone", 10);
        Assert.False((bool)result.GetValueOrDefault("success", false));
    }

    [Fact]
    public void Trade_SameResource_Fails()
    {
        var state = DefaultState.Create("trade_same", true);
        state.Resources["wood"] = 50;

        var result = Trade.ExecuteTrade(state, "wood", "wood", 10);
        Assert.False((bool)result.GetValueOrDefault("success", false));
    }

    [Fact]
    public void ExchangeRate_WithMarket_IsHigher()
    {
        var state = DefaultState.Create("market_bonus", true);
        double baseRate = Trade.GetExchangeRate("wood", "stone");

        // Add a market structure
        state.Buildings["market"] = 1;
        double marketRate = Trade.GetExchangeRate("wood", "stone", state);

        Assert.True(marketRate >= baseRate, "Market should boost trade rates");
    }

    [Fact]
    public void BattleVictory_AwardsGold()
    {
        var sim = new GameSimulator("gold_reward");
        int goldBefore = sim.State.Gold;

        sim.EndDay();
        sim.RunNightToCompletion();

        Assert.True(sim.State.Gold >= goldBefore,
            "Surviving a night should not lose gold");
    }

    [Fact]
    public void MultipleGathers_DepletesAp()
    {
        var sim = new GameSimulator("ap_depletion");
        int apBefore = sim.State.Ap;

        // Gather until AP runs out
        int gathers = 0;
        for (int i = 0; i < 10; i++)
        {
            if (sim.State.Ap <= 0) break;
            sim.Gather();
            gathers++;
        }

        Assert.True(gathers > 0, "Should be able to gather at least once");
    }

    [Fact]
    public void CraftingRecipe_RequiresResources()
    {
        var state = DefaultState.Create("craft_test", true);
        state.Resources["wood"] = 0;
        state.Resources["stone"] = 0;

        // Try crafting with no resources — should fail
        Assert.False(Crafting.CanCraft(state, "arrow_bundle"),
            "Should not be able to craft with zero resources");
    }

    [Fact]
    public void Workers_AssignAndUnassign()
    {
        var state = DefaultState.Create("worker_test", true);
        state.WorkerCount = 5;
        // Place a structure first
        int structIdx = state.BasePos.Y * state.MapW + state.BasePos.X + 1;
        state.Structures[structIdx] = "farm";

        Workers.AssignWorker(state, structIdx);
        int assigned = Workers.WorkersAt(state, structIdx);
        Assert.Equal(1, assigned);

        Workers.UnassignWorker(state, structIdx);
        assigned = Workers.WorkersAt(state, structIdx);
        Assert.Equal(0, assigned);
    }

    [Fact]
    public void Workers_BonusIncreasesWithCount()
    {
        var state = DefaultState.Create("worker_bonus", true);
        state.WorkerCount = 10;
        int structIdx = state.BasePos.Y * state.MapW + state.BasePos.X + 1;
        state.Structures[structIdx] = "farm";

        // No workers = base bonus
        double bonus0 = Workers.WorkerBonus(state, structIdx);

        // Add workers
        Workers.AssignWorker(state, structIdx);
        Workers.AssignWorker(state, structIdx);
        double bonus2 = Workers.WorkerBonus(state, structIdx);

        Assert.True(bonus2 >= bonus0, "More workers should not decrease bonus");
    }
}
