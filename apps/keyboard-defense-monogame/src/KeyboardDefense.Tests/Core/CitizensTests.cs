using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Economy;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class CitizensCoreTests
{
    private static readonly HashSet<string> ExpectedFirstNames = new(StringComparer.Ordinal)
    {
        "Ada", "Bard", "Cleo", "Dane", "Elsa", "Finn", "Gwen", "Hugo",
        "Iris", "Jade", "Knox", "Luna", "Milo", "Nora", "Owen", "Peta"
    };

    private static readonly HashSet<string> ExpectedLastNames = new(StringComparer.Ordinal)
    {
        "Stone", "Swift", "Forge", "Bloom", "Thorn", "Frost", "Spark", "Vale",
        "Ash", "Brook", "Clay", "Dale", "Elm", "Flint", "Glen", "Hart"
    };

    private static readonly HashSet<string> ExpectedProfessions = new(StringComparer.Ordinal)
    {
        "farmer", "woodcutter", "miner", "builder", "scholar", "merchant", "guard", "artisan"
    };

    [Fact]
    public void CreateCitizen_ReturnsDictionaryWithAllExpectedKeys()
    {
        var state = CreateState();

        var citizen = Citizens.CreateCitizen(state);

        var expectedKeys = new[]
        {
            "name",
            "profession",
            "morale",
            "skill_level",
            "skill_xp",
            "assigned_to",
        };

        Assert.Equal(expectedKeys.Length, citizen.Count);
        foreach (string key in expectedKeys)
        {
            Assert.True(citizen.ContainsKey(key), $"Missing expected key '{key}'.");
        }
    }

    [Fact]
    public void CreateCitizen_Name_IsNonEmptyFirstNameLastNameFormat()
    {
        var state = CreateState();

        var citizen = Citizens.CreateCitizen(state);

        var name = Assert.IsType<string>(citizen["name"]);
        Assert.False(string.IsNullOrWhiteSpace(name));
        var parts = name.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        Assert.Equal(2, parts.Length);
        Assert.False(string.IsNullOrWhiteSpace(parts[0]));
        Assert.False(string.IsNullOrWhiteSpace(parts[1]));
    }

    [Fact]
    public void CreateCitizen_Name_UsesKnownNamePools()
    {
        var state = CreateState();

        var citizen = Citizens.CreateCitizen(state);

        var name = Assert.IsType<string>(citizen["name"]);
        var parts = name.Split(' ', StringSplitOptions.RemoveEmptyEntries);

        Assert.Equal(2, parts.Length);
        Assert.Contains(parts[0], ExpectedFirstNames);
        Assert.Contains(parts[1], ExpectedLastNames);
    }

    [Fact]
    public void CreateCitizen_Profession_IsOneOfKnownProfessions()
    {
        var state = CreateState();

        var citizen = Citizens.CreateCitizen(state);

        var profession = Assert.IsType<string>(citizen["profession"]);
        Assert.Contains(profession, ExpectedProfessions);
    }

    [Fact]
    public void CreateCitizen_DefaultMorale_Is75()
    {
        var state = CreateState();

        var citizen = Citizens.CreateCitizen(state);

        Assert.Equal(75, Convert.ToInt32(citizen["morale"]));
    }

    [Fact]
    public void CreateCitizen_DefaultSkillLevel_Is1()
    {
        var state = CreateState();

        var citizen = Citizens.CreateCitizen(state);

        Assert.Equal(1, Convert.ToInt32(citizen["skill_level"]));
    }

    [Fact]
    public void CreateCitizen_DefaultSkillXp_Is0()
    {
        var state = CreateState();

        var citizen = Citizens.CreateCitizen(state);

        Assert.Equal(0, Convert.ToInt32(citizen["skill_xp"]));
    }

    [Fact]
    public void CreateCitizen_DefaultAssignedTo_IsMinusOne()
    {
        var state = CreateState();

        var citizen = Citizens.CreateCitizen(state);

        Assert.Equal(-1, Convert.ToInt32(citizen["assigned_to"]));
    }

    [Fact]
    public void GetProductionBonus_Morale75_Returns1Point1()
    {
        var citizen = CreateCitizenDict(morale: 75, skillLevel: 1);

        var result = Citizens.GetProductionBonus(citizen);

        Assert.Equal(1.1, result, 3);
    }

    [Fact]
    public void GetProductionBonus_Morale50_Returns1Point0()
    {
        var citizen = CreateCitizenDict(morale: 50, skillLevel: 1);

        var result = Citizens.GetProductionBonus(citizen);

        Assert.Equal(1.0, result, 3);
    }

    [Fact]
    public void GetProductionBonus_Morale24_Returns0Point9()
    {
        var citizen = CreateCitizenDict(morale: 24, skillLevel: 1);

        var result = Citizens.GetProductionBonus(citizen);

        Assert.Equal(0.9, result, 3);
    }

    [Fact]
    public void GetProductionBonus_SkillLevel1_HasNoSkillBonus()
    {
        var citizen = CreateCitizenDict(morale: 50, skillLevel: 1);

        var result = Citizens.GetProductionBonus(citizen);

        Assert.Equal(1.0, result, 3);
    }

    [Fact]
    public void GetProductionBonus_SkillLevel3_Adds0Point1()
    {
        var citizen = CreateCitizenDict(morale: 50, skillLevel: 3);

        var result = Citizens.GetProductionBonus(citizen);

        Assert.Equal(1.1, result, 3);
    }

    [Fact]
    public void GetProductionBonus_HighMoraleAndHighSkill_StacksBonuses()
    {
        var citizen = CreateCitizenDict(morale: 80, skillLevel: 3);

        var result = Citizens.GetProductionBonus(citizen);

        Assert.Equal(1.2, result, 3);
    }

    [Fact]
    public void TickDaily_GainsOneXpWhenNotLeveling()
    {
        var citizen = CreateCitizenDict(morale: 50, skillLevel: 1, skillXp: 0);

        Citizens.TickDaily(citizen);

        Assert.Equal(1, Convert.ToInt32(citizen["skill_xp"]));
        Assert.Equal(1, Convert.ToInt32(citizen["skill_level"]));
    }

    [Fact]
    public void TickDaily_LevelsUpAtLevelOneThreshold()
    {
        var citizen = CreateCitizenDict(morale: 50, skillLevel: 1, skillXp: 4);

        Citizens.TickDaily(citizen);

        Assert.Equal(2, Convert.ToInt32(citizen["skill_level"]));
    }

    [Fact]
    public void TickDaily_ResetsXpOnLevelUp()
    {
        var citizen = CreateCitizenDict(morale: 50, skillLevel: 1, skillXp: 4);

        Citizens.TickDaily(citizen);

        Assert.Equal(0, Convert.ToInt32(citizen["skill_xp"]));
    }

    [Fact]
    public void TickDaily_CapsSkillLevelAtFive()
    {
        var citizen = CreateCitizenDict(morale: 50, skillLevel: 5, skillXp: 24);

        Citizens.TickDaily(citizen);
        Citizens.TickDaily(citizen);

        Assert.Equal(5, Convert.ToInt32(citizen["skill_level"]));
    }

    [Fact]
    public void GetCitizens_ReturnsSameListReferenceFromState()
    {
        var state = CreateState();
        state.Citizens.Add(CreateCitizenDict());

        var citizens = Citizens.GetCitizens(state);

        Assert.Same(state.Citizens, citizens);
    }

    [Fact]
    public void GetCitizenCount_ReturnsCurrentStateCitizenCount()
    {
        var state = CreateState();
        state.Citizens.Add(CreateCitizenDict());
        state.Citizens.Add(CreateCitizenDict());
        state.Citizens.Add(CreateCitizenDict());

        var count = Citizens.GetCitizenCount(state);

        Assert.Equal(3, count);
    }

    private static GameState CreateState()
    {
        return DefaultState.Create(Guid.NewGuid().ToString("N"));
    }

    private static Dictionary<string, object> CreateCitizenDict(int morale = 50, int skillLevel = 1, int skillXp = 0)
    {
        return new Dictionary<string, object>
        {
            ["name"] = "Test Citizen",
            ["profession"] = "farmer",
            ["morale"] = morale,
            ["skill_level"] = skillLevel,
            ["skill_xp"] = skillXp,
            ["assigned_to"] = -1,
        };
    }
}
