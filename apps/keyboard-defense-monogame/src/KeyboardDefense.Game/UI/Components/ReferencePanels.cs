using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Progression;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Factory for all reference panels. Each panel is built from data definitions
/// using ReferencePanelBase, replacing 60+ individual Godot panel files.
/// </summary>
public static class ReferencePanels
{
    public static ReferencePanelBase TowerReference()
    {
        var sections = new List<ReferenceSection>();
        foreach (var (id, def) in TowerTypes.TowerStats)
        {
            sections.Add(new ReferenceSection
            {
                Title = def.Name,
                Entries = new()
                {
                    new() { Label = "Type", Value = id },
                    new() { Label = "Category", Value = def.Category.ToString() },
                    new() { Label = "Damage", Value = def.Damage.ToString() },
                    new() { Label = "Range", Value = def.Range.ToString() },
                    new() { Label = "Cooldown", Value = $"{def.Cooldown:F1}s" },
                    new() { Label = "Damage Type", Value = def.DmgType.ToString() },
                    new() { Label = "Target", Value = def.Target.ToString() },
                },
            });
        }
        return new ReferencePanelBase("Tower Reference", sections);
    }

    public static ReferencePanelBase EnemyReference()
    {
        var sections = new List<ReferenceSection>();
        var byTier = EnemyTypes.Registry
            .GroupBy(kv => kv.Value.Tier)
            .OrderBy(g => g.Key);

        foreach (var group in byTier)
        {
            var entries = new List<ReferenceEntry>();
            foreach (var (kind, def) in group)
            {
                string abilities = def.Abilities.Length > 0
                    ? string.Join(", ", def.Abilities)
                    : "none";
                entries.Add(new ReferenceEntry
                {
                    Label = def.Name,
                    Value = $"HP:{def.Hp} DMG:{def.Damage} SPD:{def.Speed} ARM:{def.Armor} | {abilities}",
                });
            }
            sections.Add(new ReferenceSection
            {
                Title = $"Tier: {group.Key}",
                Entries = entries,
            });
        }
        return new ReferencePanelBase("Enemy Reference", sections);
    }

    public static ReferencePanelBase BuildingReference()
    {
        var sections = new List<ReferenceSection>();
        string[] buildingIds = { "farm", "lumber", "quarry", "wall", "tower", "market", "barracks", "temple", "workshop" };

        foreach (string id in buildingIds)
        {
            var def = BuildingsData.GetBuilding(id);
            if (def == null) continue;

            var entries = new List<ReferenceEntry>
            {
                new() { Label = "Category", Value = def.Category },
                new() { Label = "Description", Value = def.Description },
                new() { Label = "Defense", Value = def.Defense.ToString() },
                new() { Label = "Worker Slots", Value = def.WorkerSlots.ToString() },
            };

            foreach (var (res, amount) in def.Cost)
                entries.Add(new ReferenceEntry { Label = $"  Cost ({res})", Value = amount.ToString() });

            foreach (var (res, amount) in def.Production)
                entries.Add(new ReferenceEntry { Label = $"  Produces ({res})", Value = amount.ToString() });

            sections.Add(new ReferenceSection
            {
                Title = def.Name,
                Entries = entries,
            });
        }
        return new ReferencePanelBase("Building Reference", sections);
    }

    public static ReferencePanelBase SkillReference()
    {
        var sections = new List<ReferenceSection>();
        var byCategory = Skills.Registry
            .GroupBy(kv => kv.Value.Category)
            .OrderBy(g => g.Key);

        foreach (var group in byCategory)
        {
            var entries = new List<ReferenceEntry>();
            foreach (var (id, def) in group)
            {
                string bonuses = def.Bonuses.Count > 0
                    ? string.Join(", ", def.Bonuses.Select(kv => $"{kv.Key}:+{kv.Value:F0}%"))
                    : "";
                entries.Add(new ReferenceEntry
                {
                    Label = $"T{def.Tier} {def.Name}",
                    Value = $"{def.Description}" + (bonuses.Length > 0 ? $" [{bonuses}]" : ""),
                });
            }
            sections.Add(new ReferenceSection
            {
                Title = Capitalize(group.Key),
                Entries = entries,
            });
        }
        return new ReferencePanelBase("Skill Reference", sections);
    }

    public static ReferencePanelBase QuestReference()
    {
        var sections = new List<ReferenceSection>();
        var byCategory = Quests.Registry
            .GroupBy(kv => kv.Value.Category)
            .OrderBy(g => g.Key);

        foreach (var group in byCategory)
        {
            var entries = new List<ReferenceEntry>();
            foreach (var (id, def) in group)
            {
                string rewards = def.Rewards.Count > 0
                    ? string.Join(", ", def.Rewards.Select(kv => $"{kv.Key}:{kv.Value}"))
                    : "none";
                entries.Add(new ReferenceEntry
                {
                    Label = def.Name,
                    Value = $"{def.Description} | Reward: {rewards}",
                });
            }
            sections.Add(new ReferenceSection
            {
                Title = Capitalize(group.Key),
                Entries = entries,
            });
        }
        return new ReferencePanelBase("Quest Reference", sections);
    }

    public static ReferencePanelBase ResearchReference()
    {
        var sections = new List<ReferenceSection>();
        foreach (var (id, def) in ResearchData.Registry)
        {
            var entries = new List<ReferenceEntry>
            {
                new() { Label = "Category", Value = def.Category },
                new() { Label = "Gold Cost", Value = $"{def.GoldCost}" },
                new() { Label = "Waves Required", Value = $"{def.WavesRequired}" },
            };

            if (def.Prerequisite != null)
                entries.Add(new ReferenceEntry { Label = "Requires", Value = def.Prerequisite });

            if (def.Effects.Count > 0)
            {
                foreach (var (key, value) in def.Effects)
                    entries.Add(new ReferenceEntry { Label = $"  Effect ({key})", Value = $"+{value:F0}%" });
            }

            sections.Add(new ReferenceSection
            {
                Title = def.Name,
                Entries = entries,
            });
        }
        return new ReferencePanelBase("Research Reference", sections);
    }

    public static ReferencePanelBase StatusEffectsReference()
    {
        var sections = new List<ReferenceSection>();
        foreach (var (id, def) in StatusEffects.Effects)
        {
            var entries = new List<ReferenceEntry>
            {
                new() { Label = "Category", Value = def.Category },
                new() { Label = "Duration", Value = $"{def.Duration:F1}s" },
                new() { Label = "Max Stacks", Value = def.MaxStacks.ToString() },
            };

            if (def.SpeedMod != 0)
                entries.Add(new ReferenceEntry { Label = "Speed Mod", Value = $"{def.SpeedMod:+0%;-0%}" });
            if (def.DotDamage > 0)
                entries.Add(new ReferenceEntry { Label = "DoT Damage", Value = def.DotDamage.ToString() });
            if (def.ArmorMod != 0)
                entries.Add(new ReferenceEntry { Label = "Armor Mod", Value = $"{def.ArmorMod:+0%;-0%}" });
            if (def.DamageTakenMod != 0)
                entries.Add(new ReferenceEntry { Label = "Dmg Taken Mod", Value = $"+{def.DamageTakenMod:P0}" });
            if (def.Immobilized)
                entries.Add(new ReferenceEntry { Label = "Special", Value = "Immobilized" });

            sections.Add(new ReferenceSection
            {
                Title = def.Name,
                Entries = entries,
            });
        }
        return new ReferencePanelBase("Status Effects Reference", sections);
    }

    public static ReferencePanelBase CommandsReference()
    {
        var sections = new List<ReferenceSection>
        {
            new()
            {
                Title = "Day Phase Commands",
                Entries = new()
                {
                    new() { Label = "gather <resource>", Value = "Gather wood, stone, or food (costs 1 AP)" },
                    new() { Label = "build <type> [x y]", Value = "Construct a building at position" },
                    new() { Label = "explore", Value = "Explore nearby terrain (costs 1 AP)" },
                    new() { Label = "trade <from> <to> <amt>", Value = "Trade resources at market" },
                    new() { Label = "research <id>", Value = "Start or continue research" },
                    new() { Label = "hire", Value = "Hire a worker" },
                    new() { Label = "assign <w> <bldg>", Value = "Assign worker to building" },
                    new() { Label = "upgrade <building>", Value = "Upgrade a building" },
                    new() { Label = "end", Value = "End day, begin night phase" },
                },
            },
            new()
            {
                Title = "Night Phase",
                Description = "During night, type the words shown on approaching enemies to damage them.",
                Entries = new()
                {
                    new() { Label = "Type enemy words", Value = "Deals damage matching word length" },
                },
            },
            new()
            {
                Title = "General Commands",
                Entries = new()
                {
                    new() { Label = "status", Value = "Show current game state" },
                    new() { Label = "help", Value = "Show available commands" },
                    new() { Label = "save", Value = "Save current game" },
                    new() { Label = "inspect", Value = "Inspect cursor position" },
                },
            },
        };
        return new ReferencePanelBase("Commands Reference", sections);
    }

    private static string Capitalize(string s)
        => string.IsNullOrEmpty(s) ? s : char.ToUpper(s[0]) + s[1..];
}
