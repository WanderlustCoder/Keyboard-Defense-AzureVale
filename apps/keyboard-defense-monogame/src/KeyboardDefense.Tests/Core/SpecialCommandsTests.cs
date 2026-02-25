using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Combat;

namespace KeyboardDefense.Tests.Core;

public class SpecialCommandsTests
{
    [Fact]
    public void IsValidCommand_AllRegisteredCommands_AreRecognized()
    {
        foreach (var commandId in SpecialCommands.Commands.Keys)
            Assert.True(SpecialCommands.IsValidCommand(commandId), $"Expected '{commandId}' to be recognized.");
    }

    [Fact]
    public void GetCommand_Overcharge_ReturnsExpectedCombatBoostDefinition()
    {
        var command = SpecialCommands.GetCommand("overcharge");

        Assert.NotNull(command);
        Assert.Equal("Overcharge", command!.Name);
        Assert.Equal("Doubles tower damage for 5 seconds.", command.Description);
        Assert.Equal(30, command.Cooldown);
        Assert.Equal(1, command.UnlockLevel);
        Assert.Equal("combat", command.Category);
    }

    [Fact]
    public void GetCommand_Heal_ReturnsExpectedSupportDefinition()
    {
        var command = SpecialCommands.GetCommand("heal");

        Assert.NotNull(command);
        Assert.Equal("Heal", command!.Name);
        Assert.Equal("Restores 2 castle HP.", command.Description);
        Assert.Equal(40, command.Cooldown);
        Assert.Equal(7, command.UnlockLevel);
        Assert.Equal("support", command.Category);
    }

    [Fact]
    public void GetCommand_UnknownCommand_ReturnsNull()
    {
        Assert.Null(SpecialCommands.GetCommand("meteor"));
    }

    [Fact]
    public void IsValidCommand_UnknownAndWrongCasing_ReturnFalse()
    {
        Assert.False(SpecialCommands.IsValidCommand("meteor"));
        Assert.False(SpecialCommands.IsValidCommand("Overcharge"));
        Assert.False(SpecialCommands.IsValidCommand("OVERCHARGE"));
    }

    [Fact]
    public void GetUnlockedCommands_LevelZero_ReturnsEmpty()
    {
        var unlocked = SpecialCommands.GetUnlockedCommands(0);
        Assert.Empty(unlocked);
    }

    [Fact]
    public void GetUnlockedCommands_LevelThree_ReturnsOnlyEligibleCommands()
    {
        var unlocked = SpecialCommands.GetUnlockedCommands(3);
        var expected = new HashSet<string>(StringComparer.Ordinal)
        {
            "overcharge",
            "fortify",
            "gold",
        };

        Assert.Equal(expected.Count, unlocked.Count);
        Assert.True(unlocked.All(expected.Contains));
    }

    [Fact]
    public void GetUnlockedCommands_MaxUnlockLevel_ReturnsAllCommandsWithPositiveCooldowns()
    {
        var unlocked = SpecialCommands.GetUnlockedCommands(12);

        Assert.Equal(SpecialCommands.Commands.Count, unlocked.Count);
        foreach (var commandId in unlocked)
        {
            var def = SpecialCommands.GetCommand(commandId);
            Assert.NotNull(def);
            Assert.True(def!.Cooldown > 0, $"Expected '{commandId}' to have a positive cooldown.");
            Assert.False(string.IsNullOrWhiteSpace(def.Description));
        }
    }
}
