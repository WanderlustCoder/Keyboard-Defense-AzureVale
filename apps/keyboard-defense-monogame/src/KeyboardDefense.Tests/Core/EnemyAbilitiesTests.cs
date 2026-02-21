using System.Collections.Generic;
using KeyboardDefense.Core.Combat;

namespace KeyboardDefense.Tests.Core;

public class EnemyAbilitiesTests
{
    [Fact]
    public void Abilities_Dictionary_HasElevenExpectedAbilityIds()
    {
        Assert.Equal(11, EnemyAbilities.Abilities.Count);
        Assert.Contains("fortified", EnemyAbilities.Abilities.Keys);
        Assert.Contains("enrage", EnemyAbilities.Abilities.Keys);
        Assert.Contains("ghostly", EnemyAbilities.Abilities.Keys);
        Assert.Contains("heal_aura", EnemyAbilities.Abilities.Keys);
        Assert.Contains("taunt", EnemyAbilities.Abilities.Keys);
        Assert.Contains("rally", EnemyAbilities.Abilities.Keys);
        Assert.Contains("spell_shield", EnemyAbilities.Abilities.Keys);
        Assert.Contains("blood_frenzy", EnemyAbilities.Abilities.Keys);
        Assert.Contains("summon_spawn", EnemyAbilities.Abilities.Keys);
        Assert.Contains("void_armor", EnemyAbilities.Abilities.Keys);
        Assert.Contains("regeneration", EnemyAbilities.Abilities.Keys);
    }

    [Fact]
    public void GetAbility_Fortified_ReturnsExpectedDefinition()
    {
        var ability = EnemyAbilities.GetAbility("fortified");

        Assert.NotNull(ability);
        Assert.Equal("Fortified", ability!.Name);
        Assert.Equal(EnemyAbilities.AbilityType.Passive, ability.Type);
        Assert.Null(ability.Trigger);
        Assert.Null(ability.Cooldown);
    }

    [Fact]
    public void GetAbility_UnknownId_ReturnsNull()
    {
        Assert.Null(EnemyAbilities.GetAbility("unknown_ability"));
    }

    [Fact]
    public void HasPassive_FortifiedInAbilities_ReturnsTrue()
    {
        var enemy = CreateEnemy(abilities: new List<object> { "fortified" });

        Assert.True(EnemyAbilities.HasPassive(enemy, "fortified"));
    }

    [Fact]
    public void HasPassive_EnrageInAbilities_ReturnsFalseBecauseItIsTrigger()
    {
        var enemy = CreateEnemy(abilities: new List<object> { "enrage" });

        Assert.False(EnemyAbilities.HasPassive(enemy, "enrage"));
    }

    [Fact]
    public void HasPassive_MissingAbilitiesList_ReturnsFalse()
    {
        var enemy = new Dictionary<string, object>
        {
            ["armor"] = 3,
            ["speed"] = 20,
            ["hp"] = 100,
            ["max_hp"] = 100,
        };

        Assert.False(EnemyAbilities.HasPassive(enemy, "fortified"));
    }

    [Fact]
    public void HasPassive_UnknownAbilityInList_ReturnsFalse()
    {
        var enemy = CreateEnemy(abilities: new List<object> { "made_up" });

        Assert.False(EnemyAbilities.HasPassive(enemy, "made_up"));
    }

    [Fact]
    public void GetEffectiveArmor_WithoutFortified_ReturnsBaseArmor()
    {
        var enemy = CreateEnemy(armor: 7, abilities: new List<object> { "ghostly" });

        Assert.Equal(7, EnemyAbilities.GetEffectiveArmor(enemy));
    }

    [Fact]
    public void GetEffectiveArmor_WithFortified_AddsThreeArmor()
    {
        var enemy = CreateEnemy(armor: 7, abilities: new List<object> { "fortified" });

        Assert.Equal(10, EnemyAbilities.GetEffectiveArmor(enemy));
    }

    [Fact]
    public void GetEffectiveArmor_WithTriggerAbilityOnly_DoesNotAddArmor()
    {
        var enemy = CreateEnemy(armor: 7, abilities: new List<object> { "enrage" });

        Assert.Equal(7, EnemyAbilities.GetEffectiveArmor(enemy));
    }

    [Fact]
    public void GetEffectiveSpeed_EnragedMissing_ReturnsBaseSpeed()
    {
        var enemy = CreateEnemy(speed: 20);

        Assert.Equal(20, EnemyAbilities.GetEffectiveSpeed(enemy));
    }

    [Fact]
    public void GetEffectiveSpeed_EnragedFalse_ReturnsBaseSpeed()
    {
        var enemy = CreateEnemy(speed: 20, enraged: false);

        Assert.Equal(20, EnemyAbilities.GetEffectiveSpeed(enemy));
    }

    [Fact]
    public void GetEffectiveSpeed_EnragedTrue_MultipliesByOnePointFive()
    {
        var enemy = CreateEnemy(speed: 21, enraged: true);

        Assert.Equal(31, EnemyAbilities.GetEffectiveSpeed(enemy));
    }

    [Fact]
    public void HandleTrigger_Enrage_OnLowHpAtHalf_SetsEnragedTrue()
    {
        var enemy = CreateEnemy(hp: 50, maxHp: 100, abilities: new List<object> { "enrage" });

        EnemyAbilities.HandleTrigger(enemy, EnemyAbilities.TriggerEvent.OnLowHp);

        Assert.True(enemy.GetValueOrDefault("enraged") is true);
    }

    [Fact]
    public void HandleTrigger_Enrage_OnLowHpBelowHalf_SetsEnragedTrue()
    {
        var enemy = CreateEnemy(hp: 49, maxHp: 100, abilities: new List<object> { "enrage" });

        EnemyAbilities.HandleTrigger(enemy, EnemyAbilities.TriggerEvent.OnLowHp);

        Assert.True(enemy.GetValueOrDefault("enraged") is true);
    }

    [Fact]
    public void HandleTrigger_Enrage_OnLowHpAboveHalf_DoesNotSetEnraged()
    {
        var enemy = CreateEnemy(hp: 51, maxHp: 100, enraged: false, abilities: new List<object> { "enrage" });

        EnemyAbilities.HandleTrigger(enemy, EnemyAbilities.TriggerEvent.OnLowHp);

        Assert.False(enemy.GetValueOrDefault("enraged") is true);
    }

    [Fact]
    public void HandleTrigger_Enrage_WithNonMatchingTrigger_DoesNotSetEnraged()
    {
        var enemy = CreateEnemy(hp: 10, maxHp: 100, enraged: false, abilities: new List<object> { "enrage" });

        EnemyAbilities.HandleTrigger(enemy, EnemyAbilities.TriggerEvent.OnDamage);

        Assert.False(enemy.GetValueOrDefault("enraged") is true);
    }

    [Fact]
    public void HandleTrigger_BloodFrenzy_OnAllyDeath_AddsTenSpeed()
    {
        var enemy = CreateEnemy(speed: 15, abilities: new List<object> { "blood_frenzy" });

        EnemyAbilities.HandleTrigger(enemy, EnemyAbilities.TriggerEvent.OnAllyDeath);

        Assert.Equal(25, enemy["speed"]);
    }

    [Fact]
    public void HandleTrigger_BloodFrenzy_WithNonMatchingTrigger_DoesNotChangeSpeed()
    {
        var enemy = CreateEnemy(speed: 15, abilities: new List<object> { "blood_frenzy" });

        EnemyAbilities.HandleTrigger(enemy, EnemyAbilities.TriggerEvent.OnAttack);

        Assert.Equal(15, enemy["speed"]);
    }

    [Fact]
    public void HandleTrigger_MissingAbilitiesList_DoesNothing()
    {
        var enemy = new Dictionary<string, object>
        {
            ["speed"] = 12,
            ["hp"] = 40,
            ["max_hp"] = 100,
            ["enraged"] = false,
        };

        EnemyAbilities.HandleTrigger(enemy, EnemyAbilities.TriggerEvent.OnLowHp);
        EnemyAbilities.HandleTrigger(enemy, EnemyAbilities.TriggerEvent.OnAllyDeath);

        Assert.Equal(12, enemy["speed"]);
        Assert.False((bool)enemy["enraged"]);
    }

    private static Dictionary<string, object> CreateEnemy(
        int armor = 0,
        int speed = 0,
        int hp = 100,
        int maxHp = 100,
        bool? enraged = null,
        List<object>? abilities = null)
    {
        var enemy = new Dictionary<string, object>
        {
            ["armor"] = armor,
            ["speed"] = speed,
            ["hp"] = hp,
            ["max_hp"] = maxHp,
        };

        if (enraged.HasValue)
            enemy["enraged"] = enraged.Value;

        if (abilities != null)
            enemy["abilities"] = abilities;

        return enemy;
    }
}
