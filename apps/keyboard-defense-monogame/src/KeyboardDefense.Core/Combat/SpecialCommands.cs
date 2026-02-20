using System;
using System.Collections.Generic;
using System.Linq;

namespace KeyboardDefense.Core.Combat;

/// <summary>
/// Special typing commands triggered by specific words.
/// Ported from sim/special_commands.gd.
/// </summary>
public static class SpecialCommands
{
    public static readonly Dictionary<string, SpecialCommandDef> Commands = new()
    {
        ["overcharge"] = new("Overcharge", "Doubles tower damage for 5 seconds.", 30, 1, "combat"),
        ["barrage"] = new("Barrage", "All towers fire rapidly for 3 seconds.", 45, 5, "combat"),
        ["fortify"] = new("Fortify", "Castle gains 3 armor for 10 seconds.", 25, 3, "defense"),
        ["heal"] = new("Heal", "Restores 2 castle HP.", 40, 7, "support"),
        ["freeze"] = new("Freeze", "Slows all enemies by 50% for 5 seconds.", 35, 5, "control"),
        ["fury"] = new("Fury", "Triples combo multiplier for 5 seconds.", 50, 10, "combat"),
        ["gold"] = new("Gold Rush", "Doubles gold earned for 10 seconds.", 20, 3, "economy"),
        ["critical"] = new("Critical Strike", "Next tower attack deals triple damage.", 30, 5, "combat"),
        ["cleave"] = new("Cleave", "Next attack hits all enemies in range.", 40, 8, "combat"),
        ["execute"] = new("Execute", "Instantly kills enemy below 20% HP.", 45, 12, "combat"),
        ["combo"] = new("Combo Boost", "Adds 10 to current combo.", 25, 5, "typing"),
        ["shield"] = new("Shield", "Blocks next 3 damage to castle.", 30, 7, "defense"),
    };

    public static SpecialCommandDef? GetCommand(string id) => Commands.GetValueOrDefault(id);
    public static bool IsValidCommand(string id) => Commands.ContainsKey(id);

    public static List<string> GetUnlockedCommands(int playerLevel)
    {
        return Commands.Keys.Where(id =>
        {
            var def = Commands[id];
            return playerLevel >= def.UnlockLevel;
        }).ToList();
    }
}

public record SpecialCommandDef(string Name, string Description, int Cooldown, int UnlockLevel, string Category);
