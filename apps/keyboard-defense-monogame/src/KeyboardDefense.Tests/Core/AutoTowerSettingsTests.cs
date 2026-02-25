using System.Text.Json;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class AutoTowerSettingsTests
{
    [Fact]
    public void Constructor_DefaultValues_AreExpected()
    {
        var settings = new AutoTowerSettings();

        Assert.False(settings.AutoBuild);
        Assert.Equal("balanced", settings.BuildPriority);
        Assert.False(settings.AutoUpgrade);
        Assert.True(settings.AutoRepair);
        Assert.Equal(0, settings.ResourceReservePercent);
    }

    [Fact]
    public void Setters_ApplyProvidedValues()
    {
        var settings = new AutoTowerSettings
        {
            AutoBuild = true,
            BuildPriority = "defense",
            AutoUpgrade = true,
            AutoRepair = false,
            ResourceReservePercent = 50,
        };

        Assert.True(settings.AutoBuild);
        Assert.Equal("defense", settings.BuildPriority);
        Assert.True(settings.AutoUpgrade);
        Assert.False(settings.AutoRepair);
        Assert.Equal(50, settings.ResourceReservePercent);
    }

    [Fact]
    public void BuildPriorityOptions_HasExpectedEntries()
    {
        Assert.Equal(new[] { "offense", "defense", "balanced" }, AutoTowerSettings.BuildPriorityOptions);
    }

    [Fact]
    public void ReservePercentOptions_HasExpectedBoundaryValues()
    {
        Assert.Equal(new[] { 0, 25, 50, 75 }, AutoTowerSettings.ReservePercentOptions);
        Assert.Equal(0, AutoTowerSettings.ReservePercentOptions[0]);
        Assert.Equal(75, AutoTowerSettings.ReservePercentOptions[^1]);
    }

    [Fact]
    public void SerializationRoundTrip_PreservesValues()
    {
        var original = new AutoTowerSettings
        {
            AutoBuild = true,
            BuildPriority = "offense",
            AutoUpgrade = true,
            AutoRepair = false,
            ResourceReservePercent = 75,
        };

        var json = JsonSerializer.Serialize(original);
        var roundTripped = JsonSerializer.Deserialize<AutoTowerSettings>(json);

        Assert.NotNull(roundTripped);
        Assert.Equal(original.AutoBuild, roundTripped!.AutoBuild);
        Assert.Equal(original.BuildPriority, roundTripped.BuildPriority);
        Assert.Equal(original.AutoUpgrade, roundTripped.AutoUpgrade);
        Assert.Equal(original.AutoRepair, roundTripped.AutoRepair);
        Assert.Equal(original.ResourceReservePercent, roundTripped.ResourceReservePercent);
    }

    [Fact]
    public void ResourceReservePercent_AcceptsIntegerBoundaryValues()
    {
        var settings = new AutoTowerSettings
        {
            ResourceReservePercent = int.MinValue,
        };

        Assert.Equal(int.MinValue, settings.ResourceReservePercent);

        settings.ResourceReservePercent = int.MaxValue;

        Assert.Equal(int.MaxValue, settings.ResourceReservePercent);
    }
}
