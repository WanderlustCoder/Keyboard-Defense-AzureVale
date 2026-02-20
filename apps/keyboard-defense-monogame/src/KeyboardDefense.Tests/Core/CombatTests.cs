using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class TowerTypesTests
{
    [Fact]
    public void TowerStats_ContainsKnownTypes()
    {
        Assert.True(TowerTypes.IsValidTowerType("arrow"));
        Assert.True(TowerTypes.IsValidTowerType("magic"));
        Assert.True(TowerTypes.IsValidTowerType("frost"));
        Assert.True(TowerTypes.IsValidTowerType("cannon"));
    }

    [Fact]
    public void GetTowerData_ReturnsValidDef()
    {
        var arrow = TowerTypes.GetTowerData("arrow");
        Assert.NotNull(arrow);
        Assert.Equal("Arrow Tower", arrow!.Name);
        Assert.True(arrow.Damage > 0);
        Assert.True(arrow.Range > 0);
        Assert.True(arrow.Cooldown > 0);
    }

    [Fact]
    public void GetTowerData_InvalidType_ReturnsNull()
    {
        Assert.Null(TowerTypes.GetTowerData("nonexistent"));
    }

    [Fact]
    public void GetTowerName_ValidType()
    {
        Assert.Equal("Arrow Tower", TowerTypes.GetTowerName("arrow"));
    }

    [Fact]
    public void IsLegendary_PurifierIsLegendary()
    {
        Assert.True(TowerTypes.IsLegendary("purifier"));
        Assert.False(TowerTypes.IsLegendary("arrow"));
    }
}

public class EnemyTypesTests
{
    [Fact]
    public void Registry_HasEntries()
    {
        Assert.NotEmpty(EnemyTypes.Registry);
    }

    [Fact]
    public void Get_KnownEnemy_ReturnsData()
    {
        var raider = EnemyTypes.Get("raider");
        Assert.NotNull(raider);
        Assert.Equal("Raider", raider!.Name);
        Assert.Equal(EnemyTypes.Tier.Minion, raider.Tier);
        Assert.True(raider.Hp > 0);
    }

    [Fact]
    public void Get_UnknownEnemy_ReturnsNull()
    {
        Assert.Null(EnemyTypes.Get("nonexistent"));
    }

    [Fact]
    public void GetByTier_ReturnsMatchingEntries()
    {
        var minions = EnemyTypes.GetByTier(EnemyTypes.Tier.Minion);
        Assert.NotEmpty(minions);
        foreach (var kind in minions)
        {
            var def = EnemyTypes.Get(kind);
            Assert.Equal(EnemyTypes.Tier.Minion, def!.Tier);
        }
    }
}

public class StatusEffectsTests
{
    [Fact]
    public void Effects_ContainsBasicEffects()
    {
        Assert.NotNull(StatusEffects.GetEffect("slow"));
        Assert.NotNull(StatusEffects.GetEffect("burning"));
        Assert.NotNull(StatusEffects.GetEffect("poisoned"));
    }

    [Fact]
    public void GetEffectName_ReturnsDisplayName()
    {
        Assert.Equal("Slowed", StatusEffects.GetEffectName("slow"));
        Assert.Equal("Burning", StatusEffects.GetEffectName("burning"));
    }

    [Fact]
    public void GetEffect_HasValidDuration()
    {
        var slow = StatusEffects.GetEffect("slow");
        Assert.NotNull(slow);
        Assert.True(slow!.Duration > 0);
    }
}

public class BestiaryTests
{
    [Fact]
    public void RecordEncounter_AddsEntry()
    {
        var data = new Dictionary<string, object>();
        Bestiary.RecordEncounter(data, "raider");
        Assert.True(data.ContainsKey("raider"));
    }

    [Fact]
    public void RecordDefeat_IncrementsCount()
    {
        var data = new Dictionary<string, object>();
        Bestiary.RecordEncounter(data, "raider");
        Bestiary.RecordDefeat(data, "raider");

        var entry = data["raider"] as Dictionary<string, object>;
        Assert.NotNull(entry);
        Assert.Equal(1, entry!["defeats"]);
    }

    [Fact]
    public void GetSummary_ReturnsStats()
    {
        var data = new Dictionary<string, object>();
        Bestiary.RecordEncounter(data, "raider");
        var summary = Bestiary.GetSummary(data);
        Assert.True(summary.ContainsKey("total_types"));
        Assert.True(summary.ContainsKey("encountered"));
    }

    [Fact]
    public void GetEnemyInfo_KnownEnemy_ReturnsInfo()
    {
        var info = Bestiary.GetEnemyInfo("raider");
        Assert.NotNull(info);
        Assert.Equal("Raider", info!["name"]);
    }
}
