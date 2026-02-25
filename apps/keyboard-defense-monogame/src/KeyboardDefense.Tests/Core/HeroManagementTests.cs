using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Balance;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Economy;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class HeroManagementTests
{
    [Fact]
    public void HeroTypeDefinitions_HaveFinitePositiveBonusStats()
    {
        Assert.NotEmpty(HeroTypes.Heroes);

        foreach (var (heroId, heroDef) in HeroTypes.Heroes)
        {
            Assert.False(string.IsNullOrWhiteSpace(heroId));
            Assert.False(string.IsNullOrWhiteSpace(heroDef.Name));
            Assert.False(string.IsNullOrWhiteSpace(heroDef.Description));
            Assert.NotEmpty(heroDef.Bonuses);

            foreach (var (bonusKey, bonusValue) in heroDef.Bonuses)
            {
                Assert.False(string.IsNullOrWhiteSpace(bonusKey));
                Assert.True(double.IsFinite(bonusValue), $"Hero '{heroId}' bonus '{bonusKey}' is not finite.");
                Assert.True(bonusValue > 0, $"Hero '{heroId}' bonus '{bonusKey}' must be positive.");
            }
        }
    }

    [Fact]
    public void HeroRecruitment_HeroSetIntent_AssignsKnownHeroToNewState()
    {
        var state = CreateState();

        var (recruitedState, events) = Apply(state, "hero_set", new()
        {
            ["hero_id"] = "commander"
        });

        Assert.Equal(string.Empty, state.HeroId);
        Assert.Equal("commander", recruitedState.HeroId);
        Assert.Equal("Hero set to: Commander", Assert.Single(events));
    }

    [Fact]
    public void HeroRecruitment_HeroClearIntent_RemovesAssignedHero()
    {
        var state = CreateState();
        state.HeroId = "ranger";

        var (updatedState, events) = Apply(state, "hero_clear");

        Assert.Equal(string.Empty, updatedState.HeroId);
        Assert.Equal("Hero cleared.", Assert.Single(events));
    }

    [Fact]
    public void HeroLeveling_HeroEffectLevelMetadata_RoundTripsAcrossRuntimeAndSave()
    {
        var state = CreateState();
        state.HeroId = "scholar";
        state.HeroActiveEffects.Add(new Dictionary<string, object>
        {
            ["effect_id"] = "battle_hardened",
            ["level"] = 2,
            ["xp"] = 14
        });

        var (runtimeState, _) = Apply(state, "status");
        var runtimeEffect = Assert.Single(runtimeState.HeroActiveEffects);
        Assert.Equal(2, Convert.ToInt32(runtimeEffect["level"]));
        Assert.Equal(14, Convert.ToInt32(runtimeEffect["xp"]));

        string json = SaveManager.StateToJson(runtimeState);
        var (ok, loaded, error) = SaveManager.StateFromJson(json);

        Assert.True(ok, error);
        Assert.NotNull(loaded);

        var loadedEffect = Assert.Single(loaded!.HeroActiveEffects);
        Assert.Equal(2, Convert.ToInt32(loadedEffect["level"]));
        Assert.Equal(14, Convert.ToInt32(loadedEffect["xp"]));
    }

    [Fact]
    public void HeroAbilityActivation_ActiveCooldownAndEffects_PersistThroughIntentApply()
    {
        var state = CreateState();
        state.HeroId = "warrior";
        state.HeroAbilityCooldown = 3.5f;
        state.HeroActiveEffects.Add(new Dictionary<string, object>
        {
            ["ability"] = "battle_cry",
            ["duration"] = 2.0,
            ["damage_mult"] = 1.2
        });

        var (updatedState, events) = Apply(state, "hero_show");

        Assert.Equal("Active hero: warrior", Assert.Single(events));
        Assert.Equal(3.5f, updatedState.HeroAbilityCooldown, 3);
        var effect = Assert.Single(updatedState.HeroActiveEffects);
        Assert.Equal("battle_cry", effect["ability"]);
        Assert.Equal(2.0, Convert.ToDouble(effect["duration"]), 3);
    }

    [Fact]
    public void HeroAbilityActivation_HeroClear_OnlyClearsHeroSelection()
    {
        var state = CreateState();
        state.HeroId = "warrior";
        state.HeroAbilityCooldown = 5.0f;
        state.HeroActiveEffects.Add(new Dictionary<string, object>
        {
            ["ability"] = "fortify",
            ["duration"] = 3
        });

        var (updatedState, events) = Apply(state, "hero_clear");

        Assert.Equal("Hero cleared.", Assert.Single(events));
        Assert.Equal(string.Empty, updatedState.HeroId);
        Assert.Equal(5.0f, updatedState.HeroAbilityCooldown, 3);
        Assert.Single(updatedState.HeroActiveEffects);
    }

    [Fact]
    public void HeroEquipmentSlots_EquippingItems_UsesExpectedSlotKeys()
    {
        var state = CreateState();
        state.HeroId = "warrior";

        Assert.True(Items.Equip(state, "steel_sword"));
        Assert.True(Items.Equip(state, "steel_armor"));
        Assert.True(Items.Equip(state, "swift_boots"));
        Assert.True(Items.Equip(state, "power_ring"));
        Assert.True(Items.Equip(state, "guardian_shield"));
        Assert.True(Items.Equip(state, "arcane_amulet"));

        Assert.Equal(
            new HashSet<string>(StringComparer.Ordinal)
            {
                "weapon",
                "armor",
                "boots",
                "ring",
                "shield",
                "amulet"
            },
            state.EquippedItems.Keys.ToHashSet(StringComparer.Ordinal));
    }

    [Fact]
    public void HeroEquipmentSlots_ReequippingSameSlot_ReplacesPreviousItemStats()
    {
        var state = CreateState();
        state.HeroId = "warrior";

        Assert.True(Items.Equip(state, "iron_sword"));
        Assert.True(Items.Equip(state, "steel_sword"));

        Assert.Single(state.EquippedItems);
        Assert.Equal("steel_sword", state.EquippedItems["weapon"]);

        Dictionary<string, int> totals = Items.GetTotalEquipmentStats(state);
        Assert.Equal(6, totals["damage"]);
    }

    [Fact]
    public void HeroSynergyWithTowers_CommanderBonus_StacksWithKillBoxSynergy()
    {
        var state = CreateState();
        state.HeroId = "commander";
        state.Structures.Clear();

        var cannonPos = state.BasePos;
        var frostPos = new GridPoint(cannonPos.X + 1, cannonPos.Y);
        state.Structures[cannonPos.ToIndex(state.MapW)] = TowerTypes.Cannon;
        state.Structures[frostPos.ToIndex(state.MapW)] = TowerTypes.Frost;

        List<string> activeSynergies = SynergyDetector.DetectActiveSynergies(state);
        Assert.Contains("kill_box", activeSynergies);

        int baseDamage = TowerTypes.GetTowerData(TowerTypes.Cannon)!.Damage;
        int leveledDamage = SimBalance.CalculateTowerDamage(baseDamage, level: 3);
        double synergyMult = SynergyDetector.GetSynergyDamageMultiplier(activeSynergies);

        int noHeroDamage = (int)(leveledDamage * synergyMult);
        int scholarDamage = (int)(leveledDamage * synergyMult * HeroTypes.GetHeroBonus("scholar", "tower_damage", 1.0));
        int commanderDamage = (int)(leveledDamage * synergyMult * HeroTypes.GetHeroBonus("commander", "tower_damage", 1.0));

        Assert.Equal(noHeroDamage, scholarDamage);
        Assert.True(commanderDamage > noHeroDamage);
    }

    private static GameState CreateState()
    {
        return DefaultState.Create();
    }

    private static (GameState State, List<string> Events) Apply(
        GameState state,
        string kind,
        Dictionary<string, object>? data = null)
    {
        var result = IntentApplier.Apply(state, SimIntents.Make(kind, data));
        var newState = Assert.IsType<GameState>(result["state"]);
        var events = Assert.IsType<List<string>>(result["events"]);
        return (newState, events);
    }
}
