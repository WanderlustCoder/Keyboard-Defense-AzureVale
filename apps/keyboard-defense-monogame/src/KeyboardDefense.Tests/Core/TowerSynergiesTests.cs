using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class TowerSynergiesCoreTests
{
    [Fact]
    public void Synergies_HasSevenEntries()
    {
        Assert.Equal(7, TowerSynergies.Synergies.Count);
    }

    [Fact]
    public void FireWind_Definition_IsExpected()
    {
        var def = GetSynergy("fire_wind");

        Assert.Equal("pair", def.Pattern);
        Assert.Equal(new[] { "fire", "wind" }, def.RequiredTypes);
        Assert.Equal(1.3, def.Bonuses["damage_mult"], 5);
        Assert.Equal(1.5, def.Bonuses["burn_duration"], 5);
    }

    [Fact]
    public void IceLightning_Definition_IsExpected()
    {
        var def = GetSynergy("ice_lightning");

        Assert.Equal("pair", def.Pattern);
        Assert.Equal(new[] { "ice", "lightning" }, def.RequiredTypes);
        Assert.Equal(1.25, def.Bonuses["damage_mult"], 5);
        Assert.Equal(0.15, def.Bonuses["stun_chance"], 5);
    }

    [Fact]
    public void HolyNature_Definition_IsExpected()
    {
        var def = GetSynergy("holy_nature");

        Assert.Equal("pair", def.Pattern);
        Assert.Equal(new[] { "holy", "nature" }, def.RequiredTypes);
        Assert.Equal(1.2, def.Bonuses["heal_bonus"], 5);
        Assert.Equal(1.15, def.Bonuses["damage_mult"], 5);
    }

    [Fact]
    public void ArcaneCluster_Definition_IsExpected()
    {
        var def = GetSynergy("arcane_cluster");

        Assert.Equal("cluster", def.Pattern);
        Assert.Equal(new[] { "arcane", "arcane", "arcane" }, def.RequiredTypes);
        Assert.Equal(1.5, def.Bonuses["damage_mult"], 5);
        Assert.Equal(1.2, def.Bonuses["range_bonus"], 5);
    }

    [Fact]
    public void SiegeSupport_Definition_IsExpected()
    {
        var def = GetSynergy("siege_support");

        Assert.Equal("supported", def.Pattern);
        Assert.Equal(new[] { "siege", "support" }, def.RequiredTypes);
        Assert.Equal(1.4, def.Bonuses["damage_mult"], 5);
        Assert.Equal(1.2, def.Bonuses["attack_speed"], 5);
    }

    [Fact]
    public void PoisonFire_Definition_IsExpected()
    {
        var def = GetSynergy("poison_fire");

        Assert.Equal("pair", def.Pattern);
        Assert.Equal(new[] { "poison", "fire" }, def.RequiredTypes);
        Assert.Equal(2.0, def.Bonuses["dot_mult"], 5);
    }

    [Fact]
    public void Legion_Definition_IsExpected()
    {
        var def = GetSynergy("legion");

        Assert.Equal("pair", def.Pattern);
        Assert.Equal(new[] { "summoner", "summoner" }, def.RequiredTypes);
        Assert.Equal(1.0, def.Bonuses["summon_bonus"], 5);
        Assert.Equal(1.2, def.Bonuses["damage_mult"], 5);
    }

    [Fact]
    public void GetDamageMultiplier_NoSynergies_ReturnsOne()
    {
        var mult = TowerSynergies.GetDamageMultiplier(new List<ActiveSynergy>(), new GridPoint(5, 5));

        Assert.Equal(1.0, mult, 5);
    }

    [Fact]
    public void GetDamageMultiplier_WithMatchingSynergy_ReturnsMultiplier()
    {
        var pos = new GridPoint(2, 2);
        var synergies = new List<ActiveSynergy>
        {
            new()
            {
                SynergyId = "fire_wind",
                Bonuses = new Dictionary<string, double> { ["damage_mult"] = 1.3 },
                AffectedPositions = new HashSet<GridPoint> { pos }
            }
        };

        var mult = TowerSynergies.GetDamageMultiplier(synergies, pos);

        Assert.Equal(1.3, mult, 5);
    }

    [Fact]
    public void GetDamageMultiplier_WithMatchingSynergyWithoutDamageMult_ReturnsOne()
    {
        var pos = new GridPoint(2, 2);
        var synergies = new List<ActiveSynergy>
        {
            new()
            {
                SynergyId = "poison_fire",
                Bonuses = new Dictionary<string, double> { ["dot_mult"] = 2.0 },
                AffectedPositions = new HashSet<GridPoint> { pos }
            }
        };

        var mult = TowerSynergies.GetDamageMultiplier(synergies, pos);

        Assert.Equal(1.0, mult, 5);
    }

    [Fact]
    public void GetDamageMultiplier_IgnoresSynergiesThatDoNotAffectPosition()
    {
        var targetPos = new GridPoint(3, 3);
        var synergies = new List<ActiveSynergy>
        {
            new()
            {
                SynergyId = "fire_wind",
                Bonuses = new Dictionary<string, double> { ["damage_mult"] = 5.0 },
                AffectedPositions = new HashSet<GridPoint> { new GridPoint(1, 1) }
            }
        };

        var mult = TowerSynergies.GetDamageMultiplier(synergies, targetPos);

        Assert.Equal(1.0, mult, 5);
    }

    [Fact]
    public void GetDamageMultiplier_MultipleMatchingSynergies_MultipliesBonuses()
    {
        var pos = new GridPoint(4, 4);
        var synergies = new List<ActiveSynergy>
        {
            new()
            {
                SynergyId = "s1",
                Bonuses = new Dictionary<string, double> { ["damage_mult"] = 1.25 },
                AffectedPositions = new HashSet<GridPoint> { pos }
            },
            new()
            {
                SynergyId = "s2",
                Bonuses = new Dictionary<string, double> { ["damage_mult"] = 1.4 },
                AffectedPositions = new HashSet<GridPoint> { pos }
            },
            new()
            {
                SynergyId = "s3",
                Bonuses = new Dictionary<string, double> { ["damage_mult"] = 2.0 },
                AffectedPositions = new HashSet<GridPoint> { new GridPoint(0, 0) }
            }
        };

        var mult = TowerSynergies.GetDamageMultiplier(synergies, pos);

        Assert.Equal(1.75, mult, 5);
    }

    [Fact]
    public void DetectSynergies_WithNoStructures_ReturnsEmpty()
    {
        var state = CreateState();

        var synergies = TowerSynergies.DetectSynergies(state);

        Assert.Empty(synergies);
    }

    [Fact]
    public void DetectSynergies_PairAdjacentMatchingTypes_FindsFireWind()
    {
        var state = CreateState();
        var firePos = new GridPoint(10, 10);
        var windPos = new GridPoint(11, 10);

        PlaceTower(state, firePos, "fire");
        PlaceTower(state, windPos, "wind");

        var synergies = TowerSynergies.DetectSynergies(state);
        var fireWind = Assert.Single(synergies, s => s.SynergyId == "fire_wind");

        Assert.Equal("Inferno Gale", fireWind.Name);
        Assert.Contains(firePos, fireWind.AffectedPositions);
        Assert.Contains(windPos, fireWind.AffectedPositions);
    }

    [Fact]
    public void DetectSynergies_PairNonAdjacentMatchingTypes_DoesNotFindFireWind()
    {
        var state = CreateState();
        PlaceTower(state, new GridPoint(10, 10), "fire");
        PlaceTower(state, new GridPoint(12, 10), "wind");

        var synergies = TowerSynergies.DetectSynergies(state);

        Assert.DoesNotContain(synergies, s => s.SynergyId == "fire_wind");
    }

    [Fact]
    public void DetectSynergies_ArcaneCluster_WithDefaultTowerMappings_DoesNotActivate()
    {
        var state = CreateState();
        PlaceTower(state, new GridPoint(20, 20), TowerTypes.Arcane);
        PlaceTower(state, new GridPoint(21, 20), TowerTypes.Arcane);
        PlaceTower(state, new GridPoint(20, 21), TowerTypes.Arcane);

        var synergies = TowerSynergies.DetectSynergies(state);

        Assert.DoesNotContain(synergies, s => s.SynergyId == "arcane_cluster");
    }

    [Fact]
    public void DetectSynergies_ArcaneCluster_WhenRequirementsMatchCategories_FindsCluster()
    {
        var original = TowerSynergies.Synergies["arcane_cluster"];

        try
        {
            TowerSynergies.Synergies["arcane_cluster"] =
                original with { RequiredTypes = new[] { "advanced", "advanced", "advanced" } };

            var state = CreateState();
            var a = new GridPoint(20, 20);
            var b = new GridPoint(21, 20);
            var c = new GridPoint(20, 21);
            PlaceTower(state, a, TowerTypes.Arcane);
            PlaceTower(state, b, TowerTypes.Arcane);
            PlaceTower(state, c, TowerTypes.Arcane);

            var synergies = TowerSynergies.DetectSynergies(state);
            var cluster = Assert.Single(synergies, s => s.SynergyId == "arcane_cluster");

            Assert.Equal(3, cluster.AffectedPositions.Count);
            Assert.Contains(a, cluster.AffectedPositions);
            Assert.Contains(b, cluster.AffectedPositions);
            Assert.Contains(c, cluster.AffectedPositions);
        }
        finally
        {
            TowerSynergies.Synergies["arcane_cluster"] = original;
        }
    }

    [Fact]
    public void DetectSynergies_Supported_WhenRequirementsMatchCategories_FindsSiegeSupport()
    {
        var original = TowerSynergies.Synergies["siege_support"];

        try
        {
            TowerSynergies.Synergies["siege_support"] =
                original with { RequiredTypes = new[] { "advanced", "specialist" } };

            var state = CreateState();
            var siegePos = new GridPoint(30, 30);
            var supportPos = new GridPoint(31, 30);
            PlaceTower(state, siegePos, TowerTypes.Siege);
            PlaceTower(state, supportPos, TowerTypes.Support);

            var synergies = TowerSynergies.DetectSynergies(state);
            var supported = Assert.Single(synergies, s => s.SynergyId == "siege_support");

            Assert.Contains(siegePos, supported.AffectedPositions);
            Assert.Contains(supportPos, supported.AffectedPositions);
            Assert.Equal(1.4, supported.Bonuses["damage_mult"], 5);
        }
        finally
        {
            TowerSynergies.Synergies["siege_support"] = original;
        }
    }

    private static SynergyDef GetSynergy(string id)
    {
        Assert.True(TowerSynergies.Synergies.TryGetValue(id, out var def));
        return def!;
    }

    private static GameState CreateState() => new();

    private static void PlaceTower(GameState state, GridPoint pos, string towerType)
    {
        state.Structures[pos.ToIndex(state.MapW)] = towerType;
    }
}
