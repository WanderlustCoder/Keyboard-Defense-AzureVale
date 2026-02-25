using System;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class SkillsExtendedTests
{
    [Fact]
    public void CanUnlock_WordMasteryRequiresEntirePrerequisiteChain()
    {
        var state = CreateState(skillPoints: 10);

        Assert.False(Skills.CanUnlock(state, "word_mastery"));

        var quickUnlock = Skills.UnlockSkill(state, "quick_fingers");
        Assert.True((bool)quickUnlock["ok"]);
        Assert.False(Skills.CanUnlock(state, "word_mastery"));

        var criticalUnlock = Skills.UnlockSkill(state, "critical_strike");
        Assert.True((bool)criticalUnlock["ok"]);
        Assert.True(Skills.CanUnlock(state, "word_mastery"));
    }

    [Fact]
    public void CanUnlock_UnrelatedBranchUnlockDoesNotSatisfyPrerequisite()
    {
        var state = CreateState(skillPoints: 5);

        var unlockDefense = Skills.UnlockSkill(state, "iron_walls");

        Assert.True((bool)unlockDefense["ok"]);
        Assert.False(Skills.CanUnlock(state, "critical_strike"));
    }

    [Fact]
    public void UnlockSkill_SameSkillCannotBeUnlockedTwice_MaxLevelIsOne()
    {
        var state = CreateState(skillPoints: 5);

        var first = Skills.UnlockSkill(state, "quick_fingers");
        var second = Skills.UnlockSkill(state, "quick_fingers");

        Assert.True((bool)first["ok"]);
        Assert.False((bool)second["ok"]);
        Assert.Equal("Cannot unlock skill.", second["error"]);
        Assert.Equal(4, state.SkillPoints);
        Assert.Single(state.UnlockedSkills);
    }

    [Fact]
    public void UnlockSkill_WordMasteryWithExactSkillPointsAndPrerequisites_ConsumesAllPoints()
    {
        var state = CreateState(skillPoints: 3);
        state.UnlockedSkills.Add("quick_fingers");
        state.UnlockedSkills.Add("critical_strike");

        Assert.True(Skills.CanUnlock(state, "word_mastery"));

        var result = Skills.UnlockSkill(state, "word_mastery");

        Assert.True((bool)result["ok"]);
        Assert.Equal(0, state.SkillPoints);
        Assert.Contains("word_mastery", state.UnlockedSkills);
    }

    [Fact]
    public void Respec_ClearUnlockedSkills_RemovesPreviouslyAppliedBonuses()
    {
        var state = CreateState();
        state.UnlockedSkills.Add("quick_fingers");
        state.UnlockedSkills.Add("critical_strike");

        Assert.Equal(1.1, Skills.GetBonusValue(state, "damage_mult", 1.0), 3);
        Assert.Equal(0.05, Skills.GetBonusValue(state, "crit_chance"), 3);

        state.UnlockedSkills.Clear();

        Assert.Equal(1.0, Skills.GetBonusValue(state, "damage_mult", 1.0), 3);
        Assert.Equal(0.0, Skills.GetBonusValue(state, "crit_chance"), 3);
    }

    [Fact]
    public void Respec_RefundedPointsCanBeReallocatedToDifferentBranch()
    {
        var state = CreateState(skillPoints: 3);

        var quickUnlock = Skills.UnlockSkill(state, "quick_fingers");
        Assert.True((bool)quickUnlock["ok"]);
        Assert.Equal(2, state.SkillPoints);

        // Simulate reset/refund by clearing unlocked skills and restoring spent points.
        state.UnlockedSkills.Clear();
        state.SkillPoints += 1;

        var defenseUnlock = Skills.UnlockSkill(state, "iron_walls");

        Assert.True((bool)defenseUnlock["ok"]);
        Assert.Equal(2, state.SkillPoints);
        Assert.DoesNotContain("quick_fingers", state.UnlockedSkills);
        Assert.Contains("iron_walls", state.UnlockedSkills);
    }

    [Fact]
    public void GetBonusValue_AdditiveBonusesFromMultipleSkills_StackAdditively()
    {
        const string skillA = "__skills_extended_additive_a";
        const string skillB = "__skills_extended_additive_b";
        var state = CreateState();

        Skills.Registry[skillA] = new SkillDef(
            "Additive A",
            "Test additive bonus A.",
            "combat",
            1,
            new() { ["flat_damage"] = 2.0 },
            null);
        Skills.Registry[skillB] = new SkillDef(
            "Additive B",
            "Test additive bonus B.",
            "combat",
            1,
            new() { ["flat_damage"] = 2.5 },
            null);

        try
        {
            state.UnlockedSkills.Add(skillA);
            state.UnlockedSkills.Add(skillB);

            var result = Skills.GetBonusValue(state, "flat_damage", 1.5);

            Assert.Equal(6.0, result, 3);
        }
        finally
        {
            Skills.Registry.Remove(skillA);
            Skills.Registry.Remove(skillB);
        }
    }

    [Fact]
    public void GetBonusValue_MultiplierBonusesApplyToNonUnitDefault()
    {
        const string skillId = "__skills_extended_mult_default";
        var state = CreateState();

        Skills.Registry[skillId] = new SkillDef(
            "Multiplier Default",
            "Test multiplier bonus.",
            "combat",
            1,
            new() { ["damage_mult"] = 1.25 },
            null);

        try
        {
            state.UnlockedSkills.Add("quick_fingers");
            state.UnlockedSkills.Add(skillId);

            var result = Skills.GetBonusValue(state, "damage_mult", 2.0);

            Assert.Equal(2.75, result, 3);
        }
        finally
        {
            Skills.Registry.Remove(skillId);
        }
    }

    [Fact]
    public void UnlockSkill_UnknownSkillId_ReturnsErrorAndDoesNotMutateState()
    {
        var state = CreateState(skillPoints: 5);
        state.UnlockedSkills.Add("quick_fingers");
        int pointsBefore = state.SkillPoints;
        var unlockedBefore = new HashSet<string>(state.UnlockedSkills);

        var result = Skills.UnlockSkill(state, "__missing_skill");

        Assert.False((bool)result["ok"]);
        Assert.Equal("Cannot unlock skill.", result["error"]);
        Assert.Equal(pointsBefore, state.SkillPoints);
        Assert.True(state.UnlockedSkills.SetEquals(unlockedBefore));
    }

    [Fact]
    public void UnknownUnlockedSkillIds_AreIgnoredByBonusAndAvailabilityQueries()
    {
        var state = CreateState(skillPoints: 1);
        state.UnlockedSkills.Add("__missing_skill");

        var bonus = Skills.GetBonusValue(state, "damage_mult", 1.0);
        var available = Skills.GetAvailableSkills(state);

        Assert.Equal(1.0, bonus, 3);
        Assert.Contains("quick_fingers", available);
    }

    private static GameState CreateState(int skillPoints = 0)
    {
        var state = DefaultState.Create(Guid.NewGuid().ToString("N"));
        state.UnlockedSkills.Clear();
        state.SkillPoints = skillPoints;
        return state;
    }
}
