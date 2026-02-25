using System.Collections.Generic;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class SynergyDetectorTests
{
    [Fact]
    public void DetectActiveSynergies_AdjacentCannonAndFrost_ActivatesKillBox()
    {
        var state = CreateState(
            (new GridPoint(5, 5), TowerTypes.Cannon),
            (new GridPoint(6, 5), TowerTypes.Frost));

        var active = SynergyDetector.DetectActiveSynergies(state);

        Assert.Contains("kill_box", active);
    }

    [Fact]
    public void DetectActiveSynergies_CannonAndFrostFarApart_DoesNotActivateKillBox()
    {
        var state = CreateState(
            (new GridPoint(1, 1), TowerTypes.Cannon),
            (new GridPoint(20, 20), TowerTypes.Frost));

        var active = SynergyDetector.DetectActiveSynergies(state);

        Assert.DoesNotContain("kill_box", active);
    }

    [Fact]
    public void DetectActiveSynergies_ThreeAdjacentArrows_ActivatesArrowRain()
    {
        var state = CreateState(
            (new GridPoint(10, 10), TowerTypes.Arrow),
            (new GridPoint(11, 10), TowerTypes.Arrow),
            (new GridPoint(12, 10), TowerTypes.Arrow));

        var active = SynergyDetector.DetectActiveSynergies(state);

        Assert.Contains("arrow_rain", active);
    }

    [Fact]
    public void DetectActiveSynergies_ThreeArrowsFarApart_DoesNotActivateArrowRain()
    {
        var state = CreateState(
            (new GridPoint(1, 1), TowerTypes.Arrow),
            (new GridPoint(12, 12), TowerTypes.Arrow),
            (new GridPoint(25, 25), TowerTypes.Arrow));

        var active = SynergyDetector.DetectActiveSynergies(state);

        Assert.DoesNotContain("arrow_rain", active);
    }

    [Fact]
    public void DetectActiveSynergies_AdjacentGroups_ActivatesStackedSynergies()
    {
        var state = CreateState(
            (new GridPoint(5, 5), TowerTypes.Cannon),
            (new GridPoint(6, 5), TowerTypes.Frost),
            (new GridPoint(10, 10), TowerTypes.Arrow),
            (new GridPoint(11, 10), TowerTypes.Arrow),
            (new GridPoint(12, 10), TowerTypes.Arrow));

        var active = SynergyDetector.DetectActiveSynergies(state);

        Assert.Contains("kill_box", active);
        Assert.Contains("arrow_rain", active);
    }

    [Fact]
    public void GetSynergyDamageMultiplier_TwoPairBonuses_MultipliesBoth()
    {
        var activeSynergies = new List<string> { "kill_box", "fire_ice" };

        double mult = SynergyDetector.GetSynergyDamageMultiplier(activeSynergies);

        Assert.Equal(1.68, mult, 5);
    }

    [Fact]
    public void GetSynergyDamageMultiplier_StackedPairAndGroupBonus_MultipliesAll()
    {
        var activeSynergies = new List<string> { "kill_box", "fire_ice", "arrow_rain" };

        double mult = SynergyDetector.GetSynergyDamageMultiplier(activeSynergies);

        Assert.Equal(2.184, mult, 5);
    }

    private static GameState CreateState(params (GridPoint Pos, string Type)[] towers)
    {
        var state = new GameState();
        state.Structures.Clear();

        foreach (var (pos, towerType) in towers)
            state.Structures[pos.ToIndex(state.MapW)] = towerType;

        return state;
    }
}
